import logging
import os
import requests as r
import datetime as dt
import json
import time

logger = logging.getLogger(__name__)

def extract(url, max_tries, dir):
    """
    This will call an api. If there's a server side issue it will rety for the specified number of times.
    The data will be saved in the specifed directory.

    Args:
        url (string): URL to call
        max_tries (integer: numnber of times to retry if there's a server side error
        dir (string): directory to save data to
    """    
    timestamp = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    response = r.get(url)
    response_code = response.status_code
    count = 0 

    while count < max_tries:
        if 200 <= response_code < 300:

            data = response.json()
            os.makedirs(dir, exist_ok=True)
            file_name = f"{timestamp}.json"
        
            with open(os.path.join(dir,file_name), "w") as file:
                json.dump(data, file)
            logger.info(f"File {file_name} was successfully created")
            return True
            break

        elif response_code >= 500:
            time.sleep(10)
            logger.info(f"Response {response_code}: Trying again.. Attempt {count}")
            count += 1

        else:
            logger.error(f"Error creating files: {response_code}")
            break