import com.bmo.cmrods.inputdata.collateral.GeneralCalculator;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;



import static org.junit.Assert.assertEquals;


public class GeneralCalculatorTest {
    //Uncomment line 16 to run tests and change path of reference file
    //crashes jar build because of permission issues/ access denied, carbon black firewall
    @Test
    public void main() throws IOException {
        String test_map = "src/main/resources/bcl/staticdata/GL_mapping.csv";
        GeneralCalculator Gcalc = new GeneralCalculator();

        List<String> test_keys = new ArrayList<String>(Arrays.asList("PRODUCT_SUB_TYPE_CD", "GL_TYPE"));
        List<String> test_values = new ArrayList<String>(Arrays.asList("GL_NUM"));

        Map<List<String>, List<String>> multi = Gcalc.readMappingFile(test_map,',',test_keys, test_values);

        for (Map.Entry<List<String>, List<String>> entry : multi.entrySet()) {
            String key = entry.getKey().toString();
            List<String> value = entry.getValue();
            System.out.println("key, " + key + " value " + value);
        }
        List<String> test_1 = new ArrayList<String>(Arrays.asList("BOND_FUTURES", "Positive MTM"));
        List<String> test_pos_1 = new ArrayList<String>(Arrays.asList("190512000"));
        List<String> test_res_1 = multi.get(test_1);

        assertEquals(test_pos_1, test_res_1);

        System.out.println(test_res_1);


    }
}



