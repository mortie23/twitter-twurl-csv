#!/bin/bash
## Name:    Christopher Mortimer
## Date:    2017-07-26
## Desc:    Parse twurl status json responses into CSV files for statuses and users
## Params:  filename
## Require: called from script that has included common-functions.sh
## Usage:   . twurl-jsonToCsv.sh 
##          jsonToCSV <filename>
## Example: . twurl-jsonToCsv.sh 
##          jsonToCSV mortie23

## Function to create a CSV file from a JSON Twurl result
function createCSV() {
  filename=${1}
  i=${2}

  if [ ${i} == 1 ]; then
    rm ./data/${filename}-statuses.csv
    rm ./data/${filename}-users.csv
    if [ ${user_mentions} == 'yes' ]; then
      rm ./data/${filename}-mentions.csv
    fi
    #echoLog 'INFO' "cleaned previous CSV"
    echo 'status_id,user_id,text,is_quote_status,quoted_status_id,in_reply_to_status_id,in_reply_to_user_id,retweet_count,favorite_count,favorited,retweeted,retweeted_status_id,created_at,filename' > ./data/${filename}-statuses.csv
    echo 'user_id,screen_name,location,description,followers_count,friends_count,listed_count,favourites_count,verified,statuses_count,created_at,filename' > ./data/${filename}-users.csv
    
    if [ ${user_mentions} == 'yes' ]; then
      echo 'status_id,user_id,screen_name,filename,mention_order' > ./data/${filename}-mentions.csv
    fi
    #echoLog 'INFO' "CSV with header row created"
  fi
  echoLog 'INFO' "filename: ${filename}, \e[93mi: ${i}\e[0m, user_mentions: ${user_mentions}"

  ## Status
  cat ./data/${filename}-${i}.json | jq -r --arg filename "${filename}-${i}.json" '.statuses[]+{filename:$filename} | ([.id_str, .user.id_str, .full_text, .is_quote_status, .quoted_status_id, .in_reply_to_status_id, .in_reply_to_user_id, .retweet_count, .favorite_count, .favorited, .retweeted, .retweeted_status.id, .created_at, .filename] | @csv)'  >> ./data/${filename}-statuses.csv
  ## User
  cat ./data/${filename}-${i}.json | jq -r --arg filename "${filename}-${i}.json" '.statuses[]+{filename:$filename} | ([.user.id_str, .user.screen_name, .user.location, .user.description, .user.followers_count, .user.friends_count, .user.listed_count, .user.favourites_count, .user.verified, .user.statuses_count, .user.created_at, .filename] | @csv)' >> ./data/${filename}-users.csv
  
  if [ ${user_mentions} == 'yes' ]; then
    ## User mentions
    cat ./data/${filename}-${i}.json | jq -r '.statuses[] as $in | ([$in.id_str, $in.entities.user_mentions[].id_str, $in.entities.user_mentions[].screen_name] | @csv)' >> ./data/${filename}-mentions-temp.csv
    # transpose the columns to rows
    linenum=0
    for line in $(cat ./data/${filename}-mentions-temp.csv);
      do
        linenum=$((linenum+1))
        if [ ${linenum} == 1 ]; then
          echoLog "INFO" "transposing mentions"
        fi 
        id=`echo ${line} | cut -d "," -f1`
        # count mentions
        num_mentions=$((`echo ${line} | tr -cd , | wc -c`/2))
        for (( c=1; c<=${num_mentions}; c++ ))
          do
            user_id_dlm=$((c+1))
            screen_name_dlm=$((c+${num_mentions}+1))
            user_id=`echo ${line} | cut -d "," -f${user_id_dlm}`
            screen_name=`echo ${line} | cut -d "," -f${screen_name_dlm}`
            echo "${id}, ${user_id}, ${screen_name}, ${filename}-${i}.json, ${c}|${num_mentions}" >> ./data/${filename}-mentions.csv
          done
      done
      echoLog "INFO" "${linenum} total lines transposed"
      ## Cleanup the mentions-temp
      rm ./data/${filename}-mentions-temp.csv
    fi
}

## Loop over files to create CSV
function loopJSONs() {
  echoLog "INFO" "\e[34mSTART\e[0m, search: ${filename}, type: ${search_type}"
  for (( j=1; j<=${apiCalls}; j++ ))
    do
      createCSV ${filename} ${j}
      cnext=$((j+1))
    done
  echoLog "INFO" "\e[31mEND\e[0m, search: ${filename}, type: ${search_type}"
}

## Get the number of files to loop through based on the search string
function jsonToCsv() {
  filename=${1}
  user_mentions=${2}
  ## list of files 
  apiCalls=`ls ./data/*.json | grep ${filename} | wc -l`
  ## Loop over all the json files
  loopJSONs
}
