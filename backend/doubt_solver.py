from semantic_search import SimTheory ,SimNumericProblem
from image_generator import ImageGenerator
from question_bank import DoubtResolution
from google.oauth2 import service_account
from google.cloud import storage
from dotenv import load_dotenv
from google import genai
from datetime import timedelta ,datetime
from sqlalchemy.orm import sessionmaker
from db_engine import Engine
import json
import os


load_dotenv(override=True)
Session = sessionmaker(bind=Engine)

prompt = prompt = """###Instruction: Using the given knowledge base, resolve the student's doubt in 4-5 lines. The explanation should be tailored for a {clss}th-grade student from a rural area in {state}, India, making it relatable to their daily life and experiences. Keep the explanation concise and easy to understand.

Next, generate a detailed prompt to create a cartoon-style image that visually represents the explanation. The image should rely entirely on visuals, symbols, and characters without any text, numbers, or written words. Ensure that the image does not include depictions of children, as this would violate our image generation safety settings. Use only adult characters in the image

Then, create three multiple-choice questions (MCQs) based on the knowledge base to check if the student's doubt has been resolved.

###Knowledge Base: {knowledge_base}

###Doubt: {question}

###Output formate : {{ 
   "doubt_resolution": "",
   "image_generation_prompt": "",
   "mcqs": [
      {{ 
         "question": "", 
         "options": [ "opt1", "opt2", "opt3", "opt4" ], 
         "correct_option": "", 
         "why": "" 
      }},
   ]
}}"""

class DoubtSolver:
    model = os.getenv("LANGUAGE_MODEL_ID")
    client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))
    context_cache = { }
    Image_gen_obj = ImageGenerator()

    def __init__(self, state ,clss ,subj ,chap ,school_id = None):
        self.clss = clss
        self.state = state
        self.img = None

        if subj != 'Math':
            self.common_id = f"{state}_{clss}_{subj}_{chap}_{school_id}"
            self.q_type = "numeric"
        else:
            self.common_id = f"{clss}_{subj}_{chap}"
            self.q_type = "theory"
        
        if self.common_id not in self.context_cache : 
            if subj == "Math":
                self.context_cache[self.common_id] = SimNumericProblem(
                    stud_clss = clss,
                    chap = chap,
                    subj = subj,
                )
            else:
                self.context_cache[self.common_id] = SimTheory(
                    stud_clss = clss,
                    subj = subj,
                    chap = chap
                )
    
    def add_image(self ,link):
        self.img = self.client.files.upload(file = link)

    def resolve(self ,question):
        kb = self.context_cache[self.common_id].search(question)
        if len(kb) == 0:
            return {"doubt_resolution": "No Context available", "img":"null" ,"mcqs": []}

        form_prmpt = prompt.format(
            knowledge_base = kb,
            state = self.state,
            clss = self.clss,
            question = question   
        )
        
        if self.img is None:
            content = form_prmpt
        else:
            content = [self.img ,form_prmpt]

        resp = self.client.models.generate_content(
            model=self.model,
            contents = content,
        ).text

        resp = self.__extract_dict(response = resp)

        img_bucket_link = self.Image_gen_obj.generate(
            prompt = resp['image_generation_prompt'],
            common_id = self.common_id
        )
        
        if img_bucket_link != None :
            url ,expiration = self.__img_acces_url(img = img_bucket_link)
            session = Session()

            obj = DoubtResolution(
                relative_id = self.common_id,
                question = question,
                explanation = resp['doubt_resolution'],
                q_type = self.q_type,
                img = img_bucket_link,
                access_url = url,
                expiration = expiration
            )

            session.add(obj)
            session.commit()
            session.close()
        
        del resp['image_generation_prompt']
        resp['img'] = url

        return resp
        
        
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


        




        


