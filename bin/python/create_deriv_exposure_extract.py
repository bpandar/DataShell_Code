#!/usr/bin/python

import pandas as pd
from datetime import datetime
from report_utility import add_leading_char
from sys import argv
import csv


################################
########### MARP-528 ###########
################################

def write_to_report(df: pd.DataFrame, output_file, sep=',', header=False, mode='w'):
    try:
        df.to_csv(output_file, mode=mode, index=False, sep=sep, header=header, quoting=csv.QUOTE_NONE, escapechar='\\')

    except Exception as e:
        print(e)


def generate_report(date, input_path, output_path):
    print('Starting report construction...')

    # header 1
    hdr1 = 'HDR1'
    file_name = 'IBGC_EXPOSURE'
    bus_dt = date
    record_type = '00000'
    data_source = 'CMR_ODS'
    run_date = datetime.today().strftime('%Y%m%d:') + datetime.today().strftime('%H:%M:%S')
    col_names = ['HDR1', 'FILE_NAME', 'BUS_DT', 'RECORD_TYPE', 'DATA_SOURCE', 'RUN_DATE']
    values = [hdr1, file_name, bus_dt, record_type, data_source, run_date]
    df_head = pd.DataFrame([values], columns=col_names)
    print(df_head)
    write_to_report(df_head, output_path, sep='|', mode='w')

    # header 2
    df_body = pd.read_csv(input_path, sep=',', dtype=str)
    hdr2 = 'HDR2'
    values2 = list(df_body.columns.values)
    values2.insert(0, hdr2)
    print(values2)
    df_head2 = pd.DataFrame([values2], columns=values2)
    print(df_head2)
    write_to_report(df_head2, output_path, sep='|', mode='a')

    # body
    col_details = [("SRC_SYS_ID", False), ("DERIV_EXP_TRANS_ID", False), ("TRD_SRC_SYS_ID", False), ("FAC_ID", False),
                   ("RSK_TYP_CD", False), ("BRWR_UEN_ID", False), ("RESP_NODE", False), ("TRANSIT_NO", True),
                   ("GL_ACCT_NO", False), ("BAL_AMT_CURR_CD", False), ("BSL_AST_CLS", False), ("OSFI_EXP_TYP", False),
                   ("OSFI_DERIV_INST_TYP", False), ("CR_DRV_USED_FOR_CRM_IND", False), ("CNTRY_ULT_RISK_CD", False),
                   ("PROV_ULT_RISK_CD", False), ("HLD_TRD_BK_IND", False), ("PRIM_BRWR_IND", False),
                   ("BRWR_LGL_NM", False), ("BRWR_RISK_RTG", False), ("CDN_SIC_CD", True), ("US_SIC_CD", True),
                   ("NAIC_CD", False), ("NIC_CD", False), ("SME_IND", False), ("SUB_PER_NET_IND", False),
                   ("CALC_METH_TYP", False), ("DFT_EXP_IND", False), ("TERM_TO_MAT_DT", False),
                   ("PD_PCT_PRE_CRM", False), ("PD_PCT_POST_CRM", False), ("EAD_CURR_CD", False),
                   ("EL_BE_CURR_CD", False), ("EL_BE_AMT", False), ("EL_BE_PCT", False),
                   ("AST_CLS_GUAR_PROV_CRM", False), ("GUAR_SME_IND", False), ("DECR_EXP_GUAR_CR_DER_AMT", False),
                   ("BAL_AMT", False), ("TOT_ANN_SLS_CURR_CD", False), ("TOT_ANN_SLS_AMT", False),
                   ("REPL_CST_BFR_NET_AMT_CURR_CD", False), ("REPL_CST_BFR_NET_AMT", False),
                   ("INTR_BNK_CNTRPRTY_IND", False), ("BSL_REC_TYP", False), ("VAR_REC_IND", False),
                   ("LNDR_HOST_CD", False), ("CMN_RISK_NBR", False), ("RW_PRE_CRM", False), ("RW_POST_CRM", False),
                   ("GUAR_CR_DERIV_OR_COLL_IND", False), ("BOR_RRS_CD", False), ("BLTRL_IND", False),
                   ("CCP_IND", False), ("QCCP_IND", False), ("AVC_APLBL_IND", False),
                   ("CR_VALTN_ADJ_AMT_CURR_CD", False), ("CR_VALTN_ADJ_AMT", False), ("CR_RSK_BNK_RL_CD", False),
                   ("ACR_CD", False), ("VAR_MRGN_AMT_CURR_CD", False), ("VAR_MRGN_RCVD_AMT", False),
                   ("VAR_MRGN_PSTD_AMT", False), ("STD_COLL_TYP_IND", False), ("BCAR_RPTG_CGY", False),
                   ("EXP_RRM", False), ("ISSR_CD", False), ("SRC_CUSIP_NBR", False), ("SRC_ISIN_NBR", False),
                   ("QLFY_TXN_CDS_IND", False), ("PD_SUB_TP_CD", False), ("ACCTG_NET_IND", False),
                   ("CLI_LEG_IND", False), ("INIT_MRGN_CLI_TRD_CURR_CD", False), ("INIT_MRGN_CLI_TRD_AMT", False),
                   ("CLI_TRD_CCP_PERF_GNT_IND", False), ("CLI_LEG_CLRD_QCCP_IND", False),
                   ("CLI_TRD_EAD_SCLR_VAL", False), ("CLI_TRD_SGRGTD_ACCT_IND", False), ("BOR_PD_PCT", False),
                   ("BOR_CNTRY_RES_CD", False), ("PROV_RES_CD", False), ("SA_CCR_EFF_NTNL_AMT", False),
                   ("SA_CCR_REPL_CST_AMT", False), ("SA_CCR_POT_EXP_AMT", False), ("MRGN_IND", False),
                   ("CVA_CPTL_EXMPT_IND", False), ("SA_CCR_AST_CLS_CGY", False), ("LGD_PCT_PRE_CRM", False),
                   ("RWA_STND_AMT", False), ("RWA_AMT", False), ("SA_CCR_EFF_MAT", False),
                   ("CREDIT_DERIVATIVES_SWAP_CLASS", False), ("QCCP_RWA_CAP_IND", False),
                   ("CLI_LEG_LVG_RTO_IND", False), ("SA_CCR_LVG_RTO_REPL_CST_AMT", False),
                   ("SA_CCR_LVG_RTO_POT_EXP_AMT", False), ("BORR_ENTITY_EXT_RTG", False), ("BORR_CNTRY_EXT_RTG", False),
                   ("WAIVER_EXEMP_PORTFOLIO_CD", False), ("CMN_RISK_KMV_NBR", False), ("CMN_RISK_NM", False),
                   ("BOR_BSL_AST_CLS", False), ("FAC_PRIM_TYP", False), ("FAC_BOOK_TRANSIT_NBR", True),
                   ("FAC_COMMIT_IND", False), ("FAC_SHARED_LINK_IND", False), ("FAC_REVIEW_DT", False),
                   ("FAC_STATUS_CD", False), ("FAC_CASH_MSEC_TYP", False), ("FAC_PRIM_COLL_TYP", False),
                   ("FAC_SNR_PROF_TYP", False), ("FAC_SYN_IND", False), ("FAC_SYN_ROLE_CD", False),
                   ("FAC_RRS_CD", False), ("FAC_AUTH_AMT", False), ("PST_CRM_ELOSS_AMT", False),
                   ("REG_CPTL_AMT", False), ("R_FCTR_VAL", False), ("K_FCTR_VAL", False), ("B_FCTR_VAL", False),
                   ("M_FCTR_VAL", False), ("GUAR_CALC_METH_TYP", False), ("GUAR_AVC_APLBL_IND", False),
                   ("GUAR_TOT_ANN_SLS_AMT", False), ("EXT_CRD_RATE", False), ("RATE_AGNC_NAME", False),
                   ("SHRT_TERM_IND", False), ("GUAR_EXT_CRD_RATE", False), ("GUAR_RATE_AGNC_NAME", False),
                   ("GUAR_ENTITY_EXT_RTG", False), ("RISKCALC_RUN_ID", False), ("PRODUCT_GROUP", False),
                   ("FINANCE_RECON_STATE", False), ("UTI", False), ("RECON_KEY", False), ("BUS_DT", False),
                   ("MSE_CODE", False), ("MATURITY_DT", False), ("SACCR_NETTING_SET_ID", False),
                   ("SACCR_COLLATERAL_SET_ID", False)
                   ]

    col_types = [('CHAR', 4), ('CHAR', 60), ('CHAR', 10), ('CHAR', 22), ('CHAR', 15), ('CHAR', 22), ('CHAR', 5),
                 ('CHAR', 5), ('CHAR', 10), ('CHAR', 3), ('CHAR', 10), ('CHAR', 6), ('CHAR', 6), ('CHAR', 1),
                 ('CHAR', 2), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1), ('CHAR', 200), ('CHAR', 10), ('CHAR', 4),
                 ('CHAR', 4), ('CHAR', 6), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1), ('CHAR', 6), ('CHAR', 1),
                 ('NUMERIC', 11, 1), ('NUMERIC', 11, 6), ('NUMERIC', 11, 6), ('CHAR', 3), ('CHAR', 3),
                 ('NUMERIC', 21, 4), ('NUMERIC', 12, 6), ('CHAR', 10), ('CHAR', 1), ('NUMERIC', 21, 4),
                 ('NUMERIC', 21, 4), ('CHAR', 3), ('NUMERIC', 20, 4), ('CHAR', 3), ('NUMERIC', 21, 4),
                 ('CHAR', 1), ('CHAR', 3), ('CHAR', 1), ('CHAR', 10), ('CHAR', 22), ('NUMERIC', 11, 6),
                 ('NUMERIC', 11, 6), ('CHAR', 1), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1), ('CHAR', 1),
                 ('CHAR', 1), ('CHAR', 3), ('NUMERIC', 21, 4), ('CHAR', 10), ('CHAR', 30), ('CHAR', 3),
                 ('NUMERIC', 21, 4), ('NUMERIC', 21, 4), ('CHAR', 1), ('CHAR', 5), ('CHAR', 250), ('CHAR', 64),
                 ('CHAR', 30), ('CHAR', 30), ('CHAR', 1), ('CHAR', 50), ('CHAR', 1), ('CHAR', 1), ('CHAR', 3),
                 ('NUMERIC', 21, 4), ('CHAR', 1), ('CHAR', 1), ('NUMERIC', 6, 4), ('CHAR', 1), ('NUMERIC', 12, 6),
                 ('CHAR', 2), ('CHAR', 3), ('NUMERIC', 21, 4), ('NUMERIC', 21, 4), ('NUMERIC', 21, 4), ('CHAR', 1),
                 ('CHAR', 1), ('CHAR', 20), ('NUMERIC', 12, 6), ('NUMERIC', 21, 4), ('NUMERIC', 21, 4),
                 ('NUMERIC', 11, 1), ('VARCHAR', 45), ('CHAR', 1), ('CHAR', 1), ('NUMERIC', 21, 4),
                 ('NUMERIC', 21, 4), ('CHAR', 30), ('CHAR', 30), ('CHAR', 25), ('CHAR', 15), ('CHAR', 100),
                 ('CHAR', 10), ('CHAR', 10), ('CHAR', 5), ('CHAR', 1), ('CHAR', 1), ('CHAR', 8), ('CHAR', 2),
                 ('CHAR', 1), ('CHAR', 8), ('CHAR', 30), ('CHAR', 1), ('CHAR', 1), ('CHAR', 3),
                 ('NUMERIC', 21, 4), ('NUMERIC', 21, 4), ('NUMERIC', 21, 4), ('NUMERIC', 11, 9),
                 ('NUMERIC', 11, 9), ('NUMERIC', 11, 9), ('NUMERIC', 11, 9), ('CHAR', 6), ('CHAR', 1),
                 ('NUMERIC', 20, 4), ('CHAR', 50), ('CHAR', 10), ('CHAR', 1), ('CHAR', 50), ('CHAR', 10),
                 ('CHAR', 30), ('NUMBER', 38, 0), ('VARCHAR2', 30), ('VARCHAR2', 1), ('VARCHAR2', 128),
                 ('VARCHAR2', 128), 'DATE', ('CHAR', 10), 'DATE', ('CHAR', 100), ('CHAR', 100)]

    df_body['BUS_DT'] = pd.to_datetime(df_body['BUS_DT'])
    df_body['BUS_DT'].dt.date

    df_body['MATURITY_DT'] = pd.to_datetime(df_body['MATURITY_DT'])
    df_body['MATURITY_DT'].dt.date

    # df_body = df_body.replace('\|', '\\|', regex=True).replace('"', '', regex=True)
    df_body = df_body.replace('"', '', regex=True)

    for column in df_body:
        idx = df_body.columns.get_loc(column)
        # MARP-1643: apply Feed Specifications

        df_body[column] = df_body[column].apply(format_chars, cols=col_types, _index=idx)

        # MARP-1905: add leading zeros to some attributes
        if col_details[idx][1]:
            df_body[column] = df_body[column].apply(add_leading_char, char='0', char_len=col_types[idx][1])

    df_body.columns = range(df_body.shape[1])
    write_to_report(df_body, output_path, sep='|', mode='a')

    # trailer
    TRL = 'TRL'
    RECORD_COUNT = len(df_body.axes[0])
    col_names = ['TRL', 'BUS_DT', 'RECORD_COUNT']
    values = [TRL, bus_dt, RECORD_COUNT]
    df_tail = pd.DataFrame([values], columns=col_names)
    print(df_tail)

    write_to_report(df_tail, output_path, sep='|', mode='a')
    print('Finishing report construction...')


