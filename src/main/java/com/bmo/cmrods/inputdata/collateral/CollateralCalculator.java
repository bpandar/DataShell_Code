package com.bmo.cmrods.inputdata.collateral;
import javafx.util.Pair;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.CSVRecord;

import java.io.*;
import java.util.*;


public class CollateralCalculator {
    static String [] HEADER = {"PRINCIPAL_LEGAL_ENTITY", "COUNTERPARTY_LEGAL_NAME", "AGREEMENT_TYPE", "COUNTERPARTY_CODE", "COLLATERAL_STATUS", "MARGIN_IND", "IA_GROSS_IND", "REHYPOTHECATION_FLAG", "CUSTODIAN_PO", "ISSUER", "ISSUER_COUNTRY", "MARKET_SECTOR", "ISSUER_INDUSTRY", "SECURITY_TYP2", "PARENT_COMP_NAME", "CREDITRATING_S_AND_P", "CREDITRATING_MOODY", "CREDITRATING_FITCH", "CREDITRATING_DBRS", "PRD_DESCRIPTION", "COUPON", "IS_ZEROCOUPON", "MATURITY", "ISIN", "CUSIP", "HAIRCUT_PERCENTAGE", "COLLATERAL_CURRENCY", "NOTIONAL_AMOUNT", "PRE_HRCT_MKT_VAL_CLLTRL", "VALUE_AGREEMENT_CCY", "AGREEMENT_CURRENCY", "FX_RATE", "USD_FX_RATE", "VALUE_USD", "CAD_FX_RATE", "VALUE_CAD", "POST_HRCT_VAL_CLLTRL", "POST_HRCT_VAL_CLLTRL_AGRMT_CCY", "VALUE_POST_HAIRCUT_USD", "VALUE_POST_HAIRCUT_CAD", "ELIGIBLE_COLLATERAL_GROUP", "AGREEMENT_ID", "MATURITY_PAYMENT_DATE", "COLLATERAL_REFERENCE", "CUSTODIAN_LE", "SECURED_PARTY", "BOOK"};
    static String CPTY_CD = "COUNTERPARTY_CODE";
    static String ALLOC_IND = "Y";
    static String DERIV_MRGN_IND = "N";
    final Map<Pair<String, String>, List<String>> referenceMap;
    public CollateralCalculator() throws IOException {
        //first we need to read VM property to find out location of config file.
        if(!System.getProperties().containsKey("ods.collateral.reference.file")   ){
            throw new RuntimeException("could not find system property: \"ods.collateral.reference.file\"");
        }
        String referenceFile = System.getProperty("ods.collateral.reference.file");
        referenceMap = readCollateralReferenceFile(referenceFile);
    }
    private Map<Pair<String, String>, List<String>> readCollateralReferenceFile(String file_path) throws IOException {

        int counter_mapping =0;
        Map<Pair<String, String>, List<String>> collateral_reference_map;
        try (
                BufferedReader reader = new BufferedReader(new FileReader(file_path));
                CSVParser csvParser = new CSVParser(reader,
                        CSVFormat.DEFAULT.withDelimiter('|').withFirstRecordAsHeader().withIgnoreEmptyLines().withTrim());
        ) {
            List<String> collateral_references = new ArrayList<>();
            List<String> books = new ArrayList<>();
            List<String> cpty_cds = new ArrayList<>();
            List<String> alloc_inds = new ArrayList<>();
            List<String> deriv_mrgn_inds = new ArrayList<>();
            List<String> bltrl_inds = new ArrayList<>();

            Iterator<CSVRecord> iterator = csvParser.iterator();
            //First row is header
            while(iterator.hasNext()){
                Map<String,String> csvRowAsMap = iterator.next().toMap();

                collateral_references.add(csvRowAsMap.get("Collateral Reference"));
                books.add(csvRowAsMap.get("Book"));
                cpty_cds.add(csvRowAsMap.get("CPTY_CD"));
                alloc_inds.add(csvRowAsMap.get("ALLOC_IND"));
                deriv_mrgn_inds.add(csvRowAsMap.get("DERIV_MRGN_IND"));
                bltrl_inds.add(csvRowAsMap.get("BLTRL_IND"));
                counter_mapping++;
            }
            collateral_reference_map = createCollateralReferenceMapping(collateral_references, books, cpty_cds, alloc_inds, deriv_mrgn_inds, bltrl_inds);
        }
        catch (Exception e){
            throw new RuntimeException("Error reading record at line ["+counter_mapping+"] in file =["+file_path+"]", e);
        }
        return collateral_reference_map;
    }

