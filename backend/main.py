from mcq_generation_cache import McqGenerationCache
from base_mcq_generater import BaseMcqGenerator
from regional.interface import RegionalInterface
from subtopics_generate import SubtopicGenerator
from assesment_handler import AssignmentHandler
from google.cloud import translate_v2 as translate
from flask import Flask, request, jsonify
from sqlalchemy.orm import sessionmaker
from user_engagement_db import StudentScore
from solution_generator import SoltuionGenerator
from subtopic_explainer import SubtpcExplGen
from explanation_track import ExplanTrack
from regional.interface import state_language
from dotenv import load_dotenv
from db_engine import Engine
from doubt_solver import DoubtSolver
from image_quest_extrct import ExtractQuestion
from numeric_prob_extracter import NumericProbExtractor
from semantic_search import SimNumericProblem
from question_bank import Question
from PIL import Image
import json
import copy 
import time 
import fitz
import io
import os
import jwt
import random


##loadin the env file  
load_dotenv(override=True)

app = Flask(__name__)
subtopic_generator_obj = SubtopicGenerator()
time.sleep(2)
mcq_gen_cache = McqGenerationCache( )
assigment_handler = AssignmentHandler()

##question extractor
img_quest_ext = ExtractQuestion()

##friendly explanation
response_cache = {}

##creating a session object with question bank db  
Session = sessionmaker(bind=Engine)

##translation api
translate_client = translate.Client() 

##explanation track obj
exp_trck_obj = ExplanTrack()

##folder 
TEMP_IMG_UPLOAD_FOLDER = "temp_img_flder"
TEMP_PDF_FILE = "temp_pdf_flder"

##roles
ADMIN = "admin"
TEACHER = "teacher"
STUDENT = "student"

@app.route('/authorise', methods=['POST'])
def user_authentication():
    try:
        resp = authoris(
            role = "any" ,
            is_any = True
        )
        if resp : 
            return jsonify({"status" : "succes"}) ,200
        else:
            return jsonify({"status" : "unsuccess"}) ,400
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/admin/subtopic_generation', methods=['POST'])
def generate_subtopics():
    try:
        if not authoris(role = ADMIN):
            return jsonify({"status" : "access_denied"}),400
        
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400

        file = request.files['file']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400
        
        # Process PDF in-memory
        file_stream = io.BytesIO(file.read())
        
        # retriving the text from the pdf in memory 
        doc = fitz.open(stream=file_stream, filetype='pdf')
        text = ""
        for page in doc:
            text += page.get_text()
        
        ##genertaing subtopics 
        response = subtopic_generator_obj.generate( 
            chapter_text = text
        )
        
        return jsonify({"subtopics": response}) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/admin/mcq_generation', methods=['POST'])
