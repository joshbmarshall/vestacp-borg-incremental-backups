#!/bin/bash

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Borg backup path not entered. Aborting..."
  exit 1
fi

REPO_PATH=$1

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

if [ -z $BORG_SERVER ]; then
  cd $REPO_PATH
  echo *
  cd -
else
  REMOTE_REPO_PATH=`echo $REPO_PATH | sed -e "s#${BACKUP_DIR}#${BORG_SERVER_DIR}#"`
  ssh -n $BORG_SERVER_USER@$BORG_SERVER -p $BORG_SERVER_PORT "cd $REMOTE_REPO_PATH; echo *"
fi

