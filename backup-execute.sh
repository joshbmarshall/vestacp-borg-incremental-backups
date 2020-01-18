#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

### Variables ###

# Set script start time
START_TIME=`date +%s`

# Exclude is a temp file that stores dirs that we dont want to backup
EXCLUDE=$CURRENT_DIR/exclude

# Set backup archive name to current day
ARCHIVE=$(date +'%F')

### Start processing ###

# Dump databases to borg
$CURRENT_DIR/dump-databases.sh $ARCHIVE

echo
echo "$(date +'%F %T') #################### USER PROCESSING ####################"
echo

# Prepare excluded users array
IFS=', ' read -r -a EXCLUDED_USERS <<< "$EXCLUDED_USERS"

COUNT=0

for USER_DIR in $HOME_DIR/* ; do
  if [ -d "$USER_DIR" ]; then
    USER=$(basename $USER_DIR)

    echo "$(date +'%F %T') ########## Processing user $USER ##########"
    echo

    # Check if the user is in the excluded users list and skip if true
    for EXCLUDED_USER in "${EXCLUDED_USERS[@]}"
    do
      if [ "$USER" == "$EXCLUDED_USER" ]; then
        echo "!! User $USER is in the excluded users list, the backup will not run"
        echo
        continue 2
      fi
    done

    # Clean exclusion list
    if [ -f "$EXCLUDE" ]; then
      rm $EXCLUDE
    fi

    # Build exclusion list
    # No need for drush backups, tmp folder and .cache dir
    echo "$USER_DIR/drush-backups" >> $EXCLUDE
    echo "$USER_DIR/tmp" >> $EXCLUDE
    echo "$USER_DIR/.cache" >> $EXCLUDE

    # Exclude drupal and wordpress cache dirs
    for WEB_DIR in $USER_DIR/web/* ; do
      if [ -d "$WEB_DIR/$PUBLIC_HTML_DIR_NAME" ]; then
        find $WEB_DIR/$PUBLIC_HTML_DIR_NAME -maxdepth 2 -type d -name "cache" | grep "wp-content/cache" >> $EXCLUDE
        if [ -d "$WEB_DIR/$PUBLIC_HTML_DIR_NAME/cache" ]; then
          echo "$WEB_DIR/$PUBLIC_HTML_DIR_NAME/cache" >> $EXCLUDE
        fi
      fi
    done

    # Set user borg repo path
    USER_REPO=$REPO_USERS_DIR/$USER

    # Check if repo was initialized, if its not we perform borg init
    $CURRENT_DIR/inc/borg_init.sh $USER_REPO

    echo "-- Creating new backup archive $USER_REPO::$ARCHIVE"
    $CURRENT_DIR/inc/borg_create.sh $USER_REPO $ARCHIVE "$USER_DIR --exclude-from=$EXCLUDE"
    echo "-- Cleaning old backup archives"
    $CURRENT_DIR/inc/borg_prune.sh $USER_REPO

    let COUNT++
    echo
  fi
done

echo "$(date +'%F %T') ########## $COUNT USERS PROCESSED ##########"

# We dont need exclude list anymore
if [ -f "$EXCLUDE" ]; then
  rm $EXCLUDE
fi

echo
echo
echo "$(date +'%F %T') #################### SERVER LEVEL BACKUPS #####################"

echo "$(date +'%F %T') ########## Executing scripts backup: $SCRIPTS_DIR ##########"
$CURRENT_DIR/inc/borg_init.sh $REPO_SCRIPTS
echo "-- Creating new backup archive $REPO_SCRIPTS::$ARCHIVE"
$CURRENT_DIR/inc/borg_create.sh $REPO_SCRIPTS $ARCHIVE $SCRIPTS_DIR
echo "-- Cleaning old backup archives"
$CURRENT_DIR/inc/borg_prune.sh $REPO_SCRIPTS
echo

echo "$(date +'%F %T') ########## Executing server config backup: $ETC_DIR ##########"
$CURRENT_DIR/inc/borg_init.sh $REPO_ETC
echo "-- Creating new backup archive $REPO_ETC::$ARCHIVE"
$CURRENT_DIR/inc/borg_create.sh $REPO_ETC $ARCHIVE $ETC_DIR
echo "-- Cleaning old backup archives"
$CURRENT_DIR/inc/borg_prune.sh $REPO_ETC
echo

echo "$(date +'%F %T') ########## Executing Vesta dir backup: $VESTA_DIR ##########"
$CURRENT_DIR/inc/borg_init.sh $REPO_VESTA
echo "-- Creating new backup archive $REPO_VESTA::$ARCHIVE"
$CURRENT_DIR/inc/borg_create.sh $REPO_VESTA $ARCHIVE $VESTA_DIR
echo "-- Cleaning old backup archives"
$CURRENT_DIR/inc/borg_prune.sh $REPO_VESTA
echo

if [[ ! -z "$REMOTE_BACKUP_SERVER" && ! -z "$REMOTE_BACKUP_SERVER_DIR" ]]; then
  echo
  echo "$(date +'%F %T') #################### SYNC BACKUP DIR $BACKUP_DIR TO REMOTE SERVER: $REMOTE_BACKUP_SERVER:$REMOTE_BACKUP_SERVER_DIR ####################"
  rsync -za --delete --stats $BACKUP_DIR/ $REMOTE_BACKUP_SERVER_USER@$REMOTE_BACKUP_SERVER:$REMOTE_BACKUP_SERVER_DIR/
fi

echo
echo "$(date +'%F %T') #################### BACKUP COMPLETED ####################"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo
