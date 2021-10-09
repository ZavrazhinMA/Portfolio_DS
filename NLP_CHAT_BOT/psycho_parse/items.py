# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy


class PsychoParseItem(scrapy.Item):
    d_id = scrapy.Field()
    _url = scrapy.Field()
    author = scrapy.Field()
    title = scrapy.Field()
    question_date = scrapy.Field()
    comment_id = scrapy.Field()
    comment_date = scrapy.Field()
    dialog = scrapy.Field()
    text = scrapy.Field()
