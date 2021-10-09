_page_selectors = {
    "dialog_pages": '//div[@class="CommentsWrap"]//div[@id="PagerAfter"]//a[@class="Next"]/@href',
    "discussion": "//ul[@class='DataList Discussions']//div[@class='Title']/a/@href",
    "pages": '//div[@class="PageControls Bottom"]//div[@id="PagerAfter"]//a[@class="Next"]/@href'
}

_dialog_info = {
    "title": "//div[@class='PageTitle']//h1/text()",
    "question": '//div[@class="Item ItemDiscussion"]//div[@class="Message"]/text()',
    "author": '//div[@class="Item ItemDiscussion"]//div[@class="Item-Header DiscussionHeader"]//a['
              '@class="Username"]/text() ',
    'question_date': '//div[@class="Item ItemDiscussion"]//div[@class="Item-Header DiscussionHeader"]//div['
                     '@class="Meta DiscussionMeta"]//time/@datetime',
    'dialog': {
        'comment_id': '//div[@class="CommentsWrap"]//ul[@class="MessageList DataList Comments"]/li/@id',
        'author': '//div[@class="CommentsWrap"]//ul[@class="MessageList DataList Comments"]/li//div['
                  '@class="AuthorWrap"]//a[@class="Username"]/text()',
        'comment_date': '//div[@class="CommentsWrap"]//ul[@class="MessageList DataList Comments"]/li//div['
                     '@class="Meta CommentMeta CommentInfo"]//time/@datetime',
        'text': '//div[@class="CommentsWrap"]//ul[@class="MessageList DataList Comments"]/li//div[@class="Message"]/text()'
               }
    # 'answer_date' = scrapy.Field()
    # 'answer' = scrapy.Field()
}
