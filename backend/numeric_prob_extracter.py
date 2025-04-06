from dotenv import load_dotenv
from google import genai
import json
import os

load_dotenv(override=True) # Looks for a .env file by default

raw_cont_extract_prmpt = """Extract all the contents from the attached file and provide the response exactly as it provided in the file. Do not modify, add, or remove anything from the original content."""

unstruct_to_struct_prmpt = """### Instruction:  
Analyze the given unstructured data and extract relevant information to provide a structured output in the specified format. 
Explain the solution given for the question in the unstructured content step by step. 
Do not modify, add, or remove anything from the original content ,just explain the existing soltuion step by step.  

### Output Format:  
[  
    {{  
      "question": "",  
      "explained_solution": ""  
    }}  
]  

### Unstructured Data: {unstructured_data}"""


class NumericProbExtractor : 
    client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))
    model = os.getenv("LANGUAGE_MODEL_ID")

    def __init__(self ,file_link):
        self.file = self.client.files.upload(file = file_link)
    
    def extract(self):
        raw_cnt = self.__extract_raw_content()
        return self.__unstruct_to_struct(raw_cont = raw_cnt)

    def __extract_raw_content(self):
        content = [self.file ,raw_cont_extract_prmpt]
        result = self.client.models.generate_content(
            model = self.model,
            contents =content
        ).text
        return result
    
    def __unstruct_to_struct(self ,raw_cont):
        prmpt = unstruct_to_struct_prmpt.format(unstructured_data = raw_cont)
        result = self.client.models.generate_content(
            model = self.model,
            contents = prmpt
        ).text
        return self.__extract_list(response = result)
        
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


        



        
        


       
    