def generate_mcq():
    try:
        if not authoris(role = ADMIN):
            return jsonify({"status" : "access_denied"}),400
        
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400

        file = request.files['file']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        if file and file.filename.endswith('.pdf'):
            # Process PDF in-memory
            file_stream = io.BytesIO(file.read())

            # retriving the text from the pdf in memory 
            doc = fitz.open(stream=file_stream, filetype='pdf')
            text = ""
            for page in doc:
                text += page.get_text()
            
            ##extracting the json part
            data = json.loads( request.form.get('data') )
            
            mcq_dict = {}
            
            ##generating the base mcqs
            base_mcq_generator_obj = BaseMcqGenerator( 
                document_text = text , 
                subtpc_count = data["subtopic_q_count"],
                age = 9 + (data["class"] - 4) ,##as the base class is 4th  
                exmpl_percentage = data["example_percentage"], 
                stud_clss = data['class'] ,
                subj = data['subject'].strip(),
                chap = data['chapter'].strip() 
            )

            resp = base_mcq_generator_obj.generate()
            mcq_dict["common"] = resp["example"] + resp["normal"]
            
            ##breaking if no base mcq 
            if len(mcq_dict["common"]) == 0:
                return jsonify(mcq_dict)

            ##generating for each state 
            data["choose_regions"].remove("common")

            ##generating for 
            for state in data["choose_regions"] :
                
                state_converter = RegionalInterface( 
                    state = state ,
                    age = 9 + (data["class"] - 4) ,##as the base class is 4th  
                )
                
                ##if regional transformation needed (only for example based questions)
                if data["is_region_transform"] and len(resp["example"]) > 0 :
                    state_exmp = state_converter.transform( 
                        mcqs = resp["example"] ,
                        subtopics = list(data["subtopic_q_count"].keys())
                    )
                else:
                    state_exmp = resp["example"]
                
                ##state transformed mcqs in english 
                mcq_dict[state] = state_exmp + copy.deepcopy(resp["normal"])
                
                ##translating regional language and storing it   
                lang = state_language[state]
                mcq_dict[lang] = state_converter.translate(
                    mcqs = mcq_dict[state],
                    subtopics = list(data["subtopic_q_count"].keys())
                )
                
            ##creating access key
            access = f"{random.randint(0,99999)}--{random.randint(0,99999)}--{time.time()}"

            ##adding the data to the cache
            mcq_gen_cache.add( 
                access = access , 
                stdent_class = data["class"] ,
                subject = data["subject"].strip() ,
                chapter = data["chapter"].strip() ,
                created_time_stamp = time.time() ,
                mcq_dict = copy.deepcopy(mcq_dict) 
            )
            
            ##adding access to response 
            mcq_dict["access"] = access
            
            ##forming respopnse dict
            response_dict = {}
            response_dict["access"] = access
            for k ,v in mcq_dict.items() :
                if k == "common" or k in state_language.keys():
                    response_dict[k] = v

            return jsonify(response_dict) ,200
       
        return jsonify({"error": "Invalid file type"}), 400
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    
@app.route('/admin/mcq_generation/submit', methods=['POST'])
def store_mcq():
    try:
        if not authoris(role = ADMIN):
            return jsonify({"status" : "access_denied"}),400
        
        print("str")
        data = request.get_json()
        print("got_json")

        if data["submit"] :

            print("attempting to submit")
            if mcq_gen_cache.store(access = data["access"]):
                print("data stored successfully")
                return  jsonify({"status" : "success"}),200
            
            return  jsonify({"status" : "failed"}),400

        print("data got removed")    
        mcq_gen_cache.remove_data(access = data["access"])
        return  jsonify({"status" : "success"}),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/teacher/mcq_availability', methods=['GET'])
def mcq_availabilty_info():
    try:
        if not authoris(role = TEACHER):
            return jsonify({"status" : "access_denied"}),400
        resp =  assigment_handler.fetch_availablity()
        return jsonify(resp),200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/teacher/assignment_schedule' ,methods = ["POST"] )
def assignment_schedule():
    try:
        if not authoris(role = TEACHER):
            return jsonify({"status" : "access_denied"}),400
        data = request.get_json() 
        assigment_handler.add_assignment( 
            student_class = data["class"], 
            subject = data["subject"].strip(),
            chapter = data["chapter"].strip(),
            start = data["start"] , 
            end = data["end"],
            subtopic_count = data["subtopic"]
        )
        return jsonify({"status" : "success"}),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/teacher/list_assignment' ,methods = ["POST"] )
def teacher_assignment_list():
    try:
        if not authoris(role = TEACHER):
            return jsonify({"status" : "access_denied"}),400
        response = assigment_handler.teacher_list_assigments()
        data = request.get_json()

        if data['lng'] == 'en':
            return jsonify(response) ,200 
        
        for k1 in response.keys():
            for dict1 in response[k1]:
                dict1['subject'] =  translate_text(target = data['lng'] ,text = dict1['subject'] )
                dict1['chapter'] =  translate_text(target = data['lng'] ,text = dict1['chapter'] )
                
        return jsonify(response) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/teacher/learning_gap_analysis' ,methods = ["POST"] )
def teacher_assignment_analysis():
    try:
        if not authoris(role = TEACHER):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()
        resp = assigment_handler.assignment_analysis(
            schedule_id = data["id"]
        )

        ###performing translation
        if data['lng'] != 'en':
            trans_resp = []
            
            for i in range(len(resp)):
                trans_resp.append({})
                
                trans_resp[i]['name'] = translate_text(target = data['lng'] ,text = resp[i]['name'])
                trans_resp[i]['subtopic_score'] = {}

                for sub_nme in resp[i]['subtopic_score'].keys():
                    trans_sub_nme = translate_text(target = data['lng'] ,text = sub_nme)
                    trans_resp[i]['subtopic_score'][trans_sub_nme] = resp[i]['subtopic_score'][sub_nme]
            
            return jsonify(trans_resp),200
         
        return jsonify(resp),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/teacher/numericprob' ,methods = ["POST"] )
