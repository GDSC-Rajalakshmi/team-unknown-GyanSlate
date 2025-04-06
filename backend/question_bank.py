from sqlalchemy import create_engine
from sqlalchemy import Column, Integer, String ,Text ,ForeignKey ,DATETIME
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv
from db_engine import Engine
import os

load_dotenv(override = True)
Base = declarative_base()


class Question(Base): 
    __tablename__ = "Question"    

    id = Column(Integer, primary_key=True, autoincrement=True)
    state = Column(Text)
    student_class = Column(Integer)
    subject = Column(Text)
    chapter = Column(Text)  # Changed to Text in case chapter names/descriptions are long
    question = Column(Text)  # Changed to Text for longer question content
    correct_option = Column(Text)
    explanation = Column(Text)  # Changed to Text for detailed explanations
    suptopic = Column(Text)
    subtopic_translated = Column(Text) #this one to store a translated subtopic
    q_type = Column(String(50))

class Options(Base):
    __tablename__ = "Options"

    id = Column(Integer, primary_key=True, autoincrement=True)
    statement = Column(Text)  # Changed to Text to accommodate longer option text
    question_id = Column(Integer, ForeignKey('Question.id'))

class SubtopicDescribe(Base):
    __tablename__ = "SuptopicDescribe"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    relative_id = Column(Text) ##{class}_{subj}_{chap}
    name = Column(Text)
    describe = Column(Text)

class SubtopicExplainer(Base):
    __tablename__ = "SuptopicExplainer"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    sub_id = Column(Integer, ForeignKey('SuptopicDescribe.id'))
    name = Column(Text)
    state = Column(Text)
    exp = Column(Text)
    img = Column(Text)
    access_url = Column(Text)
    expiration = Column(DATETIME)

class Solution(Base):
    __tablename__ = "Solution"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    relative_id = Column(Text) ##{class}_{subj}_{chap}
    question = Column(Text)
    solution = Column(Text)
    explanation = Column(Text)
    q_type = Column(Text)


class DoubtResolution(Base):
    __tablename__ = "DoubtResolution"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    relative_id = Column(Text) ##{class}_{subj}_{chap}
    question = Column(Text)
    explanation = Column(Text)
    q_type = Column(Text)
    img = Column(Text)
    access_url = Column(Text)
    expiration = Column(DATETIME)



if __name__ == "__main__": 
    inp = input( "start_creating_tables(y/n) : ")
    if inp == "y" : 
        try:
            Base.metadata.create_all(Engine)
            print( "Tables created succesfully")
        except Exception as e:
            print(f"db_creation : error occurred: {e}")
