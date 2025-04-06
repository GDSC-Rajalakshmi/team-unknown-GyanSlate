from question_bank import Question ,Options 
from assessment_db import AssesmentSchedule ,AssesmentSubtopic ,StudentAssignment ,StudentAnalysis 
from sqlalchemy.orm import sessionmaker
from feed_back_generator import FeedBackGenerator
from user_engagement_db import StudentScore 
from datetime import datetime
from db_engine import Engine
import random
import pytz

##creating a session object with question bank db  
Session = sessionmaker(bind = Engine)

##indian-standard-time
ist = pytz.timezone('Asia/Kolkata')

class AssignmentHandler : 

    def __init__(self):
        session = Session()
        self.feed_back_obj = FeedBackGenerator()
        session.close()
        
    def fetch_availablity(self):
        session = Session()
        
        results = session.query( 
            Question.student_class ,Question.subject , Question.chapter, Question.suptopic
        ).filter(
            Question.state == "common" ,# Replace '10' with your desired class
        ).distinct().all()

        response = { }
        
        for obj in results : 
            ##if class is not available adding it 
            if obj.student_class not in response:
                response[obj.student_class] = {}
            
            ##if subject is not available under the class adding it  
            if obj.subject not in response[obj.student_class]:
                response[obj.student_class][obj.subject] = {}
            
            ##if chapter is not available under the subject adding it
            if obj.chapter not in response[obj.student_class][obj.subject]:
                response[obj.student_class][obj.subject][obj.chapter] = []

            ##if subtopic is not available under the chapter adding it
            if obj.suptopic not in response[obj.student_class][obj.subject][obj.chapter]:
                response[obj.student_class][obj.subject][obj.chapter].append( 
                    obj.suptopic
                )
        
        session.close()
        return response 
    
    def add_assignment(self ,student_class ,subject ,chapter ,subtopic_count ,start ,end):
        session = Session()
        
        ##creating a schedule object
        schedule_obj = AssesmentSchedule( 
            student_class = student_class ,
            subject = subject ,
            chapter = chapter ,
            start = start ,
            end = end ,
        )

        ##commiting this to the db first 
        session.add(schedule_obj)
        session.commit()
        
        ##creating subtopic object list 
        subtopic_obj_list= [ ]
        for subtpc ,cnt in subtopic_count.items():
            subtopic_obj_list.append( 
                AssesmentSubtopic(
                    subtopic = subtpc, 
                    schedule_id = schedule_obj.id, 
                    q_count = cnt
                )
            )
        
        ##commiting subtopic object list  to the db 
        session.add_all(subtopic_obj_list)
        session.commit()

        session.close()
    
    def teacher_list_assigments(self):
        session = Session()
        
        assignment_list = session.query(AssesmentSchedule).all()
        current_datetime = datetime.now(ist).replace(tzinfo=None)
        response= { 
                "active" : [ ] ,#not completed and can be completed now
                "upcomming" : [ ] ,#upcoming start > current
                "past" : [ ]  #(not completed and end < current) or completed
            }
        
        for obj in assignment_list :

            if obj.start > current_datetime :
                response["upcomming"].append(
                    {
                       "id" : obj.id ,
                       "subject" : obj.subject,
                       "chapter":obj.chapter ,
                       "start":obj.start ,
                       "end":obj.end,
                       "class":obj.student_class  
                    }
                )
            
            else:
                if obj.end < current_datetime :
                    response["past"].append(
                        {
                            "id" : obj.id ,
                            "subject" : obj.subject,
                            "chapter":obj.chapter ,
                            "start":obj.start ,
                            "end":obj.end,
                            "class":obj.student_class  
                        }
                    )
                
                else:
                    response["active"].append(
                        {
                            "id" : obj.id ,
                            "subject" : obj.subject,
                            "chapter":obj.chapter ,
                            "start":obj.start ,
                            "end":obj.end,
                            "class":obj.student_class  
                        }
                    )

        session.close()
        return response
    
    
    def assignment_analysis(self ,schedule_id):
        session = Session()
        
        prev_assess = session.query(StudentAssignment).filter( 
            StudentAssignment.schedule_id == schedule_id
        ).all()
        
        student_assignment_ids = [obj.id for obj in prev_assess] 

        prev_sub_scores = session.query(StudentAnalysis).filter(
            StudentAnalysis.student_assignment_id.in_(student_assignment_ids)
        )
        
        previous_assessments = []
        for assess_obj in prev_assess:
            dict1 = {}
            dict1["roll_num"] = assess_obj.roll_num
            dict1["name"] = assess_obj.name
            dict1["subtopic_score"] = {}
            for sub_obj in prev_sub_scores: 
                if sub_obj.student_assignment_id == assess_obj.id :
                    dict1["subtopic_score"][sub_obj.subtopic] = sub_obj.accuracy

            previous_assessments.append(
                dict1
            )

        session.close()
        return previous_assessments

    def student_list_assigments(self ,student_class ,roll_num):        
        assert isinstance(student_class ,int) ,"student_class must be a integer"
        session = Session()


        ##taking all the assignments corresponding to this class
        assignment_list = session.query(AssesmentSchedule).filter( 
            AssesmentSchedule.student_class == student_class).all()
        
        ##taking the id's of all the completed assignments  
        completed_assignment_list = session.query(StudentAssignment).filter(
            StudentAssignment.roll_num == roll_num,
        ).all()
        
        compl_sch_ids = []
        for obj in completed_assignment_list:
            compl_sch_ids.append(
                obj.schedule_id
            )

        ##
        current_datetime = datetime.now(ist).replace(tzinfo=None)

        response= { 
            "active" : [ ] ,#not completed and can be completed now
            "upcomming" : [ ] ,#upcoming start > current
            "past" : [ ]  #(not completed and end < current) or completed
        }
        
        for obj in assignment_list :

            if obj.start > current_datetime :
                response["upcomming"].append(
                    {
                       "id" : obj.id ,
                       "subject" : obj.subject,
                       "chapter":obj.chapter ,
                       "start":obj.start ,
                       "end":obj.end  
                    }
                )
            
            else:
                if obj.end < current_datetime or obj.id in compl_sch_ids:
                    response["past"].append(
                        {
                            "id" : obj.id ,
                            "subject" : obj.subject,
                            "chapter":obj.chapter ,
                            "start":obj.start ,
                            "end":obj.end  
                        }
                    )
                
                else:
                    response["active"].append(
                        {
                            "id" : obj.id ,
                            "subject" : obj.subject,
                            "chapter":obj.chapter ,
                            "start":obj.start ,
                            "end":obj.end  
                        }
                    )
        
        session.close()
        return response
     
    def attend_assignment(self ,lang ,state ,schedule_id ):
        session = Session()
        ##fetching schedule data  
        schedule_obj = session.query(AssesmentSchedule).filter(
            AssesmentSchedule.id ==  schedule_id
        ).first()
        
        subtopic_obj = session.query(AssesmentSubtopic).filter(
            AssesmentSubtopic.schedule_id == schedule_id 
        ).all()

        subtopic_list = [obj.subtopic for obj in subtopic_obj]
        
        ##giving the regional transform made for this state in english
        if lang == "English" :  
            mcqs = session.query(Question).filter( 
                Question.student_class == schedule_obj.student_class ,
                Question.subject == schedule_obj.subject ,
                Question.chapter == schedule_obj.chapter ,
                Question.state == state,
                Question.suptopic.in_(subtopic_list)
            ).all()
        ##else fetching the mcqs in their required language 
        else : 
            mcqs = session.query(Question).filter( 
                Question.student_class == schedule_obj.student_class ,
                Question.subject == schedule_obj.subject ,
                Question.chapter == schedule_obj.chapter ,
                Question.state == lang ,
                Question.suptopic.in_(subtopic_list)
            ).all()

        ##if mcqs is not available in either of the form fetching the common
        if len(mcqs) == 0 :
            mcqs = session.query(Question).filter( 
            Question.student_class == schedule_obj.student_class ,
            Question.subject == schedule_obj.subject ,
            Question.chapter == schedule_obj.chapter ,
            Question.state == "common",
            Question.suptopic.in_(subtopic_list)
        ).all()
        
        ##shuffling to make the mcq's unique  
        random.shuffle(mcqs)
        
        ##selecting the questions 
        selected_q = [ ]
        for obj in subtopic_obj:   
            subtopic_q = []
            i = 0 
            
            while( i < len(mcqs) and len(subtopic_q) < obj.q_count):
                if mcqs[i].suptopic == obj.subtopic :
                    subtopic_q.append(
                        mcqs[i]
                    ) 
                i = i + 1
        
            selected_q = selected_q + subtopic_q
        
        question_ids = [mcq.id for mcq in selected_q]
        options = session.query(Options).filter( 
            Options.question_id.in_(question_ids)
        ).all()
                
        response = [ ]

        for mcq in selected_q:
            
            subtopic = mcq.suptopic

            mcq_dict = { 
                "question" : mcq.question , 
                "options" : [ ] ,
                "correct_option" : mcq.correct_option ,
                "why" : mcq.explanation ,
                "subtopic" : subtopic,
                "id" : mcq.id 
            } 

            for opt in options:
                if opt.question_id == mcq.id : 
                    mcq_dict["options"].append(
                        opt.statement
                    )

            response.append(mcq_dict)
        
        session.close()
        return response
    
    def complete_assignment(self ,state ,lang ,roll_num ,name ,schedule_id ,subtopic_eval):
        session = Session()
        
        schedule_obj = session.query(AssesmentSchedule).filter(
            AssesmentSchedule.id ==  schedule_id
        ).first()

        ##current assessment
        current_assessment = { 
            "subject" : schedule_obj.subject ,
            "chapter" : schedule_obj.chapter , 
            "subtopic" : subtopic_eval ,
        }

        ##retreving previous performance in this subject  
        prev_assess = session.query(StudentAssignment).filter( 
            StudentAssignment.roll_num == roll_num , 
            StudentAssignment.subject == schedule_obj.subject,
        ).all()
        
        student_assignment_ids = [obj.id for obj in prev_assess] 

        prev_sub_scores = session.query(StudentAnalysis).filter(
            StudentAnalysis.student_assignment_id.in_(student_assignment_ids)
        )
        
        previous_assessments = []
        previous_assessment_avgscore = [ ] ##average assessments is average of acores in all subtopics 

        for assess_obj in prev_assess:

            avg_scores = [ ]
            
            dict1 = { }
            dict1["subject"] = assess_obj.subject
            dict1["chapter"] = assess_obj.chapter 
            dict1["subtopic_score"] = {}
            dict1["feed_back"] = assess_obj.feed_back
            
            for sub_obj in prev_sub_scores: 
                if sub_obj.student_assignment_id == assess_obj.id :
                    dict1["subtopic_score"][sub_obj.subtopic] = sub_obj.accuracy
                    avg_scores.append(sub_obj.accuracy)

            previous_assessments.append(dict1)
            previous_assessment_avgscore.append(
                float(sum(avg_scores)/len(avg_scores) )
            )
        
        avg_scores = []
        for scr in current_assessment["subtopic"].values():
            avg_scores.append(scr)
        current_assessment_avgscore = sum(avg_scores)/len(avg_scores)

        ##computing percentage of time remaining for assessment to get completed   
        percentage_time_rem = (schedule_obj.end - datetime.now(ist).replace(tzinfo=None)) / (schedule_obj.end - schedule_obj.start) * 10
        
        ##computing number of scores to be added
        scr = self.__compute_engament_score(
            curr_avgscr = current_assessment_avgscore,
            percentage_time_rem = percentage_time_rem ,
            prev_avgscr_list = previous_assessment_avgscore,
            state = state , 
            student_class = schedule_obj.student_class ,
            roll_num = roll_num
        )
        
        if len(previous_assessments) == 0:
            previous_assessments = "This is the first assessment under this subject"

        ##generating feed back 
        feed_back_dict = self.feed_back_obj.generate(
            age = 9 + (int(schedule_obj.student_class) - 4) ,
            state = state , 
            current_assessment = current_assessment ,
            previous_assessment = previous_assessments,
            lang = lang
        )

        ##stroing the data in the db 
        feed_back = "\n".join( feed_back_dict.values() )

        stud_assess_obj = StudentAssignment(
            roll_num = roll_num ,
            name = name,
            state = state,
            schedule_id = schedule_id,
            subject = schedule_obj.subject,
            chapter = schedule_obj.chapter,
            feed_back = feed_back
        )

        session.add(stud_assess_obj)
        session.commit()

        subtopic_obj_list = []
        for sub ,acc in subtopic_eval.items():
            subtopic_obj_list.append(
                StudentAnalysis(
                    student_assignment_id = stud_assess_obj.id,
                    subtopic = sub,
                    accuracy = acc
                )
            )
        
        session.add_all(subtopic_obj_list)
        session.commit()

        feed_back_dict[ "score" ] = scr 
        print("feed_back_dict[ score ] : " ,feed_back_dict[ "score" ])

        session.close()
        return feed_back_dict
    
    def __compute_engament_score(self ,curr_avgscr ,prev_avgscr_list ,percentage_time_rem ,state ,student_class, roll_num ,k = 5):
        session = Session()
        
        if len(prev_avgscr_list[-k :]) > 0 :
            scr = max(0 ,10 * ( curr_avgscr - sum(prev_avgscr_list[-k :])/len(prev_avgscr_list[-k :]) ))
        else:
            scr = 0 
        
        scr = scr + 10 * curr_avgscr
        scr = scr + 2 * percentage_time_rem
        scr = int(scr)
        
        obj = session.query(StudentScore).filter(
            StudentScore.student_class == student_class,
            StudentScore.roll_num == roll_num,
            StudentScore.state == state
        ).first()
        
        if obj == None :
            obj = StudentScore(
                roll_num = roll_num ,
                state = state,
                student_class = student_class ,
                score = scr
            )
            session.add(obj)
            session.commit()
        else:
            obj.score = obj.score + scr
            session.commit()
        
        print("score : ",scr)

        session.close()
        return scr