#!/bin/bash
# Run commands :
# source ~/.bashrc
# sh Run_ODS_Collateral_ARML_DQ.sh 20221012

# 20220630 format
BUS_DT=$1

mkdir -p /apps/data/cmrods/output/FIS/BMOCollateral/intermediate
chmod -R 777 /apps/data/cmrods/output/FIS/BMOCollateral/intermediate

PROPERTIES_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral
SOURCE_DIR=/apps/data/cmrods/output/FIS/BMOCollateral
OUTPUT_DIR=/apps/data/cmrods/output/FIS/BMOCollateral/intermediate
CONFIG_DIR=/apps/cmrods/sacva_apms/conf/InputData_Collateral/config
JAR_DIR=/apps/cmrods/sacva_apms/lib

# apply filter on Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff.xml to get Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff_Active_Yes.xml
java -DBUS_DT=${BUS_DT} -DSOURCE_DIR=${SOURCE_DIR} -DOUTPUT_DIR=${OUTPUT_DIR} -DCONFIG_DIR=${CONFIG_DIR} -DTEMP_DIR=${OUTPUT_DIR} -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain arml_filter_and_override_using_config_file ${PROPERTIES_DIR}/ODS_Collateral_ARML_Filters.properties

# transform Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff_Active_Yes.xml into .csv
java -DSOURCE_DIR=${OUTPUT_DIR} -DOUTPUT_DIR=${SOURCE_DIR} -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain save_arml_attributes_to_csv_using_config_file ${PROPERTIES_DIR}/ODS_Collateral_ARML_to_csv_full.properties

# apply DQ on Admin.InternalCollateralAgreements_$BUSINESS_DATE$.Diff_Active_Yes.csv
java -Dods.feedvalidation.rules.key=InternalCollateralAgreements -Dsource_folder=${OUTPUT_DIR} -Doutput_folder=${OUTPUT_DIR} -DFILE_NAME_PREFIX=Admin.InternalCollateralAgreements_filter -DCONFIG_DIR=${CONFIG_DIR} -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_DIR}/ODS_Collateral_ARML_DQ.properties

# apply DQ on pre-defined_list.csv
PREDEFINED_LIST=${SOURCE_DIR}/pre-defined_list.csv
java -Dods.feedvalidation.rules.key=pre-defined_list -Dsource_folder=${OUTPUT_DIR} -Doutput_folder=${OUTPUT_DIR} -Dods.feedvalidation.sourcefile.name=${PREDEFINED_LIST} -DFILE_NAME_PREFIX=pre-defined_list -DCONFIG_DIR=${CONFIG_DIR} -cp ${JAR_DIR}/OdsToolsMain-1.1.5_2.12-SNAPSHOT.jar com.bmo.cmrods.odstools.main.ODSToolsMain rulesBasedFeedValidate ${PROPERTIES_DIR}/ODS_Collateral_ARML_DQ.properties

# Combine DQ results into one file
tail -n +2  ${OUTPUT_DIR}/pre-defined_list_${BUS_DT}.detail.dq.csv >>  ${OUTPUT_DIR}/Admin.InternalCollateralAgreements_filter_${BUS_DT}.detail.dq.csv
tail -n +2  C${OUTPUT_DIR}/pre-defined_list_${BUS_DT}.summary.dq.csv >>  ${OUTPUT_DIR}/Admin.InternalCollateralAgreements_filter_${BUS_DT}.summary.dq.csv

# Copy results to final output folder
cp ${OUTPUT_DIR}/Admin.InternalCollateralAgreements_filter_${BUS_DT}.detail.dq.csv ${SOURCE_DIR}/Admin.InternalCollateralAgreements_${BUS_DT}.detail.dq.csv
cp ${OUTPUT_DIR}/Admin.InternalCollateralAgreements_filter_${BUS_DT}.summary.dq.csv ${SOURCE_DIR}/Admin.InternalCollateralAgreements_${BUS_DT}.summary.dq.csv
