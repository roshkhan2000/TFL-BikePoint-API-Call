# import libs
import requests as r
import json 
import datetime as dt
import os
import time

# get current time, directory, and folder to save files to 
time = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
folder = os.path.join(os.getcwd(), "BikePoints_JSON_Files")

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
        file_name = f"{time}.json"
        
        # open the file and dump the data to it
        with open(os.path.join(folder,file_name), "w") as file:
            json.dump(data, file)
        print(f"File {file_name} was successfully created!")
        break

    # if respionse code is in the 500s then retry the API call
    elif response_code >= 500:
        time.sleep(10)
        print(f"Response {response_code}: Trying again.. Attempt {count}")
        count += 1

    # if response code is not in the 200s, then print an error message
    else:
        print(f"Error creating files: {response_code}")
        break