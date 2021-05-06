#!/bin/sh
if [ $# -ne 1 ]; then
  echo "Usage $0 server"
  exit 1
fi
server=$1
curl -XPUT -H "Content-Type: application/json" \
-u avid http://${server}:8094/api/index/station_geo -d \
'{
  "type": "fulltext-index",
  "name": "station_geo",
  "sourceType": "couchbase",
  "sourceName": "mdata",
  "planParams": {
    "maxPartitionsPerPIndex": 16,
    "indexPartitions": 4
  },
  "params": {
    "doc_config": {
      "docid_prefix_delim": "",
      "docid_regexp": "^MD:V01:METAR:station",
      "mode": "docid_regexp",
      "type_field": "type"
    },
    "mapping": {
      "analysis": {},
      "default_analyzer": "standard",
      "default_datetime_parser": "dateTimeOptional",
      "default_field": "_all",
      "default_mapping": {
        "dynamic": true,
        "enabled": false
      },
      "default_type": "_default",
      "docvalues_dynamic": true,
      "index_dynamic": true,
      "store_dynamic": false,
      "type_field": "_type",
      "types": {
        "MD:V01:METAR:station": {
          "dynamic": false,
          "enabled": true,
          "properties": {
            "description": {
              "dynamic": false,
              "enabled": true,
              "fields": [
                {
                  "analyzer": "keyword",
                  "docvalues": true,
                  "include_in_all": true,
                  "include_term_vectors": true,
                  "index": true,
                  "name": "description",
                  "store": true,
                  "type": "text"
                }
              ]
            },
            "elevation": {
              "dynamic": false,
              "enabled": true,
              "fields": [
                {
                  "docvalues": true,
                  "include_in_all": true,
                  "include_term_vectors": true,
                  "index": true,
                  "name": "elevation",
                  "store": true,
                  "type": "number"
                }
              ]
            },
            "geo": {
              "dynamic": false,
              "enabled": true,
              "fields": [
                {
                  "docvalues": true,
                  "include_in_all": true,
                  "include_term_vectors": true,
                  "index": true,
                  "name": "geo",
                  "store": true,
                  "type": "geopoint"
                }
              ]
            },
            "name": {
              "dynamic": false,
              "enabled": true,
              "fields": [
                {
                  "docvalues": true,
                  "include_in_all": true,
                  "include_term_vectors": true,
                  "index": true,
                  "name": "name",
                  "store": true,
                  "type": "text"
                }
              ]
            }
          }
        }
      }
    },
    "store": {
      "indexType": "scorch"
    }
  },
  "sourceParams": {}
}'