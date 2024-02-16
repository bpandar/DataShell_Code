#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_InputData_Endur_Saccr.sh 20220630

# 20220630 format
ExecDate=$1

INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_Endur_Saccr/properties
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib

if [ -e /apps/data/cmrods/intermediate/ENDUR_RISK_ETL/${ExecDate}/v_endur_mpe_deal.csv ]
then
    cp /apps/data/cmrods/intermediate/ENDUR_RISK_ETL/${ExecDate}/v_endur_mpe_deal.csv ${INPUT_DIR}/v_endur_mpe_deal.csv
    echo "############################"
    echo "Copying v_endur_mpe_deal.csv from Endur Risk ETL directory"
    echo "############################"


else
    date_fmt=`date -d "${ExecDate}" '+%Y-%m-%d'`
    # Download File from SDR, Date 
    #echo "Download File from SDR, Date: $date_fmt "
    #java -Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Endur_Saccr_log.properties -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain runDBAPIAndSaveToFile ${PROPERTIES_DIR}/load_v_endur_mpe_deal.properties api_v_endur_mpe_deal ${INPUT_DIR}/v_endur_mpe_deal.csv "," DATA_DATE=${date_fmt}
    
    echo "############################"
    echo "Get file from FIS Zip"
    echo "############################"

    unzip -j /apps/data/cmrods/group/CMRODS/cmrods_fis_${ExecDate}.zip apps/data/cmrods/intermediate/ENDUR_RISK_ETL/${ExecDate}/v_endur_mpe_deal.csv -d ${INPUT_DIR}

fi

sleep 5

# Perform DQ on L0
echo "############################"
echo "Perform DQ on L0: "
echo "############################"

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Endur_Saccr_log.properties -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate $PROPERTIES_DIR/v_endur_mpe_deal_DQ.properties

# Transform L0
echo "############################"
echo "Transforming L0 v_endur_mpe_deal.csv to L1: "
echo "############################"

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Endur_Saccr_log.properties -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROPERTIES_DIR/transform_v_endur_mpe_deal.properties

sleep 5

# Merge L1 with


day_or_week=`date +%w`
if [ $day_or_week == 1 ] ; then
  look_back=3
else
  look_back=1
fi

yesterday=`date -d "$look_back day ago" +'%Y/%m/%d'`

if [$yesterday == $ExecDate] ; then
     echo "############################"
     echo "Copying Deal_ENDUR_TRANFORM_OUTPUT.csv"
     echo "############################"

     cp /apps/data/cmrods/output/SACCR/Deal_ENDUR_TRANSFORM_OUTPUT.csv ${INPUT_DIR}/Deal_ENDUR_TRANSFORM_OUTPUT.csv
else
     echo "############################"
     echo "Getting Deal_ENDUR_TRANSFORM_OUTPUT.csv from archive zip"
     echo "############################"

     unzip -j /apps/data/cmrods/group/CMRODS/cmrods_fis_${ExecDate}.zip apps/data/cmrods/output/SACCR/Deal_ENDUR_TRANSFORM_OUTPUT.csv -d ${INPUT_DIR}
fi
sleep 4

echo "############################"
echo "Merging L1_v_endur_mpe_deal.csv to with  Deal_ENDUR_TRANFORM_OUTPUT "
echo "############################"

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Endur_Saccr_log.properties -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain merge_csv_using_config $PROPERTIES_DIR/merge_v_endur_mpe_deal.properties

mv /apps/data/cmrods/output/inputData/Intermediate/augmentation/Deal_ENDUR_TRANSFORM_OUTPUT_final.csv /apps/data/cmrods/output/inputData/Deal_ENDUR_TRANSFORM_OUTPUT.csv

echo "FINSHED PROCESS"
