#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_Input_Data_Finance_Report.sh 20220831
# Authors imalek,ekonovalov
# 20220630 format
EXEC_DATE=$1

INPUT_DIR=/apps/data/cmrods/input/inputData
OUTPUT_DIR=/apps/data/cmrods/output/inputData
PREV_DIR=/apps/data/cmrods/prev
PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf 
STATIC_DATA=/apps/data/cmrods/staticdata
TEMP_DIR=/apps/data/cmrods/tmp
JAR_DIR=/apps/cmrods/sacva_apms/lib


##################### STEP 1: Perform DQ on Finance Report (MARP-225)########################

PROPERTIES_FILE=ODS_Finance_Report_DQ
PROP_FILE_TMP="${PROPERTIES_DIR}/${PROPERTIES_FILE}_temp.properties"

echo "PROP_FILE_TMP - ${PROP_FILE_TMP}"
PROP_FILE=`echo "${PROPERTIES_DIR}/${PROPERTIES_FILE}.properties"`

cp ${PROP_FILE} ${PROP_FILE_TMP}

echo "Append Property file - ${PROP_FILE_TMP}" >> ${PROP_FILE_TMP}
echo "ods.temp.script.folder=${TEMP_DIR}" >> ${PROP_FILE_TMP}
echo "BUS_DATE=${EXEC_DATE}" >> ${PROP_FILE_TMP}
echo "prev=${PREV_DIR}" >> ${PROP_FILE_TMP}
echo "source_folder=${INPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/DQ" >> ${PROP_FILE_TMP}
echo "ods.feedvalidation.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_DQ_rules.csv" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------- STEP 1: Perform DQ on Finance Report (MARP-225) ------------------------------------------------ "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROP_FILE_TMP}

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

FILE=${OUTPUT_DIR}/DQ/CM_Finance_${EXEC_DATE}.output.csv
if [ -f "$FILE" ]; then
    echo "$FILE exists. Can proceed to STEP 2 -----------------------------!"
else 
    echo "$FILE does not exist. Stop entire job -----------------------------!"
	exit 1
fi

# Change input file to orig, and copy output to input location
mv ${INPUT_DIR}/CM_Finance_${EXEC_DATE}.csv ${INPUT_DIR}/CM_Finance_${EXEC_DATE}_orig.csv

# Copy output to Prev for tomorrow
cp ${OUTPUT_DIR}/DQ/CM_Finance_${EXEC_DATE}.output.csv ${PREV_DIR}/CM_Finance.csv

# Move New DQ output to input
mv ${OUTPUT_DIR}/DQ/CM_Finance_${EXEC_DATE}.output.csv ${INPUT_DIR}/CM_Finance_${EXEC_DATE}.csv 

sleep 2

################### STEP 2: Apply transformations on DQ output Finance Report (MARP-52, MARP-53, MARP-54 and MARP-492) ###############################

PROPERTIES_FILE=ODS_finance_report_transformation

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
echo "source_folder=${INPUT_DIR}" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/augmentation" >> ${PROP_FILE_TMP}

echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "----------------- STEP 2: Apply transformations on DQ output Finance Report (MARP-52, MARP-53, MARP-54 and MARP-492)  ------------------------------------ "
echo "---------------------------------------------------------------------------------------------------------------------------------------------------------- "

java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -Dods.bcl.mapping.file.GL=$STATIC_DATA/BCL_GL_mapping.csv -Dods.source_system.file=$STATIC_DATA/FinanceReport_sourceSystemMapping.txt -Dods.legal_entity.file=$STATIC_DATA/FinanceReport_legalEntityMapping.txt -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar:$JAR_DIR/ods-inputdata-calculator-1.0-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain transform_csv_v2 $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2


################ STEP 3: Apply other overrides/transformations on DQ output Finance Report (MARP-425) ####################

PROPERTIES_FILE=ODS_finance_report_overrides

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
echo "source_folder=${OUTPUT_DIR}/Intermediate/augmentation" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/overrides" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_rule_based_overrides.csv" >> ${PROP_FILE_TMP}

echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------- STEP 3: Apply other overrides/transformations on DQ output Finance Report (MARP-425) --------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "------------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2

# Rename Output File
mv ${OUTPUT_DIR}/Intermediate/overrides/CM_Finance_${EXEC_DATE}_output.csv ${OUTPUT_DIR}/Intermediate/overrides/CM_Finance_${EXEC_DATE}_transformed.csv

################ STEP 4: Apply Filter on transformed output Transformed Finance Report File (MARP-436) ####################

PROPERTIES_FILE=ODS_finance_report_filters

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
echo "source_folder=${OUTPUT_DIR}/Intermediate/overrides" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/filters" >> ${PROP_FILE_TMP}
echo "ods.feedfilterandoverride.rules.file=${PROPERTIES_DIR}/config/ODS_Finance_SaccrExposure_Filters.csv" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "----------------------------- STEP 4: Apply Filter on transformed output Transformed Finance Report File (MARP-436)  ----------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedFilterAndOverride $PROP_FILE_TMP

#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2


################ STEP 5: Apply Aggregation to Finance Report File (MARP-49) ####################

PROPERTIES_FILE=ODS_finance_report_aggregation

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
echo "BASE_DIR=${PROPERTIES_DIR}" >> ${PROP_FILE_TMP}
echo "INTER_DIR=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}
echo "source_folder=${OUTPUT_DIR}/Intermediate/filters" >> ${PROP_FILE_TMP}
echo "output_folder=${OUTPUT_DIR}/Intermediate/spark" >> ${PROP_FILE_TMP}

echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "---------------------------------------- STEP 5: Apply Aggregation to Finance Report File (MARP-49)  --------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------- "
# Aggregation STEP 1 (simple_spark_etl)
java -Dlog4j.configuration=file://${PROPERTIES_DIR}/input_data_log.properties -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain simple_spark_etl $PROP_FILE_TMP
# Aggregation STEP 2 (removeDuplicateCSVRows) 
java -cp $JAR_DIR/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain removeDuplicateCSVRows ${OUTPUT_DIR}/Intermediate/spark/CM_Finance_${EXEC_DATE}_aggregation_inter.csv ${OUTPUT_DIR}/Intermediate/spark/CM_Finance_${EXEC_DATE}_aggregation.csv SourceSystem,SourceTradeId "|"


#remove temp properties file
rm ${PROP_FILE_TMP}

sleep 2


# Rename Output File
mv ${OUTPUT_DIR}/Intermediate/spark/CM_Finance_${EXEC_DATE}_aggregation.csv ${OUTPUT_DIR}/CM_Finance_${EXEC_DATE}_L1.csv