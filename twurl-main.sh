#!/bin/bash
## Name:    Christopher Mortimer
## Date:    2017-07-26
## Desc:    Get all the statuses for a search term
## Params:  -s:   Search string (sent to the API in the query field)
##          -n:   Number of API calls to make if you want to limit it, or use a high number such as 10000 to pull all available
##          -st:  String search type (at: @, hash: #, special: a custom search term)
##          -um:  Create a CSV file for user mentions, very resource intensive
##          -rt:  Run type (json: only call the API, csv: only call the CSV concerstion, both: Call API then the CSV conversion)
##          -f:   File name for the output files
##          -sp:  Speed the rate of calls. The script may fail due passing the to 180 calls in 15 mintues limit
## Usage:    ./twurl-main.sh -s <search_string> -n <num_files|10000> -st <hash|at|special> -um <yes|no> -rt <json|csv|both> [-f <file_name>] -sp
##          example:
##          ./twurl-main.sh -s mortie23 -n 1000 -st at -um yes -rt both
##  ./twurl-main.sh -s 7News -n 1000 -st hash -um no -rt json

. common-functions.sh
parseArgs "$@"

## Show help
if [ ${help} == 'Y' ]; then
  echo 'HELP'
  echo '  Desc:     Get twitter statuses for a search term'
  echo '  Usage:      ./twurl-main.sh -s <search_string> -n <num_files|10000> -st <hash|at|special> -um <yes|no> -rt <json|csv|both> [-sp]'
  echo '  Examples:'
  echo '    # Get all tweets for @mortie23 do not do CSV converstion'
  echo '    ./twurl-main.sh -s mortie23 -n 10000 -st at -um no -rt json -sp'
  echo '    # Get all tweets for @mortie23 since status_id=1222085487105474562'
  echo '    ./twurl-main.sh -s "%40mortie23&since_id=1222085487105474562" -n 10000 -st special -um no -rt json'
  echo '  Parameters:'
  echo '    -s:  Search string (sent to the API in the query field)'
  echo '    -n:  Number of API calls to make if you want to limit it, or use a high number such as 10000 to pull all available'
  echo '    -st: String search type (at: @, hash: #, special: a custom search term)'
  echo '    -um: Create a CSV file for user mentions, very resource intensive (valid for -st csv|both)'
  echo '    -rt: Run type (json: only call the API, csv: only call the CSV concerstion, both: Call API then the CSV conversion)'
  echo '    -sp: Speed the rate of calls. The script may fail due passing the to 180 calls in 15 mintues limit'
  exit
fi

## see parseArgs function from common-functions.sh to see what variables are returned 
. twurl-apiCall.sh
. twurl-jsonToCsv.sh

## Initialise variables
max_id=-1
since_id=-1
next_id=-1
i=1

## Initialise filename
if [ -z ${filename+x} ]; then
  echoLog "INFO" "No filename passed as argument"
  filename='nil'
fi

## Process Search Type
if [ ${search_type} == 'hash' ]; then
    ascii='%23'
elif [ ${search_type} == 'at' ]; then
    ascii='%40'
elif [ ${search_type} == 'special' ]; then    
    ascii=''
    if [ ${filename} == 'nil' ]; then
      filename='special'
    fi
else
    ascii=''
fi
if [ ${filename} == 'nil' ]; then
  filename=${search_string}
fi
echoLog "INFO" "\e[34mSTART\e[0m, filename: ${filename}, search_string: ${search_string}, search_type: ${search_type}, ascii: ${ascii}"
echoLog "INFO" "\e[34mSTART\e[0m, max_id: ${max_id}, since_id: ${since_id}"
echoLog "INFO" "\e[34mSTART\e[0m, user_mentions: ${user_mentions}, run_type: ${run_type}, filename: ${filename}, speed: ${speed}"

## _main_ function to direct process logic (i.e. get JSON, convert JSON to CSV or both sequentially)
function _main_() {
  if [ ${run_type} == 'json' ]; then
    apiCall ${search_string} ${search_type} ${num_files} ${filename} ${speed} ${ascii} 
  elif [ ${run_type} == 'csv' ]; then
    jsonToCsv ${filename} ${user_mentions}
  elif [ ${run_type} == 'both' ]; then
    apiCall ${search_string} ${search_type} ${num_files} ${filename} ${speed} ${ascii}
    jsonToCsv ${filename} ${user_mentions}
  fi
}
_main_