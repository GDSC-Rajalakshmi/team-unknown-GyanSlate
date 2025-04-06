from embedder import Embedder
from user_engagement_db import StudentScore
import numpy as np
from db_engine import Engine
from sqlalchemy.orm import sessionmaker
from google import genai
from dotenv import load_dotenv
import os
import json


load_dotenv(override = True)

Session = sessionmaker(bind = Engine)

combiner_prompt = """Task:
You are given a list of explanation points written by a student about a specific topic. Your job is to combine all the relevant points into one clear and coherent paragraph that accurately conveys what the student is trying to explain.

Instructions:

Use only the information provided in the explanation list.

Do not add any new information or assumptions.

Do not remove any relevant detail from the original explanations.

You may ignore any explanation that is clearly off-topic or unrelated to the given subject.

The final output must be a single, well-structured paragraph that logically combines all the relevant points.

If the student has not provided any explanation relevant to the given topic, simply output: "No relevant information."

Topic: {target_expl}

Explanation List: {expl_list}"""

class ExplanTrack : 
    cache = {}
    embedder = Embedder()
    total_scr = 100
    min_win_scr = 70 ##75% of total score 
    lng_scr = 0.1
    time_efficency_scr = 5
    model = os.getenv("LANGUAGE_MODEL_ID")
    client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))

    def is_exist(self ,access):
        return access in self.cache

    def start(self ,access ,target_txt ):
        self.cache[access] = { }
        self.cache[access]['target'] = target_txt
        self.cache[access]['targ_embed'] = self.embedder.encode([target_txt])[0]
        self.cache[access]['track'] = [] ##track = [{'lng' : "" ,'expl' : "" ,'duartion':""} ,]##
        self.cache[access]['score'] = 0 ##range from 0-100

        ##printing the target 
        print("Target :" ,self.cache[access]['target'] ,"\n\n")
    
    def track(self ,access ,expl ,lng ,duration ,stud_clss ,roll_num ,state):
        
        self.cache[access]['track'].append({'lng' : lng ,'expl': expl ,"duration" : int(duration)})
        
        ##combining all the explanation peices made till now 
        track_list = [dict1['expl'] for dict1 in self.cache[access]['track']]
        combined_exp = self.__combine(track_list = track_list ,target = self.cache[access]['target'] )
        
        ####
        print( f"Explanation provide at({len(track_list)}) : " ,combined_exp)

        ##computing the similarity
        sim = self.__similarity( target_vec = self.cache[access]['targ_embed'] ,explantion = combined_exp)
        sim = sim * self.total_scr
        
        ##seting the score value 
        self.cache[access]['score'] = max(self.cache[access]['score'] ,sim)
        
        if self.cache[access]['score'] >= self.min_win_scr :
            ##computing a new score
            extra_pnts = self.__compute_scr(sim ,access)
            
            ##adding the new points in the db 
            session = Session()
            pnt_obj = session.query(StudentScore).filter(
                StudentScore.roll_num == roll_num,
                StudentScore.state == state,
                StudentScore.student_class == stud_clss
            ).first()
            pnt_obj.score += extra_pnts
            session.commit()
            session.close()

            return self.cache[access]['score'] ,True ,extra_pnts
        
        return self.cache[access]['score'] ,False ,0   
    
    def __compute_scr(self ,score ,access):
        eng_time ,native_time = 0 ,0

        for dict1 in self.cache[access]['track']:
            if dict1['lng'] == 'en' : 
                eng_time += dict1['duration']
            else:
                native_time += dict1['duration']
        
        pnts = (score/(eng_time + native_time)) * self.time_efficency_scr 
        pnts += self.lng_scr * native_time
        pnts += self.lng_scr * 2 * eng_time  ##2x score for speaking in english 
        return int(pnts) 

    def __similarity(self ,explantion ,target_vec ,depr = 2):
        expl_vec = self.embedder.encode([explantion])[0]
        
        dot_product = np.dot(expl_vec, target_vec)
        norm_vec1 = np.linalg.norm(expl_vec)
        norm_vec2 = np.linalg.norm(target_vec)
        cosine_sim = dot_product / (norm_vec1 * norm_vec2)

        if cosine_sim < 0:
            return 0
        
        return cosine_sim**depr
    
    def __combine(self ,track_list ,target):
        form_prmpt = combiner_prompt.format(
            expl_list = track_list ,
            target_expl = target
        )
        
        resp_unstruct = self.client.models.generate_content(
            model=self.model,
            contents = form_prmpt,
        ).text 

        return resp_unstruct

    
    def __extract_dict(self ,response):
        try:
            return json.loads(response)
        except:
            i1 ,i2 = None ,None  
            for i in range(len(response)):
                if i1 is None and response[i] == "{" : 
                    i1 = i 
                elif response[i] == "}" :
                    i2 = i 
            return json.loads( response[i1 : i2 + 1] )