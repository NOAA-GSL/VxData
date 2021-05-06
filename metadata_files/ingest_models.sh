#!/bin/sh
if [ $# -ne 1 ]; then
  echo "Usage $0 credentials-file"
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "$1 is not a file - exiting"
  exit 1
fi
credentials_file=$1

host=`grep cb_host ${credentials_file} | awk '{print $2}'`
user=`grep cb_user ${credentials_file} | awk '{print $2}'`
pwd=`grep cb_password ${credentials_file} | awk '{print $2}'`

cbimport json --cluster couchbase://${host} --bucket mdata --username ${user} --password ${pwd} --format list --generate-key %id% --dataset file:///${HOME}/VxData/MatsMetadataAndIndexes/metadata_files/ingest_models.json
