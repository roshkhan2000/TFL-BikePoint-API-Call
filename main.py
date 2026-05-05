# import libs
import requests as r
import json 
import datetime as dt
import os
import time
import logging

# create a logging config, directory, and timestamp
log_dir = f"{os.getcwd()}/logs"
os.makedirs(log_dir, exist_ok=True)
timestamp = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
log_filename = f"{log_dir}/{timestamp}.log"

logging.basicConfig(
    filename=log_filename,
    format="%(asctime)s - %(levelname)s - %(message)s",
    level=logging.INFO
)

logger = logging.getLogger()
logger.info('Logger Initialised')

# create folder to save files to 
folder = os.path.join(os.getcwd(), "JSON_Files")

# set url for API and make the call
# store the status of the API call
url = f"https://api.tfl.gov.uk/BikePoint/"
response = r.get(url)
response_code = response.status_code

# create vars for API call retry (if it fails)
count = 0 
max_tries = 3

while count < max_tries:
    # if response is within the 200s then do the following
    if 200 <= response_code < 300:

        # convert API respoinse to JSON
        data = response.json()
        # create a folder (if it doesn't exist already) and file to save 
        os.makedirs(folder, exist_ok=True)
        file_name = f"{timestamp}.json"
        
        # open the file and dump the data to it
        with open(os.path.join(folder,file_name), "w") as file:
            json.dump(data, file)
        logger.info(f"{file_name} was successfully created!")
        break

    # if respionse code is in the 500s then retry the API call
    elif response_code >= 500:
        time.sleep(10)
        logger.info(f"Response {response_code}: Trying again.. Attempt {count}")
        count += 1

    # if response code is not in the 200s, then print an error message
    else:
        logger.error(f"Error creating files: {response_code}")
        break