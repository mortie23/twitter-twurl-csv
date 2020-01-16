#!/usr/bin/python3
## Author:  Christopher Mortimer
## Date:    2020-01-15
## Desc:    Get all statuses based on a list of ids
## Depend:  pip3 install tweepy --user
##          pip3 install pandas --user
##          pip3 install os --user

import sys
## Add the parent directory containing the auth files
sys.path.append('../')
import myAuth

import os
import tweepy as tw
import pandas as pd

#consumer_key='from myAuth file in parent directory'
#consumer_secret='from myAuth file in parent directory'
#access_token='from myAuth file in parent directory'
#access_token_secret='from myAuth file in parent directory'

auth = tw.OAuthHandler(myAuth.consumer_key, myAuth.consumer_secret)
auth.set_access_token(myAuth.access_token, myAuth.access_token_secret)
api = tw.API(auth, wait_on_rate_limit=True)

search_words = "@mortie23"
date_since = "2018-11-16"

# Collect tweets as object
tweets = tw.Cursor(api.search,q=search_words,lang="en",since=date_since).items(5)
# Iterate and print tweets
for i, tweet in enumerate(tweets):
  print(i,":\n")
  print(tweet.text)

print("\n\nNow without retweets\n\n")
## Get tweets without retweets
new_search = search_words + " -filter:retweets"
#print(new_search)
tweets = tw.Cursor(api.search,q=new_search,lang="en",since=date_since).items(10)
for i, tweet in enumerate(tweets):
  print(i,":\n")
  print(tweet.text)

#print(vars(tweets))

## User timeline
print("\n\nNow a timeline\n\n")
tweets = tw.Cursor(api.user_timeline, id="mortie23").items(10)
for i, tweet in enumerate(tweets):
  print(i,":\n")
  print(tweet.text)