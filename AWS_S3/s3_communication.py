from fastapi import FastAPI, HTTPException, Request
from models import PanoImage, Panorama, serialize_panorama
from typing import Union
import base64
import boto3
import json
import os

# Initialize s3 client
s3_client = boto3.client('s3')

# Define bucket name
bucket_name = 'chrononauts'

# Initialize Fast Api
app = FastAPI()

def initial_dataload(location_name):
    panorama_json, pano_images = serialize_panorama(location_name)

    folder = f'panorama/{location_name}'
    obj_key = f'{folder}/{location_name}.json'

    for pano_image in pano_images:
        image_name = pano_image.name
        image_path = f'/Users/pav13928/Desktop/Hackathon/Chrononauts/Chrononauts/Assets.xcassets/{image_name}.imageset'
        if not os.path.isdir(image_path):
            print(f'Error in {image_path}')
            return
        
    s3_client.put_object(Bucket=bucket_name, Key=obj_key, Body=panorama_json)

    for pano_image in pano_images:
        image_name = pano_image.name
        folder_key = f'{folder}/{image_name}.imageset'
        image_path = f'/Users/pav13928/Desktop/Hackathon/Chrononauts/Chrononauts/Assets.xcassets/{image_name}.imageset'

        for root, _, files in os.walk(image_path):
            for file in files:
                file_path = os.path.join(root, file)
                # Construct S3 key maintaining the directory structure
                relative_path = os.path.relpath(file_path, image_path)
                s3_key = f'{folder_key}/{relative_path}'
                
                with open(file_path, 'rb') as image_file:
                   s3_client.upload_fileobj(image_file, bucket_name, s3_key)

def get_data_from_s3(key: str) -> Union[dict, bytes]:
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=key)
        _, ext = os.path.splitext(key)
        
        if ext == '.json':
            content = response['Body'].read().decode('utf-8')
            return json.loads(content)
        elif ext in ['.jpg', '.jpeg', '.png']:
            return response['Body'].read()
        else:
            raise HTTPException(status_code=400, detail="Unsupported file type")
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Error retrieving {key}: {str(e)}")
    
def list_objects_in_folder(folder_key):
    response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=folder_key)
    return [obj['Key'] for obj in response.get('Contents', [])]


@app.get("/initial_pano_json")
def read_combined_data():
    # Define the keys for the JSON files in S3
    esri_key = 'panorama/esri/esri.json'
    truist_park_key = 'panorama/park/park.json'

    # Retrieve JSON data from S3
    esri_data = get_data_from_s3(esri_key)
    truist_park_data = get_data_from_s3(truist_park_key)

    # Combine data
    combined_data = [esri_data, truist_park_data]
    return combined_data


@app.get("/panoimage_data/{location_data}")
def read_combined_data(location_data: str):
    esri_base_folder_key = f'panorama/{location_data}/'

    # List objects in the base folder
    all_object_keys = list_objects_in_folder(esri_base_folder_key)

    unique_folders = set(os.path.dirname(key) for key in all_object_keys if key.startswith(f'panorama/{location_data}/'))

    file_contents = {}
    for folder_key in unique_folders:
        if 'imageset' not in folder_key:
            continue
        object_keys = list_objects_in_folder(f'{folder_key}/')
        file_list = []
        for key in object_keys:
            file_content = get_data_from_s3(key)
            _, ext = os.path.splitext(key)
            if ext == '.json':
                file_list.append({os.path.basename(key): file_content})
            elif ext in ['.jpg', '.jpeg', '.png']:
                file_list.append({os.path.basename(key): base64.b64encode(file_content).decode('utf-8')})
        file_contents[os.path.basename(folder_key)] = file_list

    return file_contents

@app.post("/memory_post")
async def save_user_photo(request: Request):
    print("hello")
    try:
        user_photo = await request.json()
        file_path = f"/Users/pav13928/Desktop/{user_photo['id']}.json"

        with open(file_path, "w") as f:
            json.dump(user_photo, f, indent=4)
        
        print("HIT!!!!!!!!")

        return {"message": "UserPhoto saved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/memory_get/{id}")
async def get_user_memory(id: str):
    print("GEt hitttttttt")
    file_path = f"/Users/pav13928/Desktop/{id}.json"
    with open(file_path, "r") as f:
        response = json.load(f, indent=4)
    return response


# uvicorn s3_communication:app --host 0.0.0.0 --port 8000
# http://192.168.1.199:8000/initial_pano_json
# http://192.168.1.199:8000/panoimage_data/esri
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
    uvicorn.run(app, host="0.0.0.0", port=8000, ssl_keyfile="ssl_key.pem", ssl_certfile="ssl_cert.pem")


# ######################################

# def main():
#     # One time thing to upload to S3
#     initial_dataload("esri")
#     initial_dataload("park")

# if __name__ == "__main__":
#     main()