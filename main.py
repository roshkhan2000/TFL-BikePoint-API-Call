# import libraries and modules
import requests as r
import json 
import datetime as dt

# set variables for api call and make that call using get
url = f"https://api.tfl.gov.uk/BikePoint"
response = r.get(url)

# error handling
if (response.status_code) == 200:
    # if response is 200 then convert response to json
    data = response.json()
    # for each dictionary in the list, get current time
    # also, get the name of the BikePoint using record.get("id")
    for record in data:
        time = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        file_name = f"{record.get("id")}_{time}.json"
        # create a json file in my folder
        # the w specifies that if a file does not exist, then create it, otherwise just open it
        # then dump the data resposne in to that file
        with open(file_name, "w") as file:
            json.dump(record, file)
        print(f"File {file_name} was successfully created!")
# otherwise throw the below error
else:
    error_message = data.get("message", "no message given")
    print(f"Error creating files: {response.status_code} {error_message}")