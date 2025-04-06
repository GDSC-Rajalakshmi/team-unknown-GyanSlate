from dotenv import load_dotenv
from google import genai
from semantic_search import SimNumericProblem ,SimTheory
import json
import os
import time
from question_bank import Solution
from db_engine import Engine
from sqlalchemy.orm import sessionmaker

load_dotenv(override=True) # Looks for a .env file by default
Session = sessionmaker(bind = Engine)


theory_prmpt = """###Instruction : Your task is to provide a solution to the given problem using the provided knowledge base.
>First, present a clear and concise solution.

>Then, explain the solution in a simple and relatable way for a {stud_class}-class student from a rural area in {state}, India.

>Keep the explanation brief and easy to understand for rural student.

###Output formate:{{
  "solution" : "",
  "explanation" : ""
}}

###Knowledge Base:{knowledge_base}

###Question:{question}"""


numeric_prmpt = """###Instruction : Solve the given numeric problem using the provided knowledge base.

>The solution must follow a step-by-step approach, aligning with similar problems in the knowledge base.

>just follow procedure/methods followed in knowledge each step in solution formation

>Each step should be clearly explained to ensure understanding.

>Keep the explanation brief and easy to understand.

###Example output : {{
  "solution" : 0.297,
  "explanation" : "To compute the coefficient of quartile deviation, we first need to find Q1 and Q3. The total frequency (N) is 5 + 8 + 12 + 20 + 10 + 5 = 60.

1. **Finding Q1:**
Q1 is the [(N+1)/4]th item, which is [(60+1)/4] = 15.25th item. This falls within the 20-30 class interval.
Using interpolation:
Q1 = L + [(N/4 - cf)/f] * h
Where:
L = lower limit of the class interval = 20
cf = cumulative frequency of the class preceding the interval containing Q1 = 13
f = frequency of the class interval containing Q1 = 12
h = class width = 10

Q1 = 20 + [(15.25 - 13)/12] * 10
   = 20 + [(2.25)/12] * 10
   ≈ 21.875

2. **Finding Q3:**
Q3 is the [3(N+1)/4]th item, which is [3(60+1)/4] = 45.75th item. This falls within the 30-40 class interval.
Using interpolation:
Q3 = L + [(3N/4 - cf)/f] * h
Where:
L = lower limit of the class interval = 30
cf = cumulative frequency of the class preceding the interval containing Q3 = 25
f = frequency of the class interval containing Q3 = 20
h = class width = 10

Q3 = 30 + [(45.75 - 25)/20] * 10
   = 30 + [(20.75)/20] * 10
   ≈ 40.375

3. **Calculating the Coefficient of Quartile Deviation:**
Coefficient of Quartile Deviation = (Q3 - Q1) / (Q3 + Q1)
                                  = (40.375 - 21.875) / (40.375 + 21.875)
                                  = 18.5 / 62.25
                                  ≈ 0.297"
}}

###Output formate:{{
  "solution" : "",
  "explanation" : ""
}}

###Knowledge Base:{knowledge_base}

###Numeric Problem:{question}"""


error_check_prmpt = """

"""

class SoltuionGenerator:
    context_cache = {}
    model = os.getenv("LANGUAGE_MODEL_ID")
    client = genai.Client(api_key = os.getenv("GOOGLE_API_KEY"))

    def __init__(self ,stud_clss ,subj ,chap ,state ,school_id = None):
        self.stud_clss = stud_clss
        self.subj = subj
        self.chap = chap
        self.state = state
        self.school_id = school_id
        self.__add_cache()
        

    def __add_cache(self):
        self.common_id = { }
        self.common_id['theory'] = f"{self.stud_clss}_{self.subj}_{self.chap}"
        self.common_id['numeric'] = f"{self.stud_clss}_{self.subj}_{self.chap}_{self.state}_{self.school_id}"

        ##when the context is not cached 
        if self.common_id['theory'] not in self.context_cache:
            self.context_cache[ self.common_id['theory'] ] = SimTheory(self.stud_clss ,self.subj ,self.chap)
        
        if self.common_id['numeric'] not in self.context_cache:
            self.context_cache[ self.common_id['numeric'] ] = SimNumericProblem(
                stud_clss = self.stud_clss,
                subj = self.subj,
                chap = self.chap
            )
        
    def solution(self ,question ,q_type):
        ##checking if solution already available in the db  
        obj = self.__check_avail(question ,q_type)
        if obj : 
            return {
                "solution" : obj.solution,
                "explanation" : obj.explanation
            }

        ###else generating 
        kb = self.context_cache[ self.common_id[q_type] ].search(query = question)
        
        ##if no context is available
        if len(kb) == 0:
            return {"solution" : "No context available" ,"explanation" : "No context available" }
        
        if q_type == "theory" : 
            prmpt = theory_prmpt.format(
                stud_class = self.stud_clss, 
                state = self.state,
                knowledge_base = kb,
                question = question
            )
        
        else:
            prmpt = numeric_prmpt.format(
                knowledge_base = kb,
                question = question
            )
        
        resp = self.__generate(prmpt = prmpt)
        
        ##adding the generated response to the db 
        obj = Solution(
            relative_id = self.common_id[q_type],
            question = question,
            solution = resp['solution'],
            explanation = resp['explanation'],
            q_type = q_type
        )

        session = Session()
        session.add(obj)
        session.commit()
        session.close()

        return resp
    
    def __check_avail(self ,question ,q_type):
        session = Session()
        obj = session.query(Solution).filter(
            Solution.relative_id == self.common_id[q_type],
            Solution.question == question,
            Solution.q_type == q_type
        ).first()
        session.close()
        return obj 
    

    def __generate(self ,prmpt):        
        response = self.client.models.generate_content(
            model=self.model,
            contents = prmpt,
        ).text    
        
        return self.__extract_dict(response)

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








    








         