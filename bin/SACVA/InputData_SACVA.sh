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
mkdir -p /apps/data/cmrods/group/CMRODS/SACVA/DQ/logs

echo "=========================Defining paths========================="
INPUT_DIR=/apps/data/cmrods/sacva/${ExecDate}/input
OUTPUT_DIR=/apps/data/cmrods/group/CMRODS/SACVA/DQ
WORKING_DIRECTORY=/apps/cmrods/sacva_apms/conf/InputData_SACVA
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACVA/properties
PREV_DIR=/apps/data/cmrods/prev
TEMP_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACVA/temp
JAR_DIR=/apps/cmrods/sacva_apms/lib

ODS_JAR=${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain
DQ_FUNCTION=rulesBasedFeedValidate
FILTER_OVRD_FUNCTION=rulesBasedFeedFilterAndOverride

PROPERTIES_FILE_DQ=${PROPERTIES_DIR}/SACVA_dq.properties
PROPERTIES_FILTER=${PROPERTIES_DIR}/SACVA_filter.properties
PROPERTIES_PREDEFINED_LIST=${PROPERTIES_DIR}/SACVA_PredefinedList_DQ.properties


LOG4J="-Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_SACVA_log.properties"
USER_ARGUM=" -DBUS_DATE=${ExecDate} ${LOG4J} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} "; export USER_ARGUM
OPTS_ARGUM="-classpath ${ODS_JAR} ${MAIN_PROGRAM}"; export OPTS_ARGUM


rm -rf ${OUTPUT_DIR}/${ExecDate}/output/*

echo "=========================Defining file names==========================="
FILENM="FX_MARKETDATA,LITES.CVA.HEDGE.BFG,LITES.CVA.SENS.BFG,MAPG_OVRD,SACCR_BWAR,SACCR_EBA-BME,SACCR_OSFI-BFG-CARVEDIN,SACCR_OSFI-BFG-CARVEDOUT,SACCR_OSFI-BFG-NEW,SACCR_OSFI-CHN"

#FILENM="FX_MARKETDATA,LITES.CVA.HEDGE.BFG,LITES.CVA.SENS.BFG"


if [ -d "$INPUT_DIR" ]; then
 echo "=========================Itterate all the subfolders and Itterate all the files in each subfolder========================="
 for SUB_FOLDER in "${INPUT_DIR}"/*; do
 	mkdir -p ${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
 	OUTPUT_FOLDER=${OUTPUT_DIR}/${ExecDate}/output/$(basename "$SUB_FOLDER")
 	echo "=========================Extract Subfolders $SUB_FOLDER========================="

	for DATA_FILE in ${FILENM//,/ }; do

	if [[ -f ${SUB_FOLDER}/${DATA_FILE}_${ExecDate}.csv ]]; then

		# cp ${SUB_FOLDER}/${DATA_FILE}_${ExecDate}.csv ${PREV_DIR}/${DATA_FILE}.csv

		echo "${SUB_FOLDER}/${DATA_FILE}_${ExecDate}.csv"
		echo "=========================Extract File name $DATA_FILE ========================="
		commandLine="${USER_ARGUM} -DFILE_NAME_PREFIX=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER} -DOUTPUT_DIR=${OUTPUT_FOLDER} ${OPTS_ARGUM} ${DQ_FUNCTION}  ${PROPERTIES_FILE_DQ}"
		echo "=========================commandLine START========================="
		echo "=========================${JAVA_HOME} ${commandLine}========================="
		echo "=========================commandLine END========================="
		java ${commandLine}
		echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
		echo ""
		rm -rf ${TEMP_DIR}/Jython*

		# Verify the Predefined CCY_PAIR is present in FX_MARKETDATA file
		if [[ $DATA_FILE == *"FX_MARKETDATA"* ]] || [[ $DATA_FILE == *"LITES.CVA."* ]]; then
			echo "=========================Extract File name $DATA_FILE ========================="
			commandLine="${USER_ARGUM} -DFILE_NAME_PREFIX=${DATA_FILE}_LIST -DINPUT_DIR=${SUB_FOLDER} -DOUTPUT_DIR=${OUTPUT_FOLDER} ${OPTS_ARGUM} ${DQ_FUNCTION} ${PROPERTIES_PREDEFINED_LIST}"
			echo "=========================commandLine START========================="
			echo "=========================${JAVA_HOME} ${commandLine}========================="
			echo "=========================commandLine END========================="
			java ${commandLine}
			echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
			echo ""
			rm -rf ${TEMP_DIR}/Jython*
		fi

		# Filter Records from $DATA_FILE where INT_EXT_IND ="N"
		if [[ $DATA_FILE == *"SACCR_"* ]]; then
			echo "=========================Filter Records from $DATA_FILE where INT_EXT_IND ="N" ========================="
			mkdir -p ${OUTPUT_FOLDER}/filter
			commandLine="${USER_ARGUM} -DFILE_NAME_PREFIX=${DATA_FILE} -DINPUT_DIR=${SUB_FOLDER} -DOUTPUT_DIR=${OUTPUT_FOLDER}/filter ${OPTS_ARGUM} ${FILTER_OVRD_FUNCTION} ${PROPERTIES_FILTER}"
			echo "=========================commandLine START========================="
			echo "=========================${JAVA_HOME} ${commandLine}========================="
			echo "=========================commandLine END========================="
			java ${commandLine}
			echo "=========================Filter Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
			echo ""
			# cp ${OUTPUT_FOLDER}/filter/${DATA_FILE}_filter_${ExecDate}.csv ${PREV_DIR}/${DATA_FILE}_filter.csv
			rm -rf ${TEMP_DIR}/Jython*

			sleep 2

			echo "=========================Extract File name $DATA_FILE ========================="
			commandLine="${USER_ARGUM} -DFILE_NAME_PREFIX=${DATA_FILE}_filter -DINPUT_DIR=${OUTPUT_FOLDER}/filter -DOUTPUT_DIR=${OUTPUT_FOLDER} ${OPTS_ARGUM} ${DQ_FUNCTION} ${PROPERTIES_FILE_DQ}"
			echo "=========================commandLine START========================="
			echo "=========================${JAVA_HOME} ${commandLine}========================="
			echo "=========================commandLine END========================="
			java ${commandLine}
			echo "=========================DQ Functionality Process is complete for $DATA_FILE, output is present at: ${OUTPUT_FOLDER}========================="
			echo ""
			rm -rf ${TEMP_DIR}/Jython*

		fi
	 fi

	done
 done
else
 echo "Input folder is not exist : ${INPUT_DIR}"
fi

sleep 5

# Running BeSpoke DQ check on input feed files
echo ""
echo "============== Running BeSpoke DQ checks ============"

python=/apps/cmrods/ng/Anaconda3/bin/python3

echo "${python} InputData_SACVA_BeSpokeDQ.py ${ExecDate} ${INPUT_DIR} ${OUTPUT_DIR}/${ExecDate}/output"

${python} InputData_SACVA_BeSpokeDQ.py ${ExecDate} ${INPUT_DIR} ${OUTPUT_DIR}/${ExecDate}/output

echo "============== BeSpoke DQ checks completed============"


echo ""
echo "============== InputData SACVA DQ Summary Report ============"

sh InputData_SACVA_summary.sh ${ExecDate}

echo "=================Summary Report generated...==================="