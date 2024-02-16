#!/usr/bin/python

import pandas as pd
from datetime import datetime
from report_utility import add_leading_char
from sys import argv

input_file = argv[1]
output_file = argv[2]  # "B3R_IBG_CAP_MKTS_EXP.DAT"
BUS_DT = argv[3]  # "20221215"


################################
########### MARP-399 ###########
################################

class BCLReportWriter:
    """
    class BCLReportWriter:
        * This class is used to write the content from the BCL Report (csv file) to a .dat file to be sent to downstream
        * along with header and trailer records
    """

    def __init__(self, filename: str):
        """
        Parameters
        __________
        output_file (str) - dat file
        """

        self.filename = filename

    def write_to_report(self, df: pd.DataFrame, colspecs: list, col_types: list, mode='w'):
        """
        This is the main function of the class. It reads a pandas Data Frame and write its content to the target file.

        Parameters
        __________
        df (pd.DataFrame) - DataFrame containing the content to be written to the output file
        colspecs (list) - List of tuples specifying columns spacing
        col_types (list) - List of tuples specifying the data type of each column
        mode (str) - File mode

        Return
        ______
        None
        """
        try:
            with open(self.filename, mode, newline="\n") as f:
                for _, row in df.fillna('').iterrows():
                    for idx, value in enumerate(row):

                        w = colspecs[idx][1] - colspecs[idx][0]
                        if value == '':
                            f.write("{: <{}}".format(value, w))
                        elif col_types[idx][0] == 'UNSIGNED INT':
                            f.write("{:0{}d}".format(int(value), w))
                        elif col_types[idx][0] == 'UNSIGNED DEC':
                            f.write("{:0{}d}".format(int(float(value) * 10 ** col_types[idx][2]), w))
                        elif col_types[idx][0] == 'SIGNED DEC':
                            f.write("{:+0{}d}".format(int(float(value) * 10 ** col_types[idx][2]), w))
                        else:
                            if len(str(value)) > w:
                                value = str(value)[0:w - 1]
                            f.write("{: <{}}".format(value, w))

                    f.write("\n")

        except Exception as e:
            print(e)
            # print(value)


