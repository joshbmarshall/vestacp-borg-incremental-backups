#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Borg backup path not entered. Aborting..."
  exit 1
fi

if [ -z $2 ]; then
  echo "!!!!! Borg archive not entered. Aborting..."
  exit 1
fi

REPO_PATH=$1
ARCHIVE=$2

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

if [ -z $BORG_SERVER ]; then
  borg extract --stdout $REPO_PATH::$ARCHIVE
else
  REMOTE_REPO_PATH=`echo $REPO_PATH | sed -e "s#${BACKUP_DIR}#${BORG_SERVER_DIR}#"`
  borg extract --stdout ssh://$BORG_SERVER_USER@$BORG_SERVER:$BORG_SERVER_PORT/$REMOTE_REPO_PATH::$ARCHIVE
fi