def teacher_numericprob_submiting():
    try:
        if not authoris(role = TEACHER):
            return jsonify({"status" : "access_denied"}),400
        
        pdf_file = request.files['file']
        data = json.loads( request.form.get('data') )


        if pdf_file.filename.endswith('.pdf'):
            ##if pdf file exist ,temperarly saving it 
            uniq_pth = f"{data['class']}_{data['subj'].strip()}_{data['chap'].strip()}_{random.randint(0,9999)}.pdf"
            path = os.path.join(TEMP_PDF_FILE ,uniq_pth)
            pdf_file.save(path)

            ###
            extract_obj = NumericProbExtractor(file_link = path)
            resp_list = extract_obj.extract()

            new_problems = [dict1['question'] for dict1 in resp_list]
            new_solutions = [dict1['explained_solution'] for dict1 in resp_list]

            sim_obj = SimNumericProblem(
                stud_clss = data['class'],
                subj = data['subj'].strip(),
                chap = data['chap'].strip(), 
            )

            sim_obj.add(
                new_questions = new_problems,
                new_soltutions = new_solutions
            )
            
            ##removing temparoryly stored files 
            os.remove(path = path)

            return jsonify({"status" : "success"}) ,200
        
        return jsonify({"error" : "file type not supported"}) ,400
        
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/my_score' ,methods = ["POST"] )
def student_score():
    try:
        session = Session()

        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        data = request.get_json()
        
        ##trying to fetch prexisting student_score 
        score_obj = session.query(StudentScore).filter(
            StudentScore.student_class == data["class"] ,
            StudentScore.roll_num == data["roll_num"] ,
            StudentScore.state == data["state"] 
        ).first()
        
        ##score obj for the student exist
        if score_obj != None:
            src = score_obj.score
            session.close()
            return jsonify({"score" : src })
        
        ##if object donot exist means creating anew student-score object 
        score_obj = StudentScore(
            student_class = data["class"],
            roll_num = data["roll_num"],
            state = data["state"],
            score = 0
        )
        
        session.add(score_obj)
        session.commit()
        session.close()

        return jsonify({"score" : 0}),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/update_score' ,methods = ["POST"] )
def student_update_score():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()
        
        session = Session() 
        score_obj = session.query(StudentScore).filter(
            StudentScore.student_class == data["class"] ,
            StudentScore.roll_num == data["roll_num"] ,
            StudentScore.state == data["state"] 
        ).first()
        
        if score_obj is None:
            session.close()
            return jsonify({"status" : "student data not avilable"}),400
        
        score_obj.score += data['score']
        session.commit()
        session.close() 

        return jsonify({"status" : 'success' }),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400
   
@app.route('/student/list_assignment' ,methods = ["POST"] )
def student_list_assignment():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        data = request.get_json()
        
        response = assigment_handler.student_list_assigments( 
            student_class = int(data["class"]) ,
            roll_num = data["roll_num"]
        )
        
        if data['lng'] == 'en':
            return jsonify(response) ,200 
        
        ##converting the response to native language
        data = request.get_json()
        for k1 in response.keys():
            for dict1 in response[k1]:
                dict1['subject'] =  translate_text(target = data['lng'] ,text = dict1['subject'] )
                dict1['chapter'] =  translate_text(target = data['lng'] ,text = dict1['chapter'] )
                
        return jsonify(response) ,200    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/attend_assignment' ,methods = ["POST"] )
def student_attend_assignment():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        data = request.get_json()
        print("hello bro" ,data)
        
        response = assigment_handler.attend_assignment(
            state = data["state"], 
            schedule_id = data["id"],
            lang = data["lang"]
        )

        return jsonify(response),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/complet_assignment' ,methods = ["POST"] )
def student_complet_assignment():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()
        
        feed_back_dict = assigment_handler.complete_assignment(
            state = data["state"] , 
            roll_num = data["roll_num"] ,
            schedule_id = data["id"],
            subtopic_eval = data["subtopic_eval"],
            name = data['name'],
            lang = data['lang']
        )
        
        print("hi there : " ,feed_back_dict)
        return jsonify(feed_back_dict),200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/availabilty' ,methods = ["POST"] )