def main(date: str, input_path: str, output_path: str):
    generate_report(date, input_path, output_path)


def format_chars(x, cols, _index):
    if cols[_index][0] in ["CHAR", "VARCHAR2"] and not pd.isna(x):
        res = str(x)[: cols[_index][1]]
    else:
        if cols[_index][0] in ["NUMBER", "NUMERIC"] and not pd.isna(x):
            if "." in str(x) and len(str(abs(int(float(x))))) < cols[_index][1]:
                if "E" in str(x):
                    # There is scientific notation in the file??
                    x = float(x)
                if "-" in str(x):
                    res = str(x)[: len(str(abs(int(float(x))))) + 2 + cols[_index][2]]
                else:
                    # Input formatting missing leading 0 for decimals
                    if str(x)[0] == ".":
                        this_x = x
                        x = "0" + x

                    res = str(x)[: len(str(abs(int(float(x))))) + 1 + cols[_index][2]]
            else:
                if "-" in str(x) and len(str(abs(int(float(x))))) >= cols[_index][1]:
                    res = str(x)[: cols[_index][1] + 1]
                else:
                    res = str(x)[: cols[_index][1]]
        else:
            res = x

    return res


if __name__ == '__main__':

    input_file = argv[1]
    bus_dt = argv[2]
    output_dir = argv[3]

    output_file = f'{output_dir}/CMRODS.IDP.FULL.IBGC_EXPOSURE.DAILY.{bus_dt}.csv'
    main(bus_dt, input_file, output_file)
    output_file = f'{output_dir}/CMRODS.IDP.FULL.IBGC_EXPOSURE.MONTHLY.{bus_dt}.csv'
    main(bus_dt, input_file, output_file)
