#!/bin/bash

pgsqlstr=`cat ${VESTA_DIR}/conf/pgsql.conf`
eval $pgsqlstr
export PGPASSWORD=$PASSWORD
