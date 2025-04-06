from explanation_track import ExplanTrack


et = ExplanTrack()

access_key = "student_001"

"""
Test1-Test2 :-
target = "Photosynthesis is the process by which green plants make their own food using sunlight, carbon dioxide from the air, and water from the soil. This process takes place in the leaves using a green pigment called chlorophyll. Oxygen is released as a by-product."

Test3-Test4 :-
target = "The water cycle is the continuous movement of water on, above, and below the surface of the Earth. It includes processes like evaporation, condensation, precipitation, and collection. The Sun provides energy for the water to evaporate and rise into the atmosphere."
"""

prmpt = """Instruction:
You are given an explanation list that contains multiple pieces of explanation provided by a student about a particular topic. Your task is to combine all the smaller pieces into a single coherent paragraph that clearly conveys what the student is trying to explain.

The topic which the student is trying to explain is given as Target below.

Important Guidelines:
Only include the information present in the explanation list.

Do not add any new information or assumptions.

Do not remove any detail from the original explanations.

The output should be a single, well-structured paragraph.

Then, identify all the key ideas the student talks about regarding the given target.

Target:
"The water cycle is the continuous movement of water on, above, and below the surface of the Earth. It includes processes like evaporation, condensation, precipitation, and collection. The Sun provides energy for the water to evaporate and rise into the atmosphere."

Target : {target_expl}

Explanation List : {expl_list}

Output Format: 
{{
  "over_all_explanation": "<combined paragraph here>",
  "explanation_about_target": "<list of key things student mentions about the water cycle>"
}}"""



target = "The water cycle is the continuous movement of water on, above, and below the surface of the Earth. It includes processes like evaporation, condensation, precipitation, and collection. The Sun provides energy for the water to evaporate and rise into the atmosphere."

et.start(access_key, target)

# Simulate each explanation with language ('en' or 'ta'), explanation text, duration (in seconds), and dummy student identifiers

test1 = [
    ("en" ,"Plant take water from soil and also carbon dioxide coming from air.", 10),
    ("en" ,"Sunlight using to make food by plant.", 5),
    ("en" ,"This all happening in leaf with green colour thing called chlorophyll.",10),
    ("en" ,"During this, oxygen coming out from plant." ,5),
]
###test1 worked properly

test2 = [
    ("en", "Plant take water from soil and also carbon dioxide coming from air.", 10),
    ("en", "Sunlight using to make food by plant.", 5),
    ("en", "I saw big green plant near my school yesterday.", 4),  # ❌ Off-topic
    ("en", "This all happening in leaf with green colour thing called chlorophyll.", 10),
    ("en", "My friend told me plant also drink milk, but I don’t think so.", 6),  # ❌ Off-topic
    ("en", "During this, oxygen coming out from plant.", 5),
]
###test2 did not work properly once the out of topic statement is added ,score did not increase after

test3 = [
    ("en", "Water going up in air when sun make it hot.", 8),
    ("en", "Then it become cloud and later fall down like rain.", 6),
    ("en", "One time, our clothes also dry very fast in summer.", 5),  # ❌ Off-topic
    ("en", "This thing happening again and again, like cycle.", 7),
    ("en", "After rain, water going back to river and ground.", 6),
    ("en", "My uncle told rain comes because gods are crying.", 4),  # ❌ Off-topic
]
###test3 did not work properly once the out of topic statement is added ,score did not increase after

test4 = [
    ("en", "Water going up in air when sun make it hot.", 8),
    ("en", "Then it become cloud and later fall down like rain.", 6),
    ("en", "This thing happening again and again, like cycle.", 7),
    ("en", "After rain, water going back to river and ground.", 6),
]
###test4 worked properly

test5 = [
    ("en", "After rain, water going back to river and ground.", 6),
    ("en", "Then it become cloud and later fall down like rain.", 6),
    ("en", "Water going up in air when sun make it hot.", 8),
    ("en", "This thing happening again and again, like cycle.", 7),
]
###test5 suggesr order in which the explanation provided ,will deeply affects the score 
##order of explanation provided should be same as order of target

test6 = [
    ("en", "Water going up in air when sun make it hot. My grandmother say not to go out at noon.", 8),
    ("en", "Then it become cloud and later fall down like rain. I like rain because we get school holiday sometimes.", 6),
    ("en", "This thing happening again and again, like cycle. My science teacher told it is very important for farming.", 7),
    ("en", "After rain, water going back to river and ground. One time, our street was full of water after big rain.", 6),
]
###if out of topic speech and in topic speech is mixed  

test7 = [
    ("en", "Water become gas when sun heat it.", 6),  # Mentions evaporation
    ("en", "It go up, and... something happen in sky.", 5),  # Vague; missing condensation
    ("en", "Then sometimes water coming down.", 5),  # Implied precipitation, but unclear
    ("en", "Rain water go somewhere, maybe ground.", 4),  # Vague collection
]
###this check whether out of topic 

test8 = [
    ("en", "Water become gas when sun heat it. That’s why we feel so hot in May month.", 6),  # Evaporation + off-topic
    ("en", "It go up, and... something happen in sky. I saw clouds like cotton last week.", 5),  # Vague condensation + side note
    ("en", "Then sometimes water coming down. My brother run in rain and got fever.", 5),  # Vague precipitation + personal story
    ("en", "Rain water go somewhere, maybe ground. Our field got full water after big rain.", 4),  # Vague collection + real-life reference
]
##what if negative example is mixed with out of topic  

for lng, expl, dur in test8:
    score, passed, bonus = et.track(
        access = access_key , 
        expl = expl, 
        lng = lng ,
        duration = dur, 
        stud_clss = 8, 
        roll_num= 1234, 
        state="TN"
    )
    print(f"Score: {score:.2f}, Passed: {passed}, Bonus: {bonus}")
