from dotenv import load_dotenv
from google import genai
import json
import os 

load_dotenv(override = True)

class SubtopicGenerator: 
    def __init__(self):
        self.model = os.getenv("LANGUAGE_MODEL_ID")
        self.client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY") )
    
    def generate(self ,chapter_text):
        pmpt = """Below is an instruction that describes a task, paired with an input that provides further context.
Write a response that appropriately completes the request.

###Instruction:
Perform a complete analyses on the provide input and determine what are all different subtopics comes under it.
Make sure that you cover all the subtopics in the output and outputed subtopics comes under the provided input  

###Output formate : ["subtopic_1" ,"subtopic_2" ,"subtopic_3" ,.....]

###Input : {}"""

        formated_prompt = pmpt.format(chapter_text)
        response = self.client.models.generate_content(
            model=self.model,
            contents = formated_prompt,
        ).text
        return self.__extract_list(response) 
      
    
      
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