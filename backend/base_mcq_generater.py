
from question_bank import SubtopicDescribe
from sqlalchemy.orm import sessionmaker
from db_engine import Engine
from semantic_search import SimTheory
from google import genai
import json   

Session = sessionmaker(bind = Engine)

class BaseMcqGenerator : 

    def __init__(self ,document_text ,subtpc_count ,age ,exmpl_percentage ,stud_clss ,subj ,chap):
        assert exmpl_percentage >= 0  and exmpl_percentage <=  1 ,"exmpl_percentage >= 0  and exmpl_percentage <=  1"
        
        self.knowledge_base = document_text 
        self.subtpc_count = subtpc_count ##subtopic - count  
        self.age = age 
        self.exmpl_percentage = exmpl_percentage 
        
        ##google gemini api access  
        self.model='models/gemini-1.5-flash-001'
        self.client = genai.Client(
            api_key = "AIzaSyDqKLbGrP2m8Y94oYkBhZfpDxKxhVi7oyc"
        )
        ###addding common id
        self.common_id = f"{stud_clss}_{subj}_{chap}"

        ##geting description for the subtopic  and storing it in the db
        self.subtpc_descrp =self.__sub_topic_description() ##subtopic - description 
        self.__store_subtopic_describ(subtpc_descrp = self.subtpc_descrp)##storing it in the db
        

        ##semantic
        self.semantic_search = SimTheory(
            stud_clss = stud_clss ,
            subj = subj ,
            chap = chap 
        )
        self.semantic_search.add(text = document_text)
    
    def __sub_topic_description(self):
        subtopic_dscrb_prmpt = """
###Instruction : provide two to three line describtion for given subtopic's in context of the knowledge base provided

###Knowledge base : {knowledge_base}

###Subtopics : {subtopics}

###Output formate : {{ 
   "subtopic1" : "subtopic1 describtion" , 
   "subtopic2" : "subtopic2 describtion" ,
}}

###Response : 
"""

        formated_prompt = subtopic_dscrb_prmpt.format(
            knowledge_base = self.knowledge_base , 
            subtopics = self.subtpc_count.keys()
            )
      
        response = self.client.models.generate_content(
                model=self.model,
                contents = formated_prompt,
            ).text

        try : 
            return json.loads( response )
        except:
            try :
                i1 ,i2 = None ,None  
                for i in range(len(response)): 
                    if response[i] == "{" :
                        i1 = i 
                    elif response[i] == "}" and i1 is not None :
                        i2 = i 
                return json.loads( response[ i1 : i2 + 1 ] )
            
            except:
                return dict.fromkeys(self.subtpc_count.keys(), "Sorry failed fetch instruction so use your knowledge") 
    
    def __store_subtopic_describ(self ,subtpc_descrp :dict):
        session = Session()
        objs = []
        for sub ,describ in subtpc_descrp.items():
            objs.append(
                SubtopicDescribe(
                    relative_id = self.common_id ,
                    describe = describ,
                    name = sub
                )
            )
        session.add_all(objs)
        session.commit()

    
    def generate(self): 
        example_mcqs = [ ]
        normal_mcqs = [ ]

        for subtopic in self.subtpc_descrp.keys() :
            ##going to next subtopic if no questions is need for this means  
            if self.subtpc_count[subtopic] == 0:
                continue
            
            ##if q need fetching the relvent content for it 
            context = f"{subtopic} : " +  self.subtpc_descrp[subtopic]
            print(context)
            relavent_chunks = self.semantic_search.search( query = context )

            ##genertating example based questions if only neeedee
            if int(self.subtpc_count[subtopic] * self.exmpl_percentage) > 0 :
                formated_prompt = self.__example_question_prompt(subtopic = subtopic ,relavent_chunks = relavent_chunks)
                response = self.__llm_call( 
                    subtopic = subtopic 
                    ,formated_prompt = formated_prompt 
                    ,qtype = "example"
                )
                example_mcqs  = example_mcqs + response
            
            ##genertating normal questions
            if int(self.subtpc_count[subtopic] * (1 - self.exmpl_percentage)) > 0 :
                formated_prompt = self.__normal_question_prompt(subtopic = subtopic ,relavent_chunks = relavent_chunks)
                response = self.__llm_call( 
                    subtopic = subtopic 
                    ,formated_prompt = formated_prompt 
                    ,qtype = "normal"
                )
                normal_mcqs = normal_mcqs + response
        
        return {"example" : example_mcqs ,"normal" : normal_mcqs }


    def __llm_call(self ,subtopic ,formated_prompt ,qtype):
        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents = formated_prompt,
            ).text
            
            response = self.__extract_list(response)
            for i in range(len(response)) : 
                response[i]["subtopic"] = subtopic
                response[i]["type"] = qtype

            return response
        
        except Exception as e:
            print("ERROR : base_mcq_generator :- " ,e) 
            return []
        

    def __example_question_prompt(self ,subtopic ,relavent_chunks): 
        prompt = """###Requirement : 
Your role is to generate real time example based multiple choice questions for {age} year old children from 
the provided knowledge base for the given sub topic. Make sure that provided real life example's are more relatable 
and imaginable for a {age} year old's life style and it comes under the given sub topic . Also make sure hardness 

###Output formate : [
  {{ "question" : " " ,
    "options" :[ opt1 ,opt2 .. ],
    "correct_option" : ""
    "why" : "" }} ,
]

###Question count : {question_count}
    
###Subtopic : {subtopic} 

###Knowledge_base : {knowledge_base}

###Response : """ 
        return prompt.format(  
            age = self.age,
            question_count = int(self.subtpc_count[subtopic] * self.exmpl_percentage),
            subtopic = subtopic,
            knowledge_base = relavent_chunks
        )

    
    def __normal_question_prompt(self ,subtopic ,relavent_chunks):
        prompt = """###Requirement : 
Your role is to generate multiple choice questions for {age} year old children from the provided knowledge base 
for the given sub topic. Make sure that generated mcq is suitable {age} year old children and it comes under the 
given sub topic.

###Output formate : [
  {{ "question" : " " ,
    "options" :[ opt1 ,opt2 .. ],
    "correct_option" : ""
    "why" : "" }} ,
]

###Question count : {question_count}
    
###Subtopic : {subtopic} 

###Knowledge_base : {knowledge_base}

###Response : """ 
        return prompt.format(  
            age = self.age,
            question_count = int(self.subtpc_count[subtopic] * (1 - self.exmpl_percentage)),
            subtopic = subtopic,
            knowledge_base = relavent_chunks
        )
    
    def __extract_list(self ,response):
        try:
            return json.loads(response)
        except:
            i1 ,i2 = None ,None  
            for i in range(len(response)):
                if i1 is None and response[i] == "[" : 
                    i1 = i 
                elif response[i] == "]" :
                    i2 = i 
            return json.loads( response[i1 : i2 + 1] )

        

          
    

    


                     



    

        




        

    
    

        