def student_availabilty():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()

        session = Session()
        t1 = time.time()
        objs = session.query(Question).filter(Question.student_class ==  data['class'])
        t2 = time.time()

        respons = {}
        for obj in objs:
            
            if obj.subject not in respons:
                respons[obj.subject] = []
            
            if obj.chapter not in respons[obj.subject]:
                respons[obj.subject].append(
                    obj.chapter
                )
        session.close()
        print("Time taken for mysqldb : " ,t2-t1)
        return jsonify(respons) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/extract_q' ,methods = ["POST"] )
def student_extract_q():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        temp_img_file = save_temp_img()

        resp = img_quest_ext.extract(
            path = temp_img_file
        )
        os.remove(temp_img_file)
        return jsonify( {"questions" : resp} ) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/book_question' ,methods = ["POST"] )
def student_book_question():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()

        subtpc_exp = SubtpcExplGen(
            stud_clss = data['class'],
            state = data['state'],
            subj = data['subj'].strip(),
            chap = data['chap'].strip()
        )

        subtopic_exp_resp ,q_type = subtpc_exp.create( 
            question = data['question'] 
        )

        sol_gen = SoltuionGenerator(
            stud_clss = data['class'],
            state = data['state'],
            subj = data['subj'].strip(),
            chap = data['chap'].strip(),
        )

        sol_resp = sol_gen.solution(
            question = data['question'] ,
            q_type = q_type
        )

        ##translating subtopic explanations response 
        sub_exp_var = copy.deepcopy(subtopic_exp_resp)
        if data['lng'] != 'en':
            translated_subtopic_exp_resp = {}
            
            for sub_nme  in subtopic_exp_resp.keys():    
                trans_nme = translate_text(target = data['lng'] ,text = sub_nme)
                translated_subtopic_exp_resp[trans_nme] = {}

                translated_subtopic_exp_resp[trans_nme]['explanation'] = translate_text(
                    target = data['lng'],
                    text = subtopic_exp_resp[sub_nme]['explanation']
                )

                translated_subtopic_exp_resp[trans_nme]['img'] = subtopic_exp_resp[sub_nme]['img']

            subtopic_exp_resp = translated_subtopic_exp_resp
        
        response = { 
            "subtopic" : subtopic_exp_resp,
            "solution" : translate_text(target = data['lng'] ,text = sol_resp['solution']),
            "explanation" : translate_text(target = data['lng'] ,text = sol_resp['explanation']),
            'q_type' : q_type
        }
        
        access = f"question_expl:{time.time()}_{random.randint(0, 99999)}_{random.randint(0, 99999)}"
        response['access'] =  access
        
        ##caching for explanation tracking 
        response_cache[access] = {}
        if q_type == "theory":
            
            ##if solution is very small explain the explanation provided 
            if len(sol_resp['solution'].split(" ")) <= 30:
                response_cache[access]['target'] = sol_resp['explanation']
                response_cache[access]['what_to_exp'] = "Help me understand the solution!" 
            
            ##else the solution it self 
            else:
                response_cache[access]['target'] = sol_resp['solution']
                response_cache[access]['what_to_exp'] = "I need help with how to answer that question."
        
        else:
            sub_exp = "\n\n".join([dict1['explanation'] for dict1 in sub_exp_var.values()])
            response_cache[access]['target'] = sub_exp
            response_cache[access]['what_to_exp'] = "Can you help me understand the topics related to that solution?"
        
        if data['lng'] != 'en' :
            ##translating what to explain
            response_cache[access]['what_to_exp'] = translate_text(
                target = data['lng'],
                text = response_cache[access]['what_to_exp']
            ) 

        return jsonify(response) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/student/what_to_expl' ,methods = ["POST"] )
def student_what_to_expl():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()
        if data['access'] in response_cache:
            return jsonify({"what_to_exp" :response_cache[data['access']]['what_to_exp']}) ,200
        
        return jsonify({"error" :"session not available"}) ,402
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400 

