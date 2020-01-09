#!/bin/bash
## Name:		Christopher Mortimer
## Date:		2017-07-26
## Desc:		Get all the statuses for a search term
## Params:	-s: search string
##					-n: number of API calls to make, or use high number such as 1000 to pull all available
##					-st: string search type (at for @, hash for #)
##					-um: this option creates the CSV file for user mentions, very resource intensive
## Usage:		./twurl-status.sh -s <search_string> -n <num_files|high> -st <hash|at> -um <yes|no>
##					example:
##					./twurl-status.sh -s mortie23 -n 1000 -st at -um yes

. common-functions.sh
parseArgs "$@"

# Initialise variables
max_id=-1
since_id=-1
next_id=-1
i=1

## Process Search Type
if [ ${search_type} == 'hash' ]; then
    ascii='%23'
else
    ascii='%40'
fi

echoLog "INFO" "\e[34mSTART\e[0m, search: ${search_string}, type: ${search_type}, ascii: ${ascii}, max_id: ${max_id}, since_id: ${since_id}"

## Function to create a CSV file from a JSON Twurl result
function createCSV() {
	search_string=${1}
	i=${2}

	echoLog 'INFO' "search_string: ${search_string}, \e[93mi: ${i}\e[0m"
	if [ ${i} == 1 ]; then
		rm ./data/${search_string}-statuses.csv
		rm ./data/${search_string}-users.csv
		rm ./data/${search_string}-mentions.csv
		#echoLog 'INFO' "cleaned previous CSV"
		echo 'status_id,user_id,text,is_quote_status,retweet_count,favorite_count,favorited,retweeted,created_at,filename' > ./data/${search_string}-statuses.csv
		echo 'user_id,screen_name,location,description,followers_count,friends_count,listed_count,favourites_count,verified,statuses_count,created_at,filename' > ./data/${search_string}-users.csv
		
		if [ ${user_mentions} == 'yes' ]; then
			echo 'status_id,user_id,screen_name,filename,mention_order' > ./data/${search_string}-mentions.csv
		fi
		#echoLog 'INFO' "CSV with header row created"
	fi

	## Status
	cat ./data/${search_string}-${i}.json | jq -r --arg filename "${search_string}-${i}.json" '.statuses[]+{filename:$filename} | ([.id_str, .user.id_str, .full_text, .is_quote_status, .retweet_count, .favorite_count, .favorited, .retweeted, .created_at, .filename] | @csv)'  >> ./data/${search_string}-statuses.csv
	## User
	cat ./data/${search_string}-${i}.json | jq -r --arg filename "${search_string}-${i}.json" '.statuses[]+{filename:$filename} | ([.user.id_str, .user.screen_name, .user.location, .user.description, .user.followers_count, .user.friends_count, .user.listed_count, .user.favourites_count, .user.verified, .user.statuses_count, .user.created_at, .filename] | @csv)' >> ./data/${search_string}-users.csv
	
	if [ ${user_mentions} == 'yes' ]; then
		## User mentions
		cat ./data/${search_string}-${i}.json | jq -r '.statuses[] as $in | ([$in.id_str, $in.entities.user_mentions[].id_str, $in.entities.user_mentions[].screen_name] | @csv)' >> ./data/${search_string}-mentions-temp.csv
		# transpose the columns to rows
		linenum=0
		for line in $(cat ./data/${search_string}-mentions-temp.csv);
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
						echo "${id}, ${user_id}, ${screen_name}, ${search_string}-${i}.json, ${c}|${num_mentions}" >> ./data/${search_string}-mentions.csv
					done
			done
			echoLog "INFO" "${linenum} total lines transposed"
			## Cleanup the mentions-temp
			rm ./data/${search_string}-mentions-temp.csv
		else
			#echoLog "INFO" "Not transposing user_mentions file"
		fi
}

## Call the Twitter status API
function APICall() {
	echoLog "INFO" "\e[34mSTART\e[0m, search: ${search_string}, type: ${search_type}, ascii: ${ascii}, max_id: ${max_id}, since_id: ${since_id}"

	## Loop through the number of times the user inputs
	for i in $(eval echo {1..${num_files}}); do
		## on first run dont send an id
		if [ ${i} == 1 ]; then
			twurl "/1.1/search/tweets.json?q=${ascii}${search_string}&result_type=recent&count=100&lang=en&tweet_mode=extended" > ./data/${search_string}-${i}.json
		else
			twurl "/1.1/search/tweets.json?q=${ascii}${search_string}&result_type=recent&count=100&lang=en&tweet_mode=extended&max_id=${max_id_next}" > ./data/${search_string}-${i}.json
		fi

		## Remove all newlines
		sed -i 's/\\n/ /g' ./data/${search_string}-${i}.json
		sed -i 's/\\r/ /g' ./data/${search_string}-${i}.json

		## parsing the search parameters
		max_id=`jq '.search_metadata.max_id' ./data/${search_string}-${i}.json`
		since_id=`jq '.search_metadata.since_id' ./data/${search_string}-${i}.json`
		count=`jq '.search_metadata.count' ./data/${search_string}-${i}.json`
		next_results=`jq -r '.search_metadata.next_results' ./data/${search_string}-${i}.json`
		## get the max_id from the next_results query string
		max_id_next=`grep -oP '(?<=max_id=).*?(?=&q=)' <<< "${next_results}"`
		#echoLog "INFO" "max_id_next: ${max_id_next}"

		## finding the last id, to send it to the next request
		## send list of all status id to temp file
		jq '.statuses[].id' ./data/${search_string}-${i}.json > temp.txt
		## create an array of all the status id
		IFS=$'\n' read -d '' -r -a lines < temp.txt
		## find the length of the statuses
		len=`cat temp.txt | wc -l`
		echoLog "INFO" "\e[93m${i} of ${num_files}\e[0m, \e[93mlen: ${len}\e[0m, max_id: ${max_id}, max_id_next: ${max_id_next}, since_id: ${since_id}"
		rm temp.txt

		## find the next results. if not existant then exit
		next_results=`jq -r '.search_metadata.next_results' ./data/${search_string}-${i}.json`
		if [ ${next_results} == "null" ]; then
			echoLog "INFO" "No more results"
			apiCalls=${i}
			break
		fi

	done
	echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}, type: ${search_type}, ascii: ${ascii}"
}

## Loop over files to create CSV
function loopJSONs() {
	echoLog "INFO" "\e[34mSTART\e[0m, search: ${search_string}, type: ${search_type}"
	for (( j=1; j<=${apiCalls}; j++ ))
		do
			createCSV ${search_string} ${j}
			cnext=$((j+1))
		done
	echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}, type: ${search_type}"
}

## Clean up duplicates in the user file
## This wont work now that the filname id added for each row. The duplication is across files
function dupClean() {
	echoLog "INFO" "\e[34mNODUP\e[0m, filetype: users"
	awk '!a[$0]++' ./data/${search_string}-users.csv  > ./data/${search_string}-users-nodup.csv
	rm ./data/${search_string}-users.csv
	mv ./data/${search_string}-users-nodup.csv ./data/${search_string}-users.csv
}

## Call the functions
APICall
## loopJSONs is a loop that finds all the JSON files and then calls the createCSV function
loopJSONs
#dupClean

echoLog "INFO" "\e[31mEND\e[0m, search: ${search_string}, type: ${search_type}, ascii: ${ascii}, max_id: ${max_id}, since_id: ${since_id}"
