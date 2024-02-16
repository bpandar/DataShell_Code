#!/bin/bash

source /apps/cmrods/common/1.4/bin/commonEnvironment.sh

JobFqn=$1
ExecDate=$2
JobId=$3
WorkspaceDir=$4
LogDir=$5
StagingDir=$6
OutputDir=$7
JobParamFile=$8

mkdir -p /apps/data/cmrods/output/inputData/Intermediate/overrides/
mkdir -p /apps/data/cmrods/output/inputData/DQ
mkdir -p /apps/data/cmrods/output/inputData/Intermediate/augmentation
mkdir -p /apps/data/cmrods/output/inputData/Intermediate/filters
mkdir -p /apps/data/cmrods/output/inputData/Intermediate/overrides
mkdir -p /apps/data/cmrods/output/inputData/Intermediate/spark/staging
mkdir -p /apps/data/cmrods/input/inputData

cd /apps/cmrods/sacva_apms/bin
sh inputdata_download.sh $1 $2

echo "************************************************ RUN ID *******************************************************"
cd /apps/data/cmrods/input/inputData
filename=`ls saccr_report_OSFI-BFG-NEW_${2}_*.csv | tail -1`
echo "Using: $filename"
runID=`echo ${filename} |cut -d'_' -f5 | cut -d'.' -f1`
echo "*********** Run ID = $runID ****************"


echo "************************************************Saccr exposure run *******************************************************"
echo "Date: "  $2
cd /apps/cmrods/sacva_apms/bin
sh Saccr_exposure_run.sh $2 $runID

echo "************************************************Finance Report Run*******************************************************"
sh Finance_Report_run.sh $2 $runID


echo "************************************************Finance Report Join *******************************************************"
sh Saccr_Finance_Report_Join.sh $2 $runID $2
sh Transform_Joined_Saccr_Finance_Report.sh $2 $runID

echo "************************************************Generating BCL report *******************************************************"
sh Run_BCL_Report.sh $2 $runID
sh Run_Derivative_Report.sh $2 $runID

echo "***************************************Copying output*************************************************************************"
mkdir -p "/apps/data/cmrods/group/CCR Test files/inputData/$2/input"
mkdir -p "/apps/data/cmrods/group/CCR Test files/inputData/$2/output"


#cp -r /apps/data/cmrods/input/inputData/* "/apps/data/cmrods/group/CCR Test files/inputData/$2/input/"
mkdir -p /apps/data/cmrods-bak/input_data/$2
cp -r /apps/data/cmrods/output/inputData/* /apps/data/cmrods-bak/input_data/$2/
cp $5/console.log /apps/data/cmrods-bak/input_data/$2/
chmod -R 777 /apps/data/cmrods-bak/input_data/

echo "***************************************End of Execution*************************************************************************"

