import numpy as np


def hit_rate(recommended_list, bought_list, top_k: int = None):
    """
    = (был ли хотя бы 1 релевантный товар среди топ-k рекомендованных)
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: Hit rate@k {0, 1}
    """

    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)
    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)
    flags = np.isin(bought_list, recommended_list[:top_k])

    return (flags.sum() > 0) * 1


def precision(recommended_list, bought_list, top_k: int = None):
    """
    Precision@k = (# of recommended items @k that are relevant) / (# of recommended items @k)
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: float
    """

    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)
    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)
    flags = np.isin(bought_list, recommended_list[:top_k])

    return flags.sum() / len(recommended_list[:top_k])


def money_precision(recommended_list, bought_list, prices_recommended, top_k: int = None):
    """
    Money Precision@k = (revenue of recommended items @k that are relevant) / (revenue of recommended items @k)
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :param prices_recommended: цена рекоммендованных товаров
    :return: float
    """
    recommend_list = np.array(recommended_list)
    bought_list = np.array(bought_list)
    prices_recommended = np.array(prices_recommended)

    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)

    flags = np.isin(recommend_list[:top_k], bought_list)
    m_precision = np.dot(flags, prices_recommended[:top_k]).sum() / prices_recommended[:top_k].sum()

    return m_precision


def recall(recommended_list, bought_list, top_k: int = None):
    """
    Recall@k = (N of recommended items @k that are relevant) / (N of relevant items)
     доля рекомендованных товаров среди релевантных = Какой % купленных товаров был среди рекомендованных
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: float
    """

    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)
    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)
    flags = np.isin(bought_list, recommended_list[:top_k])

    return flags.sum() / len(bought_list)


def money_recall(recommended_list, bought_list, prices_recommended, prices_bought, top_k: int = None):
    """
    Money Recall@k = (revenue of recommended items @k that are relevant) / (revenue of relevant items)
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :param prices_recommended: цена рекоммендованных товаров
    :param prices_bought:
    :return: float
    """
    bought_list = np.array(bought_list)
    prices_bought = np.array(prices_bought)
    recommended_list = np.array(recommended_list)
    prices_recommended = np.array(prices_recommended)
    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)

    flags = np.isin(recommended_list[:top_k], bought_list)
    m_recall = np.dot(flags, prices_recommended[:top_k]).sum() / prices_bought.sum()

    return m_recall


def ap(recommended_list, bought_list, top_k: int = None):
    """
    AP@k - average precision at k
    Суммируем по всем релевантным товарам
    Зависит от порядка реокмендаций
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: float
    """
    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)
    if top_k:
        if top_k > len(recommended_list) | top_k is None:
            top_k = len(recommended_list)

    relevant_indexes = np.nonzero(np.isin(recommended_list[:top_k], bought_list))[0]
    if len(relevant_indexes) == 0:
        return 0

    amount_relevant = len(relevant_indexes)
    sum_ = sum([precision(recommended_list, bought_list, top_k=index_relevant + 1)
                for index_relevant in relevant_indexes])
    return sum_ / amount_relevant


def map_at_k(recommended_list, bought_list, top_k: int = None):
    """
    MAP@k (Mean Average Precision@k)
    Среднее AP@k по всем юзерам
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: float
    """
    sum_ap = 0
    n_users = len(recommended_list)

    if n_users == 0:
        return 0

    for user in range(n_users):
        sum_ap += ap(recommended_list[user], bought_list[user], top_k)

    return sum_ap / n_users


def ndcg_at_k(recommended_list, bought_list, top_k, return_dcg=False):
    """
    Normalized discounted cumulative gain ( NDCG@k)
    :param return_dcg: if True returns dcg, ndcg_at_k
    :param recommended_list: список рекоммендованых товаров
    :param bought_list: список купленных товаров
    :param top_k: топ k товаров
    :return: float ndcg_at_k | dcg, ndcg_at_k
    """
    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)

    if top_k > len(recommended_list):
        top_k = len(recommended_list)
    if top_k == 0:
        return 0
    flags = np.isin(recommended_list[:top_k], bought_list)
    gain_array = [1 / i if i < 3 else 1 / np.log2(i) for i in range(1, top_k + 1)]
    ideal_dcg = sum(gain_array) / top_k
    dcg = np.dot(flags, np.array(gain_array)) / top_k

    if return_dcg:
        return dcg, dcg / ideal_dcg

    return dcg / ideal_dcg


def reciprocal_rank(recommended_list, bought_list, top_k):
    """
    Mean Reciprocal Rank ( MRR@k )
    :param recommended_list: списки рекомендованных товаров для пользователей
    :param bought_list: списки покупок пользователей
    :param top_k: топ k товаров
    :return: float
    """
    bought_list = np.array(bought_list)
    recommended_list = np.array(recommended_list)
    sum_ku = 0

    if top_k > len(recommended_list[0]):
        top_k = len(recommended_list[0])

    n_users = len(recommended_list)
    if n_users == 0:
        return 0

    for user in range(n_users):
        try:
            ku = np.nonzero(np.isin(recommended_list[user][:top_k], bought_list[user]))[0][0] + 1
            sum_ku += 1 / ku
        except IndexError:
            continue

    return sum_ku / n_users
