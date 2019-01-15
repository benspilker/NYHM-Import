#Python 3.7.1
#RestfulClient.py

import requests
#from requests.auth import HTTPDigestAuth
import json

url = 'https://my.zerotier.com/api/network'
authToken = 'bearer mPXKrT8RgK7bQgQg4xDvjJLcNrVdOE0M'



myResponse = requests.get(url,headers={'Authorization': authToken})
#myResponse.status_code
networks = json.loads(myResponse.text)
for network in networks:
#    print(network["description"])
#    print(network["id"])
    if network["config"]["name"] == "steve":
        print(network["id"])
    
   