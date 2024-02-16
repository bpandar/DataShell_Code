package com.bmo.cmrods.inputdata.collateral;

import java.io.*;
import java.util.*;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;


// JAva unmodified list

public class GeneralCalculator {

    public Map<List<String>, List<String>> readMappingFile(String file_path, char delimiter, List<String> primary_keys, List<String> value_columns) {
        /***
         * Function to create a mapping table with for n length keys and n values size list
         * ***/
        Map<List<String>, List<String>> map = new HashMap<>();
        int counter_mapping = 0;

        try (
                BufferedReader reader = new BufferedReader(new FileReader(file_path));
                CSVParser records = new CSVParser(reader, CSVFormat.DEFAULT.withDelimiter(delimiter).withFirstRecordAsHeader().withIgnoreEmptyLines().withTrim())
        ) {
            for (CSVRecord record: records){
                // for each row get you list of keys and values
                List<String> key_list = new ArrayList<String>(primary_keys.size());
                List<String> value_list = new ArrayList<String>(value_columns.size());

                for (int i=0; i< primary_keys.size(); i++){
                    String this_key = primary_keys.get(i);
                    key_list.add(i, record.get(this_key));
                }

                for (int i=0; i< value_columns.size(); i++){
                    String this_value = value_columns.get(i);
                    value_list.add(i, record.get(this_value));
                }
                // Make keys immutable because a key in a hashmap should be immutable
                key_list = Collections.unmodifiableList(key_list);

                map.put(key_list, value_list);

                counter_mapping++;
            }

        } catch (Exception e) {
            throw new RuntimeException("Error reading record at line [" + counter_mapping + "] in file =[" + file_path + "]", e);
        }
        return map;
    }
}
