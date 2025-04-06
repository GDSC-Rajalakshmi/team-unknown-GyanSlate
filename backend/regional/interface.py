from .language_translator import Language_translor 
from .regional_transformer import RegionalTransformer
import copy
import json

##state to mother tongue mapping  
state_language = {
    "Andhra Pradesh": "Telugu",
    "Arunachal Pradesh": "English",
    "Assam": "Assamese",
    "Bihar": "Hindi",
    "Chhattisgarh": "Hindi",
    "Goa": "Konkani",
    "Gujarat": "Gujarati",
    "Haryana": "Hindi",
    "Himachal Pradesh": "Hindi",
    "Jharkhand": "Hindi",
    "Karnataka": "Kannada",
    "Kerala": "Malayalam",
    "Madhya Pradesh": "Hindi",
    "Maharashtra": "Marathi",
    "Manipur": "Manipuri",
    "Meghalaya": "English",
    "Mizoram": "Mizo",
    "Nagaland": "English",
    "Odisha": "Odia",
    "Punjab": "Punjabi",
    "Rajasthan": "Hindi",
    "Sikkim": "Nepali",
    "Tamil Nadu": "Tamil",
    "Telangana": "Telugu",
    "Tripura": "Bengali", 
    "Uttar Pradesh": "Hindi",
    "Uttarakhand": "Hindi",
    "West Bengal": "Bengali",
    "Delhi": "Hindi",
    "Jammu and Kashmir": "Kashmiri" 
}

class RegionalInterface : 
    def __init__(self ,state ,age):
        assert state in state_language.keys() ,"the state is not supported by the system"
        self.reg_transform = RegionalTransformer(state = state ,age = age)
        self.lang_trans = Language_translor()
        self.state = state 
        self.age = age 
        self.batch_size = 15
        self.target_lang = state_language[state]   
    
    ##performs regional transformation as transformation 
    def transform(self ,mcqs ,subtopics):
        assert isinstance(subtopics ,list) ,"subtopics shoudl be a list data type"
        mcqs = copy.deepcopy(mcqs) 
        
        try :            
            for i in range(0 ,len(mcqs) ,self.batch_size): ##perform batched operations to reduce latency 
                batch = mcqs[i  : i + self.batch_size]
                batch_conv_resp = self.reg_transform.transform(mcq_list = batch)
            
                ##making update in mcqs varaible
                for j in range(len(batch_conv_resp)):
                    indx = i + j 
                    mcqs[indx]["question"] = batch_conv_resp[j]['question']
                    mcqs[indx]["options"] = batch_conv_resp[j]['options']
                    mcqs[indx]["correct_option"] = batch_conv_resp[j]['correct_option']
                    mcqs[indx]["why"] = batch_conv_resp[j]['why']
                    mcqs[indx]["subtopic"] = batch_conv_resp[j]["subtopic"]
                    mcqs[indx]["type"] = batch_conv_resp[j]["type"]
                    
            return mcqs   
        
        except Exception as e:
            print("ERROR : Regional.transform :-" ,e)
            return []
    
    ##performs regional translation
    def translate(self ,mcqs ,subtopics):
        assert isinstance(subtopics ,list) ,"subtopics shoudl be a list data type"
        mcqs = copy.deepcopy(mcqs) 
        
        try :
            subtopic_dict = self.__translate_subtopics(subtopics = subtopics) ##translation subtopics alone 
            trans_output_format = """[
  [
    "translated_question",
    [
      "translated_option1",
      "translated_option2",
      "translated_option3",
      ...
    ],
    "translated_correct_option",
    "translated_explanation"
  ]
]""" 
            
            for i in range(0 ,len(mcqs) ,self.batch_size): ##perform batched operations to reduce latency 
                batch = mcqs[i  : i + self.batch_size]
                
                ##converting batch translation form 
                batch_trans_list = [ ]
                for mcq in batch :
                    batch_trans_list.append( [ 
                            mcq["question"],
                            mcq["options"],
                            mcq["correct_option"],
                            mcq["why"] 
                    ])

                ##performing translation
                batch_trans_resp = self.lang_trans.translate(
                    source = "english" ,
                    target = self.target_lang , 
                    inp = batch_trans_list ,
                    output_format = trans_output_format
                )
                
                batch_trans_resp = self.__extract_list(response = batch_trans_resp)

                ##making update in mcqs varaible
                for j in range(len(batch_trans_resp)):
                    indx = i + j 
                    mcqs[indx]["question"] = batch_trans_resp[j][0]
                    mcqs[indx]["options"] = batch_trans_resp[j][1]
                    mcqs[indx]["correct_option"] = batch_trans_resp[j][2]
                    mcqs[indx]["why"] = batch_trans_resp[j][3]
                    mcqs[indx]["subtopic_translated"] = subtopic_dict[mcqs[indx]["subtopic"]]
            
            return mcqs   
        
        except Exception as e:
            print("ERROR : regional.translate :-" ,e)
            return []

    def __translate_subtopics(self ,subtopics):
        subtopics = list( set(subtopics) ) 
        output_format = """[ "translated_sub_topic1" ,"translated_sub_topic2" ,"translated_sub_topic2" ,..]"""
        response = self.lang_trans.translate( 
            source = "english" , 
            target = self.target_lang,
            inp = subtopics ,
            output_format = output_format
        )
        response = self.__extract_list(response)
        output = { } 
        for src ,trg in zip(subtopics ,response):
            output[src] = trg
        return output

    
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
            print("xxml",response[i1 : i2 + 1])
            return json.loads( response[i1 : i2 + 1] )








                

            


