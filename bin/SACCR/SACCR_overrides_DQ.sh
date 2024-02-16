#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh SACCR_overrides_DQ.sh YYYYMMDD 
# sh SACCR_overrides_DQ.sh 20221031
# 

# 20220630 format
echo "=========================Date and Number for Execution========================="
JobFqn=$1
ExecDate=$2
JobId=$3
WorkspaceDir=$4
LogDir=$5
StagingDir=$6
OutputDir=$7
JobParamFile=$8

echo "=========================Creating folders====================================="
mkdir -p /apps/data/cmrods/input/inputData
mkdir -p /apps/data/cmrods/output/inputData
mkdir -p /apps/data/cmrods/output/inputData/DQ
mkdir -p /apps/data/cmrods/output/inputData/DQ/SACCR
mkdir -p /apps/data/cmrods/saccr/MR/in/override/trade/DQ


#==============================Input files copy==============================
InputFileCopy(){

echo "===========Copy input files based on businessdate============="

FILE_PATTERN=trade_override_set_*_${ExecDate}.csv
REMOTE_DIR=/apps/data/cmrods/saccr/MR/in/override/trade

FILE_LIST=`ls ${REMOTE_DIR}/${FILE_PATTERN}`

echo "List of files: $FILE_LIST"

	for FILE in $FILE_LIST
	do
   		if [ -f $FILE ]; then
      			echo "File present and coping into input folder : $FILE"
      			cp ${FILE} /apps/data/cmrods/input/inputData/
   		else
      			echo "File present for today business, check the business location...!"
      			exit 1
   		fi
	done

echo "==========Input file copy completed..=============="

}



echo "=========================Defining paths=========================================="
INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData/DQ/SACCR
WORKING_DIR=/apps/cmrods/sacva_apms
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACCR/properties
CONFIG_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACCR/config
TEMP_DIR=/apps/cmrods/sacva_apms/conf/InputData_SACCR/temp
BIN_DIR=${WORKING_DIR}/bin


JAR_DIR=/apps/cmrods/sacva_apms/lib
ODS_JAR=${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain
PROPERTIES_FILE_DQ=${PROPERTIES_DIR}/SACCR_overrides_DQ.properties


echo "========================Define Filename ===================================="
FILENM="trade_override_set"

echo "Download input files...."
#downloadSFTP
InputFileCopy

echo "========================Iterate all the files matching trade_override_set_??_YYYYMMDD.csv=========================================="

FILE_PATTERN=trade_override_set_*_${ExecDate}.csv

FILE_LIST=`ls ${INPUT_DIR}/${FILE_PATTERN}`

if [[ -n "$FILE_LIST" ]]; then

   echo "List of files exist in input directory: $FILE_LIST"
   #${INPUT_DIR}/trade_override_set_??_${ExecDate}.csv

   # Delete existing results output location.
   rm ${OUTPUT_DIR}/*.*

   for FILE in $FILE_LIST; do

	BASE_FILE=$(basename ${FILE})
	SOURCE_FILE=${BASE_FILE%.*}
	echo ""
	echo "=========================${SOURCE_FILE}.csv DQ START==================================="
	VM_ARUGM="-Dods.temp.script.folder=${TEMP_DIR} -DBUS_DATE=${ExecDate} -DFILE_NAME_PREFIX=${FILENM} -DSOURCE_FILE=${SOURCE_FILE}"

	commandLine="${VM_ARUGM} -classpath ${ODS_JAR} ${MAIN_PROGRAM} rulesBasedFeedValidate ${PROPERTIES_FILE_DQ}"

	echo "---------------------commandLine START---------------------"
	echo "${JAVA_HOME} ${commandLine}"
	echo "---------------------commandLine END-----------------------"

	java ${commandLine}

	echo "Output Files present in ${OUTPUT_DIR}"
	echo "=========================${SOURCE_FILE}.csv DQ Completed.==================================="
	echo ""
   done

fi

rm -rf ${TEMP_DIR}/Jython*

sleep 2


# MARP-7328 Override Bespoke DQ Rules validation
echo ""
echo "==========Override Bespoke DQ Rules validation============="
   if [[ -n "$FILE_LIST" ]]; then
     python ${BIN_DIR}/SACCR_override_Bespoke_DQ.py ${ExecDate} ${INPUT_DIR} ${OUTPUT_DIR}
   fi
echo "==========Override Bespoke DQ Rules Completed..============="
echo ""

# Copy DQ results into Remote location.
cp -r ${OUTPUT_DIR}/trade_override_set_*_${ExecDate}* ${REMOTE_DIR}/DQ/
cp -r ${OUTPUT_DIR}/trade_override_set_${ExecDate}* ${REMOTE_DIR}/DQ/


# Output files permissions.
chmod -R 777 ${OUTPUT_DIR}
