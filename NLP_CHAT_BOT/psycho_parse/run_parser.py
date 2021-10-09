from scrapy.crawler import CrawlerProcess  # процесс управляет пауками
from scrapy.settings import Settings  # настройки
from spiders.psi_spider import PsiSpider  # паук

if __name__ == '__main__':
    crawler_settings = Settings()
    crawler_settings.setmodule('settings')  # взять настройки из модуля settings
    crawler_process = CrawlerProcess(settings=crawler_settings)
    crawler_process.crawl(PsiSpider)
    crawler_process.start()
