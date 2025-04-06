from sqlalchemy import create_engine
from sqlalchemy import Column ,Text ,JSON ,Integer
from sqlalchemy.orm import declarative_base
from db_engine import Engine

Base = declarative_base()

#used in genertaing context aware solution for logical/theoritical questions
class TheoryContext(Base):
    __tablename__ = "TheoryContext"

    id = Column(Integer, primary_key=True ,autoincrement=True)
    relative_id = Column(Text)
    chunk = Column(Text)
    text_vector = Column(JSON)

##this context used for generating soltuions for numeric problems   
class NumericProblemContext(Base):
    __tablename__ = "MathProblemContext"

    id = Column(Integer, primary_key=True ,autoincrement=True)
    relative_id = Column(Text)
    question = Column(Text)
    solution = Column(Text)
    text_vector = Column(JSON)

if __name__ == "__main__" : 
    inp = input( "start_creating_tables(y/n) : ")
    if inp == "y" : 
        try:
            Base.metadata.create_all(Engine)
            print( "Tables created succesfully")
        except Exception as e:
            print(f"db_creation : error occurred: {e}")

