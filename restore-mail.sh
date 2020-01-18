#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a mail domain from incremental backup.
USAGE="restore-mail.sh 2018-03-25 user domain.com"

# Assign arguments
TIME=$1
USER=$2
DOMAIN=$3

# Set script start time
START_TIME=`date +%s`

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and mail domain."
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER" ]; then
  echo "!!!!! User $USER does not exist"
  echo "---"
  echo "Available users:"
  ls $HOME_DIR
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER/mail/$DOMAIN" ]; then
  echo "!!!!! The mail domain $DOMAIN does not exist under user $USER."
  echo "---"
  echo "User $USER has the following available mail domains:"
  ls $HOME_DIR/$USER/mail
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if ! $CURRENT_DIR/inc/borg_list.sh $USER_REPO | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  $CURRENT_DIR/inc/borg_list.sh $USER_REPO
  echo "Usage example:"
  echo $USAGE
  exit 1
fi


echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH RESTORE ##########"

read -p "Are you sure you want to restore mail domain $DOMAIN owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

# Set dir paths
DOMAIN_DIR=$HOME_DIR/$USER/mail/$DOMAIN
BACKUP_DOMAIN_DIR="${DOMAIN_DIR:1}" # Paths inside borg repo are relative

if ! $CURRENT_DIR/inc/borg_list.sh $USER_REPO::$TIME | grep -q $BACKUP_DOMAIN_DIR; then
  echo "!!!!! $DOMAIN mail domain is not present in backup archive $TIME. Aborting..."
  exit 1
fi
echo "-- Restoring mail domain files from backup $USER_REPO::$TIME to $BACKUP_DOMAIN_DIR"
cd /
rm -fr $BACKUP_DOMAIN_DIR
$CURRENT_DIR/inc/borg_extract.sh $USER_REPO $TIME $BACKUP_DOMAIN_DIR

echo "-- Fixing permissions"
chown -R $USER:mail $DOMAIN_DIR/

echo
echo "$(date +'%F %T') ########## MAIL DOMAIN $DOMAIN OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
