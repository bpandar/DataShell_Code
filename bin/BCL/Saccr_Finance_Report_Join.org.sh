#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Saccr_Finance_Report_Join.sh 20220831 5713 20221031
# Authors imalek
# 20220630 format


EXEC_DATE=$1
RUN_ID=$2
FINANCE_DATE=$3


INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib

################ STEP 1: Left Join of Saccr Report and Finance Report File (MARP-196) ####################

PROPERTIES_FILE=ODS_Joined_finance_report

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "RUN_ID=${RUN_ID}" >> ${PROP_FILE_TMP}
echo "FINANCE_DATE=${FINANCE_DATE}" >> ${PROP_FILE_TMP}
echo "BASE_DIR=${PROPERTIES_DIR}" >> ${PROP_FILE_TMP}
echo "INTER_DIR=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}
echo "source_folder=${OUTPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------ STEP 1: Left Join of Saccr Report and Finance Report File (MARP-196) ---------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain simple_spark_etl $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2
