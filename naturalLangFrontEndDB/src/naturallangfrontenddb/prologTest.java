/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package naturallangfrontenddb;

import jpl.*;



/**
 *
 * @author brayc0
 */
public class prologTest
{
  public void test()
  {
    Query q1 = new Query("consult", new Term[] {new Atom("test.pl")}
    );
  }
}