    private Map<Pair<String, String>, List<String>> createCollateralReferenceMapping(List<String> collateral_reference, List<String> book, List<String> cpty_cd, List<String> alloc_ind, List<String> deriv_mrgn_ind, List<String> bltrl_inds) {
        Map<Pair<String, String>, List<String>> map = new HashMap<>();

        for (int i = 0; i < collateral_reference.size(); i++) {
            List<String> new_cols = new ArrayList<>();
            new_cols.add(cpty_cd.get(i));
            new_cols.add(alloc_ind.get(i));
            new_cols.add(deriv_mrgn_ind.get(i));
            new_cols.add(bltrl_inds.get(i));

            map.put(new Pair<>(collateral_reference.get(i), book.get(i)), new_cols);
        }
        return map;
    }

    public String map_cpt_code(Object[] key_list) {
        if (key_list.length < 3){
            throw new IndexOutOfBoundsException("Expected size of list is 3 elements, submitted input size: " + key_list.length);
        }
        Pair<String, String> key = new Pair<>(key_list[0].toString(), key_list[1].toString());
        if (this.referenceMap.get(key) != null){
            return this.referenceMap.get(key).get(0);
        }
        else return key_list[2].toString();
    }

    public String map_counterparty_code(Object[] key_list) {

        if (key_list.length < 3){
            throw new IndexOutOfBoundsException("Expected size of list is 3 elements, submitted input size: " + key_list.length);
        }
        boolean empty = key_list[2].toString().isEmpty();
        if (empty==true) {
            Pair<String, String> key = new Pair<>(key_list[0].toString(), key_list[1].toString());
            if (this.referenceMap.get(key) != null) {
                return this.referenceMap.get(key).get(0);
            } else return "";
        } else{
            return key_list[2].toString();
        }
    }

    public String map_alloc_ind(Object[] key_list) {
        if (key_list.length < 2){
            throw new IndexOutOfBoundsException("Expected size of list is 2 elements, submitted input size: " + key_list.length);
        }
        Pair<String, String> key = new Pair<>(key_list[0].toString(), key_list[1].toString());
        if (this.referenceMap.get(key) != null){
            return this.referenceMap.get(key).get(1);
        }
        else return "N";
    }

    public String map_deriv_marg(Object[] key_list) {
        if (key_list.length < 2){
            throw new IndexOutOfBoundsException("Expected size of list is 2 elements, submitted input size: " + key_list.length);
        }
        Pair<String, String> key = new Pair<>(key_list[0].toString(), key_list[1].toString());
        if (this.referenceMap.get(key) != null){
            return this.referenceMap.get(key).get(2);
        }
        else return "Y";
    }
    public String map_bltrl_ind(Object[] key_list) {
        if (key_list.length < 2){
            throw new IndexOutOfBoundsException("Expected size of list is 2 elements, submitted input size: " + key_list.length);
        }
        Pair<String, String> key = new Pair<>(key_list[0].toString(), key_list[1].toString()); //key_list[0] is "collateral reference", key_list[1] is "book"
        if (this.referenceMap.containsKey(key)){
            return this.referenceMap.get(key).get(3);
        }
        else return "Y"; // for primary keys cannot be found in the collateral refernece table, default "BLTRL_IND" = "Y"
    }

}
