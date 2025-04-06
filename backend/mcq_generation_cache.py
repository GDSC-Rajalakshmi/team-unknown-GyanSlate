from question_bank import Question ,Options  
from sqlalchemy.orm import sessionmaker
import time  
from regional.interface import state_language
from db_engine import Engine

##creating a session object with question bank db  
Session = sessionmaker(bind=Engine)

"""
{  
  "access" : "admin_key + time_stamp_of_starting of creation" ,
  "stdent_class" : int ,
  "subject" : str,
  "chapter" : str,
  "created_time_stamp" : str 
  "mcq_dict" : { 
      "common" : [ ....] ##common mcq_list   
      "state1" : [ ....] ##stat1 mcq_list
      "state2" : [ ....] ##stat2 mcq_list 
   }
}
"""

"""
single mcq formate 
{ 
  "question" : " " ,
  "options" :[ opt1 ,opt2 .. ],
  "correct_option" : "",
  "why" : "" ,
  "subtopic" : "",
  "subtopic_translated" : "" ,(if it is not common mcq )
  "q_type" : ""
}
"""

class McqGenerationCache:
    ##max_limit represents maximum number of cache at a time  
    def __init__(self ):
        session = Session()
        self.data_list = []
        self.timeoutgap = 30 * 60 ## in seconds  
        self.total_q_count = session.query(Question).count()
        session.close()

    def add(self ,access ,stdent_class ,subject ,chapter ,created_time_stamp ,mcq_dict):
        assert isinstance(mcq_dict ,dict) ,"mcq is must be dict ,containing all the states mcq's as key - values pairs"
        self.data_list.append( 
            {  
            "access" : access,
            "stdent_class" : stdent_class,
            "subject" : subject ,
            "chapter" : chapter,
            "created_time_stamp" : created_time_stamp, 
            "mcq_dict" : mcq_dict
            }
        )
        return True 
    
    ##removing the timed out data from the cache  
    def remove_timout_data(self): 
        incache = self.data_list
        self.data_list = [ ]
        for data in incache: 
            if time.time() - data["created_time_stamp"] < self.timeoutgap:
                self.data_list.append( 
                    data
                )
        del incache
    
    ##storing the cached data to question db and clearing the cache  
    def store(self ,access):
        session = Session()

        for data in self.data_list : 
            
            if data["access"] == access:
                option_obj_list = [ ]
                
                for state ,mcq_list in data["mcq_dict"].items():
                    question_obj_list = []

                    for mcq in mcq_list:
                        ##store question ,correct option ,explanation...
                        subtopic_translated = ""
                        if state != "common" and state in state_language.values():
                            subtopic_translated = mcq["subtopic_translated"] 
                        
                        question_obj_list.append(
                                Question(  
                                state = state,
                                student_class = data["stdent_class"],
                                subject = data["subject"],
                                chapter = data["chapter"],
                                question = mcq["question"],
                                correct_option = mcq["correct_option"],
                                explanation = mcq["why"],
                                suptopic = mcq["subtopic"],
                                subtopic_translated = subtopic_translated,
                                q_type = mcq["type"]
                            )
                        )
                        
                    ##flushing the q_obj to get the id 
                    session.add_all(question_obj_list)
                    session.flush()
                    
                    for i,mcq in enumerate(mcq_list):
                        q_obj = question_obj_list[i]
                        
                        ##store the options 
                        for option in mcq["options"]:
                            option_obj_list.append(
                                Options( 
                                    statement = option,
                                    question_id = q_obj.id,
                                )
                           )
                
                session.add_all(option_obj_list)
                session.commit()
                
                session.close()
                return True
        
        session.close()
        return False
    
    def remove_data(self, access):
        for data in self.data_list:
            if data["access"] == access: 
                self.data_list.remove(data)
                return


        

                







            
        





