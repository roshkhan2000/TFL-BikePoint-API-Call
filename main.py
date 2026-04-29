# import libraries and modules
import requests as r
import json 
import datetime as dt

# allow user to input a Bikepoints ID number
insert_id = input("Insert Bikepoints ID (in number)")

# set variables for api call and make that call using get
id = f"Bikepoints_{insert_id}"
url = f"https://api.tfl.gov.uk/BikePoint/{id}"
response = r.get(url)

#set the ime to be now and create file namne using time
time = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
file_name = f"{id}_{time}.json"

# convert response to json
data = response.json()

# error handling
if (response.status_code) == 200:
    # convert response to json
    data = response.json()
    # create a json file in my folder
    # the w specifies that if a file does not exist, then create it, otherwise just open it
    # then dump the data resposne in to that file
    with open(file_name, "w") as file:
        json.dump(data, file)
    print(f"File {file_name} was successfully created!")
# otherwise throw the below error
else:
    error_message = data.get("message", "no message given")
    print(f"Error creating {file_name}: {response.status_code} {error_message}")