#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a database from incremental backup.
USAGE="restore-db.sh 2018-03-25 user database"

# Assign arguments
TIME=$1
USER=$2
DB=$3

# Set script start time
START_TIME=`date +%s`

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

# Set user repository
USER_REPO=$REPO_DB_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and database"
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

if [[ $(v-list-databases $USER | grep -w '\(my\|pg\)sql' | cut -d " " -f1 | grep "$DB") != "$DB" ]]; then
  echo "!!!!! Database $DB not found under selected user."
  echo "---"
  echo "User $USER has the following databases:"
  v-list-databases $USER | grep -w '\(my\|pg\)sql' | cut -d " " -f1
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if ! $CURRENT_DIR/inc/borg_list.sh $USER_REPO | grep -q "$DB-$TIME"; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  $CURRENT_DIR/inc/borg_list.sh $USER_REPO | grep $DB
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH DATABASE RESTORE ##########"
echo
read -p "Are you sure you want to restore database $DB owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

echo "-- Restoring database $DB from backup $USER_REPO::$TIME"

if [[ $(v-list-databases $USER | grep -w mysql | cut -d " " -f1 | grep "$DB") == "$DB" ]]; then
  echo "-- Removing database $DB"
  mysqladmin -f drop $DB

  echo "-- Creating database $DB"
  mysql -e "CREATE DATABASE IF NOT EXISTS $DB"

  echo "-- Importing $TIME to $DB database"
  $CURRENT_DIR/inc/borg_extract_stdout.sh $USER_REPO "$DB-$TIME" | mysql $DB
fi
if [[ $(v-list-databases $USER | grep -w pgsql | cut -d " " -f1 | grep "$DB") == "$DB" ]]; then
  echo "-- Removing database $DB"
  echo "DROP DATABASE $DB" | psql -U postgres

  echo "-- Creating database $DB"
  echo "CREATE DATABASE $DB" | psql -U postgres

  echo "-- Importing $TIME to $DB database"
  $CURRENT_DIR/inc/borg_extract_stdout.sh $USER_REPO "$DB-$TIME" | psql -U postgres $DB
fi

echo
echo "$(date +'%F %T') ########## DATABASE $DB OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
