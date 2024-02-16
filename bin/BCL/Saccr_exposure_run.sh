#!/bin/bash
# Run commands :
# source ~/.bashrc

# 20220630 format
EXEC_DATE=$1
Run_ID=$2

INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib

# 

##################### STEP 1: Perform DQ on SACCR Exposure file (MARP-405)########################
cd $INPUT_DIR
FILE_NAME=`ls saccr_report_OSFI-BFG-NEW_*_${EXEC_DATE}_${Run_ID}.csv | tail -1`
#FLAG=`echo file |cut -d'_' -f4 | cut -d'.' -f1`   # Reading Daily or Monthly flag from file name
FILE_NAME_PREFIX=${FILE_NAME%.*}

PROPERTIES_FILE=ODS_Saccr_exposure_DQ
PROP_FILE_TMP="${PROPERTIES_DIR}/saccr_report_OSFI_BFG_NEW_temp.properties"

echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`

cp ${PROP_FILE} ${PROP_FILE_TMP}

echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "FILE_NAME_PREFIX=${FILE_NAME_PREFIX}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "RUN_ID=${Run_ID}" >> ${PROP_FILE_TMP}
echo "prev=${PREV_DIR}" >> ${PROP_FILE_TMP}
echo "source_folder=${INPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/DQ" >> ${PROP_FILE_TMP}
echo "ods.feedvalidation.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_DQ_rules.csv" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------Running DQ on ${FILE_NAME} (MARP-405) ------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROP_FILE_TMP}

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

FILE=${OUTPUT_DIR}/DQ/${FILE_NAME_PREFIX}.output.csv
if [ -f "$FILE" ]; then
    echo "$FILE exists. Can proceed to STEP 2 -----------------------------!"
else 
    echo "$FILE does not exist. Stop entire job -----------------------------!"
	exit 1
fi

# Change input file to orig, and copy output to input location
mv ${INPUT_DIR}/${FILE_NAME} ${INPUT_DIR}/${FILE_NAME_PREFIX}_orig.csv

# Copy New DQ output to prev
cp ${OUTPUT_DIR}/DQ/${FILE_NAME_PREFIX}.output.csv ${PREV_DIR}/saccr_report_OSFI-BFG-NEW.csv

mv ${OUTPUT_DIR}/DQ/${FILE_NAME_PREFIX}.output.csv ${INPUT_DIR}/${FILE_NAME_PREFIX}.csv


################### STEP 2: Apply transformations on DQ output SACCR Exposure File Marp 533 ###############################

PROPERTIES_FILE=saccr_exposure_augmentation

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"

echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"

PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`

cp ${PROP_FILE} ${PROP_FILE_TMP}

echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "FILE_NAME_PREFIX=${FILE_NAME_PREFIX}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "RUN_ID=${Run_ID}" >> ${PROP_FILE_TMP}
echo "source_folder=${INPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/augmentation" >> ${PROP_FILE_TMP}

echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------- STEP 2: Apply transformations on DQ output Saccr Exposure File (MARP-533)  ----------------------------------------------------- "
echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2


################ STEP 3: Apply other overrides/transformations on DQ output Saccr Exposure File (MARP-425) ####################

PROPERTIES_FILE=saccr_exposure_overrides

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "FILE_NAME_PREFIX=${FILE_NAME_PREFIX}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "RUN_ID=${Run_ID}" >> ${PROP_FILE_TMP}
echo "source_folder=${OUTPUT_DIR}/Intermediate/augmentation" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/overrides" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_rule_based_overrides.csv" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------- STEP 3: Apply other overrides/transformations on DQ output Saccr Exposure File (MARP-425, MARP-535) ------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

# Rename Output File
mv ${OUTPUT_DIR}/Intermediate/overrides/${FILE_NAME_PREFIX}_output.csv ${OUTPUT_DIR}/Intermediate/overrides/${FILE_NAME_PREFIX}_transformed.csv


################ STEP 4: Apply Filter on transformed output Saccr Exposure File (MARP-478) ####################

PROPERTIES_FILE=saccr_exposure_filters

#-------------------------------------
#Append property file
#------------------------------------
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"
echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`
cp ${PROP_FILE} ${PROP_FILE_TMP}
echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "FILE_NAME_PREFIX=${FILE_NAME_PREFIX}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "RUN_ID=${Run_ID}" >> ${PROP_FILE_TMP}
echo "source_folder=${OUTPUT_DIR}/Intermediate/overrides" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/filters" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_Filters.csv" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------- STEP 4: Apply Filter on transformed output Saccr Exposure File (MARP-478)  -------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties  -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

# Move Output File
mv ${OUTPUT_DIR}/Intermediate/filters/${FILE_NAME_PREFIX}_L1.csv ${OUTPUT_DIR}/${FILE_NAME_PREFIX}_L1.csv

# Output folder permission change
chmod 755 -R ${OUTPUT_DIR}/

