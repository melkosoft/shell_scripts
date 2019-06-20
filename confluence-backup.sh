#!/usr/bin/env bash
set -o nounset
set -eo pipefail

###--- CONFIGURATION SECTION STARTS HERE ---###
# MAKE SURE ALL THE VALUES IN THIS SECTION ARE CORRECT BEFORE RUNNIG THE SCRIPT
EMAIL=user@example.com
API_TOKEN=XXXXXXXXXXXXXXXXXXX
INSTANCE=example.atlassian.net
BACKUP_BASE="/path/to/backup"
# JQ - JSON parser, https://stedolan.github.io/jq/
JQ=$(/usr/bin/which jq)
# PUP - HTML parser, https://github.com/ericchiang/pup
PUP=$(/usr/bin/which pup)
CURL=$(/usr/bin/which curl)

### Checks for progress max 3000 times, waiting 20 seconds between one check and the other ###
# If your instance is big you may want to increase the below values #
PROGRESS_CHECKS=3000
SLEEP_SECONDS=10
 
# Set this to your Atlassian instance's timezone.
# See this for a list of possible values:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TIMEZONE=America/Los_Angeles
  
###--- END OF CONFIGURATION SECTION ---####
 
####- START SCRIPT -#####
TODAY=$(TZ=$TIMEZONE date +%Y-%m-%d)
DOWNLOAD_FOLDER="${BACKUP_BASE}/${TODAY}"
mkdir -p "${DOWNLOAD_FOLDER}"
echo "starting the script: $TODAY"

#### Generate list of SPACES
SPACES=$(curl -s -u ${EMAIL}:${API_TOKEN} "https://${INSTANCE}/wiki/rest/api/space?limit=100" | ${JQ} '.results[].key' | xargs)
# echo $SPACES

#### Start iteration through list of spaces
for s in $(echo $SPACES); do
  ## The $BKPMSG variable is used to save and print the response
  TIMESTAMP=$(date +"%Y.%m.%d_%H.%M") 
  BKPMSG=$(curl -s -u ${EMAIL}:${API_TOKEN} -H "X-Atlassian-Token: no-check" -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/json"  -X POST "https://${INSTANCE}/wiki/spaces/doexportspace.action?key=${s}&confirm=Export&exportType=TYPE_XML&synchronous=false&includeComments=true&contentOption=all" )

  # Path to check if export finished
  TASKID=$(echo $BKPMSG | ${PUP} 'meta[name="ajs-pollURI"] attr{content}')
  if [ -z "$TASKID" ]; then
    continue
  fi
  # Checks if the backup process completed for the number of times specified in PROGRESS_CHECKS variable
  for (( c=1; c<=${PROGRESS_CHECKS}; c++ )); do
    PROGRESS_JSON=$(curl -s -u ${EMAIL}:${API_TOKEN} https://${INSTANCE}/wiki/${TASKID})
    FILE_NAME=$(echo "$PROGRESS_JSON" | ${JQ} '.result' | xargs )
    COMPLETE=$(echo "$PROGRESS_JSON" | ${JQ} '.complete' )
    RESULT=$(echo "$PROGRESS_JSON" | ${JQ} '.successful' )
    if [[ "$COMPLETE" == "true" ]]; then
      if [[ "$RESULT" == "true" ]]; then
        break
      fi
      FILE_NAME=
      break
    fi
    # Waits for the amount of seconds specified in SLEEP_SECONDS variable between a check and the other
    sleep ${SLEEP_SECONDS}
  done

  # If the backup is not ready after the configured amount of PROGRESS_CHECKS, it ends the script.
  if [ -z "$FILE_NAME" ]; then
    exit
  else
    ## PRINT THE FILE TO DOWNLOAD ##
    echo "Space to download: ${s}"
    curl -s -L -u ${EMAIL}:${API_TOKEN} "https://${INSTANCE}$FILE_NAME" -o "$DOWNLOAD_FOLDER/${s}-backup-${TIMESTAMP}.zip"
  fi
done
