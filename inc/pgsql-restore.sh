#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Validate arguments

if [ -z $1 ]; then
  echo "!!!!! Database not entered. Aborting..."
  exit 1
fi
if [ -z $2 ]; then
  echo "!!!!! Database file not entered. Aborting..."
  exit 1
fi

DB=$1
DB_FILE=$2

echo "-- Importing $DB_FILE to $DB database"
. $CURRENT_DIR/pgsql-setup.sh
if [[ $DB_FILE = *".gz"* ]]; then
  gunzip < $DB_FILE | psql -h localhost -U $USER $DB
else
  psql -h localhost -U $USER $DB < $DB_FILE
fi
