import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


def prefilter_items(data: pd.DataFrame,
                    group_col: str = None,
                    popular_col: str = None,
                    time_col: str = None,
                    price_col: str = None,
                    top_popular_filter_del: int = None,
                    top_popular_filter_choose: int = None,
                    last_weeks_top_popular: int = 6,
                    last_weeks_n_top_add: int = None,
                    top_unpopular_filter: int = None,
                    time_unpopular_filter: int = None,
                    chip_item_filter: int = None,
                    exp_item_filter: int = None) -> pd.DataFrame:
    """
Заменяет Item на фиктивный в датасете по набору условий
    """

    n_filter_start = (data[group_col] == 999999).sum()

    popularity = data.groupby(group_col)[popular_col].sum().reset_index()

    popularity_last_weeks = data[data['week_no'] >= data['week_no'].max() - last_weeks_top_popular].groupby(group_col)[
        popular_col].sum().reset_index()

    if top_popular_filter_choose:  # оставляет N самых полулярных товаров

        top = popularity.sort_values(popular_col, ascending=False).head(
            top_popular_filter_choose).item_id.tolist()

        if last_weeks_n_top_add:
            top_last_weeks = popularity_last_weeks.sort_values(popular_col, ascending=False).head(
                last_weeks_n_top_add).item_id.tolist()
            top = list(set(top + top_last_weeks))

        data.loc[~data[group_col].isin(top), group_col] = 999999

    if top_popular_filter_del:  # фильтр самых популярных  (которые и так купят)

        top = popularity.sort_values(popular_col, ascending=False).head(
            top_popular_filter_del).item_id.tolist()
        data.loc[data[group_col].isin(top), group_col] = 999999

    if top_unpopular_filter:  # фильтр самых популярных товаров

        bottom = popularity.sort_values(
            popular_col, ascending=True).head(top_unpopular_filter).item_id.tolist()
        data.loc[data[group_col].isin(bottom), group_col] = 999999

    if time_unpopular_filter:  # фильтр товаров, которые не продавались за последние N месяцев

        actuality = data.groupby(group_col)[time_col].min().reset_index()
        top_actual = actuality[actuality[time_col] > 365].item_id.tolist()
        data.loc[data[group_col].isin(top_actual), group_col] = 999999

    if chip_item_filter:  # Фильт товаров, которые стоят < N$

        low_price = data[data[price_col] < chip_item_filter].item_id.tolist()
        data.loc[data[group_col].isin(low_price), group_col] = 999999

    if exp_item_filter:  # Фильт товаров, которые стоят > N$ (дорогих)

        high_price = data[data[price_col] > exp_item_filter].item_id.tolist()
        data.loc[data[group_col].isin(high_price), group_col] = 999999

    n_filter = (data[group_col] == 999999).sum() - n_filter_start
    print(f'Отфильтровано {n_filter} записей')

    return data


def reduce_mem_usage(df):
    """ iterate through all the columns of a dataframe and modify the data type
        to reduce memory usage.
    """
    start_mem = df.memory_usage().sum() / 1024 ** 2
    print('Memory usage of dataframe is {:.2f} MB'.format(start_mem))
    for col in df.columns:
        col_type = df[col].dtype
        if col_type != object:
            c_min = df[col].min()
            c_max = df[col].max()
            if str(col_type)[:3] == 'int':
                if c_min > np.iinfo(np.int8).min and c_max < np.iinfo(np.int8).max:
                    df[col] = df[col].astype(np.int8)
                elif c_min > np.iinfo(np.int16).min and c_max < np.iinfo(np.int16).max:
                    df[col] = df[col].astype(np.int16)
                elif c_min > np.iinfo(np.int32).min and c_max < np.iinfo(np.int32).max:
                    df[col] = df[col].astype(np.int32)
                elif c_min > np.iinfo(np.int64).min and c_max < np.iinfo(np.int64).max:
                    df[col] = df[col].astype(np.int64)
            else:
                if c_min > np.finfo(np.float32).min and c_max < np.finfo(np.float32).max:
                    df[col] = df[col].astype(np.float32)
                else:
                    df[col] = df[col].astype(np.float64)
        else:
            df[col] = df[col].astype('category')
    end_mem = df.memory_usage().sum() / 1024 ** 2
    print('Memory usage after optimization is: {:.2f} MB'.format(end_mem))
    print('Decreased by {:.1f}%'.format(
        100 * (start_mem - end_mem) / start_mem))

    return df

def show_feature_importances(feature_names, feature_importances, get_top=None):
    feature_importances = pd.DataFrame(
        {'feature': feature_names, 'importance': feature_importances})
    feature_importances = feature_importances.sort_values(
        'importance', ascending=False)

    plt.figure(figsize=(10, len(feature_importances) * 0.3))

    sns.barplot(feature_importances['importance'],
                feature_importances['feature'])

    plt.xlabel('Importance')
    plt.title('Importance of features')
    plt.show()

    if get_top is not None:
        return feature_importances['feature'][:get_top].tolist()
