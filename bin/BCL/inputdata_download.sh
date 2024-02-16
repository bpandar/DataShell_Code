
DATE_EXECUTION=$2

echo "Business date: $DATE_EXECUTION"

rm -rf /apps/data/cmrods/input/inputData/*.csv
cd /apps/data/cmrods/output/inputData/
find /apps/data/cmrods/output/inputData/ -type f -exec rm {} +

cp /apps/data/cmrods-bak/input_data/input/finance/CM_Finance_${DATE_EXECUTION}.csv /apps/data/cmrods/input/inputData/CM_Finance_${DATE_EXECUTION}.csv
cp /apps/data/cmrods-bak/input_data/input/finance/CM_Finance_${DATE_EXECUTION}.csv /apps/data/cmrods/prev/CM_Finance.csv
if [ ! -f /apps/data/cmrods/input/inputData/CM_Finance_${DATE_EXECUTION}.csv ]
then
cp /apps/data/cmrods/prev/CM_Finance.csv /apps/data/cmrods/input/inputData/CM_Finance_${DATE_EXECUTION}.csv
fi
cp /apps/data/cmrods-bak/input_data/staticdata/* /apps/data/cmrods/staticdata
cp /apps/data/cmrods-bak/input_data/override/* /apps/cmrods/sacva_apms/conf/config/

LAST_DAY=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`

#if [[ $LAST_DAY == $DATE_EXECUTION ]]; then     
if [[ $1 = "Monthly" ]]; then
echo "Downloading from monthly server"
FLAG=m	  
sftp saccr_sftp@cmtolpsccrapp01.bmocm.com<<EOF
cd /apps/saccr/data/${DATE_EXECUTION}/out/report
lcd /apps/data/cmrods/tmp
get saccr_report_OSFI-BFG-NEW_${DATE_EXECUTION}_*.csv
lcd /apps/data/cmrods/input/inputData
get CMRODS.IDP.FULL*
get saccr_ead_*.csv
bye
EOF


else
echo "Downloading from daily server"
FLAG=d	  
sftp saccr_sftp@cmtolpsccrapp02.bmocm.com<<EOF
cd /apps/saccr/data/${DATE_EXECUTION}/out/report
lcd /apps/data/cmrods/tmp
get saccr_report_OSFI-BFG-NEW_${DATE_EXECUTION}_*.csv
lcd /apps/data/cmrods/input/inputData
get CMRODS.IDP.FULL*
get saccr_ead_*.csv
bye
EOF
fi

sleep 2

echo "***************Move saccr_report file from tmp -> input Directory *******************************************************"
cd /apps/data/cmrods/tmp
filename=`ls saccr_report_OSFI-BFG-NEW_${2}_*.csv | tail -1`
echo "Using: $filename"
runID=`echo ${filename} |cut -d'_' -f5 | cut -d'.' -f1`
echo "*********** Run ID = $runID ****************"
new_file=saccr_report_OSFI-BFG-NEW_${FLAG}_${2}_${runID}.csv
mv $filename $new_file
cp $new_file /apps/data/cmrods/input/inputData

