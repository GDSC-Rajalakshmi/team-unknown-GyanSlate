from google import genai
from pathlib import Path
from dotenv import load_dotenv
import os 

# Always relative to the script location
dotenv_path = Path(__file__).resolve().parent / ".." / ".env"
load_dotenv(dotenv_path=dotenv_path.resolve())


class RegionalContentGenerator : 

    def __init__(self):
        ##google gemini api access  
        self.model = os.getenv("LANGUAGE_MODEL_ID")
        self.client = genai.Client(
            api_key = os.getenv("GOOGLE_API_KEY")
        )
    
    def generate(self ,state):
        formated_prompt = self.__prompt(state = state)
        
        response = self.client.models.generate_content(
            model=self.model,
            contents = formated_prompt,
        ).text

        return response 
        
    
    def __prompt(self ,state ,word_count = 450):
        prmpt = """Write an informational article of approximately {word_count} words about the lifestyle of children aged 9 to 10 years in the Indian state of {state}. The article should be factual, practical, and descriptive—not poetic or embellished.

Please include specific details and real-life examples in the following categories:

Common foods typically consumed by children in this age group (e.g., meals at home, snacks at school)
Festivals celebrated, including how children participate (rituals, clothing, activities, school events)
Daily routines, including school schedule, transport, tuition or homework time, etc.
Hobbies and leisure activities, such as sports, games (traditional or modern), TV shows, or digital habits
Social environment, such as interactions with family, teachers, peers, and the role of community
Regional customs and traditions involving children
Cultural and linguistic influences that shape their everyday communication and thinking
Ensure the tone is educational and research-oriented, as if you're writing for a cultural research report or an educational publication."""
        
        return prmpt.format(state = state ,word_count = word_count)
    

if __name__ == "__main__" : 
    obj = RegionalContentGenerator()
    print(obj.generate(state = "Tamil Nadu"))



