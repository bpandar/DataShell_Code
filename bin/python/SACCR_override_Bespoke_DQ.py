# Create a python script for MARP-7328

from sys import argv
import pandas as pd
import numpy as np
import os
import glob

# Required arguments to run file
bus_dt = argv[1]
input_dir = argv[2]
output_dir = argv[3]

# Reading available files
csv_files = glob.glob(os.path.join(input_dir, "trade_override_set_??_" + bus_dt + ".csv"))

# Creating a dataframe for the summary file
summary_files = os.path.join(output_dir, "trade_override_set_" + bus_dt + ".Bespoke.summary.dq.csv")
summary_df = pd.DataFrame(columns=['Key', 'Level', 'Severity', 'Comment', 'Count'])
summary_df.to_csv(summary_files, index=False)


# Function to write a summary file for each business date
def writeSummary(key, count):
    comment = 'The concatenation of CPTY_CD+LEGL_ENTITY_CD+NETG_REF+CLTRL_REF is not unique'
    summary = {'Key': key, 'Level': 'Attribute', 'Severity': 'Warning', 'Comment': comment, 'Count': count}
    summary_df.loc[len(summary_df)] = summary


for file in csv_files:

    file_name = os.path.basename(file)
    print('Processing the File:', file_name)

    type_dict = {'CALC_TYPE': 'str', 'SRC_SYS_CD': 'str', 'PARNT_TRADE_ID': 'str', 'CPTY_CD': 'str'
                 , 'LEGL_ENTITY_CD': 'str', 'NETG_REF': 'str', 'CLTRL_REF': 'str'}

    df = pd.read_csv(file, index_col=False, sep=",", dtype=type_dict)

    # Filter only required columns
    column_list = ['CALC_TYPE', 'SRC_SYS_CD','PARNT_TRADE_ID', 'CPTY_CD', 'LEGL_ENTITY_CD', 'NETG_REF', 'CLTRL_REF']
    df = df[column_list]

    # Drop records where PARNT_TRADE_ID is Null or <NA>
    df['PARNT_TRADE_ID'] = df['PARNT_TRADE_ID'].replace('<NA>', np.nan)
    not_na_df = df.dropna(subset=['PARNT_TRADE_ID'])

    # Replace nan records with string 'NA'
    df = not_na_df.replace(np.nan, 'NA', regex=True)

    # Concatenated key for 'CALC_TYPE' + 'PARNT_TRADE_ID' + 'SRC_SYS_CD' separated by double underscore
    df['KEY'] = df['CALC_TYPE'] + "+" + df['SRC_SYS_CD'] + "+" + df['PARNT_TRADE_ID']
    df['VALUE'] = df['CPTY_CD'] + "+" + df['LEGL_ENTITY_CD'] + "+" + df['NETG_REF'] + "+" + df['CLTRL_REF']

    # Create a key-value dataframe to drop duplicates and generate count for each key
    df_key_value = df[['KEY', 'VALUE']]
    unique_df = df_key_value.drop_duplicates(subset=['KEY', 'VALUE'])
    group_df = unique_df.groupby(['KEY'])['VALUE'].count().reset_index(name='count')

    # Extract records where count > 1, indicating non-unique records
    final_df = group_df.loc[group_df['count'] > 1]
    print(final_df)
    failed_count = len(final_df)
    print(failed_count)
    failed_df = unique_df[unique_df['KEY'].isin(final_df['KEY'])]
    failed_df_sorted = failed_df.sort_values(by='KEY')

    # Generate detail file enlisting the failed records
    detail_file = file_name.split('.')[0] + ".Bespoke.detail.dq.csv"
    detail_output = os.path.join(output_dir, detail_file)

    # Generate file key
    split_list = file_name.split('_')[:4]
    key = "_".join(split_list)

    # Generate files only if failed records exist
    if failed_count > 0:
        writeSummary(key, failed_count)
        failed_df_sorted.to_csv(detail_output, index=False)


# Output the dataframe as csv file
summary_df.to_csv(summary_files, index=False)
print("Failed records are saved in the file: ", summary_files)
print()


