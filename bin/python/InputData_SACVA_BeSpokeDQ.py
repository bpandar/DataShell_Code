import glob
import math
import time
from datetime import datetime
import logging
import os.path
import sys
import pandas as pd
from numpy import double

pd.set_option('mode.chained_assignment', None)

# File paths
config_dir = r'/apps/cmrods/sacva_apms/conf/InputData_SACVA/config'
prev_dir = r'/apps/data/cmrods/prev'
pylog_dir = r'/apps/data/cmrods/group/CMRODS/SACVA/DQ/logs'

config_file = 'SACVA_BeSpoke_DQ_Rules.csv'


class BeSpokeDQ:

    def __init__(self, busdate, input_path, output_path):
        self.prev_dir = prev_dir
        self.config_dir = config_dir
        self.busdate = busdate
        self.input_path = input_path
        self.output_path = output_path
        self.summary_df = pd.DataFrame(columns=['Key', 'Level', 'Rule', 'Severity', 'Comment', 'Count'])
        self.file_name = os.path.join(self.output_path, f'Bespoke_Summary_{self.busdate}.csv')

    def executeRule(self, config):
        try:
            rule_file = os.path.join(config_dir, config)
            flag = self.checkFileExists(rule_file)
            if flag == 1:
                rule_df = self.convertCSVToDataFrame(rule_file, ',')
                self.execute_BespokeDQ_Rules(rule_df)
                print(self.summary_df)
                self.summary_df.to_csv(self.file_name, index=False)

        except IOError as err:
            print('Config file not exist: {0}'.format(config_file), type(err))
            logging.info('Config file not exist: {0}'.format(config_file), type(err))
            exit()

    # Converting csv file into Dataframe
    def convertCSVToDataFrame(self, filename, delim):
        try:
            df = pd.read_csv(filename, sep=delim, skiprows=0)
            return df

        except IOError as err:
            print('The Input file is not Present: {0}'.format(filename), type(err))
            logging.info('The Input file is not Present: {0}'.format(filename), type(err))

    # Function to check record count
    def recordCount_Check(self, feed, file_df_list, rule, level, severity, attribute, operator, value, comment):
        osfibfg_count = file_df_list[0].shape[0]
        carved_count = file_df_list[1].shape[0] + file_df_list[2].shape[0]

        if osfibfg_count % carved_count == 0:
            print("Record count check is Pass")
            logging.info("Record count check is Pass")

        else:
            print("Record count check is Fail..")
            logging.info("Record count check is Fail..")
            summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': 1}
            self.summary_df.loc[len(self.summary_df)] = summary_entry

    # check the ABS SUM of given EAD is matched.
    def absSUM_Attribute_Check(self, feed, file_df_list, rule, level, severity, attribute, operator, value, comment):
        boolean_value = ''
        if len(file_df_list) >= 3 and rule == "ABS_SUM":
            df1 = file_df_list[0][attribute].sum()
            df2 = file_df_list[1][attribute].sum()
            df3 = file_df_list[2][attribute].sum()

            # The ABS sum of EAD value between CarvedIN+CarvedOut-Osfi-Bfg-New
            abs_column = abs(df2 + df3 - df1)
            boolean_value = self.operator_Checker(abs_column, double(value), operator.lower())

        elif len(file_df_list) < 3 and rule == "SUM":
            print("Multiple files are not given check input Feed")
            logging.info("Multiple files are not given check input Feed")
            sum_column = file_df_list[0][attribute].sum()
            boolean_value = self.operator_Checker(sum_column, value, operator.lower())

        if boolean_value:
            print("{0} check is Pass....".format(attribute))
            logging.info("{0} check is Pass....".format(attribute))

        else:
            print("{0} check is Fail....".format(attribute))
            logging.info("{0} check is Fail....".format(attribute))
            summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': 1}
            self.summary_df.loc[len(self.summary_df)] = summary_entry

    # Function to check if percentage of difference between today and yesterday files is less than a threshold
    def getDelta_Percentage(self, feed, file_df_list, rule, level, severity, attribute, operator, value, comment):
        today_df = file_df_list
        yesterday_file = os.path.join(self.prev_dir, feed + ".csv")
        file_flag = self.checkFileExists(yesterday_file)
        count = 0
        if file_flag == 1:
            yesterday_df = self.convertCSVToDataFrame(yesterday_file, ",")
            if rule == 'SUM_DELTA_PERCENT':
                today_sum_df = today_df[0][attribute].sum()
                yesterday_sum_df = yesterday_df[attribute].sum()

                delta_percent = 100.0 * (today_sum_df - yesterday_sum_df) / yesterday_sum_df
                boolean_value = self.operator_Checker(delta_percent, double(value), operator.lower())
                count = 1

            elif rule == 'SUM_GROUP_DELTA_PERCENT':
                column_list = attribute.split("|")
                today_df = today_df[0][column_list]
                new_col_name = 'CONCAT_COLUMN'

                # Today file dataframe and filter value contains 0.
                today_sum_df = self.getGroupBy_Sum_Dataframe(today_df, column_list, '+', new_col_name)

                # Yesterday file dataframe and filter value contains 0.
                yesterday_sum_df = self.getGroupBy_Sum_Dataframe(yesterday_df, column_list, '+', new_col_name)
                yesterday_sum_df = yesterday_sum_df.loc[(yesterday_sum_df[column_list[0]] != 0.0)]

                merge_df = pd.merge(today_sum_df, yesterday_sum_df, left_on=[new_col_name], right_on=[new_col_name]
                                    , how='inner', suffixes=('_T', '_Y'))

                column_t = column_list[0] + '_T'
                column_y = column_list[0] + '_Y'
                merge_df['DELTA_PERCENTAGE'] = round(abs(100 * (merge_df[column_t] - merge_df[column_y]) / merge_df[column_y]))
                merge_df['check'] = self.operator_Checker(merge_df['DELTA_PERCENTAGE'], double(value), operator.lower())
                failed_df = merge_df[~merge_df['check']]
                count = len(failed_df)

                attribute = column_list[0]
                if count > 0:
                    self.write_Bad_Records(failed_df, rule, feed)
                    boolean_value = False
                else:
                    boolean_value = True

            if boolean_value:
                print("{0} sum({1}) delta percentage between today and yesterday file is less than 20%: ".format(feed, attribute))
                logging.info("{0} sum({1}) delta percentage between today and yesterday file is less than 20%: ".format(feed, attribute))
            else:
                print("{0} sum({1}) delta percentage between today and yesterday file is not less than 20%: ".format(feed, attribute))
                logging.info("{0} sum({1}) delta percentage between today and yesterday file is not less than 20%: ".format(feed, attribute))
                summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': count}
                self.summary_df.loc[len(self.summary_df)] = summary_entry

        else:
            comment = "Yesterday file is missing: {0} ".format(yesterday_file)
            print("Check the file presence or record count...")
            logging.info("Yesterday file is missing: {0} ".format(yesterday_file))
            summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': count}
            self.summary_df.loc[len(self.summary_df)] = summary_entry

    # Function to check if concatenation of attributes is unique
    def check_ConcatUnique(self, feed, file_df_list, rule, level, severity, attribute, operator, value, comment):
        attribute_list = attribute.split("|")
        df = file_df_list[0]

        if len(attribute_list) > 1 and rule == 'CONCAT_UNIQUE':
            duplicate_df = df[df.duplicated(subset=attribute_list)]
            duplicate_count = len(duplicate_df)
            failed_df = duplicate_df[attribute_list]

        elif len(attribute_list) == 2 and rule == 'CONCAT_GROUP':
            # Drop duplicate records with combination of attribute
            unique_df = df.drop_duplicates(subset=attribute_list)
            # Group by attribute1 and count multiple values of attribute2 for single attribute1 value
            group_df = unique_df.groupby([attribute_list[0]])[attribute_list[1]].count().reset_index(name='count')

            # Get More than one attribute2 value for single attribute1 value
            duplicate_df = group_df.loc[group_df['count'] > 1]
            duplicate_count = len(duplicate_df)
            failed_df = unique_df[unique_df[attribute_list[0]].isin(duplicate_df[attribute_list[0]])]
            failed_df = failed_df[attribute_list]

        elif len(attribute_list) == 1 and rule == 'UNIQUE':
            duplicate_df = df[df.duplicated(subset=attribute_list)]
            duplicate_count = len(duplicate_df)
            failed_df = duplicate_df[attribute_list]
        else:
            print("Attribute is not given to check UNIQUE record..Please check the rule")
            logging.info("Attribute is not given to check UNIQUE record..Please check the rule")

        if duplicate_count > 0:
            print("{0} Duplicate records found in : {1}".format(str(duplicate_count), feed))
            logging.info(" {0} Duplicate records found in : {1}".format(str(duplicate_count), feed))
            summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': duplicate_count}
            self.summary_df.loc[len(self.summary_df)] = summary_entry
            self.write_Bad_Records(failed_df, rule, feed)
        else:
            print("There is no Duplicate records found in: {0} ".format(feed))
            logging.info("There is no Duplicate records found in: {0} ".format(feed))

    # Function to check sum of groups
    def check_SumOf_GroupBy(self, feed, file_df_list, rule, level, severity, attribute, operator, value, comment):
        attribute_list = attribute.split("|")
        df = file_df_list[0]
        groupby_df = df.groupby([attribute_list[1]])[attribute_list[0]].sum().reset_index(name='SUM_VALUE')
        # print(groupby_df)
        passed_list = list()
        failed_list = list()
        for index, key in groupby_df.iterrows():
            if key['RISK_TYPE'] != 'Risk_Credit':
                boolean_value = self.operator_Checker(key['SUM_VALUE'], double(value), operator.lower())
                if boolean_value:
                    passed_list.append(key['RISK_TYPE'])
                else:
                    failed_list.append(key['RISK_TYPE'])
        if len(failed_list) != 0:
            print("{0} Sum of SENSITIVITY_AMOUNT is greater than 3B for Risk_Type:{1} ".format(feed, failed_list))
            logging.info("{0} Sum of SENSITIVITY_AMOUNT is greater than 3B for Risk_Type:{1} ".format(feed, failed_list))
            summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment,'Count': len(failed_list)}
            self.summary_df.loc[len(self.summary_df)] = summary_entry
            mask = groupby_df['RISK_TYPE'].isin(failed_list)
            # mask will fetch only True record from DF
            failed_df = groupby_df[mask]
            self.write_Bad_Records(failed_df, rule, feed)

    def execute_BespokeDQ_Rules(self, rule_df):

        # Running DQ Rules from config_file
        for index, row in rule_df.iterrows():
            rule_dict = dict(row)
            feed = rule_dict['Feed']
            level = rule_dict['Level']
            severity = rule_dict['Severity']
            rule = rule_dict['Rule']
            attribute = rule_dict['Attribute']
            operator = rule_dict['Operator']
            value = rule_dict['Value']
            comment = rule_dict['Comment']
            notification = rule_dict['Notification']

            file_df_list = self.get_File_Dataframe(feed)

            if len(file_df_list) > 0:
                if rule == 'RECORDCOUNT':
                    print("Performing Bespoke Record count between multiple files..")
                    logging.info("Performing Bespoke Record count between multiple files..")
                    self.recordCount_Check(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'ABS_SUM':
                    print("Performing Bespoke ABS SUM of EAD values between multiple files..")
                    logging.info("Performing Bespoke ABS SUM of EAD values between multiple files..")
                    self.absSUM_Attribute_Check(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'SUM':
                    print("Performing Bespoke SUM of Attribute value for each file..")
                    logging.info("Performing Bespoke SUM of Attribute value for each file..")
                    self.absSUM_Attribute_Check(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'SUM_DELTA_PERCENT':
                    print("Performing Bespoke Attribute Delta percentage between Today & Yesterday files..")
                    logging.info("Performing Bespoke Attribute Delta percentage between Today & Yesterday files..")
                    self.getDelta_Percentage(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'CONCAT_UNIQUE':
                    print("Performing Bespoke Attributes concatenation and Unique check..")
                    logging.info("Performing Bespoke Attributes concatenation and Unique check..")
                    self.check_ConcatUnique(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'CONCAT_GROUP':
                    print("Performing Bespoke Attributes Grouping and Unique check..")
                    logging.info("Performing Bespoke Attributes Grouping and Unique check..")
                    self.check_ConcatUnique(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'SUM_GROUP':
                    print("Performing Bespoke Attributes Grouping and Unique check..")
                    logging.info("Performing Bespoke Attributes Grouping and Unique check..")
                    self.check_SumOf_GroupBy(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                elif rule == 'SUM_GROUP_DELTA_PERCENT':
                    print("Performing Bespoke Attribute Delta percentage between Today & Yesterday files..")
                    logging.info("Performing Bespoke Attribute Delta percentage between Today & Yesterday files..")
                    self.getDelta_Percentage(feed, file_df_list, rule, level, severity, attribute, operator, value, comment)

                else:
                    print("Given Rule is not setup in Bespoke code..")
                    logging.info("Given Rule is not setup in Bespoke code..")
            else:
                comment = "The Given file {0} is not exist...".format(feed)
                summary_entry = {'Key': feed, 'Rule': rule, 'Level': level, 'Severity': severity, 'Comment': comment, 'Count': 1}
                self.summary_df.loc[len(self.summary_df)] = summary_entry

    # CSV file for failed records
    def write_Bad_Records(self, df, rule, feed):
        name_list = [feed, rule, self.busdate, "detail.csv"]
        file_path = self.get_Input_Output_path(self.output_path, feed)
        bad_file = os.path.join(file_path, "_".join(name_list))
        df.to_csv(bad_file, index=False)

    def get_File_Dataframe(self, feed):
        file_suffix = "_" + self.busdate + ".csv"
        file_path = self.get_Input_Output_path(self.input_path, feed)
        df_list = list()
        file_list = list()
        if ";" in feed:
            feed_list = feed.split(";")
            for filename in feed_list:
                file_list.append(os.path.join(file_path, filename + file_suffix))
        else:
            file_list.append(os.path.join(file_path, feed + file_suffix))

        for file in file_list:
            flag = self.checkFileExists(file)
            if flag == 1:
                df_list.append(self.convertCSVToDataFrame(file, ","))
            else:
                continue

        return df_list

    # Concatenate DataFrame columns values
    def concate_columns(self, df, cols_list, delim, new_col_name):
        new_col_name = new_col_name if new_col_name != '' else 'CONCAT_COLUMN'
        col_len = len(cols_list)
        if col_len > 1:
            df[new_col_name] = df[cols_list[0]]
            for col in cols_list[1:]:
                df[new_col_name] = df[new_col_name].map(str) + delim + df[col].map(str)
            return df
        else:
            print("Provide more than one columns to Concatenate & columns size is: {0}".format(col_len))
            logging.info("Provide more than one columns to Concatenate & columns size is: {0}".format(col_len))

    # Function to check sum of concatenated groups
    def getGroupBy_Sum_Dataframe(self, df, column_list, delim, concat_column):
        filtered_df = df[~df[column_list[0]].isna()]
        filtered_df = self.concate_columns(filtered_df, column_list[1:], delim, concat_column)
        new_column_df = filtered_df[[concat_column, column_list[0]]]
        sum_df = new_column_df.groupby(by=concat_column)[column_list[0]].sum().reset_index()
        return sum_df

    def operator_Checker(self, qty, limit, operator):

        if "eq" == operator:
            return math.abs(qty - limit) < 1e-06
        elif "le" == operator:
            return qty <= limit
        elif "lt" == operator:
            return qty < limit
        elif "ge" == operator:
            return qty >= limit
        elif "gt" == operator:
            return qty > limit
        elif "bt" == operator:
            between_limit = limit.split("|")
            if len(between_limit) == 2:
                return double(between_limit[0]) <= qty <= double(between_limit[1])
            else:
                between = math.abs(double(between_limit[0]))
                return double(-between) <= qty <= double(between_limit[0])
        else:
            return True

    def get_Input_Output_path(self, path, feed):

        if "_filter" in feed:
            file_path = os.path.join(self.output_path, "saccr/filter")
        elif "LITES.CVA" in feed:
            file_path = os.path.join(path, "lites")
        elif "MAPG_OVRD" or "SACCR_BWAR" in feed:
            file_path = os.path.join(path, "bma")
        elif "FX_MARKETDATA" or "SACCR_OSFI" or "SACCR_EBA" in feed:
            file_path = os.path.join(path, "saccr")
        else:
            print("Feed name not matched with given Setup.:{0}".format(feed))
            logging.info("Feed name not matched with given Setup.:{0}".format(feed))
        return file_path

    def checkFileExists(self, file):
        try:
            if os.path.isfile(file):
                logging.info("File exist...: {0}  Continue...".format(file))
                file_flag = 1
            else:
                print("File not exist, please check the directory: {0}".format(file))
                logging.info('File not exist: {0}, please check the directory:'.format(file))
                file_flag = 0

        except IOError as err:
            print('File not exist: {0}'.format(type(err)))
            logging.info('File not exist: {0}'.format(type(err)))

        return file_flag

# Function to keep last 10 days files if log folder has more than 100 files
def manage_log_files(path):
    files = glob.glob(os.path.join(path, "*.log"))

    # Delete log files once it reached count of 100
    if len(files) >= 100:
        files.sort(key=os.path.getmtime, reverse=True)
        cleanup_files = list()
        current_time = time.time()

        for log_file in files:
            time_delta = current_time - os.path.getmtime(log_file)
            time_delta_days = time_delta / (60 * 60 * 24)

            # Add number of days file want to keep
            if time_delta_days >= 10:
                cleanup_files.append(log_file)
                os.remove(log_file)


def provide_permission(path):
    os.chmod(path, 0o777)


if __name__ == "__main__":

    now = datetime.now()
    date_time = now.strftime("%Y%d%m%H%M%S")
    logging.basicConfig(filename="{0}/sacva_bespoke_dq_logs_{1}.log".format(pylog_dir, date_time), filemode='w',
                        format='%(asctime)s - %(levelname)s - %(message)s')
    logging.getLogger().setLevel(logging.INFO)
    provide_permission("{0}/sacva_bespoke_dq_logs_{1}.log".format(pylog_dir, date_time))

    input_pram = len(sys.argv)
    try:
        if input_pram > 3:
            busdate = sys.argv[1]
            folder_in = sys.argv[2]
            folder_out = sys.argv[3]
        else:
            print('Provide Business date {0}{1}'.format('YYYYMMDD'))
            logging.info('Provide Business date {0}{1}'.format('YYYYMMDD'))

    except Exception as err_ex:
        print("__init__: Provide Business date: ", err_ex, " ", type(err_ex))
        logging.info("__init__: Provide Business date: ", err_ex, " ", type(err_ex))

    manage_log_files(pylog_dir)

    BeSpokeDQ = BeSpokeDQ(busdate, folder_in, folder_out)
    BeSpokeDQ.executeRule(config_file)
