import pandas as pd
import numpy as np

# Для работы с матрицами
from scipy.sparse import csr_matrix

# Матричная факторизация
from implicit.als import AlternatingLeastSquares
from implicit.nearest_neighbours import ItemItemRecommender  # нужен для одного трюка
from implicit.nearest_neighbours import bm25_weight, tfidf_weight


class MainRecommender:

    def __init__(self,
                 weighting: str = 'bm25',
                 n_factors: int = 100,
                 regularization: float = 0.001,
                 iterations: int = 15,
                 num_threads: int = 4,
                 verbose: bool = True):

        self.weighting = weighting
        self.n_factors = n_factors
        self.regularization = regularization
        self.iterations = iterations
        self.num_threads = num_threads
        self.verbose = verbose

        self.data = None
        self.user_item_matrix = None
        self.id_to_itemid = None
        self.id_to_userid = None
        self.itemid_to_id = None
        self.userid_to_id = None
        self.model = None
        self.own_recommender_model = None
        self.users_top_purchases = None
        self.overall_top_purchases = None

    def get_user_top_purchases(self,
                               user_col: str = 'user_id',
                               item_col: str = 'item_id',
                               values: str = 'quantity'):
        """Топ товаров с группировкой по user"""

        self.users_top_purchases = self.data.groupby([user_col, item_col])[
            values].count().reset_index()
        self.users_top_purchases.sort_values(
            values, ascending=False, inplace=True)
        self.users_top_purchases = self.users_top_purchases[self.users_top_purchases[item_col] != 999999]

    def get_top_purchases(self,
                          item_col: str = 'item_id',
                          values: str = 'quantity'):
        """Топ товаров по всему датасету"""

        self.overall_top_purchases = self.data.groupby(
            item_col)[values].count().reset_index()
        self.overall_top_purchases.sort_values(
            values, ascending=False, inplace=True)
        self.overall_top_purchases = self.overall_top_purchases[
            self.overall_top_purchases[item_col] != 999999]
        self.overall_top_purchases = self.overall_top_purchases.item_id.tolist()

    def prepare_matrix(self,
                       index: str = 'user_id',
                       columns: str = 'item_id',
                       values: str = 'quantity'):
        """Создание матрицы user-item"""

        user_item_matrix = pd.pivot_table(self.data,
                                          index=index,
                                          columns=columns,
                                          values=values,
                                          aggfunc='count',
                                          fill_value=0)

        self.user_item_matrix = user_item_matrix.astype(float)

    def prepare_dicts(self):
        """Создание словарей связи матриц (user_item_matrix/ sparse)"""

        userids = self.user_item_matrix.index.values
        itemids = self.user_item_matrix.columns.values

        matrix_userids = np.arange(len(userids))
        matrix_itemids = np.arange(len(itemids))

        self.id_to_itemid = dict(zip(matrix_itemids, itemids))
        self.id_to_userid = dict(zip(matrix_userids, userids))

        self.itemid_to_id = dict(zip(itemids, matrix_itemids))
        self.userid_to_id = dict(zip(userids, matrix_userids))

    def fit_own_recommender(self):
        """ Собсвенные рекомендации"""

        self.own_recommender_model = ItemItemRecommender(K=1, num_threads=4)
        self.own_recommender_model.fit(csr_matrix(self.user_item_matrix).T, show_progress=self.verbose)

    def fit(self, data):

        self.data = data
        self.prepare_matrix()
        self.prepare_dicts()
        self.get_user_top_purchases()
        self.get_top_purchases()

        if self.weighting == 'bm25':
            self.user_item_matrix = bm25_weight(self.user_item_matrix.T).T
        if self.weighting == 'tfidf':
            self.user_item_matrix = tfidf_weight(self.user_item_matrix.T).T

        self.model = AlternatingLeastSquares(factors=self.n_factors,
                                             regularization=self.regularization,
                                             iterations=self.iterations,
                                             num_threads=self.num_threads,
                                             random_state=13)

        self.model.fit(csr_matrix(self.user_item_matrix).T, show_progress=self.verbose)

        return self.model

    def update_dict(self, user_id):
        """Если появился новыю user / item, то нужно обновить словари"""

        if user_id not in self.userid_to_id.keys():
            max_id = max(list(self.userid_to_id.values()))
            max_id += 1

            self.userid_to_id.update({user_id: max_id})
            self.id_to_userid.update({max_id: user_id})

    def get_similar_item(self, item_id):
        """Находит товар, похожий на item_id"""

        recs = self.model.similar_items(
            self.itemid_to_id[item_id], N=2)  # Товар похож на себя -> рекомендуем 2 товара
        top_rec = recs[1][0]  # И берем второй (не товар из аргумента метода)
        return self.id_to_itemid[top_rec]

    def extend_with_top_popular(self, recommendations, N=5):
        """Если кол-во рекоммендаций < N, то дополняем их топ-популярными"""

        if len(recommendations) < N:
            recommendations.extend(self.overall_top_purchases[:N])
            recommendations = recommendations[:N]

        return recommendations

    def get_recommendations(self, user, model, N=5):
        """Рекомендации через стардартные библиотеки implicit"""

        self.update_dict(user_id=user)
        res = [self.id_to_itemid[rec[0]] for rec in model.recommend(userid=self.userid_to_id[user],
                                                                    user_items=csr_matrix(
                                                                        self.user_item_matrix),
                                                                    N=N,
                                                                    filter_already_liked_items=False,
                                                                    filter_items=[
                                                                        self.itemid_to_id[999999]],
                                                                    recalculate_user=False)]

        res = self.extend_with_top_popular(res, N=N)

        assert len(res) == N, 'Количество рекомендаций != {}'.format(N)
        return res

    def get_als_recommendations(self, user, N=5):
        """Рекомендации через стардартные библиотеки implicit"""

        self.update_dict(user_id=user)
        return self.get_recommendations(user, model=self.model, N=N)

    def get_own_recommendations(self, user, N=5):
        """Рекомендуем товары среди тех, которые юзер уже купил"""
        
        self.update_dict(user_id=user)
        self.fit_own_recommender()
        return self.get_recommendations(user, model=self.own_recommender_model, N=N)

    def get_similar_items_recommendation(self, user_id, N=5):
        """Рекомендуем товары, похожие на топ-N купленных юзером товаров"""

        top_users_purchases = self.users_top_purchases[self.users_top_purchases['user_id'] == user_id].head(
            N)

        res = top_users_purchases['item_id'].apply(
            lambda x: self.get_similar_item(x)).tolist()
        res = self.extend_with_top_popular(res, N=N)

        return res

    def get_similar_users_recommendation(self, user_id, N=5):
        """Рекомендуем топ-N товаров, среди купленных похожими юзерами"""

        res = []

        # Находим топ-N похожих пользователей
        similar_users = self.model.similar_users(
            self.userid_to_id[user_id], N=N + 1)
        similar_users = [self.id_to_userid[rec[0]] for rec in similar_users]
        similar_users = similar_users[1:]  # удалим юзера из запроса

        for _user_id in similar_users:
            res.extend(self.get_own_recommendations(_user_id, N=1))

        res = self.extend_with_top_popular(res, N=N)

        return res
