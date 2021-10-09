import dill
import pandas as pd
import os
import flask
import logging
from logging.handlers import RotatingFileHandler
from time import strftime

dill._dill._reverse_typemap['ClassType'] = type

app = flask.Flask(__name__)
model = None

handler = RotatingFileHandler(filename='app.log', maxBytes=100000, backupCount=10)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(handler)


def load_model(model_path):
    global model
    with open(model_path, 'rb') as f:
        model = dill.load(f)
    print(model)


modelpath = "/app/app/model/xgb_pipeline.dill"
load_model(modelpath)


@app.route("/", methods=["GET"])
def general():
    return """Welcome to HR prediction process."""


@app.route("/predict", methods=["POST"])
def predict():
    data = {"success": False}
    dt = strftime("[%Y-%b-%d %H:%M:%S]")

    if flask.request.method == "POST":

        enrollee_id = ""
        city = ""
        city_development_index = ""
        gender = ""
        relevent_experience = ""
        enrolled_university = ""
        education_level = ""
        major_discipline = ""
        experience = ""
        company_size = ""
        company_type = ""
        last_new_job = ""
        training_hours = ""

        request_json = flask.request.get_json()

        if request_json["enrollee_id"]:
            enrollee_id = request_json["enrollee_id"]
        if request_json["city"]:
            city = request_json["city"]
        if request_json["city_development_index"]:
            city_development_index = request_json["city_development_index"]
        if request_json["gender"]:
            gender = request_json["gender"]
        if request_json["relevent_experience"]:
            relevent_experience = request_json["relevent_experience"]
        if request_json["enrolled_university"]:
            enrolled_university = request_json["enrolled_university"]
        if request_json["education_level"]:
            education_level = request_json["education_level"]
        if request_json["major_discipline"]:
            major_discipline = request_json["major_discipline"]
        if request_json["experience"]:
            experience = request_json["experience"]
        if request_json["company_size"]:
            company_size = request_json["company_size"]
        if request_json["company_type"]:
            company_type = request_json["company_type"]
        if request_json["last_new_job"]:
            last_new_job = request_json["last_new_job"]
        if request_json["training_hours"]:
            training_hours = request_json["training_hours"]

        logger.info(
            f'{dt} Data:enrollee_id={enrollee_id}, city={city}, city_development_index={city_development_index},'
            f'gender={gender},relevent_experience={relevent_experience},'
            f'enrolled_university={enrolled_university}, education_level={education_level},'
            f'major_discipline={major_discipline}, experience={experience}, company_size={company_size},'
            f'company_type={company_type}, last_new_job={last_new_job}, training_hours= {training_hours}'
        )
        try:
            preds = model.predict_proba(pd.DataFrame({"enrollee_id": [enrollee_id],
                                                      "city": [city],
                                                      "city_development_index": [city_development_index],
                                                      "gender": [gender],
                                                      "relevent_experience": [relevent_experience],
                                                      "enrolled_university": [enrolled_university],
                                                      "education_level": [education_level],
                                                      "major_discipline": [major_discipline],
                                                      "experience": [experience],
                                                      "company_size": [company_size],
                                                      "company_type": [company_type],
                                                      "last_new_job": [last_new_job],
                                                      "training_hours": [training_hours]
                                                      }))
        except AttributeError as e:
            logger.warning(f'{dt} Exception: {str(e)}')
            data['predictions'] = str(e)
            data['success'] = False
            return flask.jsonify(data)

        data["predictions"] = preds[:, 1][0]
        data["success"] = True

    return flask.jsonify(data)


# if this is the main thread of execution first load the model and
# then start the server
if __name__ == "__main__":
    print(("* Loading the model and Flask starting server..."
           "please wait until server has fully started"))
    port = int(os.environ.get('PORT', 8180))
    app.run(host='0.0.0.0', debug=True, port=port)
