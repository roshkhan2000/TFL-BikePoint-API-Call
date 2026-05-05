# import libs
import requests as r
import json 
import datetime as dt
import os

# get current time, directory, and folder to save files to 
time = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
folder = os.path.join(os.getcwd(), "BikePoints_JSON_Files")

# set url for API and make the call
# store the status of the API call
url = f"https://api.tfl.gov.uk/BikePoint/"
response = r.get(url)
response_code = response.status_code

# if response starts with 2 then do the following
if response_code == 200:

    # convert API respoinse to JSON
    data = response.json()
    # create a folder and file to save if it doesn't exist already
    os.makedirs(folder, exist_ok=True)
    file_name = f"{time}.json"
    
    # open the file and dump the data in to it
    with open(os.path.join(folder,file_name), "w") as file:
        json.dump(data, file)
    print(f"File {file_name} was successfully created!")

# if response does not start with 2 then give an error
else:
    print(f"Error creating files: {response.status_code}")