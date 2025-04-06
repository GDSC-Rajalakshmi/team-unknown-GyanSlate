from question_bank import SubtopicDescribe ,SubtopicExplainer
from google.oauth2 import service_account
from google.cloud import storage
from datetime import timedelta ,datetime
from image_generator import ImageGenerator
from semantic_search import SimTheory
from sqlalchemy.orm import sessionmaker
from db_engine import Engine
from dotenv import load_dotenv
from google import genai
import json
import os

load_dotenv(override=True) 
Session = sessionmaker(bind = Engine)


subtopic_select_prmpt = """### Instruction:  
From the given list of subtopics, select only those that are essential to solving or answering the given question. Additionally, determine whether the question is numeric (involving calculations, equations, or problem-solving) or theory-based (conceptual, explanatory, or descriptive).  

### Output Format:  
{{  
  "question_type": "numeric" | "theory",  
  "chosen_subtopics": [  
    "chosen_subtopic1_name",  
    "chosen_subtopic2_name",  
    "chosen_subtopic3_name"  
  ]  
}}  

### Question: {question}  

### Subtopics: {subtopic_dict}"""


subtopic_exp_prmpt = """### Instruction: Provide a brief and easily understandable explanation for the given subtopic using the provided knowledge base.  
The explanation should be tailored for a {clss}th-grade student from a rural area in {state}, India. Ensure that it is relatable to their daily life and experiences. Keep the explanation concise, fitting within 4-5 lines.  

Next, generate a detailed prompt to create a cartoon-style image that visually represents the explanation. The image should rely entirely on visuals, symbols, and characters without any text, numbers, or written words. Ensure that the image does not include depictions of children, as this would violate our image generation safety settings. Use only adult characters in the image

### Subtopic Description: {subtopic_describ}  

### Knowledge Base: {knowledge}  

### Output Format:  
{{  
  "explanation": "",  
  "img_generation_prompt": ""  
}}"""



class SubtpcExplGen : 
    model = os.getenv("LANGUAGE_MODEL_ID")
    client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))
    context_cache = { }
    img_generator = ImageGenerator()

    def __init__(self ,stud_clss ,subj ,chap ,state):
        self.stud_class = stud_clss
        self.subj = subj
        self.chap = chap
        self.state = state
        
        ##caching for faster
        self.common_id = f"{self.stud_class}_{self.subj}_{self.chap}"
        if self.common_id not in self.context_cache : 
            self.context_cache[self.common_id] = SimTheory(
                stud_clss = stud_clss,
                subj = subj,
                chap = chap,
            )
        
        ##having identifier to it  
        self.context = self.context_cache[self.common_id]
        
    def create(self ,question):
        sub_objs = self.__fetch_subtops()  ##fetch all the suptopic-description under this chap
        select_subs ,q_type = self.__select_subs(sub_objs = sub_objs ,question = question) ##choose sub which is related to this  
        print(select_subs ,q_type)

        avail_obj_list = self.__check_avail(select_subs = select_subs) ##fetching already available explanation 
        avail_nam_list = [obj.name for obj in avail_obj_list]

        new_subexp_objs = []
        db_selected_objs = []
        
        for obj in select_subs:
            if obj.name not in avail_nam_list:    

                new_obj_temp = self.__regional_exp(sub_obj = obj)
                if new_obj_temp :    
                    new_subexp_objs.append(new_obj_temp)

                    ##if new_obj donot contain image it is not selected
                    if new_obj_temp.img != None :
                        db_selected_objs.append(new_obj_temp)
                
        session = Session()
        session.add_all(db_selected_objs)
        session.commit()
        
        result_objs = avail_obj_list + new_subexp_objs
        print(result_objs)
        result = {}
        for obj in result_objs : 

            ##refereshing the acces if url is timed out  
            if obj.expiration and obj.expiration > datetime.now() : 
                url ,expiration = self.__img_acces_url(img = obj.img)
                obj.access_url = url
                obj.expiration = expiration
            
            result[obj.name] = {
                "img" : obj.access_url,
                "explanation" : obj.exp
            }
        
        session.commit()
        session.close()

        return result ,q_type
        
    def __regional_exp(self ,sub_obj):
        query = f"{sub_obj.name}:{sub_obj.describe}"
        kb = self.context.search(query = query)
        
        if len(kb) == 0:
            return None

        prmpt = subtopic_exp_prmpt.format(
            subtopic_describ = query,
            state = self.state,
            knowledge = kb, 
            clss = self.stud_class
        )

        unstruct_resp = self.__generate(prmpt = prmpt)
        resp = self.__extract_dict(unstruct_resp)
        
        print(resp)

        img_bucket_link = self.img_generator.generate(
            prompt = resp["img_generation_prompt"],
            common_id = self.common_id + f"{self.state}_{sub_obj.name}"
        )

        url ,expiration = self.__img_acces_url(img = img_bucket_link)
 
        obj = SubtopicExplainer(
            sub_id = sub_obj.id,
            name = sub_obj.name,
            state = self.state,
            exp = resp["explanation"],
            img = img_bucket_link,
            access_url = url,
            expiration = expiration
        )

        return obj
    
    def __img_acces_url(self ,img):
        try:
            key_path = os.path.abspath(os.getenv("CRED_JSON_PATH"))
            credentials = service_account.Credentials.from_service_account_file(key_path)
            storage_client = storage.Client(credentials = credentials )

            bucket = storage_client.bucket(os.getenv("BUCKET_NAME"))
            blob = bucket.blob(img)  # Use the actual path stored in DB

            # Generate a signed URL (valid for 1 hour)
            signed_url = blob.generate_signed_url(
                expiration=timedelta(hours=1440),
                method="GET",
            )
        
            return signed_url ,datetime.now() + timedelta(hours=1400)

        except Exception as e:
            print("ERROR :- " ,e)
            return None ,None
        

    def __fetch_subtops(self):
        session = Session()
        sub_objs = session.query(SubtopicDescribe).filter(
            SubtopicDescribe.relative_id == self.common_id
        ).all()
        session.close()
        return sub_objs
    
    def __check_avail(self ,select_subs):
        ids = [obj.id for obj in select_subs]
        
        session = Session()
        sub_exp_objs = session.query(SubtopicExplainer).filter(
            SubtopicExplainer.state == self.state,
            SubtopicExplainer.sub_id.in_(ids)
        ).all()
        session.close()

        return sub_exp_objs
    
    def __select_subs(self ,sub_objs ,question):
        subtopic_describ = {}
        for obj in sub_objs : 
            subtopic_describ[obj.name] = obj.describe
        
        print("subtopic_describ :" ,subtopic_describ)

        form_prmpt = subtopic_select_prmpt.format(
            subtopic_dict = subtopic_describ,
            question = question
        )

        unstuct_resp = self.__generate(prmpt = form_prmpt)
        print("selection resp : " ,unstuct_resp)
        resp = self.__extract_dict(unstuct_resp)
        

        select_subs = []
        for obj in sub_objs:
            if obj.name in resp['chosen_subtopics']:
                select_subs.append(obj)
        
        return select_subs ,resp['question_type']

    
    def __generate(self ,prmpt):
        return self.client.models.generate_content(
            model=self.model,
            contents = prmpt,
        ).text


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
            return json.loads( response[i1 : i2 + 1])
    
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
            return json.loads( response[i1 : i2 + 1])
    

    

         


        
            







        

        
        