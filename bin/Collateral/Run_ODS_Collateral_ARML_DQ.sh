#!/bin/bash
# Run commands : sh Run_ODS_Collateral_ARML_DQ.sh 1 20221012

source ~/.bashrc

# 20220630 format
FileType=$1
ExecDate=$2
ARMLFILES=$3


BUS_DT=${ExecDate}
echo "Business Date: $BUS_DT"
echo "$FileType"


INPUT_DIR=/apps/data/cmrods/input/inputData
SOURCE_DIR=/apps/data/cmrods/output/FIS/BMOCollateral
OUTPUT_DIR=/apps/data/cmrods/output/FIS/BMOCollateral/intermediate
DQ_OUTPUT_DIR=/apps/data/cmrods/output/inputData/DQ/Collateral
FILTTER_DIR=${DQ_OUTPUT_DIR}/filter
PREV_DIR=/apps/data/cmrods/prev
DQ_RESULTS_DIR=/apps/data/cmrods/output/FIS/BMOCollateral/DQ

PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/properties
CONFIG_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/config
JAR_DIR=/apps/cmrods/sacva_apms/lib
TEMP_DIR=/apps/data/cmrods/output/inputData/logs/tmp

JAR_NAME=OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar
MAIN_PROGRAM=com.bmo.cmrods.odstools.main.ODSToolsMain;export MAIN_PROGRAM
DQ_FUNCTION=rulesBasedFeedValidate
FILTER_OVRD_FUNCTION=rulesBasedFeedFilterAndOverride
ARMLTOCSV_FUNCTION=save_arml_attributes_to_csv_using_config_file
ARML_FILTER_FUNCTION=arml_filter_and_override_using_config_file

mkdir -p /apps/data/cmrods/output/inputData/DQ/Collateral
mkdir -p /apps/data/cmrods/output/inputData/DQ/Collateral/filter/
mkdir -p /apps/data/cmrods/input/inputData
mkdir -p /apps/data/cmrods/output/FIS/BMOCollateral
mkdir -p /apps/data/cmrods/output/inputData/logs
mkdir -p /apps/data/cmrods/output/inputData/logs/tmp
mkdir -p /apps/data/cmrods/output/FIS/BMOCollateral/intermediate
mkdir -p /apps/data/cmrods/output/FIS/BMOCollateral/DQ

chmod -R 755 /apps/data/cmrods/output/FIS/BMOCollateral/intermediate/
chmod -R 755 /apps/data/cmrods/output/inputData/DQ/Collateral/

#==================================================

checkFileExist(){
  echo "Checking file presence ..."
    File=$1
    Level=$2
    XML_File=$3
    if [ ! -f ${File} ]; then
      echo " File not Exist... ${File}
              Please check the DQ output directory."
      if [[ ${Level} == "L2" ]]; then
        mv ${SOURCE_DIR}/${XML_File} ${SOURCE_DIR}/${XML_File}.DQFailed
      fi

	    mailx -s "$(echo -e " DQ Validation Failure\nThe below file is not generated due to DQ fail\n$1\nContent-Type: text/html")" #DGMRTETL@bmo.com

      exit 1
    else
      echo " File Exist... ${File} "
      echo ""
    fi
}

checkCommandStatus(){
  if [ "$1" != "0" ]; then
     echo "ERROR while executing $2 . Error message=$3 "
     exit 1
  else
     echo "INFO: Successfull $1 "
  fi
}

executeCommand(){
  echo ""
  CMD=$1
  errorMsg=$($CMD)
  exeCode="$?"
  checkCommandStatus $exeCode $CMD $errorMsg
  sleep 2
  echo ""
  rm -rf ${TEMP_DIR}/Jython*
  rm -rf ${TEMP_DIR}/TempPython*
}


#===============copy input feeds from below location into Inputdata location===============

