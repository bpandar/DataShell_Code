#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_Input_Data_Finance_Report.sh 20220831

# 20220630 format
BUS_DATE=$1
YESTERDAY=20220731

#BASE_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox
#INPUT_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox/input
#OUTPUT_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox/output
#PROPERTIES_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox/properties
#RULES_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox/rules
#STATIC_DATA=/apps/home/sa_cmrods_dev/elviras_sandbox/staticdata
#TEMP_DIR=/apps/home/sa_cmrods_dev/elviras_sandbox/temp

BASE_DIR=/apps/data/cmrods/InputData-pilot/apps/data
INPUT_DIR=/apps/data/cmrods/InputData-pilot/apps/data/input
OUTPUT_DIR=/apps/data/cmrods/InputData-pilot/apps/data/output
PROPERTIES_DIR=/apps/data/cmrods/InputData-pilot/apps/data/properties
RULES_DIR=/apps/data/cmrods/InputData-pilot/apps/data/rules
STATIC_DATA=/apps/data/cmrods/InputData-pilot/apps/data/static
TEMP_DIR=/apps/data/cmrods/InputData-pilot/apps/temp
JAR_DIR=/apps/data/cmrods/InputData-pilot/apps/lib

# STEP 1: Perform DQ on Finance Report (MARP-225)

PROPERTIES_FILE=ods_cm_finance_final_dq

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/odsdbtools_finance_report_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${BUS_DATE}" >> ${PROP_FILE_TMP}
echo "YESTERDAY=${YESTERDAY}" >> ${PROP_FILE_TMP}
echo "base_folder=${BASE_DIR}" >> ${PROP_FILE_TMP}
echo "source_folder=${INPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/DQ" >> ${PROP_FILE_TMP}
echo "ods.feedvalidation.rules.file=${RULES_DIR}/ODS_FinanceReport_DQ_rules.csv" >> ${PROP_FILE_TMP}


echo "----------------------------- STEP 1: Perform DQ on Finance Report (MARP-225) ----------------------------- "
java -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2
sleep 2
sleep 2

# STEP 2: Apply transformations on DQ output Finance Report (MARP-52, MARP-53, MARP-54, MARP-425 and MARP-492)

PROPERTIES_FILE=ODS_finance_report_transformation

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/odsdbtools_finance_report_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "BUS_DT=${BUS_DATE}" >> ${PROP_FILE_TMP}
echo "SOURCE_DIR=${OUTPUT_DIR}/DQ" >> ${PROP_FILE_TMP}
echo "OUTPUT_DIR=${OUTPUT_DIR}/inter" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}

echo "----------------------------- STEP 2: Apply transformations on DQ output Finance Report (MARP-52, MARP-53, MARP-54 and MARP-492)----------------------------- "
#java -cp $BASE_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar;$BASE_DIR/ods-inputdata-calculator-1.0-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROPERTIES_DIR/ODSODS_finance_report_transformation.properties

java -Dods.source_system.file=$STATIC_DATA/sourceSystemMapping.txt -Dods.legal_entity.file=$STATIC_DATA/legalEntityMapping.txt -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar:$JAR_DIR/ods-inputdata-calculator-1.0-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2
sleep 2
sleep 2

# STEP 3: Apply other overrides/transformations on DQ output Finance Report (MARP-425)

PROPERTIES_FILE=finance_report_overrides

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/odsdbtools_finance_report_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "BUS_DT=${BUS_DATE}" >> ${PROP_FILE_TMP}
echo "SOURCE_DIR=${OUTPUT_DIR}/inter" >> ${PROP_FILE_TMP}
echo "HELPER_DIR=${RULES_DIR}" >> ${PROP_FILE_TMP}
echo "OUTPUT_DIR=${OUTPUT_DIR}/OverrideAndFilter" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${RULES_DIR}/bcl_extract_rule_based_overrides.csv" >> ${PROP_FILE_TMP}

echo "----------------------------- STEP 3: Apply other overrides/transformations on DQ output Finance Report (MARP-425) ----------------------------- "
#java -cp $BASE_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROPERTIES_DIR/finance_report_overrides.properties
java -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2
sleep 2
sleep 2

# Rename Output File
mv $OUTPUT_DIR/OverrideAndFilter/cm_finance_${BUS_DATE}_output.csv $OUTPUT_DIR/cm_finance_${BUS_DATE}_transformed.csv