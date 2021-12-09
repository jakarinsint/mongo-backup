#!/bin/bash
 
######################################################################
##
##   MongoDB Database Backup Script 
##   Written By: Jakarin S.
##   Created Date: 09/12/2021
##
######################################################################
CONFIG_FILE=./config
TODAY=`date +"%d%b%Y"`

checkenv() {
  if [ -f "$CONFIG_FILE" ]; then
    return 
  else 
    false
  fi
}

init() {
  printf "mongo-backup: start initializing\n"

  source $CONFIG_FILE
  mkdir -p ${DB_BACKUP_PATH}/${TODAY}

  printf "mongo-backup: initializing...............[DONE]\n\n"
}

# backup - a function to backup data from specific collection with date condition.
backup() {
  printf "mongo-backup: start backing up\n"

  QUERY="{ \"created\": { \"\$lte\": {  \"\$date\": \"${MARK_TIMESTAMP}\" } } }"
  mongoexport --uri="${MONGO_URI}" --collection=${COLLECTION_NAME} -q="${QUERY}" --out=${DB_BACKUP_PATH}/${TODAY}/${COLLECTION_NAME}.json > /dev/null

  printf "mongo-backup: backing up.................[DONE]\n\n"
}

# remove - a function to remove data from specific collection with date condition.
remove() {
  printf "mongo-backup: start removing data\n"

  MONGO_SHELL=$(echo "db.$COLLECTION_NAME.deleteMany( { \"created\": { \"\$lte\": ISODate(\"${MARK_TIMESTAMP}\") } } )")
  MESSAGE=$(mongo "${MONGO_URI}" --eval "${MONGO_SHELL}" >&1)

  printf "result: "
  printf "$MESSAGE\n" | sed -n '$p'
  printf "mongo-backup: removing data..............[DONE]\n\n"
}

###
# Main body of script starts here
###
START=$SECONDS
if checkenv ; then

  # initial environment before processing
  init

  if [ -z "$MARK_TIMESTAMP" ]
  then
    printf "mongo-backup error: MARK_TIMESTAMP is not specified.\n"
  else
    # do backup
    backup

    # do remove
    remove

    TOTALSEC=$((SECONDS-START))
    echo "mongo-backup: finished about  $((TOTALSEC%3600/60)) minutes."
    printf "mongo-backup: your backup data [${DB_BACKUP_PATH}/${TODAY}/${COLLECTION_NAME}.json]\n"
    
  fi
  
else
  printf "mongo-backup error: configuration file does not exist\n"
fi

