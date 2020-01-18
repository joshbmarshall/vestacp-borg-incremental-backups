#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Borg backup path not entered. Aborting..."
  exit 1
fi

if [ -z $2 ]; then
  echo "!!!!! Borg archive name not entered. Aborting..."
  exit 1
fi

if [ -z "$3" ]; then
  echo "!!!!! Borg dir to back up not entered. Aborting..."
  exit 1
fi

REPO_PATH=$1
ARCHIVE=$2
TO_BACKUP=$3

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

if [ -z $BORG_SERVER ]; then
  borg create $OPTIONS_CREATE $REPO_PATH::$ARCHIVE $TO_BACKUP
else
  REMOTE_REPO_PATH=`echo $REPO_PATH | sed -e "s#${BACKUP_DIR}#${BORG_SERVER_DIR}#"`
  echo "-- Creating borg archive $ARCHIVE in repository $REMOTE_REPO_PATH"
  borg create $OPTIONS_CREATE ssh://$BORG_SERVER_USER@$BORG_SERVER:$BORG_SERVER_PORT/$REMOTE_REPO_PATH::$ARCHIVE $TO_BACKUP
fi

