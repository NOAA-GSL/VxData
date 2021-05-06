#!/bin/sh
if [ $# -ne 1 ]; then
  echo "Usage $0 credentials-file"
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "$1 is not a valid file - exiting"
  exit 1
fi

credentials=$1
m_host=$(grep mysql_host ${credentials} | awk '{print $2}')
m_user=$(grep mysql_user ${credentials} | awk '{print $2}')
m_password=$(grep mysql_password ${credentials} | awk '{print $2}')
cb_host=$(grep cb_host ${credentials} | awk '{print $2}')
cb_user=$(grep cb_user ${credentials} | awk '{print $2}')
cb_pwd=$(grep cb_password ${credentials} | awk '{print $2}')
cred="${cb_user}:${cb_pwd}"

for model in HRRR HRRR_OPS RAP_OPS RRFS_dev1
  do
  cmd=$(cat <<-%EODupdatemetadata
    UPDATE mdata
    SET thresholds = (
        SELECT DISTINCT RAW d_thresholds
        FROM (
            SELECT OBJECT_NAMES(object_names_t.data) AS thresholds
            FROM mdata AS object_names_t
            WHERE object_names_t.type='DD'
                AND object_names_t.docType='CTC'
                AND object_names_t.subset='METAR'
                AND object_names_t.version='V01'
                AND object_names_t.model='${model}') AS d
        UNNEST d.thresholds AS d_thresholds),
    fcstLens=(
    SELECT DISTINCT VALUE fl.fcstLen
    FROM mdata as fl
    WHERE fl.type='DD'
        AND fl.docType='CTC'
        AND fl.subset='METAR'
        AND fl.version='V01'
        AND fl.model='${model}'
        ORDER BY fl.fcstLen),
    regions=(
    SELECT DISTINCT VALUE rg.region
    FROM mdata as rg
    WHERE rg.type='DD'
        AND rg.docType='CTC'
        AND rg.subset='METAR'
        AND rg.version='V01'
        AND rg.model='${model}'
    ORDER BY r.mdata.region),
    displayText=(SELECT RAW m.standardizedModelList.${model}
        FROM mdata AS m
        USE KEYS "MD:matsAux:COMMON:V01")[0],
    displayCategory=(select raw 1)[0],
    displayOrder=(
        WITH k AS
            ( SELECT RAW m.standardizedModelList.${model}
            FROM mdata AS m
            USE KEYS "MD:matsAux:COMMON:V01" )
        SELECT RAW m.primaryModelOrders.[k[0]].m_order
        FROM mdata AS m
        USE KEYS "MD:matsAux:COMMON:V01")[0],
    mindate=(
        SELECT RAW MIN(mt.fcstValidEpoch) AS mintime
        FROM mdata AS mt
        WHERE mt.type='DD'
            AND mt.docType='CTC'
            AND mt.subset='METAR'
            AND mt.version='V01'
            AND mt.model='${model}')[0],
    maxdate=(
        SELECT RAW MAX(mat.fcstValidEpoch) AS maxtime
        FROM mdata AS mat
        WHERE mat.type='DD'
            AND mat.docType='CTC'
            AND mat.subset='METAR'
            AND mat.version='V01'
            AND mat.model='${model}')[0],
    numrecs=(
        SELECT RAW COUNT(META().id)
        FROM mdata AS n
        WHERE n.type='DD'
            AND n.docType='CTC'
            AND n.subset='METAR'
            AND n.version='V01'
            AND n.model='${model}')[0],
    updated=(SELECT RAW FLOOR(NOW_MILLIS()/1000))[0]
    WHERE type='MD'
        AND docType='matsGui'
        AND subset='COMMON'
        AND version='V01'
        AND app='cb-ceiling'
        AND META().id='MD:matsGui:cb-ceiling:${model}:COMMON:V01';
%EODupdatemetadata
)

  echo "curl -s -u ${cred} http://${cb_host}:8093/query/service -d \"statement=${cmd}\""
  curl -s -u ${cred} http://${cb_host}:8093/query/service -d "statement=${cmd}"
  echo "---------------"
done
