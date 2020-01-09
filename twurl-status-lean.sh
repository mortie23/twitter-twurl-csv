#!/bin/bash
## Name:  Christopher Mortimer
## Date:  2020-01-09
## Desc:  Get all the statuses for a search term
## Usage:  ./twurl-status.sh -s <search_string> -n <num_files>
##        example:
##        ./twurl-status-lean.sh -s mortie23 -n 100

. common-functions.sh
parseArgs "$@"

# Initialise variables
max_id=-1
since_id=-1
i=1
next_results=null

## Call the Twitter status API
function APICall() {
  echoLog "INFO" "\e[34mSTART\e[0m, search: ${search_string}, max_id: ${max_id}, since_id: ${since_id}"

  ## Loop through the number of times the user inputs
  for i in $(eval echo {1..${num_files}}); do
    ## on first run dont send an id
    if [ ${i} == 1 ]; then
      twurl "/1.1/search/tweets.json?q=${search_string}&result_type=recent&count=100&lang=en&tweet_mode=extended" > ./data/${search_string}-${i}.json
    else
      twurl "/1.1/search/tweets.json${next_results}" > ./data/${search_string}-${i}.json
    fi

    ## Remove all newlines
    sed -i 's/\\n/ /g' ./data/${search_string}-${i}.json
    sed -i 's/\\r/ /g' ./data/${search_string}-${i}.json

    ## parsing the search parameters
    max_id=`jq '.search_metadata.max_id' ./data/${search_string}-${i}.json`
    since_id=`jq '.search_metadata.since_id' ./data/${search_string}-${i}.json`
    count=`jq '.search_metadata.count' ./data/${search_string}-${i}.json`

    ## finding the last id, to send it to the next request
    ## send list of all status id to temp file
    jq '.statuses[].id' ./data/${search_string}-${i}.json > temp.txt
    ## create an array of all the status id
    IFS=$'\n' read -d '' -r -a lines < temp.txt
    ## find the length of the statuses
    len=`cat temp.txt | wc -l`
    echoLog "INFO" "\e[93m${i} of ${num_files}\e[0m, \e[93mlen: ${len}\e[0m, count: ${count}, max_id: ${max_id}, since_id: ${since_id}"
    rm temp.txt

    ## find the next results. somthing strange with adding a %23
    next_results=`jq -r '.search_metadata.next_results' ./data/${search_string}-${i}.json`
    #next_results=`echo "${next_results_tmp}" | sed "s/%25/%/g"`
    #echoLog "INFO" "next_results: ${next_results}"

    if [ ${next_results} == "null" ]; then
      echoLog "INFO" "No more results"
      exit
    fi

  done
  echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}"
}

## Call the functions
APICall

echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}, max_id: ${max_id}, since_id: ${since_id}"
