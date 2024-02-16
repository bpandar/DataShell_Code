#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_BCL_Report.sh 20230105
# Authors imalek,ekonovalov
# 20220630 format
EXEC_DATE=$1

INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib


################ STEP 1: Apply other overrides/adjustments on BCL Report (MARP-561) ####################

PROPERTIES_FILE=BCL_Report_adjustments

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
echo "source_folder=${OUTPUT_DIR}/" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/overrides" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_BCL_rule_based_overrides_filters.csv" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------- STEP 1: Apply other overrides/adjustments on BCL Report (MARP-561) --------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2




##################### STEP 2: Perform DQ on Finance Report (MARP-225)########################

PROPERTIES_FILE=BCL_Report_DQ
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"

echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`

cp ${PROP_FILE} ${PROP_FILE_TMP}

echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "prev=${PREV_DIR}" >> ${PROP_FILE_TMP}
echo "source_folder=${INPUT_DIR}/Intermediate/overrides/" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/DQ" >> ${PROP_FILE_TMP}
echo "ods.feedvalidation.sourcefile.name=${OUTPUT_DIR}/Intermediate/overrides/BCL_Report_output.csv" >> ${PROP_FILE_TMP}
echo "ods.feedvalidation.rules.file=${PROPERTIES_DIR}/config/ODS_BCL_DQ_rules.csv" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------- STEP 2: Perform DQ on BCL Report (MARP-508) ------------------------------------------------ "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROP_FILE_TMP}

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

# Change input file to orig, and copy output to input location
mv ${OUTPUT_DIR}/BCL_Report.csv ${OUTPUT_DIR}/BCL_Report_orig.csv

# Move New DQ output to input
mv ${OUTPUT_DIR}/DQ/BCL_Report.output.csv ${OUTPUT_DIR}/BCL_Report.csv 

sleep 2

# Formatting via Python

/apps/cmrods/ng/Anaconda3/bin/python3 /apps/cmrods/sacva_apms/bin/python/create_bcl_report.py ${OUTPUT_DIR}/BCL_Report.csv ${OUTPUT_DIR}/B3R_IBG_CAP_MKTS_EXP.DAT ${EXEC_DATE}
