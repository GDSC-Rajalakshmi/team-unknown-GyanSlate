from dotenv import load_dotenv
from google import genai
import json
import os

load_dotenv(override=True)

image_q_extrct_prmpt = """### Instruction: Fetch the questions alone from the given image. Do not modify, add, or remove anything from the original content—just extract the questions from the image.

If a question contains options, a hint, or any other information related to the question (apart from the solution), include that as well.

### Output format:
[
  "question1",
  "question2"
]"""  

class ExtractQuestion :
    llm_model = os.getenv("LANGUAGE_MODEL_ID")
    client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
    
    def extract(self ,path):
        """Uses an LLM to extract questions from the image."""
        client_file = self.client.files.upload(file=path) 
        content = [client_file, image_q_extrct_prmpt]
        
        response = self.client.models.generate_content(
            model=self.llm_model,
            contents=content,
        ).text
        
        return self.extract_list(response)
    
    def extract_list(self ,response):
        try:
            return json.loads(response)
        except:
            i1, i2 = None, None  
            for i in range(len(response)):
                if i1 is None and response[i] == "[":
                    i1 = i 
                elif response[i] == "]":
                    i2 = i 
            
            return json.loads(response[i1: i2 + 1])

