# MLB_flask_docker
Итоговый проект курса "Машинное обучение в бизнесе"

Стек:
* ML: sklearn, pandas, numpy, xgboost
* API: flask
* Модель: XGBoostClassifier
* Данные: с kaggle - https://www.kaggle.com/arashnic/hr-analytics-job-change-of-data-scientists
* Задача: предсказать target: 0 – Not looking for job change, 1 – Looking for a job change. Бинарная классификация

Используемые признаки:
|N|Features|Description
|------|-------------------|----------|
1|enrollee_id | Unique ID for candidate
2|city| City code
3|city_ development _index|Developement index of the city (scaled)
4|gender| Gender of candidate
5|relevent_experience| Relevant experience of candidate
6|enrolled_university| Type of University course enrolled if any
7|education_level| Education level of candidate
8|major_discipline|Education major discipline of candidate
9|experience| Candidate total experience in years
10|company_size| No of employees in current employer's company
11|company_type| Type of current employer
12|lastnewjob| Difference in years between previous job and current job
13|training_hours| training hours completed

### Клон репозитория и создаение образа
```
$ git clone https://github.com/ZavrazhinMA/MLB_flask_docker.git
$ cd MLB_flask_docker
$ docker build -t mlb/docker_ex .
```
### Запуск контейнера

```
$ docker run -d -p 8180:8180 -v <your_local_path_to_pretrained_models>:/app/app/model mlb/docker_ex 
<your_local_path_to_pretrained_models> - заменить на полный путь к каталогу c предобученной моделью

