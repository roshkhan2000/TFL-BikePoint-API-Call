# import libs
from dotenv import load_dotenv
import os
import boto3
import logging
import pandas as pd
import datetime as dt

# create a logging config, directory, and timestamp
log_dir = f"{os.getcwd()}/logs"
os.makedirs(log_dir, exist_ok=True)
timestamp = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
log_filename = f"{log_dir}/load_{timestamp}.log"

logging.basicConfig(
    filename=log_filename,
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO
)

# create a logger
logger = logging.getLogger()
logger.info('Logger Initialised')

# import keys
load_dotenv()
aws_key = os.getenv("AWS_ACCESS_KEY")
aws_secret = os.getenv("AWS_SECRET_KEY")
bucket= os.getenv("bucket")

# define the s3 client
s3_client = boto3.client(
    "s3",
    aws_access_key_id=aws_key,
    aws_secret_access_key=aws_secret
)

# define directory and files to upload
dir_to_upload = f"{os.getcwd()}/JSON_Files"
files_to_upload = os.listdir(dir_to_upload)

files_processed = 0

for file in files_to_upload:
    if file.endswith("json"):

        # join the folder path with the filename
        full_path = os.path.join(dir_to_upload, file)
        
        try:
            # upload using the full path
            s3_client.upload_file(full_path, bucket, file)
            logger.info(f"{file} uploaded to S3")
            
            # delete using the full path
            os.remove(full_path)
            logger.info(f"{file} deleted locally")
            files_processed += 1
        
        # if above fails then give error
        except Exception as e:
            logger.error(f"Failed to process {file}: {e}")

logger.info(f'Processed {files_processed} files')