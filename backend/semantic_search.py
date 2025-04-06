from langchain_text_splitters import RecursiveCharacterTextSplitter # type: ignore ## split the document into smaller chunks 
from sklearn.metrics.pairwise import cosine_similarity
from sqlalchemy.orm import sessionmaker
from embedder import Embedder
from context_db import TheoryContext ,NumericProblemContext
from db_engine import Engine
import numpy as np 

Session = sessionmaker(bind=Engine)

class SemanticSearch:
    embedder = Embedder()
    min_similarity = 0.50
    k = 5
    

class SimTheory(SemanticSearch):
    text_spliter = RecursiveCharacterTextSplitter(
        separators=["\n\n", "\n", "."],
        chunk_size=500,
        chunk_overlap=100
    )

    def __init__(self, stud_clss, subj, chap):
        self.common_id = f"{stud_clss}_{subj}_{chap}"
        session = Session()
        self.objs = session.query(TheoryContext).filter(TheoryContext.relative_id == self.common_id).all()
        self.chunks = [obj.chunk for obj in self.objs]
        self.embeddings = np.array([obj.text_vector for obj in self.objs])
        session.close()
    
    def add(self, text):
        assert isinstance(text, str), "text should be a string"
         
        if len(self.objs) > 0:
            print(f"{self.common_id} already exists")

        new_chunks = self.text_spliter.split_text(text=text)
        new_embeddings = self.embedder.encode(new_chunks).tolist()
        
        self.objs += self.__store(new_chunks, new_embeddings)
        self.chunks += new_chunks

        old_embeddings = self.embeddings.tolist()
        self.embeddings = np.array(old_embeddings + new_embeddings)
        
    def __store(self, new_chunks, new_embeddings):
        objs = [
            TheoryContext(
                relative_id=self.common_id,
                chunk=new_chunks[i],
                text_vector=new_embeddings[i]
            ) for i in range(len(new_chunks))
        ]
        
        session = Session()
        session.add_all(objs)
        session.commit()
        session.close()
        
        return objs

    def search(self, query):
        if len(self.embeddings) == 0:
            return ""
        
        print("Query type :" ,type(query))
        print("Embedding_shape :" ,self.embeddings.shape) 
        query_embedding = self.embedder.encode([query])[0]
        if query_embedding.ndim == 1:
            print("Reshaping the query vector")
            query_embedding = query_embedding.reshape(1, -1)
        print("Query shape" ,query_embedding.shape)

        similarities = cosine_similarity(query_embedding, self.embeddings)[0]
        print("Similarities :" ,similarities)
        ranked_results = sorted(
            zip(self.chunks, similarities), key=lambda x: x[1], reverse=True
        )
        
        selected_chunks = [chunk for chunk, sim in ranked_results][:self.k]
        return "/n".join(selected_chunks)


class SimNumericProblem(SemanticSearch):

    def __init__(self ,stud_clss, subj, chap ,state = "common" ,school_id = "common"):
        self.common_id = f"{stud_clss}_{subj}_{chap}_{state}_{school_id}"
        session = Session()
        
        self.objs = session.query(NumericProblemContext).filter(
            NumericProblemContext.relative_id == self.common_id 
        ).all()
        
        self.questions = [obj.question for obj in self.objs]
        self.solutons = [obj.solution for obj in self.objs]
        self.embeddings = np.array([obj.text_vector for obj in self.objs])
    
    def add(self ,new_questions ,new_soltutions):
        assert len(new_questions) == len(new_soltutions) ,"there is mismatch in number of questions and solutions"
        
        if len(self.objs) > 0:
            print(f"{self.common_id}-numeric problems already exists")

        new_embeddings = self.embedder.encode(new_questions)
        
        new_objs = self.__store(
            new_questions = new_questions , 
            new_soltutions = new_soltutions,
            new_embeddings = new_embeddings.tolist()
        )
        
        print(new_objs ,self.objs)
        self.objs += new_objs
        self.questions += new_questions
        self.solutons += new_soltutions
        self.embeddings = np.array(self.embeddings.tolist() + new_embeddings.tolist())
    
    def __store(self ,new_questions ,new_soltutions ,new_embeddings):
        session = Session()
        new_objs = [
            NumericProblemContext(
                relative_id = self.common_id, 
                question = new_questions[i],
                solution  = new_soltutions[i],
                text_vector = new_embeddings[i]
            ) for i in range(len(new_questions))
        ]
        session.add_all(new_objs)
        session.commit()
        session.close()
        return new_objs

    def search(self, query):
        if len(self.embeddings) == 0:
            return [ ]
        
        query_embedding = self.embedder.encode([query])
        if query_embedding.ndim == 1:
            query_embedding = query_embedding.reshape(1, -1)

        similarities = cosine_similarity(query_embedding, self.embeddings)[0]
        ranked_results = sorted(
            zip(self.questions, self.solutons ,similarities), key=lambda x: x[2], reverse=True
        )
        
        selected_q = [{
            "question" : quest,
            "solution" : sol,
            "sim" : sim
        } for quest ,sol ,sim in ranked_results][:self.k]
        
        return selected_q

        





        
        
        



