from langdetect import detect
from google import genai
import pycountry
from pathlib import Path
from dotenv import load_dotenv
import os 

# Always relative to the script location
dotenv_path = Path(__file__).resolve().parent / ".." / ".env"
load_dotenv(dotenv_path=dotenv_path.resolve())


class Language_translor: 

  def __init__(self):
    self.api_key = os.getenv("GOOGLE_API_KEY")
    self.model = os.getenv("LANGUAGE_MODEL_ID")
    self.max_output_tokens = 150
    self.__set_prompt_format() 
    self.client = genai.Client(api_key = self.api_key )
    self.max_cycles = 5
    
  def __set_prompt_format(self):
    self.prompt = """Below is an instruction that describes a task, paired with an input that provides further context.
Write a response that appropriately completes the request.

###Instruction:
Translate the provided input text from the specified source language to the target language, ensuring both accuracy and natural fluency. The translation should be engaging, culturally relevant, and easily understandable for the target language community. 

###Source : {}

###Target : {}

###Output formate : {}

###input : {}"""
  
  def translate(self ,source ,target ,inp ,output_format):
    response = None    
    formated_prompt = self.prompt.format(source ,target ,output_format ,inp)
    response = self.client.models.generate_content(
        model=self.model,
        contents = formated_prompt,
    ).text
    return response 
      
      
  def __detect_lang(self ,inp):
    lang_code = detect(inp)
    return pycountry.languages.get(alpha_2 = lang_code).name