def main():
    print('Begin BCLReportWriter script')
    report = BCLReportWriter(output_file)

    # Header
    colspecs = [(0, 3), (3, 7), (7, 10), (10, 20), (20, 50), (50, 58), (58, 66), (66, 74), (74, 76), (76, 2068)]
    col_names = ['REC_TYP', 'APPL_SRC_CD', 'PLATFORM', 'JOB_NM', 'FILE_DESC', 'MTH_END_DT', 'RUN_DT', 'RUN_TIME',
                 'FILE_GEN_NBR', 'FILLER']
    col_types = [('CHAR', 3), ('CHAR', 4), ('CHAR', 3), ('CHAR', 10), ('CHAR', 30), ('CHAR', 8), ('CHAR', 8),
                 ('CHAR', 8), ('CHAR', 2), ('CHAR', 1997)]
    values = ['HDR', 'IBGC', 'WIN', 'F4', 'B3R_IBG_CAP_MKTS_EXP.DAT', BUS_DT.replace('-', ''),
              datetime.today().strftime('%Y%m%d'), datetime.today().strftime('%H:%M:%S'), 1, None]
    df_head = pd.DataFrame([values], columns=col_names)
    report.write_to_report(df_head, colspecs, col_types)

    # Body
    col_details = [("REC_TYP", False), ("SRC_SYS_ID", False), ("DERIV_EXP_TRANS_ID", False), ("TRD_SRC_SYS_ID", False),
                   ("FAC_ID", False), ("RSK_TYP_CD", False), ("BRWR_UEN_ID", False), ("RESP_NODE", False),
                   ("TRANSIT_NO", True), ("GL_ACCT_NO", False), ("BAL_AMT_CURR_CD", False), ("BSL_AST_CLS", False),
                   ("OSFI_EXP_TYP", False), ("OSFI_DERIV_INST_TYP", False), ("CR_DRV_USED_FOR_CRM_IND", False),
                   ("CNTRY_ULT_RISK_CD", False), ("PROV_ULT_RISK_CD", False), ("HLD_TRD_BK_IND", False),
                   ("PRIM_BRWR_IND", False), ("BRWR_LGL_NM", False), ("BRWR_RISK_RTG", False), ("CDN_SIC_CD", True),
                   ("US_SIC_CD", True), ("NAIC_CD", False), ("NIC_CD", False), ("SME_IND", False),
                   ("SUB_PER_NET_IND", False), ("CALC_METH_TYP", False), ("DFT_EXP_IND", False),
                   ("TERM_TO_MAT_DT", False), ("PD_PCT_PRE_CRM", False), ("PD_PCT_POST_CRM", False),
                   ("EAD_CURR_CD", False), ("EL_BE_CURR_CD", False), ("EL_BE_AMT", False), ("EL_BE_PCT", False),
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
                   ("GUAR_ENTITY_EXT_RTG", False)
                   ]

    colspecs = [(0, 3), (3, 7), (7, 67), (67, 77), (77, 99), (99, 114), (114, 136), (136, 141), (141, 146), (146, 156),
                (156, 159), (159, 169), (169, 175), (175, 181), (181, 182), (182, 184), (184, 187), (187, 188),
                (188, 189), (189, 389), (389, 399), (399, 403), (403, 407), (407, 413), (413, 416), (416, 417),
                (417, 418), (418, 424), (424, 425), (425, 436), (436, 447), (447, 458), (458, 461), (461, 464),
                (464, 486), (486, 498), (498, 508), (508, 509), (509, 531), (531, 553), (553, 556), (556, 576),
                (576, 579), (579, 601), (601, 602), (602, 605), (605, 606), (606, 616), (616, 638), (638, 649),
                (649, 660), (660, 661), (661, 664), (664, 665), (665, 666), (666, 667), (667, 668), (668, 671),
                (671, 693), (693, 703), (703, 733), (733, 736), (736, 758), (758, 780), (780, 781), (781, 786),
                (786, 1036), (1036, 1100), (1100, 1130), (1130, 1160), (1160, 1161), (1161, 1211), (1211, 1212),
                (1212, 1213), (1213, 1216), (1216, 1238), (1238, 1239), (1239, 1240), (1240, 1246), (1246, 1247),
                (1247, 1259), (1259, 1261), (1261, 1264), (1264, 1286), (1286, 1308), (1308, 1330), (1330, 1331),
                (1330, 1331), (1331, 1351), (1351, 1363), (1363, 1385), (1385, 1407), (1407, 1418), (1418, 1463),
                (1463, 1464), (1464, 1465), (1465, 1487), (1487, 1509), (1509, 1539), (1539, 1569), (1569, 1594),
                (1594, 1609), (1609, 1709), (1710, 1720), (1720, 1725), (1725, 1726), (1726, 1727), (1727, 1735),
                (1735, 1737), (1737, 1738), (1738, 1746), (1746, 1776), (1776, 1777), (1777, 1778), (1778, 1781),
                (1781, 1802), (1802, 1824), (1824, 1846), (1846, 1857), (1857, 1868), (1868, 1879), (1879, 1890),
                (1890, 1896), (1896, 1897), (1897, 1917), (1917, 1967), (1967, 1977), (1977, 1978), (1978, 2028),
                (2028, 2038), (2038, 2068)
                ]

    col_types = [('CHAR', 3), ('CHAR', 4), ('CHAR', 60), ('CHAR', 10), ('UNSIGNED INT', 22), ('CHAR', 15),
                 ('UNSIGNED INT', 22), ('CHAR', 5), ('CHAR', 5), ('CHAR', 10), ('CHAR', 3), ('CHAR', 10), ('CHAR', 6),
                 ('CHAR', 6), ('CHAR', 1), ('CHAR', 2), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1), ('CHAR', 200),
                 ('CHAR', 10), ('CHAR', 4), ('CHAR', 4), ('CHAR', 6), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1),
                 ('CHAR', 6), ('CHAR', 1), ('UNSIGNED DEC', 11, 1), ('UNSIGNED DEC', 11, 6), ('UNSIGNED DEC', 11, 6),
                 ('CHAR', 3), ('CHAR', 3), ('SIGNED DEC', 21, 4), ('UNSIGNED DEC', 12, 6), ('CHAR', 10), ('CHAR', 1),
                 ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4), ('CHAR', 3), ('UNSIGNED DEC', 20, 4), ('CHAR', 3),
                 ('SIGNED DEC', 21, 4), ('CHAR', 1), ('CHAR', 3), ('CHAR', 1), ('CHAR', 10), ('UNSIGNED INT', 22),
                 ('UNSIGNED DEC', 11, 6), ('UNSIGNED DEC', 11, 6), ('CHAR', 1), ('CHAR', 3), ('CHAR', 1), ('CHAR', 1),
                 ('CHAR', 1), ('CHAR', 1), ('CHAR', 3), ('SIGNED DEC', 21, 4), ('CHAR', 10), ('CHAR', 30), ('CHAR', 3),
                 ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4), ('CHAR', 1), ('CHAR', 5), ('CHAR', 250), ('CHAR', 64),
                 ('CHAR', 30), ('CHAR', 30), ('CHAR', 1), ('CHAR', 50), ('CHAR', 1), ('CHAR', 1), ('CHAR', 3),
                 ('SIGNED DEC', 21, 4), ('CHAR', 1), ('CHAR', 1), ('UNSIGNED DEC', 6, 4), ('CHAR', 1),
                 ('UNSIGNED DEC', 12, 6), ('CHAR', 2), ('CHAR', 3), ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4),
                 ('SIGNED DEC', 21, 4), ('CHAR', 1), ('CHAR', 1), ('CHAR', 20), ('UNSIGNED DEC', 12, 6),
                 ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4), ('UNSIGNED DEC', 11, 1), ('VARCHAR', 45), ('CHAR', 1),
                 ('CHAR', 1), ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4), ('CHAR', 30), ('CHAR', 30), ('CHAR', 25),
                 ('CHAR', 15), ('CHAR', 100), ('CHAR', 10), ('CHAR', 5), ('CHAR', 1), ('CHAR', 1),
                 ('CHAR', 8), ('CHAR', 2), ('CHAR', 1), ('CHAR', 8), ('CHAR', 30), ('CHAR', 1), ('CHAR', 1),
                 ('CHAR', 3), ('UNSIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4), ('SIGNED DEC', 21, 4),
                 ('UNSIGNED DEC', 11, 9), ('UNSIGNED DEC', 11, 9), ('UNSIGNED DEC', 11, 9), ('UNSIGNED DEC', 11, 9),
                 ('CHAR', 6), ('CHAR', 1), ('UNSIGNED DEC', 20, 4), ('CHAR', 50), ('CHAR', 10), ('CHAR', 1),
                 ('CHAR', 50), ('CHAR', 10), ('CHAR', 30)
                 ]
    df_body = pd.read_csv(input_file, header=0, sep='|', dtype=str)
    #
    # print(df_body.tail(15))
    df_body.drop('BOR_BSL_AST_CLS', axis=1, inplace=True)

    for column in df_body:
        idx = df_body.columns.get_loc(column)

        # MARP-1905: add leading zeros to some attributes
        if col_details[idx][1]:
            df_body[column] = df_body[column].apply(add_leading_char, char='0', char_len=col_types[idx][1])

    report.write_to_report(df_body, colspecs, col_types, mode='a')

    # Trailer
    colspecs = [(0, 3), (3, 11), (11, 22), (22, 47), (47, 72), (72, 2068)]
    col_names = ['REC_TYP', 'RUN_DT', 'REC_CNT', 'CHECKSUM_1', 'CHECKSUM_2', 'FILLER']
    col_types = [('CHAR', 3), ('CHAR', 8), ('UNSIGNED INT', 11), ('SIGNED DEC', 24, 4), ('SIGNED DEC', 24, 4),
                 ('CHAR', 2001)]
    values = ['TRL', datetime.today().strftime('%Y%m%d'), len(df_body.axes[0]),
              df_body['REPL_CST_BFR_NET_AMT'].astype("float").sum(),
              df_body['BAL_AMT'].astype("float").sum(), None]
    df_trailer = pd.DataFrame([values], columns=col_names)
    report.write_to_report(df_trailer, colspecs, col_types, mode='a')
    print('End BCLReportWriter script')


if __name__ == '__main__':
    main()
