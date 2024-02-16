#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_Input_Data_Finance_Report.sh 20221031
# Authors: imalek

# 20220630 format
EXEC_DATE=$1


INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib



################### STEP 1: Apply transformations on Left Joined Saccr Exposure and Finance Report Marp 399 ###############################

PROPERTIES_FILE=ODS_Joined_finance_report_transformation

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
echo "RUN_ID=${Run_ID}" >> ${PROP_FILE_TMP}
echo "source_folder=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/augmentation" >> ${PROP_FILE_TMP}

echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------- STEP 1: Apply transformations on DQ output Saccr Exposure File (MARP-399)  ----------------------------------------------------- "
echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -Dods.bcl.mapping.file.GL=$STATIC_DATA/BCL_GL_mapping.csv -Dods.source_system.file=$STATIC_DATA/FinanceReport_sourceSystemMapping.txt -Dods.legal_entity.file=$STATIC_DATA/FinanceReport_legalEntityMapping.txt -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar:$JAR_DIR/ods-inputdata-calculator-1.0-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

cp ${OUTPUT_DIR}/Intermediate/augmentation/Joined_Finance_Saccr_Report_transformed.csv ${OUTPUT_DIR}/BCL_Report.csv 