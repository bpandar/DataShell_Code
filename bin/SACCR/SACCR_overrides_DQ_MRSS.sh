#!/bin/bash
# Run commands :
# sh SACCR_overrides_DQ_MRSS.sh YYYYMMDD(today) YYYYMMDD(yeasterday)
# 


echo "=========================Creating folders====================================="
mkdir -p /apps/data/cmrods/input/inputData
mkdir -p /apps/data/cmrods/output/inputData
mkdir -p /apps/data/cmrods/output/inputData/DQ
mkdir -p /apps/data/cmrods/output/inputData/DQ/SACCR
mkdir -p /apps/data/cmrods/saccr/MR/in/override/trade/DQ
mkdir -p /apps/data/cmrods/input/FIS/marketdata/DQ


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




echo "========================= DQ saccr_ex_bbg_YYYYMMDD.out=========================================="
today=$1
today_ext=$1
mkdir -p /apps/data/cmrods-bak/mrss/${today}/mrsecurityservice/DQ
mkdir -p /apps/data/cmrods-bak/mrss/${today}/mrsecurityservice/DQ/Filter
mkdir -p /apps/data/cmrods-bak/mrss/${today}/mrsecurityservice/DQ/DQ
PROPERTIES_FILE_FILTER_MRSS=${PROPERTIES_DIR}/SACCR_MRSS_Feed_Filter.properties
PROPERTIES_FILE_DQ_MRSS=${PROPERTIES_DIR}/SACCR_MRSS_Feed_DQ.properties
INPUT_MRSS=/apps/data/cmrods-bak/mrss
OUTPUT_MRSS=/apps/data/cmrods-bak/mrss

java -Dods.temp.script.folder=${TEMP_DIR} -Dtoday_ext=${today_ext} -DCONFIG_DIR=${CONFIG_DIR} -Dtoday=${today} -DINPUT_DIR=${INPUT_MRSS} -DOUTPUT_DIR=${OUTPUT_MRSS} -cp ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride ${PROPERTIES_FILE_FILTER_MRSS}
java -Dods.temp.script.folder=${TEMP_DIR} -Dtoday_ext=${today_ext} -DCONFIG_DIR=${CONFIG_DIR} -Dtoday=${today} -DINPUT_DIR=${INPUT_MRSS} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_MRSS} -classpath ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_FILE_DQ_MRSS}

# Calculate last business day
get_previous_busday(){
	if ["$1" == ""]
	then
		echo 'Date missing'
		return 1
	fi
	base_date="$1"
	if ! day_of_week="$(date -d "$base_date" +%u)"
	then
		echo 'Not a valid date'
		return 2
	fi
	case "$day_of_week" in
		(0|7)
			offset=-2
			;;
		(1)     offset=-3
			;;
		(*)     offset=-1
	esac
	if ! prev_date="$(date -d "$base_date $offset day")"
	then 
		echo "Error calculating"
		return 3
	fi
	yesterday=`date -d"$prev_date" '+%Y%m%d'`
	echo $yesterday
}

get_previous_busday "$today"
yesterday_ext=$yesterday

# var1 for the current date filesize
var1=$(stat -c %s ${INPUT_MRSS}/${today}/mrsecurityservice/response/saccr_ex_bbg_${today_ext}.out)
# var2 for the yesterday filesize
var2=$(stat -c %s ${INPUT_MRSS}/${yesterday}/mrsecurityservice/response/saccr_ex_bbg_${yesterday_ext}.out)
# compare the filesize differnce
percent=$(bc <<< "scale=2; ($var1-$var2)/$var1*100")
if ((  $(bc <<< "${percent#-} > 20.00") > 0)); then
	echo 'Day over day file size change > 20%'
	echo "Warning,Feed,,CCRCapital@bmo.com,Day over day file size change > 20%,," >> ${OUTPUT_MRSS}/${today}/mrsecurityservice/DQ/DQ/SACCR_MRSS_Feed_${today_ext}_DQ.detail.csv
fi
echo "${percent#-}"

echo "========================= send email notificartion for saccr_ex_bbg_YYYYMMDD.1.out=========================================="
File=${OUTPUT_MRSS}/${today}/mrsecurityservice/DQ/DQ/SACCR_MRSS_Feed_${today_ext}_DQ.detail.csv
LineNum=$(wc -l < "$File")
if [ ! -f ${File} ]; then
      echo " File not Exist... ${File} DQ ERROR. Please check DQ."
else
      echo " File Exist... ${File} "
	if [ ${LineNum} != 1 ]; then
		echo "DQ rules failed" 
		mailx -s 'DQ rules failed' elaine.qiu@bmo.com < ${File}
	else
		echo "DQ PASS"
	fi
      echo "done" 
fi







echo "========================= DQ saccr_ex_bbg_YYYYMMDD.1.out=========================================="
today_ext=$today_ext.1
yesterday_ext=$yesterday_ext.1
java -Dods.temp.script.folder=${TEMP_DIR} -Dtoday_ext=${today_ext} -DCONFIG_DIR=${CONFIG_DIR} -Dtoday=${today} -DINPUT_DIR=${INPUT_MRSS} -DOUTPUT_DIR=${OUTPUT_MRSS} -cp ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride ${PROPERTIES_FILE_FILTER_MRSS}
java -Dods.temp.script.folder=${TEMP_DIR} -Dtoday_ext=${today_ext} -DCONFIG_DIR=${CONFIG_DIR} -Dtoday=${today} -DINPUT_DIR=${INPUT_MRSS} -DWORKING_DIRECTORY=${WORKING_DIRECTORY} -DOUTPUT_DIR=${OUTPUT_MRSS} -classpath ${ODS_JAR} com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_FILE_DQ_MRSS}

var1=$(stat -c %s ${INPUT_MRSS}/${today}/mrsecurityservice/response/saccr_ex_bbg_${today_ext}.out)
var2=$(stat -c %s ${INPUT_MRSS}/${yesterday}/mrsecurityservice/response/saccr_ex_bbg_${yesterday_ext}.out)
# compare the filesize differnce
percent=$(bc <<< "scale=2; ($var1-$var2)/$var1*100")
if ((  $(bc <<< "${percent#-} > 20.00") > 0)); then
	echo 'Day over day file size change > 20%'
	echo "Warning,Feed,,CCRCapital@bmo.com,Day over day file size change > 20%,," >> ${OUTPUT_MRSS}/${today}/mrsecurityservice/DQ/DQ/SACCR_MRSS_Feed_${today_ext}_DQ.detail.csv
fi
echo "${percent#-}"


echo "========================= send email notificartion for saccr_ex_bbg_YYYYMMDD.1.out=========================================="
File=${OUTPUT_MRSS}/${today}/mrsecurityservice/DQ/DQ/SACCR_MRSS_Feed_${today_ext}_DQ.detail.csv
LineNum=$(wc -l < "$File")
if [ ! -f ${File} ]; then
      echo " File not Exist... ${File} DQ ERROR. Please check DQ."
else
      echo " File Exist... ${File} "
	if [ ${LineNum} != 1 ]; then
		echo "DQ rules failed" 
		mailx -s 'DQ rules failed' elaine.qiu@bmo.com < ${File}
	else
		echo "DQ PASS"
	fi
      echo "done" 
fi
