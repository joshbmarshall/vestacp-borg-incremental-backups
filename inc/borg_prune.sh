#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Borg backup path not entered. Aborting..."
  exit 1
fi

REPO_PATH=$1
PRUNE_ARGS=$2

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

if [ -z $BORG_SERVER ]; then
  borg prune $OPTIONS_PRUNE $REPO_PATH $PRUNE_ARGS
else
  REMOTE_REPO_PATH=`echo $REPO_PATH | sed -e "s#${BACKUP_DIR}#${BORG_SERVER_DIR}#"`
  echo "-- Pruning borg repository $REMOTE_REPO_PATH"
  borg prune $OPTIONS_PRUNE ssh://$BORG_SERVER_USER@$BORG_SERVER:$BORG_SERVER_PORT/$REMOTE_REPO_PATH $PRUNE_ARGS
fi

