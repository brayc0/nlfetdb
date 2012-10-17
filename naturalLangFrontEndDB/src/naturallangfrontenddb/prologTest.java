package naturallangfrontenddb;

import jpl.*;

public class prologTest
{
  public static void test()
  {
    //Opens the database file
    Query q1 = new Query("consult", new Term[] {new Atom("sentence.pl")});
    //tells us whether it was successful or not
    System.out.println( "consult " + (q1.query() ? "succeeded" : "failed"));
  }
}
