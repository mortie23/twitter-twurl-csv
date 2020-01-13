#!/bin/bash
## Name:    Christopher Mortimer
## Date:    2017-07-26
## Desc:    Get all the statuses for a search term
## Params:  -s: search string
##          -n: number of API calls to make, or use high number such as 1000 to pull all available
##          -st: string search type (at for @, hash for #)
##          -um: this option creates the CSV file for user mentions, very resource intensive
## Usage:    ./twurl-main.sh -s <search_string> -n <num_files|high> -st <hash|at|nil> -um <yes|no> -rt <json|csv|both>
##          example:
##          ./twurl-main.sh -s mortie23 -n 1000 -st at -um yes -rt both

. common-functions.sh
parseArgs "$@"
## see parseArgs function from common-functions.sh to see what variables are returned 
. twurl-apiCall.sh
. twurl-jsonToCsv.sh

## Initialise variables
max_id=-1
since_id=-1
next_id=-1
i=1

echoLog "INFO" "\e[34mSTART\e[0m, search: ${search_string}, search_type: ${search_type}, max_id: ${max_id}, since_id: ${since_id}, user_mentions: ${user_mentions}, run_type: ${run_type}"

## _main_ function to direct process logic (i.e. get JSON, convert JSON to CSV or both sequentially)
function _main_() {
  if [ ${run_type} == 'json' ]; then
    apiCall ${search_string} ${search_type} ${num_files}
  elif [ ${run_type} == 'csv' ]; then
    jsonToCsv ${search_string} ${user_mentions}
  elif [ ${run_type} == 'both' ]; then
    apiCall ${search_string} ${search_type} ${num_files}
    jsonToCsv ${search_string} ${user_mentions}
  fi
}
_main_