#!/bin/bash
## Name:    Christopher Mortimer
## Date:    2017-07-26
## Desc:    Parse twurl status json responses into CSV files for statuses and users
## Params:  search_string
## Require: called from script that has included common-functions.sh
## Usage:   . twurl-apiCall.sh 
##          apiCall ${search_string} ${search_type} ${num_files} ${file_name} ${ascii} ${speed}
## Example: . twurl-apiCall.sh 
##          apiCall mortie23 at 10 foo %40 Y

## Call the Twitter status API
function apiCall() {

  search_string=${1}
  search_type=${2}
  num_files=${3}
  filename=${4}
  speed=${5}
  ascii=${6}
  
  echoLog "INFO" "\e[34mSTART\e[0m, search_string: ${search_string}, search_type: ${search_type}, ascii: ${ascii}, max_id: ${max_id}, since_id: ${since_id}"

  ## Loop through the number of times the user inputs            
  for i in $(eval echo {1..${num_files}}); do        
    ## on first run dont send an id 
    if [ ${i} == 1 ]; then
      twurl "/1.1/search/tweets.json?q=${ascii}${search_string}&result_type=recent&count=100&lang=en&tweet_mode=extended" > ./data/${filename}-${i}.json      
    else
      twurl "/1.1/search/tweets.json?q=${ascii}${search_string}&result_type=recent&count=100&lang=en&tweet_mode=extended&max_id=${max_id_next}" > ./data/${filename}-${i}.json      
    fi

    ## Remove all newlines
    ## disabled this as it can cause invalid escape characters to be left breaking the JSON documents
    ##sed -i 's/\\n/ /g' ./data/${filename}-${i}.json
    ##sed -i 's/\\r/ /g' ./data/${filename}-${i}.json

    ##copy for search metadata extraction
    cp ./data/${filename}-${i}.json ./data/${filename}-${i}-search_metadata.json
    ##keep just search metadata
    sed -i -E 's/.*("search_metadata":\{.*)/\{\1/g' ./data/${filename}-${i}-search_metadata.json
    
    ## parsing the search parameters
    max_id=`jq '.search_metadata.max_id_str' ./data/${filename}-${i}-search_metadata.json`
    since_id=`jq '.search_metadata.since_id_str' ./data/${filename}-${i}-search_metadata.json`
    count=`jq '.search_metadata.count' ./data/${filename}-${i}-search_metadata.json`
    next_results=`jq -r '.search_metadata.next_results' ./data/${filename}-${i}-search_metadata.json`
    ## get the max_id from the next_results query string
    max_id_next=`grep -oP '(?<=max_id=).*?(?=&q=)' <<< "${next_results}"`
    #echoLog "INFO" "max_id_next: ${max_id_next}"

    ## finding the last id, to send it to the next request
    ## send list of all status id to temp file
    ##jq '.statuses[].id' ./data/${filename}-${i}.json > temp.txt
    ## create an array of all the status id
    ##IFS=$'\n' read -d '' -r -a lines < temp.txt
    ## find the length of the statuses
    ##len=`cat temp.txt | wc -l`
    echoLog "INFO" "\e[93m${i} of ${num_files}\e[0m, \e[93mlen: ${len}\e[0m, max_id: ${max_id}, max_id_next: ${max_id_next}, since_id: ${since_id}"
    ##rm temp.txt

    ## find the next results
    next_results=`jq -r '.search_metadata.next_results' ./data/${filename}-${i}-search_metadata.json`
    
    ## remove the metadata file
    rm ./data/${filename}-${i}-search_metadata.json
    
    ## exit if there are no more results
    if [ ${next_results} == "null" ]; then
      echoLog "INFO" "No more results"
      apiCalls=${i}
      break
    fi

    ## Twitter API only allows 180 calls in 15 mintues. 
    ## Wait 5 seconds to keep below the rate limit
    if [ ${speed} == 'N' ]; then
      sleep 5
    fi
 
  done
  echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}, type: ${search_type}, ascii: ${ascii}"
}
