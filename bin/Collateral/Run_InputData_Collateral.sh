#!/bin/bash
# Run commands : sh Run_InputData_Collateral.sh 20220630

source ~/.bashrc
source /apps/cmrods/common/1.4/bin/commonEnvironment.sh


# 20220630 format

JobFqn=$1
ExecDate=$2
JobId=$3
WorkspaceDir=$4
LogDir=$5
StagingDir=$6
OutputDir=$7
JobParamFile=$8


INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
API_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/api
CONF_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/config
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/properties
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/output/inputData/logs/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib

JAR_NAME=OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain;export MAIN_PROGRAM
DBAPI_FUNCTION=runDBAPIAndSaveToFile
OVRD_FUNCTION=rulesBasedFeedFilterAndOverride
CSV_FUNCTION=transform_csv_v2
DQ_FUNCTION=rulesBasedFeedValidate
MERGE_FUNCTION=merge_csv_using_config

INPUTDATA_JAR=ods-inputdata-calculator-1.0-SNAPSHOT.jar

INPUT_FILE=${INPUT_DIR}/V_CALYPSO_MPE_POS_LVL_COL_${ExecDate}.csv

#L0 Properties
ODSDB_PROPERTY=${PROPERTIES_DIR}/odsdbtools_sdr.properties
L0_DQ_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_DQ.properties
L0_OVRD_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L0_overrides.properties
L0_MERGE_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L0_merge.properties

#L1 Properties
L1_AUGMENT_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L1_augmentation.properties
L1_FILTER_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L1_filters.properties
L1_DQ_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L1_DQ.properties
L1_SPLIT_PROPERTY=${PROPERTIES_DIR}/Collateral_file_split.properties

#L2 Properties
L2_OVRD_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L2_overrides.properties
L2_MERGE_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L2_merge.properties
L2_DQ_PROPERTY=${PROPERTIES_DIR}/v_calypso_mpe_pos_L2_DQ.properties
L2_SPLIT_PROPERTY=${PROPERTIES_DIR}/BMO_Collateral_Position_Summary_Bilateral_Report_split.properties

#L2 ARML Properties


LOG4J="-Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Collateral_log.properties"
COL_REF_FILE="-Dods.collateral.reference.file=${STATIC_DATA}/CollateralReferenceMapping.txt"

date_fmt=`date -d "${ExecDate}" '+%Y-%m-%d'`


checkCommandStatus(){

  if [ "$1" != "0" ]; then
     echo "ERROR while executing $2 . Error message=$3 "
     exit 1
  else
     echo "INFO: Successfull $1 "
  fi
}

executeCommand(){
  echo ""
  CMD=$1
  errorMsg=$($CMD)
  exeCode="$?"
  checkCommandStatus $exeCode $CMD $errorMsg
  sleep 2
  rm -rf ${TEMP_DIR}/Jython*
  rm -rf ${TEMP_DIR}/TempPython*
  echo ""
}


