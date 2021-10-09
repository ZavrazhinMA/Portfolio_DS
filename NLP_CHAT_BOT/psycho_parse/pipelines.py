from pymongo import MongoClient


class PsychoParsePipeline:
    def __init__(self):
        client = MongoClient()
        self.db = client["psi_parse"]

    def process_item(self, item, spider):
        self.db[spider.name].insert_one(item)
        return item

