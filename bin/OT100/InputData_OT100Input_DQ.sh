#!/bin/bash
# Run commands :
# sh InputData_OT100input_DQ.sh 20230430

source ~/.bashrc

echo "=========================Date for Execution========================="
JobFqn=$1
ExecDate=$2
JobId=$3
WorkspaceDir=$4
LogDir=$5
StagingDir=$6
OutputDir=$7
JobParamFile=$8

echo "ExecDate=$2"

echo "=========================Creating folders========================="
mkdir -p /apps/data/cmrods/output/inputData/DQ/OT100
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_OT100/config
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_OT100/properties
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_OT100/temp


echo "=========================Defining paths========================="
INPUT_DIR=/apps/data/cmrods/input/OSFI_TOP_50
OUTPUT_DIR=/apps/data/cmrods/output/inputData/DQ/OT100
WORKING_DIRECTORY=/apps/cmrods/sacva_apms/conf/InputData_OT100
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_OT100/properties
TEMP_DIR=/apps/cmrods/sacva_apms/conf/InputData_OT100/temp
JAR_DIR=/apps/cmrods/sacva_apms/lib

PROPERTIES_FILE_DQ=${PROPERTIES_DIR}/OT100_DQ.properties


ODS_JAR=${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain
DQ_FUNCTION=rulesBasedFeedValidate

OPT_ARGUMENT="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DYESTERDAY=${ExecDate} -DRUN_ID=${RUN_ID} -DWORKING_DIRECTORY=${WORKING_DIRECTORY}"

echo "=========================Defining file names==========================="
FILENM="baskets.sql,Calypso_cds.sql,eq_der_gmi.sql,eq_der_imagine.sql,eq_der_swapone.sql,eq_der_tradereh1.sql,eq_der_tradereh2.sql,calypsoTlock.sql,gfi.sql,saccr_override.sql,v_mtm_agg_enhanced.sql"



echo "=========================Itterate all files in outPut folder========================="
rm -r ${TEMP_DIR}/*
rm -r ${OUTPUT_DIR}/${ExecDate}/input/*

for SUB_FOLDER in "${INPUT_DIR}"/*; do
  #SUB_FOLDER_NAME=$(basename "$SUB_FOLDER")
  if [[ -d "$SUB_FOLDER" ]]; then
    mkdir -p ${OUTPUT_DIR}/${ExecDate}/input/$(basename "$SUB_FOLDER")
    OUTPUT_FOLDER=${OUTPUT_DIR}/${ExecDate}/input/$(basename "$SUB_FOLDER")
  fi
  
  echo "=========================Extract Subfolders $SUB_FOLDER========================="
  for DATA_FILE in ${FILENM//,/ }; do
    #Matching file names in INPUT folder
    echo "$SUB_FOLDER/$DATA_FILE"

      if [[ -f $SUB_FOLDER/$DATA_FILE.csv ]]; then
          echo "Found Matched File: $SUB_FOLDER/$DATA_FILE"
          File=$(basename $SUB_FOLDER/$DATA_FILE.csv)
          FILE_NAME_PREFIX=${File%.*}
          echo "$FILE_NAME_PREFIX"
      
		echo "=========================Extract File name $DATA_FILE ========================="
		#commandLine="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DYESTERDAY=${ExecDate} -DFILE_NAME_PREFIX=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_FOLDER} -classpath ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_FILE_DQ}"
		commandLine="${OPT_ARGUMENT} -DFILE_NAME_PREFIX=${FILE_NAME_PREFIX} -DRULE_KEY=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER}  -DOUTPUT_DIR=${OUTPUT_FOLDER} -classpath ${ODS_JAR} ${MAIN_PROGRAM} ${DQ_FUNCTION} ${PROPERTIES_FILE_DQ}"
		echo "=========================commandLine START========================="
		echo "${JAVA_HOME} ${commandLine}"
		echo "=========================commandLine END==========================="
		java ${commandLine}
		echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
		rm -rf ${TEMP_DIR}/Jython*

		OUTFILE=${OUTPUT_FOLDER}/${FILE_NAME_PREFIX}.output.csv
    if [ -f "$OUTFILE" ]; then
        echo "$OUTFILE exists.
        Can proceed to STEP 2 -----------------------------!"
    else
        echo "$OUTFILE does not exist.
        Stop entire job -----------------------------!"
      	exit 1
    fi

	fi
  done

done







