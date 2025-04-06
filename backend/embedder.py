from vertexai.language_models import TextEmbeddingModel
from dotenv import load_dotenv
import vertexai
import numpy as np
import os

load_dotenv(override=True)

##initiating vertex ai account  
vertexai.init( 
    project = os.getenv("GOOGLE_CLOUD_PROJECT_ID"), 
    location = os.getenv("GOOGLE_CLOUD_REGION")
)

class Embedder : 
    
    def __init__(self):
        self.model = TextEmbeddingModel.from_pretrained(
            os.getenv("TEXT_ENCODER_ID")
        )
    
    def encode(self ,text_list):
        assert isinstance(text_list ,list) ,"text_list should be a list"
        
        embeddings = self.model.get_embeddings( 
            texts = text_list 
        )

        vectors = [ ]
        for obj in embeddings:
            vectors.append( 
                obj.values 
            ) 
        
        return np.array(vectors)
    


        
    
