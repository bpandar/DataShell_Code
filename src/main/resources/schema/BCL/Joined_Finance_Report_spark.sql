select
    SACCR.BUS_DATE,
    SACCR.RUN_ID,
    SACCR.EXPR_RUN_ID,
    SACCR.CALC_TYPE,
    SACCR.REPORTING_CCY,
    SACCR.FX_SRC,
    SACCR.REGIME_LEGAL_ENTITY,
    SACCR.SRC_SYS_CD,
    SACCR.TRADE_ID,
    SACCR.DUMMY_IND,
    SACCR.SWWR_IND,
    SACCR.CLNT_TRADE_IND,
    SACCR.CLNT_LEG_IND,
    SACCR.CCP_IND,
    SACCR.QCCP_IND,
    SACCR.BUY_SELL_CD,
    SACCR.INT_EXT_CD,
    SACCR.PRODUCT_ID,
    SACCR.PRODUCT,
    SACCR.CPTY_CD,
    SACCR.LEGL_ENTITY_CD,
    SACCR.RESP_CENTRE,
    SACCR.TRANSIT,
    SACCR.CAPITAL_TREATMENT,
    SACCR.saccr_GL,
    SACCR.NETG_REF,
    SACCR.CLTRL_REF,
    SACCR.SACCR_NETG_SET_ID,
    SACCR.CLTRL_SET_ID,
    SACCR.MRGN_IND,
    SACCR.NOTIONAL,
    SACCR.NOTIONAL_CCY,
    SACCR.MTM,
    SACCR.MTM_CCY,
    SACCR.CVA_LOSS,
    SACCR.TRADE_DT,
    SACCR.MAT_DT,
    SACCR.MAT_IN_DAYS,
    SACCR.UNDERLYING_CUSIP,
    SACCR.UNDERLYING_ISIN,
    SACCR.UNDERLYING_ISSUER,
    SACCR.SA_NOTIONAL,
    SACCR.EFF_NOTIONAL,
    SACCR.SACCR_ASSET_CLASS,
    SACCR.SUPVSRY_FACTOR,
    SACCR.ALLOCATED_VM,
    SACCR.ALLOCATED_NICA,
    SACCR.RC,
    SACCR.PFE,
    SACCR.RC_LR,
    SACCR.PFE_LR,
    SACCR.EAD,
    SACCR.EAD_LR,
    SACCR.EFF_MAT,
    SACCR.OSFI_EXPOSURE_TYPE,
    SACCR.CVA_CPTL_EXMPTN_IND,
    SACCR.CREDIT_DERIVATIVES_SWAP_CLASS,
    SACCR.CLEARING_MEMBER_IND,
    SACCR.BMO_GUAR_CCP_TO_CLIENT_IND,
    SACCR.CLIENT_LEG_CLEARED_QCCP_IND,
    SACCR.CCP_LEG_SEG_IND,
    SACCR.SACCR_LR_EXEMPT_CCP_LEG_IND,
    SACCR.UEN,
    SACCR.FACILITY_ID,
    SACCR.BSL_ASSET_CLASS,
    SACCR.COUNTRY_OF_RISK,
    SACCR.COUNTRY_EXT_RTG,
    SACCR.PROV_OF_RISK,
    SACCR.LEGAL_NAME,
    SACCR.RISK_RTG,
    SACCR.SIC_CAD_CD,
    SACCR.SIC_US_CD,
    SACCR.NAICS_CD,
    SACCR.NIC_CD,
    SACCR.SME_IND,
    SACCR.PD,
    SACCR.TOTAL_ANNUAL_SALES_CCY,
    SACCR.TOTAL_ANNUAL_SALES_AMT,
    SACCR.RISK_RTG_SYSTEM,
    SACCR.AVC_IND,
    SACCR.RISK_RTG_MODEL,
    SACCR.COUNTRY_OF_RESIDENCE,
    SACCR.PROV_OF_RESIDENCE,
    SACCR.MASTER_SCALE,
    SACCR.PRIMARY_CONNECTION_UEN,
    SACCR.DEFAULT_EXP_IND,
    SACCR.CR_DRV_USED_FOR_CRM_IND,
    SACCR.QLFY_TXN_CDS_IND,
    SACCR.FACILITY_AUTH_AMT,
    SACCR.FACILITY_PRIMARY_BORROWER_IND,
    SACCR.PRIMARY_GUARANTOR_UEN,
    SACCR.BSL_CREDIT_RISK_APPROACH,
    SACCR.WAIVER_EXEMP_PORTFOLIO_CD,
    SACCR.FIRB_LGD,
    SACCR.AIRB_LGD,
    SACCR.STND_RW,
    SACCR.STND_RW_NON_QCCP,
    SACCR.STND_RW_SCENARIO,
    SACCR.BORROWER_EXT_RTG,
    SACCR.BORROWER_EXT_RTG_NAME,
    SACCR.BORROWER_EXT_RTG_SP_EQUIV,
    SACCR.FIRB_RW,
    SACCR.AIRB_RW,
    SACCR.RWA_R_FACTOR,
    SACCR.RWA_K_FACTOR,
    SACCR.RWA_B_FACTOR,
    SACCR.RWA_M_FACTOR,
    SACCR.EXPECTED_LOSS,
    SACCR.REG_CAPITAL,
    --#MARP-15862:
    case when SACCR.BSL_CREDIT_RISK_APPROACH = 'STND' then CAST(0.08 * SACCR.STND_RWA as DECIMAL(18,5))
        else SACCR.REG_CAPITAL
        end as REG_CAPITAL_DERV,
    SACCR.STND_RWA,
    SACCR.FIRB_RWA,
    SACCR.AIRB_RWA,
    SACCR.RWA,
    SACCR.saccr_OSFI_INSTRUMENT_TYPE,
    SACCR.saccr_PRODUCT_SUB_TYPE_CODE,
    SACCR.saccr_PRODUCT_GROUP,
    SACCR.QCCP_RWA_CAP_IND,
    SACCR.SACVA_IND,
    SACCR.TOT_ANN_SLS_AMT_CAD,
    Finance.ReportDate,
    Finance.SourceSystem,
    Finance.SourceTradeId,
    Finance.AssetLiabilityCode,
    Finance.finance_GL,
    Finance.GLType,
    Finance.RespCentre,
    Finance.BookingTransit,
    Finance.Currency,
    Finance.SourceProductCode,
    Finance.ProductCategoryCode,
    Finance.InstrumentType,
    Finance.FSProduct,
    Finance.FSProductGroup,
    Finance.BuySellCode,
    Finance.ClearanceType,
    Finance.LegalEntity,
    Finance.LOB,
    Finance.CounterpartyAdaptiveCode,
    Finance.CounterpartyFullName,
    Finance.IntExtCode,
    Finance.CDE_NPV,
    Finance.TC_NPV,
    --#MARP-14059: SwapOne trade id changes for PB trades
    case when (SACCR.SRC_SYS_CD = 'SWAPONE' and SACCR.TRADE_ID RLIKE ('\\d{2}[A-Za-z]{3}\\d{4}') )
             then SACCR.NOTIONAL_CCY
             else Finance.Notional_Currency
             end as Notional_Currency,
    case when (SACCR.SRC_SYS_CD = 'SWAPONE' and SACCR.TRADE_ID RLIKE ('\\d{2}[A-Za-z]{3}\\d{4}') )
             then SACCR.NOTIONAL
             else Finance.TC_Notional_Value
             end as TC_Notional_Value,
    Finance.CDE_Notional_Value,
    Finance.MaturityDate,
    Finance.ClearingHouseFlag,
    Finance.UTI,
    Finance.Product,
    Finance.SwapOne_SwapId,
    Finance.WS_Transaction_ID,
    Finance.finance_OSFI_INSTRUMENT_TYPE,
    Finance.finance_PRODUCT_SUB_TYPE_CD,
    Finance.finance_PRODUCT_GROUP
from SACCR_Report_OSFI_BFG_NEW SACCR
LEFT JOIN CM_Finance Finance ON (case when SACCR.SRC_SYS_CD = 'SWAPONE'
                                  then regexp_replace(SACCR.TRADE_ID, '(-\\d{2}[A-Za-z]{3}\\d{4}-\\d+)?$','')
                                  else SACCR.TRADE_ID end
                                    ) = Finance.SourceTradeId
    and SACCR.SRC_SYS_CD = Finance.SourceSystem