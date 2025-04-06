from sqlalchemy import create_engine
from dotenv import load_dotenv
import os  

load_dotenv(override = True) ##loading the env files 

##creating the db engine with restructed connections //set connection timeout very high
Engine = create_engine( 
    url = os.getenv("DATA_BASE_URL") ,
    pool_size =  int(os.getenv("DB_CONNECT_COUNT")),
    max_overflow = 10,
    pool_timeout = int(os.getenv("DB_TIMEOUT")),
    pool_recycle = 1800  
)
