# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
from db_model import DataBase, UsersHandShake
from sqlalchemy import exc
from sqlite3 import IntegrityError as Ierror
from research_progress_control import search_control
# from scrapy.exceptions import CloseSpider


class InstaParsePipeline:
    def __init__(self):
        database = DataBase("sqlite:///handshake_check.db")
        self.Session = database.maker
        self.close_spider = 0

    def process_item(self, item, spider):
        if not self.close_spider:
            for user in item["users"]:
                session = self.Session()
                add_user = UsersHandShake(user, item["side"], item["parent_user"], item["relative_level"])
                session.add(add_user)
                try:
                    session.commit()

                except exc.IntegrityError or Ierror:
                    next_step = search_control(user, item["side"], item["parent_user"], item["relative_level"])
                    if next_step:
                        session.rollback()
                    else:
                        self.close_spider = 1

        return item
