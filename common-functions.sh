## Name:    Common Functions
## Author:  Christopher Moirtimer
## Date:    2019-05-20
## Desc:    Standard functions for use across all scripts
## Usage:   .commonFunctions.sh

## Echo a info log level message with the current time
## usage echoLog "<loglevel>" "<message>"
## where log level is [INFO,WARN,ERROR,etc]
logfile=./data/logs/log-`date +'%Y%m%d_%H%M%S'.log`
function echoLog() {
  logLevel=${1}
  message=${2}
  strdtm=`date +'%Y-%m-%d_%H:%M:%S'`
  echo -e "${logLevel}, ${strdtm}, func(${FUNCNAME[1]}), ${message}" |& tee -a ${logfile}
}

## to parse arguments
function parseArgs() {
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
  key="$1"

  case $key in
    -h|--help)
		help="Y"
		shift # past argument
		;;
    -s|--search_string)
    search_string="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--num_files)
    num_files="$2"
    shift # past argument
    shift # past value
    ;;
    -um|--user_mentions)
    user_mentions="$2"
    shift # past argument
    shift # past value
    ;;
    -st|--search_type)
    search_type="$2"
    shift # past argument
    shift # past value
    ;;
    -rt|--run_type)
    run_type="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--filename)
    filename="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters

  #echo search_string = "${search_string}"
  #echo num_files = "${num_files}"
  #echo search_type = "${search_type}"
}