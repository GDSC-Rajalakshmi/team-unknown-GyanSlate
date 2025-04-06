from dotenv import load_dotenv
from google import genai
import json
import os

load_dotenv(override=True) # Looks for a .env file by default


deep_analysis_prompt = """###Instruction: Analyze the performance of a {age} year old student in the current assessment in comparison to their previous assessment. Provide detailed, warm, and personalized feedback that:

- uses a friendly, encouraging tone suitable for a {age} year old,
- highlights key improvements using specific examples,
- clearly explains areas that need more attention without being negative,
- includes simple, relatable suggestions (like using real-life examples, pictures, videos, or fun learning methods),
- and keeps the language easy to understand, like talking to the student directly.
- then the maximum attainable score for each subtopic is 10  

The response should feel like a conversation with the student that builds confidence and motivates them.

###analysis_name - description :
1. current_assessment_analysis - Analyse the performance of the student in different subtopics. Identify any common patterns where the student is strong or weak. Notify areas of weakness to the student. 
2. overall_performance_improvement - Analyse previous assessments and compare them with the current one. Note any improvements, regressions, overcoming of past weaknesses, or development of new abilities.  
3. key_areas_improvement - Analyse the current and previous assessments to find intrinsic capabilities like logical thinking, critical thinking, memory, creativity, etc., where the student has shown improvement.  
4. areas_requiring_more_attention - Analyse the current and previous assessments to find intrinsic capabilities like logical thinking, critical thinking, memory, creativity, etc., where the student requires extra attention.

###Output Format:
{{
  "current_assessment_analysis" : "",
  "overall_performance_improvement": "",
  "key_areas_improvement" : "",
  "areas_requiring_more_attention" : ""
}}

Make sure that you provide your response in the given ###TargetLanguage

###Target_language: {lang}

###Current Assessment: {curr_assess}  

###Previous Assessment performance/feedback: {prev_assess}"""

summarisation_prmpt = """###Instruction : Your role is to summarize the academic performance analysis report of a particular student and provide a concise response (4–5 lines).
Make sure your output is in the given ###Target_language and includes all key information and analysis from the report, giving equal importance to the following four areas:
current_assessment_analysis
overall_performance_improvement
key_areas_improvement
areas_requiring_more_attention

The response should be:
Addressed directly to the student
Encouraging and constructive in tone
Balanced – do not focus only on the positives; include areas needing improvement as well.
Limited to 4–5 lines

Make sure that you provide your response in the given ###TargetLanguage.

###Target_language: {lang}

###Performance_Analysis:{performance_analysis}"""



class FeedBackGenerator : 
    def __init__(self):
        self.model = os.getenv("LANGUAGE_MODEL_ID")
        self.client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))
    
    def generate(self ,lang ,age ,current_assessment ,previous_assessment ,state):
        
        ##perform deep analysis 
        formated_prompt = deep_analysis_prompt.format( 
            age = age, 
            lang = lang,
            curr_assess = current_assessment ,
            prev_assess = previous_assessment ,
        )

        response = self.client.models.generate_content(
            model=self.model,
            contents = formated_prompt,
        ).text    
        
        response = self.__extract_dict(response)
        
        ##performing summaraisation
        formated_prompt = summarisation_prmpt.format(
            performance_analysis = response,
            lang = lang
        )
        
        response["summary"] =  self.client.models.generate_content(
            model=self.model,
            contents = formated_prompt,
        ).text

        return response
      
      
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