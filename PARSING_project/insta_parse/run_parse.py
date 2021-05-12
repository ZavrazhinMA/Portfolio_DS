import os
import dotenv
from scrapy.crawler import CrawlerProcess
from scrapy.settings import Settings
from insta_parse.spiders.insta_spider import InstaSpider

if __name__ == "__main__":
    dotenv.load_dotenv(".env")
    filename_db = 'handshake_check.db'
    file_result = 'final_chain.txt'
    file_main_users = 'main_users.txt'

    if os.path.exists(filename_db):
        os.remove(filename_db)
    if os.path.exists(file_result):
        os.remove(file_result)
    if os.path.exists(file_main_users):
        os.remove(file_main_users)

    max_level_parse = 10
    user_1 = "dmitriypeskov.ru"
    user_2 = "usikipeskova"

    with open("main_users.txt", "w", encoding="UTF-8") as file:
        for line in [user_1, user_2]:
            file.write(line + "\n")

    login = os.getenv('INST_LOGIN'),
    password = os.getenv("INST_PASSWORD")
    crawler_settings = Settings()
    crawler_settings.setmodule("insta_parse.settings")
    crawler_proc = CrawlerProcess(settings=crawler_settings)
    crawler_proc.crawl(
        InstaSpider,
        login=login,
        password=password,
        user_1=user_1,
        user_2=user_2,
        max_level_parse=max_level_parse
    )
    crawler_proc.start()
