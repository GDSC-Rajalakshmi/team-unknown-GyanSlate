from .regional_content import RegionalContentGenerator
from google import genai
import json
from pathlib import Path
from dotenv import load_dotenv
import os 

# Always relative to the script location
dotenv_path = Path(__file__).resolve().parent / ".." / ".env"
load_dotenv(dotenv_path=dotenv_path.resolve())


regional_cnt_generator = RegionalContentGenerator()

class RegionalTransformer : 

    def __init__(self ,state ,age):
        self.state = state  
        self.age = age 
        self.model = os.getenv("LANGUAGE_MODEL_ID")
        self.client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))
        self.regional_data = regional_cnt_generator.generate(state = state)

    
    def transform( self ,mcq_list ): 
        assert isinstance(mcq_list ,list) ,"mcq_list variable must be a list"
    
        ##generating regional content ,formating the prompt  
        formted_prompt = self.__prompt(mcq_list = mcq_list)
                
        ##perform convertion
        response = self.client.models.generate_content(
            model=self.model,
            contents = formted_prompt,
        ).text

        response = self.__extract_list(response = response)
        n = min(len(response) ,len(mcq_list))
        for i in range(n):
            response[i]["subtopic"] = mcq_list[i]["subtopic"]
            response[i]["type"] = "example"

        return response[:n] 

    
    def __prompt(self ,mcq_list):
        prmt = """###Instruction: Based on the provided data about {state} (including famous places, food, lifestyle 
of people, etc.), transform the following multiple-choice questions (MCQs) into a form that is more understandable and 
relatable to life style of {age}-year-old rural student in {state} . Use the provided regional data just for reference 
,if needed use your own knowledge about this region to make conversion more engaging and contextually relavent.Make sure 
conversions made are suitable and appropriate to the provided examples and situations in the mcqs.


###Regional data: {regional_data}

###Input mcq: {mcq_list}

###Output formate: [
  {{
    "question": "Rewritten question here",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correct_option": "Correct Option",
    "why": "Brief explanation of why this option is correct in simple language."
  }},
  ...
]

###Response:
"""      
        return prmt.format( age = self.age 
                           ,state = self.state 
                           ,mcq_list = mcq_list
                           ,regional_data = self.regional_data)
    
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
    
 








                
