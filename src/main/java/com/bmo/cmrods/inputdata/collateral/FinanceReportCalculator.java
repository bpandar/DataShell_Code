package com.bmo.cmrods.inputdata.collateral;

import javafx.util.Pair;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;

public class FinanceReportCalculator {

    final Map<String, String> sourceSystemMap;
    final Map<String, String> legalEntityMap;

    public FinanceReportCalculator() throws IOException {
        //first we need to read VM property to find out location of config file.
        if(!System.getProperties().containsKey("ods.source_system.file")   ){
            throw new RuntimeException("could not find system property: \"ods.source_system.file\"");
        }
        if(!System.getProperties().containsKey("ods.legal_entity.file")   ){
            throw new RuntimeException("could not find system property: \"ods.legal_entity.file\"");
        }


        String sourceSystemMappingFile = System.getProperty("ods.source_system.file");
        sourceSystemMap = readSourceSystemMappingFile(sourceSystemMappingFile);

        String legalEntityMappingFile = System.getProperty("ods.legal_entity.file");
        legalEntityMap = readLegalEntityMappingFile(legalEntityMappingFile);
    }

    private Map<String, String> readSourceSystemMappingFile(String file_path){
        int counter_mapping =0;
        Map<String, String> source_system_map;
        try (
                BufferedReader reader = new BufferedReader(new FileReader(file_path));
                CSVParser csvParser = new CSVParser(reader,
                        CSVFormat.DEFAULT.withDelimiter('|').withFirstRecordAsHeader().withIgnoreEmptyLines().withTrim());
        ) {
            List<String> source_systems = new ArrayList<>();
            List<String> src_sys_cds = new ArrayList<>();
            Iterator<CSVRecord> iterator = csvParser.iterator();
            //First row is header
            while(iterator.hasNext()){
                Map<String,String> csvRowAsMap = iterator.next().toMap();

                source_systems.add(csvRowAsMap.get("SourceSystem"));
                src_sys_cds.add(csvRowAsMap.get("SRC_SYS_CD"));
                counter_mapping++;
            }
            source_system_map = createSourceSystemMapping(source_systems, src_sys_cds);
        }
        catch (Exception e){
            throw new RuntimeException("Error reading record at line ["+counter_mapping+"] in file =["+file_path+"]", e);
        }
        return source_system_map;
    }

    private Map<String, String> readLegalEntityMappingFile(String file_path){
        int counter_mapping =0;
        Map<String, String> source_system_map;
        try (
                BufferedReader reader = new BufferedReader(new FileReader(file_path));
                CSVParser csvParser = new CSVParser(reader,
                        CSVFormat.DEFAULT.withDelimiter('|').withFirstRecordAsHeader().withIgnoreEmptyLines().withTrim());
        ) {
            List<String> legal_entities = new ArrayList<>();
            List<String> legal_entity_codes = new ArrayList<>();
            Iterator<CSVRecord> iterator = csvParser.iterator();
            //First row is header
            while(iterator.hasNext()){
                Map<String,String> csvRowAsMap = iterator.next().toMap();

                legal_entities.add(csvRowAsMap.get("LegalEntity"));
                legal_entity_codes.add(csvRowAsMap.get("Legal Entity Code"));
                counter_mapping++;
            }
            source_system_map = createLegalEntityMapping(legal_entities, legal_entity_codes);
        }
        catch (Exception e){
            throw new RuntimeException("Error reading record at line ["+counter_mapping+"] in file =["+file_path+"]", e);
        }
        return source_system_map;
    }

    private Map<String, String> createLegalEntityMapping(List<String> legal_entities, List<String> legal_entity_codes) {
        Map<String, String> map = new HashMap<>();

        for (int i = 0; i < legal_entities.size(); i++) {
            map.put(legal_entities.get(i).toUpperCase(), legal_entity_codes.get(i));
        }
        return map;
    }

    private Map<String, String> createSourceSystemMapping(List<String> source_systems, List<String> src_sys_cds) {
        Map<String, String> map = new HashMap<>();

        for (int i = 0; i < source_systems.size(); i++) {
            map.put(source_systems.get(i), src_sys_cds.get(i));
        }
        return map;
    }

    // MARP-52 and MARP-54
    public String mapSrcSysCd(Object[] inputs){
        // inputs[1] is swapOne_swapId
        if (!inputs[1].toString().isEmpty()) {
            return "SWAPONE";
        }
        // inputs[0] is sourceSystem
        if (this.sourceSystemMap.containsKey(inputs[0].toString())){
            return this.sourceSystemMap.get(inputs[0].toString());
        }
        return inputs[0].toString();
    }

    // MARP-53 and MARP-413
    public String overrideTradeId(Object[] inputs){
        // inputs[0] is swapOne_swapId
        if (!inputs[0].toString().trim().isEmpty()) {
            return inputs[0].toString();
        }
        // inputs[1] is sourceSystem, inputs[2] is SourceTradeId, inputs[3] is LegalEntity, inputs[4] is CounterpartyAdaptiveCode, input[5] is WSS Transaction ID
        if (inputs[1].toString().equals("TraderEH")){
            if (this.legalEntityMap.containsKey(inputs[3].toString().toUpperCase())) {
                return inputs[2].toString() + "_" + this.legalEntityMap.get(inputs[3].toString().toUpperCase()) + "_" + inputs[4].toString();
            }
        }
        // inputs[1] is sourceSystem
        if (inputs[1].toString().equals("WSS")){
            if (!inputs[5].toString().trim().isEmpty()){
                return inputs[5].toString();
            }
        }
        // input[2] is SourceTradeId
        return inputs[2].toString();
    }
    public String overrideClearanceType(Object[] inputs){
        // inputs[0] is ClearanceType
        if (inputs[0].toString().equals("OTC")){
            return "OTCDRV";
        }
        if (inputs[0].toString().equals("Exchange Traded")){
            return "EXCDRV";
        }
        return inputs[0].toString();
    }

    public String calculateGL(Object[] inputs){
        // inputs[0] is FINANCE_GL
        List<String> na_list = Arrays.asList("null", "n.a", "na", "n/a");
        if (inputs[0].toString().trim().isEmpty() || na_list.contains(inputs[0].toString().trim().toLowerCase())){
            return "n.a";
        }
        return "n.a";
    }

}
