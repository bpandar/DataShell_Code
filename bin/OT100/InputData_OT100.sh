#!/bin/bash
# Run commands :
# sh InputData_OT100.sh 20230430

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
INPUT_DIR=/apps/data/cmrods/output/OSFI_TOP_50
OUTPUT_DIR=/apps/data/cmrods/output/inputData/DQ/OT100
WORKING_DIRECTORY=/apps/cmrods/sacva_apms/conf/InputData_OT100
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_OT100/properties
TEMP_DIR=/apps/cmrods/sacva_apms/conf/InputData_OT100/temp
JAR_DIR=/apps/cmrods/sacva_apms/lib

PROPERTIES_FILE_DQ=${PROPERTIES_DIR}/OT100_DQ.properties


ODS_JAR=${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain
DQ_FUNCTION=rulesBasedFeedValidate

OPT_ARGUMENT="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DYESTERDAY=${ExecDate} -DRUN_ID=${RUN_ID}"
VM_ARGUMENT=" -DINPUT_DIR=${INPUT_DIR} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_DIR}"


echo "=========================Defining file names==========================="
FILENM="PotentialExposure,CCP_UEN_Connection,CMRODS_ExposureData"



echo "=========================Itterate all files in outPut folder========================="
for FILE_NAME in "${INPUT_DIR}"/*; do

  for DATA_FILE in ${FILENM//,/ }; do
    #Matching file names in INPUT folder
      if [[ $FILE_NAME =~ $DATA_FILE ]]; then
          echo "Found Matched File: $FILE_NAME"
          File=$(basename $FILE_NAME)
          FILE_NAME_PREFIX=${File%.*}
          echo "$FILE_NAME_PREFIX"
      
		echo "=========================Extract File name $DATA_FILE ========================="
		#commandLine="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DYESTERDAY=${ExecDate} -DFILE_NAME_PREFIX=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_FOLDER} -classpath ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_FILE_DQ}"
		commandLine="${OPT_ARGUMENT} -DFILE_NAME_PREFIX=${FILE_NAME_PREFIX} -DRULE_KEY=${DATA_FILE} ${VM_ARGUMENT} -classpath ${ODS_JAR} ${MAIN_PROGRAM} ${DQ_FUNCTION} ${PROPERTIES_FILE_DQ}"
		echo "=========================commandLine START========================="
		echo "${JAVA_HOME} ${commandLine}"
		echo "=========================commandLine END==========================="
		java ${commandLine}
		echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
		rm -rf ${TEMP_DIR}/Jython*
	fi

  done

done


#for SUB_FOLDER in "${INPUT_DIR}"/*; do
#mkdir -p ${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
#OUTPUT_FOLDER=${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
#echo "=========================Extract Subfolders $SUB_FOLDER========================="










