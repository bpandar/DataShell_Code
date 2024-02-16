import com.bmo.cmrods.inputdata.collateral.BCLCalculator_CSVTransform;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;


public class BCLCaculcatorCSVTransformTest {

    public void TestGLMapping() throws IOException {
        System.setProperty("ods.bcl.mapping.file.GL", "src/main/resources/bcl/staticdata/GL_mapping.csv");
        BCLCalculator_CSVTransform BCL_calc = new BCLCalculator_CSVTransform();

        // BOND_FORWARD_GFI_CM,Positive MTM,182210000
        // COMMODITY_SWAP,Negative MTM,490712000
        String prod_1 = "BOND_FORWARD_GFI_CM";
        String mtm_1 = "5000";
        String gl_1 = null;
        String prod_2 = "COMMODITY_SWAP";
        String mtm_2 = "-1000";
        String gl_2 = null;

        // Expected Results
        String test_pos_1 = "182210000";
        String test_pos_2 = "490712000";


        Object[] test1 = new Object[3];
        test1[0] = prod_1;
        test1[1] = mtm_1;
        test1[2] = gl_1;

        Object[] test2 = new Object[3];
        test2[0] = prod_2;
        test2[1] = mtm_2;
        test2[2] = gl_2;

        String test_res_1 = BCL_calc.GLnumCalculator(test1);
        String test_res_2 = BCL_calc.GLnumCalculator(test2);


        assertEquals(test_pos_1, test_res_1);

        assertEquals(test_pos_2, test_res_2);
    }
    @Test
    public void main() throws IOException {

        this.TestGLMapping();



    }
}