@app.route('/student/expl' ,methods = ["POST"] )
def student_explanation_submit():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        data = request.get_json()
        if data['timeout'] and data['access'] in exp_trck_obj.cache:
            del exp_trck_obj.cache[data['access']]
            del response_cache[data['access']]
            return jsonify({'status' : 'sucess'}) ,200

        if not exp_trck_obj.is_exist(data['access']):
            
            if data['access'] in response_cache:
                exp_trck_obj.start(
                    access = data['access'],
                    target_txt = response_cache[data['access']]['target']
                )
            
            else:
                return jsonify({"error" : "session_not_avil"}) ,402

        if data['lng'] != 'en':
            data['expl'] = translate_text(
                target = 'en' ,
                text = data['expl']
            )
        
        scr ,is_win ,pnts = exp_trck_obj.track(
            access = data['access'],
            expl = data['expl'],
            lng = data['lng'],
            duration = data['duration'],
            roll_num = data['roll_num'],
            state = data['state'],
            stud_clss = data['class']
        )

        if is_win :
            del exp_trck_obj.cache[data['access']]
            del response_cache[data['access']] 

        return jsonify({'score' : int(scr) ,"is_win" : is_win ,"new_points" : pnts}) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400 

@app.route('/student/doubt' ,methods = ["POST"] )
def student_doubt():
    try:
        if not authoris(role = STUDENT):
            return jsonify({"status" : "access_denied"}),400
        
        print(1)
        data = json.loads( request.form.get('data') )
        print(2)

        if data['lng'] != 'en':
            data['question'] = translate_text(
                target = 'en',
                text = data['question']
            )
        
        print(data)

        obj = DoubtSolver(
            state =  data['state'],
            clss = data['clss'],
            subj = data['subj'].strip(),
            chap = data['chap'].strip(),
            school_id = None  
        )
        
        ##adding the if image exist
        temp_img_file = None 
        if data['is_img']:
            temp_img_file = save_temp_img()
            obj.add_image(
                link = temp_img_file
            )
        

        ###doubt resolution
        resp = obj.resolve(question = data['question'])
        access = f"doubt_expl:{time.time()}_{random.randint(0, 9999)}_{random.randint(0, 99999)}"
        resp['access'] = access

        
        ##caching for explanation tracking 
        response_cache[access] = {}
        response_cache[access]['target'] = resp['doubt_resolution']
        response_cache[access]['what_to_exp'] = "I have the same doubt. Please help me."

        ##translating what to explain
        if data['lng'] != 'en' :
            response_cache[access]['what_to_exp'] = translate_text(
                target = data['lng'],
                text = response_cache[access]['what_to_exp']
            ) 

        ###deleting temp saved image 
        if temp_img_file != None:
            os.remove(temp_img_file)
        
        
        ###translating the response 
        if data['lng'] != 'en':
            mcq_list = resp['mcqs']
            
            for i in range(len(mcq_list)):
                mcq_list[i]['question'] = translate_text(target = data['lng'] ,text = mcq_list[i]['question'])
                
                option_dict = dict.fromkeys(mcq_list[i]['options'])
                for opt in option_dict.keys():
                    option_dict[opt] = translate_text(target = data['lng'] ,text = opt)
                
                mcq_list[i]['options'] = list(option_dict.values())
                mcq_list[i]['correct_option'] = option_dict[mcq_list[i]['correct_option']]
            
            resp['mcqs'] = mcq_list
            resp['doubt_resolution'] = translate_text(target = data['lng'] ,text = resp['doubt_resolution'])
       
        print(resp)

        return jsonify(resp) ,200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400

def save_temp_img():
    img = request.files['image']
    file_name = f"{random.randint(0, 9999)}_{random.randint(0, 9999)}_{random.randint(0, 99999)}.jpg"
    img_path = os.path.join(TEMP_IMG_UPLOAD_FOLDER ,file_name)
    print(img_path)

    ##deacreasing the size and saving 
    image = Image.open(img)
    image = image.resize((1024, 1024))
    image.save(img_path, quality=85, optimize=True)
    
    ##
    return img_path

def authoris(role ,is_any = False):
    ##clearing the timed out cache in mcq_cahe system
    mcq_gen_cache.remove_timout_data()
    
    ##authoraisation token 
    auth_header = request.headers.get('Authorization', None)
    
    if not auth_header:
        return False
    try:
        # The token should be in the format: "Bearer <token>"
        token = auth_header.split(" ")[1]
        decoded = jwt.decode(token, os.getenv("ENCRYPT_KEY"), algorithms=[os.getenv("ENCRYPT_ALGO")])
        if is_any :
            return True
        if decoded["role"] == role or decoded["role"] == "all" :
            return True
        else :
            return False
        
    except Exception as e:
        print("error",2)
        return False

def translate_text(target: str, text: str) -> dict:
    if isinstance(text, bytes):
        text = text.decode("utf-8")
    result = translate_client.translate(text, target_language=target)
    return result["translatedText"]


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)