#===============Remove existing results files=======================
rm -rf /apps/data/cmrods/input/inputData/V_CALYPSO_MPE_POS_LVL_COL*
rm -rf /apps/data/cmrods/output/inputData/Adaptiv/*.*
rm -rf /apps/data/cmrods/output/inputData/Saccr/*.*
rm -rf /apps/data/cmrods/output/inputData/DQ/BMO_Collateral_Position_Summary_Bilateral_Report*
rm -rf /apps/data/cmrods/output/inputData/DQ/L1_V_CALYPSO_MPE_POS_LVL_COL*
rm -rf /apps/data/cmrods/output/inputData/DQ/V_CALYPSO_MPE_POS_LVL_COL*
rm -rf /apps/data/cmrods/output/inputData/Intermediate/augmentation/BMO_Collateral_Position_Summary_Bilateral_Report*
rm -rf /apps/data/cmrods/output/inputData/Intermediate/augmentation/L1_V_CALYPSO_MPE_POS_LVL_COL*
rm -rf /apps/data/cmrods/output/inputData/Intermediate/filters/L1_V_CALYPSO_MPE_POS_LVL_COL*
rm -rf /apps/data/cmrods/output/inputData/Intermediate/overrides/BMO_Collateral_Position_Summary_Bilateral_Report*
rm -rf /apps/data/cmrods/output/inputData/Intermediate/overrides/L0_V_CALYPSO_MPE_POS_LVL_COL*
#===================================================================
echo ""

# Download File from SDR, Date
SDR_EXTRACT="java ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${DBAPI_FUNCTION} ${ODSDB_PROPERTY} api_V_CALYPSO_MPE_POS_LVL_COL ${INPUT_FILE} | DATA_DATE=${date_fmt}"
echo "############################"
echo "Download File from SDR, Date: $date_fmt "
echo "$SDR_EXTRACT"
echo "############################"
executeCommand "$SDR_EXTRACT"

#Given permission to input file.
chmod 755 -R ${INPUT_FILE}

# Perform DQ on L0
CMD_L0DQ="java -DBUS_DATE=${ExecDate} ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${DQ_FUNCTION} ${L0_DQ_PROPERTY}"
echo "############################"
echo "Perform DQ on L0: "
echo "$CMD_L0DQ"
echo "############################"
executeCommand "$CMD_L0DQ"


# L0 OVERRIDE via Delete and Modify
CMD_L0OVRD="java -DBUS_DT=$ExecDate ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${OVRD_FUNCTION} ${L0_OVRD_PROPERTY}"
echo "############################"
echo "L0 OVERRIDE via Delete and Modify: "
echo "$CMD_L0OVRD"
echo "############################"
executeCommand "$CMD_L0OVRD"


# L0 Merge, L1 created in this step
CMD_L0MERGE="java -DBUS_DT=$ExecDate ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${MERGE_FUNCTION} ${L0_MERGE_PROPERTY}"
echo "############################"
echo "L0 OVERRIDE via Merge/Add: "
echo "$CMD_L0MERGE"
echo "############################"
executeCommand "$CMD_L0MERGE"


# L1 Augmentation
CMD_L1AUGMENT="java -DBUS_DT=$ExecDate ${LOG4J} ${COL_REF_FILE} -cp ${JAR_DIR}/${JAR_NAME}:${JAR_DIR}/${INPUTDATA_JAR} ${MAIN_PROGRAM} ${CSV_FUNCTION} ${L1_AUGMENT_PROPERTY}"
echo "############################"
echo "L1 Augmentation: "
echo "$CMD_L1AUGMENT"
echo "############################"
executeCommand "$CMD_L1AUGMENT"


# L1 Filter:
CMD_L1FILTER="java -DBUS_DT=$ExecDate ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${OVRD_FUNCTION} ${L1_FILTER_PROPERTY}"
echo "############################"
echo "L1 Filter: "
echo "$CMD_L1FILTER"
echo "############################"
executeCommand "$CMD_L1FILTER"


# L1 DQ:
CMD_L1DQ="java -DBUS_DATE=${ExecDate} ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${DQ_FUNCTION} ${L1_DQ_PROPERTY}"
echo "############################"
echo "L1 DQ: "
echo "$CMD_L1DQ"
echo "############################"
executeCommand "$CMD_L1DQ"


# Splitting into Two Files: CMRODS Standard Collateral & SACCR Billateral
CMD_L1SPLIT="java -DBUS_DT=${ExecDate} ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${CSV_FUNCTION} ${L1_SPLIT_PROPERTY}"
echo "############################"
echo "Splitting into Two Files: CMRODS Standard Collateral & SACCR Billateral: "
echo "$CMD_L1SPLIT"
echo "############################"
executeCommand "$CMD_L1SPLIT"


mv "/apps/data/cmrods/output/inputData/Intermediate/augmentation/Standard Collateral File.txt" "/apps/data/cmrods/output/inputData/Standard Collateral File.txt"

# L2 OVERRIDE via Delete and Modify, SACCR Only
CMD_L2OVRD="java -DBUS_DT=${ExecDate} ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${OVRD_FUNCTION} ${L2_OVRD_PROPERTY}"
echo "############################"
echo "L2 OVERRIDE via Delete and Modify, SACCR Only"
echo "$CMD_L2OVRD"
echo "############################"
executeCommand "$CMD_L2OVRD"


# L2 OVERRIDE via Add/Merge, SACCR Only
CMD_L2MERGE="java -DBUS_DT=$ExecDate ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${MERGE_FUNCTION} ${L2_MERGE_PROPERTY}"
echo "############################"
echo "L2 OVERRIDE via Add/Merge, SACCR Only"
echo "$CMD_L2MERGE"
echo "############################"
executeCommand "$CMD_L2MERGE"


# L2 DQ:
CMD_L2DQ="java -DBUS_DATE=${ExecDate} ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${DQ_FUNCTION} ${L2_DQ_PROPERTY}"
echo "############################"
echo "L2 DQ:"
echo "$CMD_L2DQ"
echo "############################"
executeCommand "$CMD_L2DQ"


mkdir -p ${OUTPUT_DIR}/Saccr
mkdir -p ${OUTPUT_DIR}/Adaptiv
chmod -R 777 ${OUTPUT_DIR}/Saccr
chmod -R 777 ${OUTPUT_DIR}/Adaptiv

# Create Calypso Header
CMD_L2SPLIT="java -DBUS_DT=$ExecDate ${LOG4J} -cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM} ${CSV_FUNCTION} ${L2_SPLIT_PROPERTY}"
echo "############################"
echo "Create Calypso Header:"
echo "$CMD_L2SPLIT"
echo "############################"
executeCommand "$CMD_L2SPLIT"

echo "INFO: Permission change to 755 for folders post execution completed.... "
chmod -R 755 ${OUTPUT_DIR}/
chmod -R 755 ${OUTPUT_DIR}/DQ/
chmod -R 755 ${OUTPUT_DIR}/Saccr/*.*
chmod -R 755 ${OUTPUT_DIR}/Adaptiv/*.*

#Get backup on input and output files
echo " =============Backup Result files ============================= "
mkdir -p /apps/data/cmrods-bak/input_data/$ExecDate
mkdir -p /apps/data/cmrods-bak/input_data/$ExecDate/input

cp -r /apps/data/cmrods/input/inputData/V_CALYPSO_MPE_POS_LVL_COL_$ExecDate.csv /apps/data/cmrods-bak/input_data/$ExecDate/input/

cp -r /apps/data/cmrods/output/inputData/* /apps/data/cmrods-bak/input_data/$ExecDate/
cp -r /apps/data/cmrods/input/inputData/* /apps/data/cmrods-bak/input_data/$ExecDate/input/

chmod -R 755 /apps/data/cmrods-bak/input_data/$ExecDate/

echo "Collateral Task Completed...."