package com.bmo.cmrods.inputdata.collateral;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class BCLCalculator_CSVTransform extends GeneralCalculator{

    final Map<List<String>, List<String>> gl_mapping;

    public BCLCalculator_CSVTransform() throws IOException {

        //first we need to read VM property to find out location of config file.
        if(!System.getProperties().containsKey("ods.bcl.mapping.file.GL")   ){
            throw new RuntimeException("could not find system property: \"ods.bcl.mapping.file.GL\"");
        }
        String gl_referenceFile = System.getProperty("ods.bcl.mapping.file.GL");
        this.gl_mapping = readMappingFile(gl_referenceFile, ',', Arrays.asList("PRODUCT_SUB_TYPE_CD", "GL_TYPE"), Arrays.asList("GL_NUM"));
    }


    public String GLnumCalculator(Object [] key_list){
        /**
         * Takes an object array which should be implied parameters in the correct order
         * @param key_list object array with the implied parameters: finance_PRODUCT_SUB_TYPE_CD (key_list[0]), saccr_PRODUCT_SUB_TYPE_CODE (key_list[1]), MTM (key_list[2]), finance_GL (key_list[3])
         * @return The resulting value is the mapping table for keys: "PRODUCT_SUB_TYPE_CD", "GL_TYPE"
         */

        String mtm_signage = "";
        List<String> na_list = Arrays.asList("null", "n.a", "na", "n/a");

        // If finance_GL is empty do mapping
        if (key_list[3] == null || key_list[3].toString().trim().isEmpty() || na_list.contains(key_list[3].toString().trim().toLowerCase())){

            // check where MTM is positive or negative
            float mtm = Float.parseFloat(key_list[2].toString());

            if (mtm < 0){
                mtm_signage = "Negative MTM";
            }
            else { mtm_signage = "Positive MTM"; }

            // consider finance_PRODUCT_SUB_TYPE_CD first, if not available, then saccr_PRODUCT_SUB_TYPE_CODE
            List<String> finance_gl_keys = Arrays.asList(key_list[0].toString(), mtm_signage);
            List<String> saccr_gl_keys = Arrays.asList(key_list[1].toString(), mtm_signage);

            //get mapped value
            if (this.gl_mapping.containsKey(finance_gl_keys)){
                return this.gl_mapping.get(finance_gl_keys).get(0);
            }
            if (this.gl_mapping.containsKey(saccr_gl_keys)){
                return this.gl_mapping.get(saccr_gl_keys).get(0);
            }
            return "N.A.";
        }
        // if finance_GL is available
        return key_list[3].toString();
    }


}
