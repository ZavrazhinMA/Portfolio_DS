# Recommender Systems project #
### __Задача__  ###
### Требуется, на основании имеющихся исторических данных по продажам за __последние 92 недели__ и признаковых описаниях покупателей и товаров, реализовать алгоритм прогнозирующий будущие покупки и формирующий список рекомендуемых товаров на __будущие 3 недели__. ###
### Used stack (2-lvl model): ###
* ### implicit - __ALS__(подбор кандидатов), __LGBMClassifier__(ранжирование) ### 
### __Result: precision@5: 0.2799__ ###
### __Data description__ ###
* __retail_train__ - данные о покупках 2.5k клиентов 80k товаров
* __product__ - признаковое описание товаров
* __hh_demographic__ - признаковое описание пользователей
* __retail_test1__ - тестовые данные для предсказаний (3 недели)