#!/bin/bash

#=========================Date for Execution=========================
if [ $# -eq 0 ]; then
    >&2 echo "Error: Please provide the Business date(YYYYMMDD) as a parameter"
    exit 1
fi
ExecDate=$1

#=========================Defining paths=========================
INPUT_DIR=/apps/data/cmrods/group/CMRODS/SACVA/DQ/${ExecDate}
OUTPUT_DIR=/apps/data/cmrods/group/CMRODS/SACVA/DQ/${ExecDate}

# Set the output file names
summary_output_file=${OUTPUT_DIR}/CVA_${ExecDate}_summ.csv
detail_output_file=${OUTPUT_DIR}/CVA_${ExecDate}_det.csv
excel_file=${OUTPUT_DIR}/InputData_SACVA_summary_${ExecDate}.xlsx

temp_summary_file=${OUTPUT_DIR}/temp_summ_file.csv
temp_detail_file=${OUTPUT_DIR}/temp_det_file.csv

# Set Python bin path
python3=/apps/cmrods/ng/analytics/venv/bin/python3

# Remove the output file if it already exists
if [ -e "$summary_output_file" ]; then
	rm "$summary_output_file"
fi
if [ -e "$detail_output_file" ]; then
	rm "$detail_output_file"
fi
if [ -e "$excel_file" ]; then
	rm "$excel_file"
fi

if [ -e "$temp_summary_file" ]; then
	rm "$temp_summary_file"
fi

if [ -e "$temp_detail_file" ]; then
	rm "$temp_detail_file"
fi

#==================Combined Summary File=============================

														 
echo -n > "$summary_output_file"

$python3 - << EOF
import csv
import os



# Find the files that have ".summary." in their name and save their full path in a dictionary
summary_files = {}
for root, dirs, file_list in os.walk("$INPUT_DIR"):
	for file in file_list:
		if ".summary." in file.lower():
			key = os.path.basename(os.path.join(root, file))
			summary_files[key] = os.path.join(root, file)

with open("$summary_output_file", mode='w', newline='') as output_file:
	writer = csv.writer(output_file)
	# Write the header in Summary output file with custom column names
	writer.writerow(["File Name", "DQ Rule ID", "DQ Rule", "Fail Count"])
	cnt = 1

	for summary_file in summary_files:
		# Use the dictionary to get the filepath of the summary file
		with open(summary_files[summary_file], newline='') as file:
			reader = csv.reader(file)
			next(reader)
			
			for _, row in enumerate(reader, start=1):
				writer.writerow([summary_file.replace("summary.", ""), cnt, row[3], row[4]])
				cnt += 1
EOF

#==================Combined Detail File=============================

					 
																									   
echo -n > "$detail_output_file"

python3 - << EOF
import csv
import os



# Find the files that have ".detail." in their name and save their full path in a dictionary
detail_files = {}
for root, dirs, file_list in os.walk("$INPUT_DIR"):
	for file in file_list:
		if ".detail." in file.lower():
			key = os.path.basename(os.path.join(root, file))
			detail_files[key] = os.path.join(root, file)

with open("$detail_output_file", mode='w', newline='') as output_file:
	writer = csv.writer(output_file)
	# Write the header in Detail output file with custom column names
	writer.writerow(["File Name", "Severity", "Level", "RecordNumber", "Notification", "DQ Rule ID", "DQ Rule", "Fail Record"])
	cnt = 1

	for detail_file in detail_files:
		# Use the dictionary to get the filepath of the detail file
		with open(detail_files[detail_file], newline='') as file:
			reader = csv.reader(file)
			next(reader)

			for record_id, row in enumerate(reader, start=1):
				writer.writerow([detail_file.replace("detail.", ""), row[0], row[1], row[2], row[3], cnt, row[4], row[5]])
				cnt += 1
EOF

#===================Combine 2 csv files in excel=============================

# Specify the sheet names
sheet1="Summary"
sheet2="Detail"


# Create the combined Excel file using Python and xlsxwriter
$python3 - << EOF
import csv
import xlsxwriter

# Create a new Excel file
workbook = xlsxwriter.Workbook('$excel_file')

# Add the first sheet
worksheet1 = workbook.add_worksheet('$sheet1')
with open('$summary_output_file', 'r') as csvfile:
    csvreader = csv.reader(csvfile)
    for row_num, row in enumerate(csvreader):
        for col_num, value in enumerate(row):
            worksheet1.write(row_num, col_num, value)

# Add the second sheet
worksheet2 = workbook.add_worksheet('$sheet2')
with open('$detail_output_file', 'r') as csvfile:
    csvreader = csv.reader(csvfile)
    for row_num, row in enumerate(csvreader):
        for col_num, value in enumerate(row):
            worksheet2.write(row_num, col_num, value)

# Close the workbook
workbook.close()
EOF

if [ -e "$summary_output_file" ]; then
	rm "$summary_output_file"
fi
if [ -e "$detail_output_file" ]; then
	rm "$detail_output_file"
fi

echo "InputData SACVA DQ Summary Report generated at $excel_file"

#===================Uploading output File=============================
TEMP_DIR=${OUTPUT_DIR}/temp
mkdir -p ${TEMP_DIR}
chmod -R 755 ${TEMP_DIR}
cp ${OUTPUT_DIR}/InputData_SACVA_summary_${ExecDate}.xlsx ${TEMP_DIR}/

sleep 2
echo "Uploading SACVA DQ Summary report file to \\ibgnctofil02.ibg.adroot.bmogc.net\group\IRIS\Download\CMRODS\SACVA\DQ\${ExecDate}"

#sftp sa_cmrods@cmtowptitnapp02.ibg.adroot.bmogc.net<<-EOF
#lcd ${TEMP_DIR}
#cd group/IRIS/Download/CMRODS/SACVA/DQ/${ExecDate}
#put InputData_SACVA_summary_${ExecDate}.xlsx
#bye
#EOF
echo "Success : $?"
exitCode=$?


if [ $exitCode -ne 0 ]; then
   echo "SACVA DQ Summary report upload to Business Folder Failed "
else
   echo "SACVA DQ Summary report upload to Business Folder Success"
fi   
#================================================
   
sleep 2
#===================Sending email=============================
echo ""
echo "Sending Summary Report Email.."
body="Hi Team,\nInputData SACVA DQ Summary report is generated at path : \\\\\ibgnctofil02.ibg.adroot.bmogc.net\\group\\IRIS\\Download\\CMRODS\\SACVA\\DQ\\${ExecDate}\\. \n \nRegards,\nDnA Team"
subject="InputData SACVA DQ Summary Report Status"
s_From="RiskDnASupport@bmo.com"								 
s_To="Bhoopathy.pandari@bmo.com"
#echo -e "$body" | mailx -s "$subject" -r $s_From $s_To

#================================================
rm -r ${TEMP_DIR}
chmod -R 777 ${excel_file}
