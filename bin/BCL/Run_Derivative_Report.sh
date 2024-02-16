#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_Input_Data_Finance_Report.sh 20220831
# Authors imalek
# 20220630 format

EXEC_DATE=$1
RUN_ID=$1

INPUT_DIR=/apps/data/cmrods/input/FIS/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib

Delim=,
Filename=IBGC_EXPOSURE

################ STEP 1: Create Derivate Exposure Report (MARP-651) ####################

PROPERTIES_FILE=Derivative_Exposure_Report_mapping

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
echo "source_folder=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------- STEP 1: Create Derivate Exposure Report (MARP-651)---- --------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -Dods.bcl.mapping.file.GL=$STATIC_DATA/BCL_GL_mapping.csv -Dods.source_system.file=$STATIC_DATA/FinanceReport_sourceSystemMapping.txt -Dods.legal_entity.file=$STATIC_DATA/FinanceReport_legalEntityMapping.txt -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar:$JAR_DIR/ods-inputdata-calculator-1.0-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

################ STEP 2: Apply other overrides/adjustments on Derivate Exposure Report ####################

PROPERTIES_FILE=Derivative_Exposure_Report_adjustments

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
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_Derivative_Exposure_rule_based_overrides_filters.csv" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------- STEP 2: Apply other overrides/adjustments on Derivate Exposure Report --------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

/apps/cmrods/ng/Anaconda3/bin/python3 /apps/cmrods/sacva_apms/bin/python/create_deriv_exposure_extract.py ${OUTPUT_DIR}/Intermediate/overrides/SACCR_derivative_exposure_report_output.csv ${EXEC_DATE} ${OUTPUT_DIR}