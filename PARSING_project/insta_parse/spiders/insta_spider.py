import scrapy
import os
import json
import time
from scrapy.exceptions import CloseSpider
from ..research_progress_control import db_next_user_query


class InstaSpider(scrapy.Spider):
    name = 'insta_spider'
    allowed_domains = ['www.instagram.com']
    start_urls = ['https://www.instagram.com/']
    _login_url = "https://www.instagram.com/accounts/login/ajax/"
    query_url = "https://www.instagram.com/graphql/query/"
    query = {
        'edge_follow': '3dec7e2c57367ef3da3d987d89f9dbc8',
        'edge_followed_by': '5aefa9893005572d237da5068082d8d5'
    }

    def __init__(self, login, password, user_1, user_2, max_level_parse, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.login = login
        self.password = password
        self.main_user_1 = user_1
        self.main_user_2 = user_2
        self.user_list_1 = []
        self.user_list_2 = [user_2]
        self.current_parse_user = {1: [user_1]}
        self.next_user = self.user_list_2
        self.users_set_follow = set()
        self.users_set_followed_by = set()
        self.fl_end_flw_parse = 0
        self.fl_next_level = 0
        self.max_level_parse = max_level_parse
        self.current_level = 1

    def get_main_users(self):
        return self.main_user_1, self.main_user_2

    def parse(self, response, *args, **kwargs):
        try:
            yield scrapy.FormRequest(
                self._login_url,
                method="POST",
                callback=self.parse,
                formdata={"username": self.login, "enc_password": self.password},
                headers={"x-csrftoken": self.script_json_info(response)["config"]["csrf_token"]}
            )
        except AttributeError:
            if response.json()['authenticated']:
                yield from self.get_next_user(response)

    def get_next_user(self, response):
        for key, item in self.current_parse_user.items():
            for user in item:
                yield response.follow(f"/{user}/", callback=self.user_parse, cb_kwargs={"main_user": user, "side": key})

    @staticmethod
    def script_json_info(response):
        script = response.xpath("//script[contains(text(), 'window._sharedData = ')]/text()").extract_first()
        script = script.replace("window._sharedData = ", "")[:-1]
        return json.loads(script)

    def next_user_choice(self, side):
        next_side = 2 if (side == 1) and (self.user_list_2 != []) else 1
        if not self.user_list_1:
            next_side = 2
        if next_side == 1:
            next_user = self.user_list_1.pop()
        else:
            next_user = self.user_list_2.pop()
        time.sleep(3)
        if os.path.exists('final_chain.txt'):
            raise CloseSpider
        return next_side, next_user

    def user_parse(self, response, main_user, side):
        main_user = main_user
        side = side
        user_data = self.script_json_info(response)["entry_data"]["ProfilePage"][0]["graphql"]["user"]
        user_id = user_data['id']
        edge_followed_by_num = user_data['edge_followed_by']['count']
        edge_follow_num = user_data['edge_follow']['count']
        for flw in self.query.keys():
            yield response.follow(self.get_api_url(user_id, flw=flw), callback=self.parse_followings,
                                  cb_kwargs={
                                      "main_user": main_user,
                                      'flw': flw,
                                      'user_id': user_id,
                                      "side": side,
                                      "edge_followed_by_num": edge_followed_by_num,
                                      "edge_follow_num": edge_follow_num
                                  })

    def get_api_url(self, user_id, flw, after=''):

        variables = {"id": user_id,
                     "include_reel": False,
                     "fetch_mutual": False,
                     "first": 25,
                     "after": after}
        return f'{self.query_url}?query_hash={self.query[flw]}&variables={json.dumps(variables)}'

    def parse_followings(self, response, main_user, flw, user_id, side, edge_followed_by_num, edge_follow_num):

        if os.path.exists('final_chain.txt'):
            raise CloseSpider
        edge_followed_by_num = edge_followed_by_num
        edge_follow_num = edge_follow_num
        main_user = main_user
        side = side
        user_id = user_id
        flw_data = response.json()
        last_page_fl = flw_data['data']['user'][flw]['page_info']['has_next_page']
        flw_users = flw_data['data']['user'][flw]['edges']
        end_cursor = flw_data['data']['user'][flw]['page_info']['end_cursor']

        for node in flw_users:
            user = node['node']['username']
            if flw == 'edge_follow':
                self.users_set_follow.add(user)
            else:
                self.users_set_followed_by.add(user)
        if last_page_fl:
            yield response.follow(
                self.get_api_url(user_id=user_id, after=end_cursor, flw=flw),
                callback=self.parse_followings, cb_kwargs={
                    "main_user": main_user,
                    'flw': flw,
                    'user_id': user_id,
                    "edge_followed_by_num": edge_followed_by_num,
                    "edge_follow_num": edge_follow_num,
                    "side": side
                })
        if not last_page_fl:
            self.fl_end_flw_parse += 1
            if self.fl_end_flw_parse == 2:
                data = {"users": self.users_set_followed_by & self.users_set_follow,
                        "parent_user": main_user,
                        "side": side,
                        "relative_level": self.current_level}
                if len(data['users']) == 0 and main_user == (self.user_list_1 or self.user_list_2):
                    print("Один из пользователей на начальном этапе не имеет взаимных подписок. The end")
                    raise CloseSpider
                # print(1)
                self.fl_end_flw_parse = 0
                self.users_set_follow.clear()
                self.users_set_followed_by.clear()
                if not self.user_list_1 and not self.user_list_2:
                    self.user_list_1 = db_next_user_query(1, self.current_level)
                    self.fl_next_level = 1
                    if self.current_level == self.max_level_parse:
                        print("Достигнута заданная глубина поиска. Парсинг завершен")
                        raise CloseSpider
                if self.fl_next_level:
                    self.user_list_2 = db_next_user_query(2, self.current_level)
                    if self.user_list_2:
                        self.current_level += 1
                        print(f'level {self.current_level} reached')
                        self.fl_next_level = 0

                next_side, self.next_user = self.next_user_choice(side)
                self.current_parse_user.clear()
                self.current_parse_user[next_side] = [self.next_user]
                yield from self.get_next_user(response)
                # self.next_user = []
                yield data
