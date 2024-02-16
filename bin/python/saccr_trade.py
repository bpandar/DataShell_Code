# -*- coding: utf-8 -*-
"""
Author: Hoyt Lui
Date: 2023-02-22
Contact: hoyt.lui@bmo.com
Copyright: Copyright 2023, The SACCR CCBasel Decommissioning Project
Modified by: Bhoopathy, Shreya
Date: 2023-08-14
"""
import os
import glob
import datetime as dt
import sys

import numpy as np
import pandas as pd
import logging

import warnings
warnings.filterwarnings('ignore')


class SaccrTrade:
    def __init__(self, busdate, period, idp_exposure, saccr_trade, output_path):
        self.log_df = pd.DataFrame(columns=['Business date', 'Column', 'Value', 'Message'])
        self.busdate = busdate
        self.period = period
        self.path_out = output_path
        self.idp_exposure = idp_exposure
        self.saccr_trade = saccr_trade
        self.saccr_trade_file = f'saccr_ccbasel_trade_{self.period}_{self.busdate}.csv'
        self.logging_file = os.path.join(output_path, f'log_{self.period}_{self.busdate}.csv')

    def map(self):
        df = self._join()
        df = self._rename_cols(df)
        df = self._add_cols(df)
        df = self._change_type(df)
        df = self._order_cols(df)
        df = self._format(df)
        df.to_csv(os.path.join(self.path_out, self.saccr_trade_file), index=False, header=False)
        self.log_df.to_csv(self.logging_file, index=False)

    def _join(self):
        df_exposure_orig = self._read_idp_exposure()
        df_exposure = self._extract_exposure_cols(df_exposure_orig)

        df_osfi_orig = self._read_osfi_file()
        df_osfi = self._extract_osfi_cols(df_osfi_orig)
        df_osfi['SRC_SYS_CD'] = df_osfi['SRC_SYS_CD'].str.replace('NONCORE_IBG', 'NONCORE_IB')

        df = pd.merge(df_exposure, df_osfi, left_on=['DERIV_EXP_TRANS_ID', 'TRD_SRC_SYS_ID'],
                      right_on=['TRADE_ID', 'SRC_SYS_CD'], how='left', indicator=True, suffixes=('', '_obn'))
        df = df.dropna(subset=['DERIV_EXP_TRANS_ID'])
        df.drop(columns=['TRADE_ID', 'SRC_SYS_CD'], inplace=True)

        condition = (df['CLNT_TRADE_IND'] == 'Y') & (df['QCCP_IND'] == 'Y') & (df['BMO_GUAR_CCP_TO_CLIENT_IND'] == 'N')
        df['SACCR_RC'] = pd.Series(np.where(condition, df['RC_LR'], df['SA_CCR_REPL_CST_AMT']))
        df['SACCR_PFE'] = pd.Series(np.where(condition, df['PFE_LR'], df['SA_CCR_POT_EXP_AMT']))

        return df

    def _get_latest_file(self, list_of_files):
        latest_file = max(list_of_files, key=os.path.getctime)
        return latest_file

    def _rename_cols(self, df):
        df = df.rename(columns={
            'TRD_SRC_SYS_ID': 'SRC_SYS_CD',
            'DERIV_EXP_TRANS_ID': 'TRADE_ID',
            'ACR_CD': 'CPTY_CD',
            'BRWR_UEN_ID': 'UEN',
            'INTR_BNK_CNTRPRTY_IND': 'INTRNL_EXTR_IND',
            'RESP_NODE': 'RSPNSBTY_CENTRE',
            'TRANSIT_NO': 'TRANSIT',
            'LNDR_HOST_CD': 'LEGL_ENTITY_CD',
            'CR_VALTN_ADJ_AMT': 'CVA_LOSS',
            'BMO_GUAR_CCP_TO_CLIENT_IND': 'CCP_PERFC_TO_CLNT_GUAR_IND',
            'SA_CCR_EFF_NTNL_AMT': 'SACCR_EFF_NOTIONAL',
            'CVA_CPTL_EXMPT_IND': 'CVA_CPTL_EXMPTN_IND',
            'SA_NOTIONAL': 'SACCR_TRADE_NOTIONAL',
            'HLD_TRD_BK_IND': 'TRADE_OR_BANK_IND',
            'EAD_CURR_CD': 'EAD_CCY',
            'REPL_CST_BFR_NET_AMT_CURR_CD': 'REPL_COST_BFR_NET_CCY',
            'BLTRL_IND': 'BILATERAL_IND',
            'CR_VALTN_ADJ_AMT_CURR_CD': 'CVA_LOSS_CCY',
            'CLI_LEG_CLRD_QCCP_IND': 'CLIENT_CLRD_QCCP_IND',
            'GL_ACCT_NO': 'GL_NUM',
            'BSL_AST_CLS': 'BSL_ASSET_CLASS',
            'GUAR_CR_DERIV_OR_COLL_IND': 'GUAR_CR_DRVTS_OR_COLL_IND',
            'PD_PCT_POST_CRM': 'PD_POST_CRM',
            'LGD_PCT_PRE_CRM': 'LGD_POST_CRM',
            'SA_CCR_EFF_MAT': 'M_IN_DAYS',
        })
        return df

    def _add_cols(self, df):
        df['SACCR_EAD_REDUCN'] = 0
        df['BSL_NOTIONAL_CCY_CD'] = ''
        df['SACCR_STATUS_CD'] = ''
        df['CLIENT_EAD_SCLR_VAL'] = ''
        df['NET_EXP_AMT'] = ''
        df['NET_EXP_AFT_CRM'] = ''
        df['ADJ_NET_EXP_FOR_COLL'] = ''
        df['EAD_PRE_CRM'] = ''
        df['ADJ_COLL_EAD_IND'] = ''
        df['BEEL'] = ''
        df['BEEL_CCY'] = ''
        df['HARRIS_GL'] = ''
        df['HARRIS_DEPT_ID'] = ''
        df['OTC_DRV_COLL_AMT'] = ''
        df['OTC_DRV_COLL_TYPE'] = ''
        df['REPL_COST_AFR_NET_CCY'] = df['REPL_COST_BFR_NET_CCY']
        return df

    def _change_type(self, df):
        df['M_IN_DAYS'] = pd.to_numeric(df['M_IN_DAYS'], errors='coerce')
        return df

    def _order_cols(self, df):
        df = df.reindex(columns=[
            'BUS_DT', 'SRC_SYS_CD', 'TRADE_ID', 'CPTY_CD', 'UEN', 'INTRNL_EXTR_IND', 'CCP_IND', 'QCCP_IND',
            'RSPNSBTY_CENTRE', 'TRANSIT', 'LEGL_ENTITY_CD', 'BSL_NOTIONAL_CCY_CD', 'CVA_LOSS', 'CLTRL_SET_ID',
            'CCP_PERFC_TO_CLNT_GUAR_IND', 'SACCR_STATUS_CD',
            'SACCR_EFF_NOTIONAL', 'SACCR_RC', 'SACCR_PFE', 'MRGN_IND', 'SACCR_EAD_REDUCN', 'CVA_CPTL_EXMPTN_IND',
            'SACCR_TRADE_NOTIONAL', 'TRADE_OR_BANK_IND', 'EAD_CCY', 'REPL_COST_BFR_NET_CCY',
            'REPL_COST_AFR_NET_CCY',
            'BILATERAL_IND', 'CVA_LOSS_CCY', 'CLIENT_CLRD_QCCP_IND', 'GL_NUM',
            'CLIENT_EAD_SCLR_VAL', 'BSL_ASSET_CLASS', 'NET_EXP_AMT', 'SME_IND', 'NET_EXP_AFT_CRM',
            'GUAR_CR_DRVTS_OR_COLL_IND', 'ADJ_NET_EXP_FOR_COLL', 'PD_POST_CRM', 'EAD_PRE_CRM', 'LGD_POST_CRM',
            'ADJ_COLL_EAD_IND', 'M_IN_DAYS', 'BEEL', 'BEEL_CCY', 'HARRIS_GL', 'HARRIS_DEPT_ID', 'OTC_DRV_COLL_AMT',
            'MTM', 'MTM_CCY', 'OTC_DRV_COLL_TYPE'
        ])
        return df

    def _read_idp_exposure(self):
        df = pd.read_csv(self.idp_exposure, sep='|', skiprows=1)
        cols = list(df.columns)
        new_cols = cols[1:]

        type_dict = {'TRD_SRC_SYS_ID': 'str', 'DERIV_EXP_TRANS_ID': 'str', 'ACR_CD': 'str',
                     'INTR_BNK_CNTRPRTY_IND': 'str', 'CCP_IND': 'str', 'QCCP_IND': 'str', 'RESP_NODE': 'str',
                     'TRANSIT_NO': 'str', 'LNDR_HOST_CD': 'str', 'MRGN_IND': 'str', 'CVA_CPTL_EXMPT_IND': 'str',
                     'HLD_TRD_BK_IND': 'str', 'EAD_CURR_CD': 'str', 'REPL_CST_BFR_NET_AMT_CURR_CD': 'str',
                     'BLTRL_IND': 'str', 'CR_VALTN_ADJ_AMT_CURR_CD': 'str', 'CLI_LEG_CLRD_QCCP_IND': 'str',
                     'GL_ACCT_NO': 'str', 'BSL_AST_CLS': 'str', 'SME_IND': 'str', 'GUAR_CR_DERIV_OR_COLL_IND': 'str',
                     'BRWR_UEN_ID': 'str', 'CR_VALTN_ADJ_AMT': 'float64', 'SA_CCR_EFF_NTNL_AMT': 'float64',
                     'SA_CCR_REPL_CST_AMT': 'float64',
                     'SA_CCR_POT_EXP_AMT': 'float64', 'PD_PCT_POST_CRM': 'float64', 'LGD_PCT_PRE_CRM': 'float64',
                     'SA_CCR_EFF_MAT': 'float64'}

        df = pd.read_csv(self.idp_exposure, sep='|', skiprows=2, skipfooter=1, header=None, names=new_cols, dtype=type_dict)

        # Raise errors if length constraint is not followed - strings
        self.check_str_length(df, 'TRD_SRC_SYS_ID', 10)
        self.check_str_length(df, 'DERIV_EXP_TRANS_ID', 60)
        self.check_str_length(df, 'ACR_CD', 30)
        self.check_str_length(df, 'INTR_BNK_CNTRPRTY_IND', 1)
        self.check_str_length(df, 'CCP_IND', 1)
        self.check_str_length(df, 'QCCP_IND', 1)
        self.check_str_length(df, 'RESP_NODE', 5)
        self.check_str_length(df, 'TRANSIT_NO', 5)
        self.check_str_length(df, 'LNDR_HOST_CD', 10)
        self.check_str_length(df, 'MRGN_IND', 1)
        self.check_str_length(df, 'CVA_CPTL_EXMPT_IND', 1)
        self.check_str_length(df, 'HLD_TRD_BK_IND', 1)
        self.check_str_length(df, 'EAD_CURR_CD', 3)
        self.check_str_length(df, 'REPL_CST_BFR_NET_AMT_CURR_CD', 3)
        self.check_str_length(df, 'BLTRL_IND', 1)
        self.check_str_length(df, 'CR_VALTN_ADJ_AMT_CURR_CD', 3)
        self.check_str_length(df, 'CLI_LEG_CLRD_QCCP_IND', 1)
        self.check_str_length(df, 'GL_ACCT_NO', 10)
        self.check_str_length(df, 'BSL_AST_CLS', 10)
        self.check_str_length(df, 'SME_IND', 1)
        self.check_str_length(df, 'GUAR_CR_DERIV_OR_COLL_IND', 1)
        self.check_str_length(df, 'BRWR_UEN_ID', 22)

        # Raise errors if length constraint or other conditions are not followed - numbers
        self.check_num_length(df, 'CR_VALTN_ADJ_AMT', 21)
        self.count_dec_places(df, 'CR_VALTN_ADJ_AMT', 4)
        self.check_num_length(df, 'SA_CCR_EFF_NTNL_AMT', 21)
        self.count_dec_places(df, 'SA_CCR_EFF_NTNL_AMT', 4)
        self.check_num_length(df, 'SA_CCR_REPL_CST_AMT', 21)
        self.count_dec_places(df, 'SA_CCR_REPL_CST_AMT', 4)
        self.check_num_length(df, 'SA_CCR_POT_EXP_AMT', 21)
        self.count_dec_places(df, 'SA_CCR_POT_EXP_AMT', 4)
        self.check_num_length(df, 'PD_PCT_POST_CRM', 11)
        self.count_dec_places(df, 'PD_PCT_POST_CRM', 6)
        self.unsigned(df, 'PD_PCT_POST_CRM')
        self.check_num_length(df, 'LGD_PCT_PRE_CRM', 12)
        self.count_dec_places(df, 'LGD_PCT_PRE_CRM', 6)
        self.unsigned(df, 'PD_PCT_POST_CRM')
        self.check_num_length(df, 'SA_CCR_EFF_MAT', 11)
        self.count_dec_places(df, 'SA_CCR_EFF_MAT', 1)
        self.unsigned(df, 'SA_CCR_EFF_MAT')

        return df

    def check_str_length(self, df, column_name, length):
        col_val = df[column_name]
        invalid = col_val[col_val.str.len() > length]
        if len(invalid) > 0:
            for item in invalid.values:
                print(f"Value {item} in the column {column_name} does not satisfy the length constraint.")
                log_entry = {'Business date': self.busdate, 'Column': column_name, 'Value': item, 'Message': 'Value (string) does not satisfy length constraint'}
                self.log_df.loc[len(self.log_df)] = log_entry
        return

    def check_num_length(self, df, column_name, length):
        for num in df[column_name]:
            num_str = str(abs(num))

            num_str = num_str.rstrip('0').rstrip('.') if '.' in num_str else num_str  # fixing trailing 0 issue
            num_str = num_str.replace('.', '') if '.' in num_str else num_str  # removing decimal

            if len(num_str) > length:
                print(f"Value {num} in column {column_name} does not satisfy the length constraint.")
                log_entry = {'Business date': self.busdate, 'Column': column_name, 'Value': num, 'Message': 'Value (number) does not satisfy length constraint'}
                self.log_df.loc[len(self.log_df)] = log_entry
        return

    def unsigned(self, df, column_name):
        for num in df[column_name]:
            if num < 0:
                print(f"Found a negative number {num} in column {column_name}.")
                log_entry = {'Business date': self.busdate, 'Column': column_name, 'Value': num, 'Message': 'Negative number not allowed.'}
                self.log_df.loc[len(self.log_df)] = log_entry
        return

    def count_dec_places(self, df, column_name, threshold):
        for value in df[column_name]:
            num_str = str(value)
            dec_ind = num_str.find('.')
            if dec_ind != -1:
                num_dec_places = len(num_str) - dec_ind - 1
                if num_dec_places > threshold:
                    print(f'Value {value} in column {column_name} has more decimal places than the constraint')
                    log_entry = {'Business date': self.busdate, 'Column': column_name, 'Value': value, 'Message': 'Value has more decimal places than the constraint.'}
                    self.log_df.loc[len(self.log_df)] = log_entry
        return

    def _extract_exposure_cols(self, df):
        cols = [
            'BUS_DT', 'TRD_SRC_SYS_ID', 'DERIV_EXP_TRANS_ID', 'ACR_CD', 'BRWR_UEN_ID', 'INTR_BNK_CNTRPRTY_IND',
            'CCP_IND', 'QCCP_IND', 'RESP_NODE', 'TRANSIT_NO', 'LNDR_HOST_CD', 'CR_VALTN_ADJ_AMT',
            'SA_CCR_EFF_NTNL_AMT', 'SA_CCR_REPL_CST_AMT', 'SA_CCR_POT_EXP_AMT', 'MRGN_IND',
            'CVA_CPTL_EXMPT_IND', 'HLD_TRD_BK_IND', 'EAD_CURR_CD', 'REPL_CST_BFR_NET_AMT_CURR_CD',
            'BLTRL_IND', 'CR_VALTN_ADJ_AMT_CURR_CD', 'CLI_LEG_CLRD_QCCP_IND',
            'GL_ACCT_NO', 'BSL_AST_CLS', 'SME_IND', 'GUAR_CR_DERIV_OR_COLL_IND', 'PD_PCT_POST_CRM',
            'LGD_PCT_PRE_CRM', 'SA_CCR_EFF_MAT'
        ]
        df = df[cols]
        return df


    def _read_osfi_file(self):
        type_dict = {'MTM': 'float64', 'MTM_CCY': 'str'}
        df = pd.read_csv(self.saccr_trade, sep='|', dtype=type_dict)

        # formatting check
        self.check_num_length(df, 'MTM', 30)
        self.count_dec_places(df, 'MTM', 8)
        self.check_str_length(df, 'MTM_CCY', 3)

        return df

    def _extract_osfi_cols(self, df):
        cols = [
            'TRADE_ID', 'SRC_SYS_CD', 'CLTRL_SET_ID', 'BMO_GUAR_CCP_TO_CLIENT_IND', 'SA_NOTIONAL', 'MTM', 'MTM_CCY', 'RC_LR'
            , 'PFE_LR', 'QCCP_IND', 'CLNT_TRADE_IND'
        ]
        df = df[cols]
        return df

    def _format(self, df):
        df_header, df_footer = self._save_header_footer()

        df_col, df_body = self._save_body(df)

        df = pd.DataFrame(np.concatenate((df_header.values, df_col.values, df_body.values, df_footer.values)))

        return df

    def _save_header_footer(self):
        df_header = pd.read_csv(self.idp_exposure, header=None, nrows=1)
        df_header = df_header.dropna(axis=1)

        df = pd.read_csv(self.idp_exposure, sep='|', skiprows=1)
        record_count = int(str((df.values[-1])[2]).strip()) + 3
        print(record_count)
        footer_list = ["TRL", self.busdate, str(record_count)]
        df_footer = pd.DataFrame(['|'.join(footer_list)])
        print(df_footer.values)

        return df_header, df_footer

    def _save_body(self, df):
        cols = df.columns.tolist()
        col_str = '|'.join(cols)
        col_str = 'HDR2|' + col_str
        df_col = pd.DataFrame({'column': [col_str]})

        # Create df from values
        sr_val = df.fillna("").astype(str).agg('|'.join, axis=1)
        df_val = pd.DataFrame({'column': sr_val})
        return df_col, df_val


    def _identify_ccp_trades(self, df):
        mask2 = df['CLNT_TRADE_IND'] == 'Y'
        mask3 = df['QCCP_IND'] == 'Y'
        mask4 = df['BMO_GUAR_CCP_TO_CLIENT_IND'] == 'N'
        df = df.loc[mask2 & mask3 & mask4]

        return df


