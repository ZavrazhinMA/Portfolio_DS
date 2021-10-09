import pandas as pd
import dill
import os
from pathlib import Path
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier


class Preprocessing(BaseEstimator, TransformerMixin):

    def __init__(self):
        self.X = None
        self.df_city_target = None

    def fit(self, X, y):
        data = pd.concat([X, y], axis=1)
        self.df_city_target = pd.DataFrame(data.groupby(by="city")["target"].mean())
        self.df_city_target.rename(columns={"target": "city_target"}, inplace=True)
        return self

    def transform(self, X):

        X.fillna("unknown")
        X.set_index("enrollee_id", inplace=True)
        X = X.replace(to_replace="[>]", value="more ", regex=True)
        X = X.replace(to_replace="[<]", value="less ", regex=True)
        X = pd.merge(X, self.df_city_target, how="left", right_on="city", left_on="city")
        X.drop(columns="city", inplace=True)
        X = pd.get_dummies(X)
        return X


class Train:
    def __init__(self, xgb_params, data):
        self.xgb_params = xgb_params
        self.data_df = data
        self.pipeline = None
        self.X_train = None
        self.y_train = None

    def data_split(self, test_size):
        self.X_train, X_test, self.y_train, y_test = train_test_split(self.data_df.drop(columns="target"),
                                                                      self.data_df["target"], test_size=test_size,
                                                                      stratify=self.data_df["target"],
                                                                      random_state=13)
        # save test
        X_test.to_csv(os.path.join(Path(os.getcwd()).parent, "data", "X_test.csv"), index=None)
        y_test.to_csv(os.path.join(Path(os.getcwd()).parent, "data", "y_test.csv"), index=None)
        # save train
        self.X_train.to_csv(os.path.join(Path(os.getcwd()).parent, "data", "X_train.csv"), index=None)
        self.y_train.to_csv(os.path.join(Path(os.getcwd()).parent, "data", "y_train.csv"), index=None)

    def pipeline_save(self):
        if not os.path.exists(os.path.join(Path(os.getcwd()), "model")):
            os.mkdir(os.path.join(Path(os.getcwd()), "model"))
        with open(os.path.join(Path(os.getcwd()), "model", "xgb_pipeline.dill"), "wb") as f:
            dill.dump(self.pipeline, f)

    def run(self):
        self.data_split(0.25)
        self.pipeline = Pipeline([
            ("preprocessor", Preprocessing()),
            ("classifier", XGBClassifier(**self.xgb_params))
        ])
        self.pipeline.fit(self.X_train, self.y_train)
        self.pipeline_save()


if __name__ == "__main__":
    params = {
        "random_state": 13, "max_depth": 7,
        "n_estimators": 195, "learning_rate": 0.06,
        "reg_lambda": 1.1
    }

    data_df = pd.read_csv(os.path.join(Path(os.getcwd()).parent, "data", "aug_train.csv"))
    model_build = Train(params, data_df)
    model_build.run()
