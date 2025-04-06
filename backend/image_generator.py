from vertexai.preview.vision_models import ImageGenerationModel
from PIL import ImageOps as PIL_ImageOps
from PIL import Image as PIL_Image
import vertexai
import typing
import io
from dotenv import load_dotenv
from google.cloud import storage
import os  
import time 
import random

load_dotenv(override = True)

vertexai.init(project = os.getenv("GOOGLE_CLOUD_PROJECT_ID"), location = os.getenv("GOOGLE_CLOUD_REGION"))

class ImageGenerator :
    storage_client = storage.Client()
    bucket = storage_client.bucket(os.getenv("BUCKET_NAME"))

    def __init__(self):
        self.model = ImageGenerationModel.from_pretrained(os.getenv("IMAGE_GENERATOR_ID"))
        self.num_images = 1
        self.aspect_ratio = "1:1" 
        self.negative_prompt = "text, words, letters, numbers, sentences, writing, signature, watermark, logo, labels, typography, blurry"
    
    def generate(self ,prompt ,common_id):
        images = self.model.generate_images(
            prompt=prompt ,number_of_images = self.num_images,
            aspect_ratio = self.aspect_ratio ,negative_prompt = self.negative_prompt,
            person_generation="" ,safety_filter_level="",
            add_watermark=True,
        ).images
        
        ##generating file path for each generated image 
        generated_img_dir = os.getenv("GENERATED_IMG_DIR")
        blob_name_list = [f"{generated_img_dir}/{common_id}_{random.randint(0,99999)}_{int(time.time())}_{i}.jpg" for i in range(len(images))]
       
        ##finding which generated image most suits the prompt  
        chss_indx = 0
        
        # Output list for image upload results
        output = [self.__store(image=images[i], blob_name=blob_name_list[i]) for i in range(len(images))]
       
        # return link for the choosen image 
        if chss_indx<len(blob_name_list) and output[chss_indx]:
            return blob_name_list[chss_indx]
        
        ##if choosen image is not uploaded return link for first uploaded image  
        for i in range(len(output)):
            if output[i]:
                return blob_name_list[i]

        return None  


    ##purpose is to save the image  
    def __store(self ,image ,blob_name ,max_width: int = 1024 ,max_height: int = 1024) -> bytes:
        pil_image = typing.cast(PIL_Image.Image, image._pil_image)
        
        if pil_image.mode != "RGB":
            pil_image = pil_image.convert("RGB")  # Ensure compatibility

        image_width, image_height = pil_image.size
        if max_width < image_width or max_height < image_height:
            pil_image = PIL_ImageOps.contain(pil_image, (max_width, max_height))

        # Convert to bytes
        img_byte_arr = io.BytesIO()
        pil_image.save(img_byte_arr, format="JPEG")
        img_byte_arr.seek(0)

        # Upload to Google Cloud Storage
        blob = self.bucket.blob(blob_name)
        blob.upload_from_file(img_byte_arr, content_type="image/jpeg")
        
        ##waiting untill image uploaded 
        cnt = 0
        while not blob.exists() and cnt < 20:
            time.sleep(0.10)  # Wait for 1 second
            cnt += 1
        
        if blob.exists : 
            return True
        
        return False
        

    
       
    
        
        
