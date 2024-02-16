#!/bin/bash
# Run commands :
# source .bashrc
# sh InputData_SACVA.sh 20230430


echo "=========================Date for Execution========================="
ExecDate=$1
echo "ExecDate=$1"

echo "=========================Creating folders========================="
mkdir -p /apps/data/cmrods/group/CMRODS/SACVA/DQ
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_SACVA/config
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_SACVA/properties
mkdir -p /apps/cmrods/sacva_apms/conf/InputData_SACVA/temp


echo "=========================Defining paths========================="
INPUT_DIR=/apps/data/cmrods/sacva/${ExecDate}/input
OUTPUT_DIR=/apps/data/cmrods/group/CMRODS/SACVA/DQ
WORKING_DIRECTORY=/apps/cmrods/sacva_apms/conf/InputData_SACVA
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACVA/properties
TEMP_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACVA/temp
JAR_DIR=/apps/cmrods/sacva_apms/lib
ODS_JAR=${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
PROPERTIES_FILE_DQ=${PROPERTIES_DIR}/SACVA_dq.properties



echo "=========================Defining file names==========================="
FILENM="FX_MARKETDATA,LITES.CVA.HEDGE.BFG,LITES.CVA.SENS.BFG,MAPG_OVRD,SACCR_BWAR,SACCR_EBA-BME,SACCR_OSFI-BFG-CARVEDIN,SACCR_OSFI-BFG-CARVEDOUT,SACCR_OSFI-BFG-NEW,SACCR_OSFI-CHN"


if [ -d "$INPUT_DIR" ]; then
 echo "=========================Itterate all the subfolders and Itterate all the files in each subfolder========================="
 for SUB_FOLDER in "${INPUT_DIR}"/*; do
 	mkdir -p ${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
 	OUTPUT_FOLDER=${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
 	echo "=========================Extract Subfolders $SUB_FOLDER========================="
 	for DATA_FILE in ${FILENM//,/ }; do
		echo "=========================Extract File name $DATA_FILE ========================="
		commandLine="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DYESTERDAY=${ExecDate} -DFILE_NAME_PREFIX=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_FOLDER} -classpath ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_FILE_DQ}"
		echo "=========================commandLine START========================="
		echo "=========================${JAVA_HOME} ${commandLine}========================="
		echo "=========================commandLine END========================="
		java ${commandLine}
		echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
		rm -rf ${TEMP_DIR}/Jython*
	done
 done
else
 echo "Input folder is not exist : ${INPUT_DIR}"
fi

sleep 5

echo ""
echo "============== InputData SACVA DQ Summary Report ============"

sh InputData_SACVA_summary.sh ${ExecDate}

echo "=================Summary Report generated...==================="














