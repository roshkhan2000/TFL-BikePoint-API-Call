# import libs
from dotenv import load_dotenv
import os
import boto3

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
# define the file to save
# define what to call the file when it saves on s3
data = "JSON_Files/2026-05-05_10-33-42.json"
filename= "2026-05-05_10-33-42.json"

# upload file to s3 bucket
s3_client.upload_file(data, bucket, filename)
print("done")