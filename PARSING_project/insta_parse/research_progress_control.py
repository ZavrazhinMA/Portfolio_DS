from db_model import DataBase, UsersHandShake
from scrapy.exceptions import CloseSpider


def db_next_user_query(side, level):
    user_list = []
    database = DataBase("sqlite:///handshake_check.db")
    Session = database.maker
    session = Session()
    temp = session.query(UsersHandShake.username) \
        .filter(UsersHandShake.side == side) \
        .filter(UsersHandShake.relative_level == level) \
        .all()
    for el in temp:
        user_list.append(el[0])
    return user_list


def search_control(username, side, parent, level):
    if side == 1:
        opposite_side = 2
    else:
        opposite_side = 1
    database = DataBase("sqlite:///handshake_check.db")
    Session = database.maker
    session = Session()
    query = session.query(UsersHandShake.username) \
        .filter(UsersHandShake.side == opposite_side) \
        .filter(UsersHandShake.username == username) \
        .first()
    if not query:
        return 1
    else:
        chain_scheme(username, side, parent)
        print(f'Связь найдена на уровне вложенности {level}.\n'
              f' Цепочка будет восстановлена и сохранена в файл final_chain.txt\n'
              f'Работа паука будет завершена')
        raise CloseSpider


def chain_scheme(username, side, parent):
    list_side_1 = []
    list_side_2 = []
    full_chain = []
    user_1, user_2 = read_users('main_users.txt')
    user_1 = user_1.replace('\n', '')
    user_2 = user_2.replace('\n', '')

    if side == 2:
        query_username = parent
        if query_username != user_2:
            while query_username != user_2:
                list_side_2.append(query_username)
                query_username = chain_queries(query_username, 2)
        query_username = username
        while query_username != user_1:
            list_side_1.append(query_username)
            query_username = chain_queries(query_username, 1)
    else:
        query_username = username

        while query_username != user_2:
            list_side_2.append(query_username)
            query_username = chain_queries(query_username, 2)
        query_username = parent
        if query_username != user_1:
            while query_username != user_1:
                list_side_1.append(query_username)
                query_username = chain_queries(query_username, 1)

    list_side_1 = list(reversed(list_side_1))
    full_chain.append(user_1)
    full_chain.extend(list_side_1)
    full_chain.extend(list_side_2)
    full_chain.append(user_2)
    with open('final_chain.txt', "w", encoding="UTF-8") as file:
        for num, user in enumerate(full_chain, 1):
            line = f'{num}) https://www.instagram.com/{user}/\n'
            file.write(line)


def chain_queries(username, side):
    database = DataBase("sqlite:///handshake_check.db")
    Session = database.maker
    session = Session()
    username = session.query(UsersHandShake.parent_user) \
        .filter(UsersHandShake.side == side) \
        .filter(UsersHandShake.username == username) \
        .first()
    return username[0]


def read_users(file):
    data = []
    with open(file) as f:
        for line in f:
            data.append(line)
    return data[0], data[1]


# if __name__ == "__main__":
#     # user_1, user_2 = read_users('main_users.txt')
#     print(user_1, user_2)
