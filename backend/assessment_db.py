from sqlalchemy import create_engine
from sqlalchemy import Column, Integer, String ,DateTime ,ForeignKey ,Text ,Float
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv
from db_engine import Engine


load_dotenv(override = True)
## initailising db engine # URL-encoded '@' as '%40'
Base = declarative_base()

class AssesmentSchedule(Base) : 
    __tablename__ = "AssesmentSchedule"
    id = Column(Integer, primary_key=True ,autoincrement=True)
    student_class = Column(Integer)
    subject = Column(Text)
    chapter = Column(Text)
    start = Column(DateTime)
    end = Column(DateTime)

class AssesmentSubtopic(Base): 
    __tablename__ = "AssesmentSubtopic"
    id = Column(Integer, primary_key=True ,autoincrement=True)
    subtopic = Column(Text)
    schedule_id = Column(Integer ,ForeignKey('AssesmentSchedule.id'))
    q_count = Column(Integer)

class StudentAssignment(Base):
    __tablename__ = "StudentAssignment"
    id = Column(Integer, primary_key=True ,autoincrement=True)
    roll_num = Column(Text) ##student rollnumber 
    name = Column(Text) ##student name 
    state = Column(Text) ##which state the student belongs 
    schedule_id = Column(Integer ,ForeignKey('AssesmentSchedule.id'))
    subject = Column(Text)
    chapter = Column(Text)
    feed_back = Column(Text)

class StudentAnalysis(Base):
    __tablename__ = "StudentAnalysis"
    id = Column(Integer, primary_key=True ,autoincrement=True)
    student_assignment_id = Column(Integer ,ForeignKey('StudentAssignment.id'))
    subtopic = Column(Text)
    accuracy = Column(Float)
    

if __name__ == "__main__": 
    inp = input( "start_creating_tables(y/n) : ")
    if inp == "y" : 
        try:
            Base.metadata.create_all(Engine)
            print( "Tables created succesfully")
        except Exception as e:
            print(f"db_creation : error occurred: {e}")
