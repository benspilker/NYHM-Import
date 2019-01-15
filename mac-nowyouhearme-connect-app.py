#Python 3.7.1
#RestfulClient.py

import requests
#from requests.auth import HTTPDigestAuth
import json

print "******************************************"

print "******************************************"
 
email = raw_input('Please input your email, then press enter: ')
uri = 'https://my.zerotier.com/api/network'
authToken = 'bearer mPXKrT8RgK7bQgQg4xDvjJLcNrVdOE0M'
myResponse = requests.get(url,headers={'Authorization': authToken})
myResponse.status_code
networks = json.loads(myResponse.text)
for network in networks:
    if network["config"]["name"] == email:
        print(network["id"])

print "Got it! you will be joined to your NowYouHear.me network from here..."



print "Connecting to your nowyouhear.me network..."

