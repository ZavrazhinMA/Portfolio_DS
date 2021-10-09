import scrapy
from .info_xpath import _page_selectors, _dialog_info
import re


class PsiSpider(scrapy.Spider):
    name = 'psychoambulanz_ind'
    allowed_domains = ['psychoambulanz.ru']
    start_urls = ['https://psychoambulanz.ru/categories/odin-vopros']
    main_url = 'psychoambulanz.ru'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.dialog_history = {}

    @staticmethod
    def text_prp_nn(text):
        re.sub("^\s+|\n|\r|\s+$|\n{2,5}", "", text)
        return text

    @staticmethod
    def _get_follow(response, select_str, callback, **kwargs):
        for link in response.xpath(select_str):
            yield response.follow(link, callback=callback, cb_kwargs=kwargs)

    def parse(self, response, *args, **kwargs):
        yield from self._get_follow(response, _page_selectors["pages"], self.parse)
        yield from self._get_follow(response, _page_selectors["discussion"], self.parse_dialog)

    def parse_dialog(self, response):

        data = {
            'd_id': re.findall('\d+', response.url)[0],
            '_url': response.url,
            'title': response.xpath(_dialog_info['title']).extract()[0],
            'dialog': {
                'comment_id': [0],
                'author': response.xpath(_dialog_info['author']).extract(),
                'comment_date': response.xpath(_dialog_info['question_date']).extract(),
                'text': [
                    self.text_prp_nn(self.text_prp_nn(' '.join(response.xpath(_dialog_info['question']).extract())))]
            }
        }

        if str(data['d_id']) in self.dialog_history:
            data = self.dialog_history.pop(data['d_id'])

        author_add_list = [
            el for el in
            response.xpath(_dialog_info['dialog']['author']).extract()
        ]
        com_id_add_list = [
            re.findall('\d+', el)[0]
            for el in
            response.xpath(_dialog_info['dialog']['comment_id']).extract()
        ]
        com_date_add_list = [
            el for el in
            response.xpath(_dialog_info['dialog']['comment_date']).extract()
        ]
        com_text_add_list = [el for el in
                             [self.text_prp_nn(' '.join(
                                 response.xpath(_dialog_info['dialog']['text']).extract()))]][0].split(sep='\n')[1:]

        data['dialog']['comment_id'] += com_id_add_list
        data['dialog']['author'] += author_add_list
        data['dialog']['comment_date'] += com_date_add_list
        data['dialog']['text'] += com_text_add_list

        next_page = response.xpath(_page_selectors['dialog_pages']).extract()

        if next_page:
            self.dialog_history[data['d_id']] = data
            yield response.follow(next_page[0], self.parse_dialog)
        else:
            yield data
