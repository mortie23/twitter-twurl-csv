#!/bin/bash
## Name:    Christopher Mortimer
## Date:    2020-01-15
## Desc:    Get all the statuses for a list of status ids
## Usage:   ./twurl-status-ids.sh -f <filename>
##          example:
##          ./twurl-status-ids.sh -f status-ids.txt
## Depend:  filename must exist and be in the format of a valid status_id per line
##          example
##          $ cat status-ids.txt
##          1213376917350404097 
##          1205447468336349192

help='N'
. common-functions.sh
parseArgs "$@"

## Show help
if [ ${help} == 'Y' ]; then
  echo "HELP"
  echo "  Usage:    ./twurl-status-ids.sh -f <filename>"
  echo "  example:  ./twurl-status-ids.sh -f ./status-ids.txt"
  exit
fi

## Create an array of all the status ids in the file and get the length
idsArray=($(cat ${filename}))
len=`cat ${filename} | wc -l`

## Initialise the id string that will be used to send 100 ids to the API
idString=""
## Initialise the id starts from 1
from=1
## Loop through the array
for idx in "${!idsArray[@]}"; do
  i=$((${idx}+1))
  ## Modular division of the iterator
  iMod100=$((${i} % 100))
  ## Call the API when i is divisable by 100 or it is the last id in the array
  if [ ${iMod100} == 0 ] || [ $((${i})) == ${len} ]; then
    echoLog "INFO" "Getting statuses from list value ${from} to ${i}"
    ## Call API and write to JSON file
    twurl "/1.1/statuses/lookup.json?id=${idString}&tweet_mode=extended" > ./data/statuses-${i}.json
    ## Turn result array into an object with a single array inside
    echo '{"statuses":' | cat - ./data/statuses-${i}.json > temp && mv temp ./data/statuses-${i}.json
    echo '}' >> ./data/statuses-${i}.json
    ## Reset the string and set the start id of the next batch of 100 
    idString=${idsArray[${i}]}
    from=$((${i}+1))
  else
    ## Concatenate the ids to comma seperated string
    idString="${idString},${idsArray[${i}]}"
  fi
done
