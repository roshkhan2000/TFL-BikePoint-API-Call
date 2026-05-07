from modules.setup_logging import setup_logging
from modules.extract_module import extract
from modules.load_module import load
from dotenv import load_dotenv
import os

logger = setup_logging('logs')
logger.info('Logger Initialised')


load_dotenv()
aws_key = os.getenv("AWS_ACCESS_KEY")
aws_secret = os.getenv("AWS_SECRET_KEY")
bucket= os.getenv("bucket")

url = f"https://api.tfl.gov.uk/BikePoint/"

if extract(url, 3, 'JSON_Files'):
    logger.info('Extract ran successfully')
    dir_to_upload = f"{os.getcwd()}/JSON_Files"
    load(aws_key, aws_secret, bucket, dir_to_upload)
    logger.info('Extract and Load ran successfully')
else:
    logger.error("Extract failed so load did not run")