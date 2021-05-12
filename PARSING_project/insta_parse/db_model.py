
from sqlalchemy import Column, Integer, String, SmallInteger
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()


class UsersHandShake(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String, unique=True, nullable=False)
    side = Column(SmallInteger, nullable=False)
    parent_user = Column(String, nullable=False)
    relative_level = Column(Integer, nullable=False)

    def __init__(self, username, side, parent_user, relative_level):
        self.username = username
        self.side = side
        self.parent_user = parent_user
        self.relative_level = relative_level


class DataBase:
    def __init__(self, db_url):
        engine = create_engine(db_url)
        Base.metadata.create_all(bind=engine)
        self.maker = sessionmaker(bind=engine)


# if __name__ == "__main__":
#
