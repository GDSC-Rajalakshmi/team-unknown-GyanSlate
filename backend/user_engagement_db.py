from sqlalchemy import create_engine
from sqlalchemy import Column,Time,Integer,ForeignKey,Text,DATETIME
from sqlalchemy.orm import declarative_base
from pathlib import Path
from dotenv import load_dotenv
import os
from db_engine import Engine

load_dotenv(override = True)
Base = declarative_base()

##video watch tracking for the students 
class StudentScore(Base):
    __tablename__ = "StudentScore"
    id = Column(Integer, primary_key=True ,autoincrement=True)
    student_class = Column(Integer)
    state = Column(Text)
    roll_num = Column(Text)
    score = Column(Integer)
        
if __name__ == "__main__": 
    inp = input( "start_creating_tables(y/n) : ")
    if inp == "y" : 
        try:
            Base.metadata.create_all(Engine)
            print( "Tables created succesfully")
        except Exception as e:
            print(f"db_creation : error occurred: {e}")