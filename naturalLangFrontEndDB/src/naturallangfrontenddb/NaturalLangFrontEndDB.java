/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package naturallangfrontenddb;

/**
 *
 * @author connorbray
 */
public class NaturalLangFrontEndDB {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        prologTest.test();
        connectUI ui = new connectUI();
        ui.setLocationRelativeTo(null);
        ui.setSize(400, 300);
        ui.setVisible(true);
        
        
    }
}
