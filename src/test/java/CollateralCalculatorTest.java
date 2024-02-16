import com.bmo.cmrods.inputdata.collateral.CollateralCalculator;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;



import static org.junit.Assert.assertEquals;


public class CollateralCalculatorTest {
    //Uncomment line 16 to run tests and change path of reference file
    //crashes jar build because of permission issues/ access denied, carbon black firewall
    @Test
    public void main() throws IOException {
        System.setProperty("ods.collateral.reference.file","C:\\Users\\imalek\\BitBucket\\ods-inputdata-calculator\\src\\test\\data\\CollateralReferenceMapping.txt");
        CollateralCalculator cmap = new CollateralCalculator();

        String collat_good = "NBI MS 0331ABID7 - Equity Options IM";
        String book_good = "CC_NESBIT_USD";
        String collat_bad = "AVDL - BMO ISDA REG VM CSA";
        String book_bad = "CMG_BMO";
        String default_cpt = "Counterparty Code";
        String good_cpt = "ALL_MS_dummy";
        String good_alloc = "Y";
        String bad_alloc = "N";
        String good_mrgn = "N";
        String bad_mrgn = "Y";

        Object[] test1 = new Object[3];
        test1[0] =collat_good;
        test1[1] = book_good;
        test1[2] = good_cpt;

        Object[] test2 = new Object[3];
        test2[0] = collat_bad;
        test2[1] = book_bad;
        test2[2] = default_cpt;

        Object[] test3 = new Object[2];
        test3[0] = collat_good;
        test3[1] = book_good;

        Object[] test4 = new Object[2];
        test4[0] = collat_good;
        test4[1] = book_bad;

        Object[] test5 = new Object[3];
        test5[0] =collat_good;
        test5[1] = book_good;
        test5[2] = "";

        Object[] test6 = new Object[3];
        test6[0] = collat_bad;
        test6[1] = book_bad;
        test6[2] = "";

        Object[] test7 = new Object[3];
        test7[0] = collat_bad;
        test7[1] = book_bad;
        test7[2] = "FAKE";




        String CPTY_CODE = cmap.map_cpt_code(test1);
        assertEquals(good_cpt,CPTY_CODE );

        String CPTY_CODE_BAD = cmap.map_cpt_code(test2);
        assertEquals(default_cpt, CPTY_CODE_BAD );


        String alloc_var = cmap.map_alloc_ind(test3);
        assertEquals(good_alloc, alloc_var);

        String alloc_var_bad = cmap.map_alloc_ind(test4);
        assertEquals(bad_alloc, alloc_var_bad );

        String deriv_good = cmap.map_deriv_marg(test3);
        assertEquals(good_mrgn,deriv_good);

        String deriv_bad = cmap.map_deriv_marg(test4);
        assertEquals(bad_mrgn,deriv_bad );

        String counter_party_empty_good = cmap.map_counterparty_code(test5);
        assertEquals("ALL_MS_dummy",counter_party_empty_good );

        String counter_party_empty_bad = cmap.map_counterparty_code(test6);
        assertEquals("",counter_party_empty_bad );

        String counter_party_bad = cmap.map_counterparty_code(test7);
        assertEquals("FAKE",counter_party_bad );
    }
}