inputFileCopy(){

	##========== Make required Directory & Delete old input files=============
	rm -rf /apps/data/cmrods/input/inputData/BMO_Collateral_Position_Summary_Bilateral_Report*
	rm -rf /apps/data/cmrods/input/inputData/CMG_Agreements_CSA*
	rm -rf /apps/data/cmrods/input/inputData/CSA_CPTY_exposure*
	rm -rf /apps/data/cmrods/output/inputData/DQ/Collateral/*

	mkdir -p /apps/data/cmrods/output/inputData/DQ/Collateral
	mkdir -p /apps/data/cmrods/output/inputData/DQ/Collateral/filter/
	mkdir -p /apps/data/cmrods/input/inputData


	echo "=============== Copying Input CSV Files ... `date`==============="
	CALYPSO_INPUT_DIR=/apps/data/cmrods/input/FIS/calypso

	BMO_COLL_POSITN=${CALYPSO_INPUT_DIR}/BMO_Collateral_Position_Summary_Bilateral_Report_${BUS_DT}.txt
	CMG_AGREE_CSA=${CALYPSO_INPUT_DIR}/CMG_Agreements_CSA_${BUS_DT}.csv
	CSA_CPTY_EXPOSURE=${CALYPSO_INPUT_DIR}/CSA_CPTY_exposure_${BUS_DT}.txt

	echo " Input Directory for csv files: $CALYPSO_INPUT_DIR"
	echo "Required csv files : $BMO_COLL_POSITN
		$CMG_AGREE_CSA
		$CSA_CPTY_EXPOSURE"

	# Define a list of files to check
	FILE_LIST=$BMO_COLL_POSITN,$CMG_AGREE_CSA,$CSA_CPTY_EXPOSURE

	# Use comma as separator and apply as pattern
	for FILE in ${FILE_LIST//,/ }
	  do
	   echo "ls $FILE"
	   if [ ! -f $FILE ]; then
		  echo " File not Exist... $FILE
				  Please check the inputdirectory."
		  exit 1
		else
		  echo " File Exists... $FILE
				  Copy csv file into inputdata/output folder.."
		  cp $FILE ${INPUT_DIR}
		fi
	  done

	echo "=============== File Copy Completed... `date`==============="
	echo ""

}
#===============================================================================================



#CSV properties..
CSACPTY_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_CSA_CPTY_exposure_DQ.properties
ODS_FILTER_PROPERTY=${PROPERTIES_DIR}/ODS_Collateral_CSV_Filters.properties
CSA_FILTER_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_CSA_CPTY_exposure_filter_DQ.properties

CMGAGREE_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_CMG_Agreements_CSA_DQ.properties
CMG_FILTER_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_CMG_Agreements_CSA_filter_DQ.properties

BMOCOLL_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_BMO_Collateral_Position_DQ.properties

LOG4J="-Dlog4j.configuration=file://${PROPERTIES_DIR}/InputData_Collateral_ARML_log.properties"
USER_ARGUM="java -DBUS_DT=${BUS_DT} ${LOG4J}"; export USER_ARGUM
OPTS_ARGUM="-cp ${JAR_DIR}/${JAR_NAME} ${MAIN_PROGRAM}"; export OPTS_ARGUM

#CSV_FILES=${CSACPTY_DQ_PROPERTY},${CMGAGREE_DQ_PROPERTY},${BMOCOLL_DQ_PROPERTY}
echo ""

 if [ ${FileType} == "L0" ]; then

	inputFileCopy

	echo "===============  Processing csv file........`date`==============="
	# Apply DQ on CSA_CPTY_exposure_{BUS_DT}.txt
	echo "======== Processing CSA_CPTY_exposure ========"
	CSA_DQ="${USER_ARGUM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${CSACPTY_DQ_PROPERTY}"
	echo "######## Apply CSA_CPTY_exposure DQ : #########"
	echo "$CSA_DQ"
	echo "################################################"
	executeCommand "$CSA_DQ"
	CSA_DQ_OPT=${DQ_OUTPUT_DIR}/CSA_CPTY_exposure_${BUS_DT}.output.dq.csv
	checkFileExist $CSA_DQ_OPT

	# Apply Filter on Input files....

	sed -i '1d' ${INPUT_DIR}/CSA_CPTY_exposure_${BUS_DT}.txt
	INPUT_PARAM="-DSOURCE_FILE=CSA_CPTY_exposure_${BUS_DT}.txt -DFILE_KEY=CSA_CPTY_exposure -DDELIM=|"

	CSA_FILTER="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${FILTER_OVRD_FUNCTION} ${ODS_FILTER_PROPERTY}"
	echo "######## Apply CSA_CPTY_exposure Filter : #########"
	echo "$CSA_FILTER"
	echo "################################################"
	executeCommand "$CSA_FILTER"
	CSA_FIL_OPT=${FILTTER_DIR}/CSA_CPTY_exposure_${BUS_DT}_filter.csv
	checkFileExist $CSA_FIL_OPT

	# Apply DQ on Filter file CSA_CPTY_exposure_{BUS_DT}_filter.csv
	CSA_FILTER_DQ="${USER_ARGUM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${CSA_FILTER_DQ_PROPERTY}"
	echo "######## Apply CSA_CPTY_exposure filter DQ : #########"
	echo "$CSA_FILTER_DQ"
	echo "################################################"
	executeCommand "$CSA_FILTER_DQ"
	CSA_FILDQ_OPT=${DQ_OUTPUT_DIR}/CSA_CPTY_exposure_${BUS_DT}_filter.output.dq.csv
	checkFileExist $CSA_FILDQ_OPT

	echo "======== CSA_CPTY_exposure completed... ========"


	echo ""
	echo "======== Processing CMG_Agreements_CSA ========"
	# Apply DQ on CMG_Agreements_CSA_{BUS_DT}.csv
	CMG_DQ="${USER_ARGUM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${CMGAGREE_DQ_PROPERTY}"
	echo "######## Apply ODS_CMG_Agreements_CSA DQ : ################"
	echo "$CMG_DQ"
	echo "###########################################################"
	executeCommand "$CMG_DQ"
	CMG_DQ_OPT=${DQ_OUTPUT_DIR}/CMG_Agreements_CSA_${BUS_DT}.output.dq.csv
	checkFileExist $CMG_DQ_OPT
	echo ""

	# Apply Filter on Input files....
	FILE_KEY="CMG_Agreements_CSA"
	CMG_AGREE_FILE=CMG_Agreements_CSA_${BUS_DT}.csv
	INPUT_PARAM="-DSOURCE_FILE=${CMG_AGREE_FILE} -DFILE_KEY=${FILE_KEY} -DDELIM=,"

	CMG_FILTER="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${FILTER_OVRD_FUNCTION} ${ODS_FILTER_PROPERTY}"
	echo "######## Apply CMG_Agreements_CSA Filter : #########"
	echo "$CMG_FILTER"
	echo "################################################"
	executeCommand "$CMG_FILTER"
	CMG_FIL_OPT=${FILTTER_DIR}/CMG_Agreements_CSA_${BUS_DT}_filter.csv
	checkFileExist $CMG_FIL_OPT
	echo ""

	# Apply DQ on Filter file CMG_Agreements_CSA_{BUS_DT}_filter.csv
	CMG_FILTER_DQ="${USER_ARGUM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${CMG_FILTER_DQ_PROPERTY}"
	echo "######## Apply CMG_Agreements_CSA filter DQ : #########"
	echo "$CMG_FILTER_DQ"
	echo "################################################"
	executeCommand "$CMG_FILTER_DQ"
	CMG_FILDQ_OPT=${DQ_OUTPUT_DIR}/CMG_Agreements_CSA_${BUS_DT}_filter.output.dq.csv
	checkFileExist $CMG_FILDQ_OPT
	echo ""

	echo "======== CMG_Agreements_CSA completed... ========"


	echo""
	echo "======== Processing BMO_Collateral_Position_Summary ========"

	# Apply DQ on BMO_Collateral_Position_Summary_Bilateral_Report_{BUS_DT}.txt
	BMOCOLL_DQ="${USER_ARGUM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${BMOCOLL_DQ_PROPERTY}"
	echo "######## Apply BMO_Collateral_Position_Summary_Bilateral_Report DQ : ########"
	echo "$BMOCOLL_DQ"
	echo "############################################################"
	executeCommand "$BMOCOLL_DQ"
	BMO_DQ_OPT=${DQ_OUTPUT_DIR}/BMO_Collateral_Position_Summary_Bilateral_Report_${BUS_DT}.output.dq.csv
	checkFileExist $BMO_DQ_OPT
	echo ""
	echo "======== BMO_Collateral_Position_Summary completed... ========"

	echo ""
	echo "=============== csv file validation end........`date`==============="
 fi

#ARML Properties...
ARMLTOCSV_PROPERTY=${PROPERTIES_DIR}/ODS_Collateral_ARML_to_csv_full.properties
ARML_FILTER_PROPERTY=${PROPERTIES_DIR}/ODS_Collateral_ARML_Filters.properties
ARML_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_Collateral_ARML_DQ.properties
COLLRISK_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_CollaterallRiskCarrier_DQ.properties

PREDEFINED_DQ_PROPERTY=${PROPERTIES_DIR}/ODS_Collateral_PredefinedList_DQ.properties


 if [[ ${FileType} == "L2" ]] && [[ ${ARMLFILES} == "InternalCollateralAgreements" || ${ARMLFILES} == "RegulatoryCollateralAgreements" ]] ; then

	rm -rf /apps/data/cmrods/output/FIS/BMOCollateral/intermediate/Admin.${ARMLFILES}*
	rm -rf /apps/data/cmrods/output/FIS/BMOCollateral/intermediate/pre-defined_list*
	mkdir -p /apps/data/cmrods/output/FIS/BMOCollateral/intermediate

	#mv ${SOURCE_DIR}/Admin.${ARMLFILES}_${BUS_DT}.Diff.xml.DQFailed ${SOURCE_DIR}/Admin.${ARMLFILES}_${BUS_DT}.Diff.xml

	#ARML_FILES="InternalCollateralAgreements,RegulatoryCollateralAgreements"
	ARML_FILES=${ARMLFILES}
	echo ""

	for FILE in ${ARML_FILES//,/ };
	do
	  echo "=============== Processing ${FILE} file........`date`==============="

	  # transform Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff.xml into .csv
	  INPUT_PARAM="-DSOURCE_FILE=${FILE}_${BUS_DT}.Diff -DSOURCE_DIR=${SOURCE_DIR} -DOUTPUT_DIR=${OUTPUT_DIR}"
	  ARMLTOCSV="java ${LOG4J} ${INPUT_PARAM} ${OPTS_ARGUM} ${ARMLTOCSV_FUNCTION} ${ARMLTOCSV_PROPERTY}"
	  echo "########## Convert ${FILE} ARML into CSV: #########"
	  echo "$ARMLTOCSV"
	  echo "##########################################################"
	  executeCommand "$ARMLTOCSV"
	  ARML_CSV_OPT=${OUTPUT_DIR}/Admin.${FILE}_${BUS_DT}.Diff.csv
	  checkFileExist $ARML_CSV_OPT $FileType Admin.${FILE}_${BUS_DT}.Diff.xml
	  #cp ${OUTPUT_DIR}/Admin.${FILE}_${BUS_DT}.Diff.csv ${PREV_DIR}/Admin.${FILE}.csv

	  # apply DQ on Admin.InternalCollateralAgreements_$BUSINESS_DATE$_diff.csv
	  INPUT_PARAM="-DSOURCE_FILE=${FILE}_${BUS_DT}.Diff -DFILE_KEY=${FILE}"
	  ARML_DQ="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${ARML_DQ_PROPERTY}"
	  echo "########## Apply ${FILE} ARML DQ : ############"
	  echo "$ARML_DQ"
	  echo "##########################################################"
	  executeCommand "$ARML_DQ"
	  ARML_DQ_OPT=${OUTPUT_DIR}/Admin.${FILE}_${BUS_DT}.output.dq.csv
	  checkFileExist $ARML_DQ_OPT $FileType Admin.${FILE}_${BUS_DT}.Diff.xml

	  # apply filter on Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff.xml to get Admin.InternalCollateralAgreements_$BUSINESS_DATE$_filter.xml
	  ARML_FILTER="${USER_ARGUM} -DSOURCE_FILE=${FILE} ${OPTS_ARGUM} ${ARML_FILTER_FUNCTION} ${ARML_FILTER_PROPERTY}"
	  echo "######### ${FILE} ARML Filter: #########"
	  echo "$ARML_FILTER"
	  echo "###########################################################"
	  executeCommand "$ARML_FILTER"
	  ARML_FIL_OPT=${OUTPUT_DIR}/Admin.${FILE}_filter.xml
	  checkFileExist $ARML_FIL_OPT $FileType Admin.${FILE}_${BUS_DT}.Diff.xml

	  # transform Admin.InternalCollateralAgreements_$BUSINESS_DATE$_filter.xml into filter.csv
	  INPUT_PARAM="-DSOURCE_FILE=${FILE}_filter -DSOURCE_DIR=${OUTPUT_DIR} -DOUTPUT_DIR=${OUTPUT_DIR}"
	  ARMLTOCSV="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${ARMLTOCSV_FUNCTION} ${ARMLTOCSV_PROPERTY}"
	  echo "########## Convert ${FILE} ARML into CSV: #########"
	  echo "$ARMLTOCSV"
	  echo "##########################################################"
	  executeCommand "$ARMLTOCSV"
	  ARML_FILCSV_OPT=${OUTPUT_DIR}/Admin.${FILE}_filter.csv
	  checkFileExist $ARML_FILCSV_OPT $FileType Admin.${FILE}_${BUS_DT}.Diff.xml
	  #cp ${OUTPUT_DIR}/Admin.${FILE}_filter.csv ${PREV_DIR}/

	  # apply DQ on Admin.InternalCollateralAgreements_$BUSINESS_DATE$_filter.csv
	  INPUT_PARAM="-DSOURCE_FILE=${FILE}_filter -DFILE_KEY=${FILE}_filter"
	  ARML_FILTER_DQ="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${ARML_DQ_PROPERTY}"
	  echo "########## Apply ${FILE} ARML FILTER DQ : ############"
	  echo "$ARML_FILTER_DQ"
	  echo "##########################################################"
	  executeCommand "$ARML_FILTER_DQ"
	  ARML_FILDQ_OPT=${OUTPUT_DIR}/Admin.${FILE}_filter_${BUS_DT}.output.dq.csv
	  checkFileExist $ARML_FILDQ_OPT $FileType Admin.${FILE}_${BUS_DT}.Diff.xml

	  echo "=============== ${FILE} file validation completed........`date`==============="
	  echo ""

	done

	sleep 2

	echo ""
	# apply DQ on pre-defined_list.csv
	PREDEFINED_DQ="${USER_ARGUM} -DFILE_KEY=pre-defined_list_${FILE} ${OPTS_ARGUM} ${DQ_FUNCTION} ${PREDEFINED_DQ_PROPERTY}"
	echo "########## Pre-defined list DQ: #########################"
	echo "$PREDEFINED_DQ"
	echo "##########################################################"
	executeCommand "$PREDEFINED_DQ"
	PREDEFINED_DQ_OPT=${OUTPUT_DIR}/pre-defined_list_${BUS_DT}.output.dq.csv
	checkFileExist $PREDEFINED_DQ_OPT

	sleep 2

	# Copy todays files into Previous day folder
	echo ""
	echo "========Copy todays files into Previous day folder==========="
	cp ${INPUT_DIR}/CSA_CPTY_exposure_${BUS_DT}.txt ${PREV_DIR}/CSA_CPTY_exposure.txt
	cp ${FILTTER_DIR}/CSA_CPTY_exposure_${BUS_DT}_filter.csv ${PREV_DIR}/CSA_CPTY_exposure_filter.csv
	cp ${INPUT_DIR}/CMG_Agreements_CSA_${BUS_DT}.csv ${PREV_DIR}/CMG_Agreements_CSA.csv
	cp ${FILTTER_DIR}/CMG_Agreements_CSA_${BUS_DT}_filter.csv ${PREV_DIR}/CMG_Agreements_CSA_filter.csv
	cp ${INPUT_DIR}/BMO_Collateral_Position_Summary_Bilateral_Report_${BUS_DT}.txt ${PREV_DIR}/BMO_Collateral_Position_Summary_Bilateral_Report.txt

	cp ${OUTPUT_DIR}/Admin.${FILE}_${BUS_DT}.Diff.csv ${PREV_DIR}/Admin.${FILE}.csv
	cp ${OUTPUT_DIR}/Admin.${FILE}_filter.csv ${PREV_DIR}/

 fi

  if [[ ${FileType} == "L2" && ${ARMLFILES} == "CollateralRiskCarrier" ]]; then

      	rm -rf /apps/data/cmrods/output/FIS/BMOCollateral/intermediate/Dealing.CollateralRiskCarrier*
      	#cp ${SOURCE_DIR}/Dealing.CollateralRiskCarrier_${BUS_DT}.xml ${PREV_DIR}/Dealing.CollateralRiskCarrier.xml

      	echo "=============== Processing Dealing.CollateralRiskCarrier file........`date`==============="
      	echo ""
      	# apply DQ on Dealing.CollateralRiskCarrier_yyyymmdd.xml
      	INPUT_PARAM="-DSOURCE_FILE=Dealing.CollateralRiskCarrier -DFILE_KEY=CollateralRiskCarrier"
      	COLLRISK_DQ="${USER_ARGUM} ${INPUT_PARAM} ${OPTS_ARGUM} ${DQ_FUNCTION} ${COLLRISK_DQ_PROPERTY}"

      	echo "########## CollateralRiskCarrier DQ: #########################"
      	echo "$COLLRISK_DQ"
      	echo "##########################################################"
      	executeCommand "$COLLRISK_DQ"
      	COLLRISK_DQ_OPT=${OUTPUT_DIR}/Dealing.CollateralRiskCarrier_${BUS_DT}.output.dq.csv
      	checkFileExist $COLLRISK_DQ_OPT $FileType Dealing.CollateralRiskCarrier_${BUS_DT}.xml

  	cp ${SOURCE_DIR}/Dealing.CollateralRiskCarrier_${BUS_DT}.xml ${PREV_DIR}/Dealing.CollateralRiskCarrier.xml
      	echo "=============== Dealing.CollateralRiskCarrier file validation completed........`date`==============="
      	echo ""

  fi



rm -rf /apps/data/cmrods/output/FIS/BMOCollateral/DQ/*

# Move L0, L2 DQ result files into below location.
echo "======= Moving DQ result files ========="
cp -r /apps/data/cmrods/output/inputData/DQ/Collateral/* /apps/data/cmrods/output/FIS/BMOCollateral/DQ/
cp -r /apps/data/cmrods/output/FIS/BMOCollateral/intermediate/* /apps/data/cmrods/output/FIS/BMOCollateral/DQ/


# Providing permission to results files.
echo ""
echo "INFO: Permission change to 755 for folders post execution completed...."
chmod -R 755 ${SOURCE_DIR}/
chmod -R 755 ${OUTPUT_DIR}/
chmod -R 755 /apps/data/cmrods/output/inputData/DQ/Collateral/
chmod -R 755 /apps/data/cmrods/output/inputData/logs/
echo ""
echo " ===============  Task Completed =============== `date`"