def getLatestFile(pattern):
    # get list of files that matches pattern
    files = list(filter(os.path.isfile, glob.glob(os.path.join(folder_in, pattern + '*'))))
    # sort by modified time
    latest_file = ""
    if len(files) != 0:
        files.sort(key=lambda x: os.path.getmtime(x))
        # get last item in list
        latest_file = files[-1]
        print("Most recent file matching {}: {}".format(pattern,latest_file))

    else:
        print("The file is not present: ", pattern)

    return latest_file


if __name__ == "__main__":
    input_pram = len(sys.argv)
    try:
        if input_pram > 2:
            busdate = sys.argv[1]
            folder_in = sys.argv[2]
            folder_out = folder_in
        else:
            logging.info('Provide Business date {0}'.format('YYYYMMDD'))
            print('Provide Business date {0}'.format('YYYYMMDD'))

    except Exception as err_ex:
        print("__init__: Provide Business date: ", err_ex, " ", type(err_ex))
        logging.info("__init__: Provide Business date: ", err_ex, " ", type(err_ex))

    idp_d_pattern = 'CMRODS.IDP.FULL.IBGC_EXPOSURE.DAILY.' + busdate
    saccr_d_pattern = 'saccr_report_OSFI-BFG-NEW_d_' + busdate
    idp_m_pattern = 'CMRODS.IDP.FULL.IBGC_EXPOSURE.MONTHLY.' + busdate
    saccr_m_pattern = 'saccr_report_OSFI-BFG-NEW_m_' + busdate

    idp_exposure_d = getLatestFile(idp_d_pattern)
    saccr_trade_d = getLatestFile(saccr_d_pattern)

    idp_exposure_m = getLatestFile(idp_m_pattern)
    saccr_trade_m = getLatestFile(saccr_m_pattern)

    if "" != idp_exposure_m and "" != saccr_trade_m:
        print("Process the Monthly file...")
        saccr_trade = SaccrTrade(busdate, 'm', idp_exposure_m, saccr_trade_m, folder_out)
        df_saccr_trade = saccr_trade.map()
    else:
        missing_file = idp_m_pattern if len(idp_exposure_m) == 0 else saccr_m_pattern
        print("One of the Monthly Input file is missing {0}.\n Available file is : {1} {2}".format(missing_file, idp_exposure_m, saccr_trade_m))

    if "" != idp_exposure_d and "" != saccr_trade_d:
        print("Process the Daily file...")
        saccr_trade = SaccrTrade(busdate, 'd', idp_exposure_d, saccr_trade_d, folder_out)
        df_saccr_trade = saccr_trade.map()
    else:
        missing_file = idp_d_pattern if len(idp_exposure_d) == 0 else saccr_d_pattern
        print("One of the Daily Input file is missing {0}.\n Available file is : {1} {2}".format(missing_file, idp_exposure_d, saccr_trade_d))

