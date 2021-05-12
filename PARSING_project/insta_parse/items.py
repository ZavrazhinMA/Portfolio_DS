# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy


class InstaParseItem(scrapy.Item):
    users = scrapy.Field()
    parent_user = scrapy.Field()
    side = scrapy.Field()
    relative_level = scrapy.Field()
