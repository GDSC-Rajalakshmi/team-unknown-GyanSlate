from embedder import Embedder
import numpy as np

emb = Embedder()

text1 = """Deepavali, also known as Diwali, is a major Hindu festival celebrated across India
and other parts of the world. It symbolizes the victory of light over darkness and good over evil.
The festival is associated with the return of Lord Rama to Ayodhya after defeating Ravana, as well as Goddess
Lakshmi, the deity of wealth and prosperity. People celebrate by lighting oil lamps (diyas), bursting fireworks,
decorating homes, exchanging sweets, and praying for prosperity. The festival usually lasts for five days, with the
main day falling on Amavasya (new moon) of the Hindu month of Kartika (October–November)."""

text2 = """Deepavali is a major festival celebrated by Hindus in India. On this joyous occasion, children light fireworks and revel in the festivities. The festival symbolizes the triumph of light over darkness and good over evil. It is dedicated to Goddess Lakshmi, the deity of wealth and prosperity. People mark the celebration by lighting oil lamps (diyas), bursting fireworks, decorating their homes, exchanging sweets, and offering prayers for prosperity. The festival typically spans five days, with the main celebration occurring on Amavasya (the new moon) in the Hindu month of Kartika (October–November)."""

def similarity(text1, text2):
        vec1 = emb.encode([text1])[0]
        vec2 = emb.encode([text2])[0]
        
        dot_product = np.dot(vec1, vec2)

        norm_vec1 = np.linalg.norm(vec1)
        print("norm_vec1 :" ,norm_vec1)

        norm_vec2 = np.linalg.norm(vec2)
        print("norm_vec2 :" ,norm_vec2)
        
        cosine_sim = dot_product / (norm_vec1 * norm_vec2)
        print("cosine_sim :" ,cosine_sim**3)
        print( "dot_product :",dot_product)
        print("euclidian dist :",np.linalg.norm(vec1 - vec2))

        if cosine_sim < 0:
            return 0
        
similarity(text1 ,text2)

