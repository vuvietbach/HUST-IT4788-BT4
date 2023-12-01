from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pymongo import MongoClient
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from Crypto.Random import get_random_bytes
from fastapi.encoders import jsonable_encoder

import base64
app = FastAPI()

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["mydatabase"]
collection = db["user"]

def decrypt(data):
    # key  = base64.b64decode(data['key'])
    # iv = key[-16:]
    # key = key[:-16]
    print(data.keys())
    key = base64.b64decode(data['key'])
    iv = base64.b64decode(data['iv'])
    print(len(key), len(iv))
    ciphertext = base64.b64decode(data['data'])
    cipher = AES.new(key, AES.MODE_CBC, iv)
    decrypted_plaintext = unpad(cipher.decrypt(ciphertext), AES.block_size)
    data = decrypted_plaintext.decode('utf-8')
    
    data = list(data.split('%'))
    data = {
        "username": data[0],
        "password": data[1],
        'deviceId': data[2],
        'appId': data[3],
        'version': data[4],
        'timestamp': data[5]
    }
    print(data)
    return data


@app.post("/login")
async def save_user(data: dict):
    data = decrypt(data)
    res = dict(data)
    collection.insert_one(data)
    return JSONResponse(status_code=200, content=res)


@app.get("/")
async def root():
    return {"message": "Hello World"}