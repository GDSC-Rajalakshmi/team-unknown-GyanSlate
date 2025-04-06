from dotenv import load_dotenv
import datetime
import jwt
import os

load_dotenv(override=True)  # Load the .env file

# Your secret key
SECRET_KEY = os.getenv("ENCRYPT_KEY")
EXP_DAYS = int(os.getenv("ENCRYPT_KEY_EXP", 1))  # Default to 1 day if not set

role_list = ["admin", "teacher", "student", "all"]

tokens = {}


for role in role_list:
    payload = {
        "role": role,
        "exp": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=EXP_DAYS)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=os.getenv("ENCRYPT_ALGO"))
    tokens[role] = token
    print(f"{role} token:\n{token}\n")

# Optional: use the `tokens` dictionary as needed