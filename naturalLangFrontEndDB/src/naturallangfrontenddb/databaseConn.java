/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package naturallangfrontenddb;

import com.mysql.jdbc.DatabaseMetaData;
import java.sql.Statement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
/**
 *
 * @author connorbray
 */
public class databaseConn {
    static Connection conn = null;
    static String url;
    static String dbName;
    static String userName;
    static String password;

  /*
   * Creates the connection to the database
   */
  public static boolean connect(String Url, String DbName, String UserName, String Password)
  {
    url = Url;
    dbName = DbName;
    userName = UserName;
    password = Password;
    //String url = "jdbc:mysql://213.171.200.65/";
    //String dbName = "cbraydb";
    String driver = "com.mysql.jdbc.Driver";
    //String userName = "brayc0";
    //String password = "flarb393hopkins";
    try
    {
      Class.forName(driver).newInstance();
      conn = DriverManager.getConnection(url+dbName,userName,password);
      System.out.println("Connected to the database");
      return true;
    }
    catch (Exception e)
    {
      System.err.println("Could not connect to the database " + e);
      return false;
    }
  }//connect

  /*
   * Closes the connection to the database
   */
  public static void closeConn()
  {
    try
    {
      conn.close();
      System.out.println("Disconnected from database");   
    }
    catch(Exception e)
    {
      System.err.println("Could not close the connection " + e);   
    }    
  }//closeConn

  public static void genericQueryDB(String q)
  {
    try
    {
        Statement query = conn.createStatement();
        ResultSet rs = query.executeQuery(q);

        java.sql.ResultSetMetaData meta = rs.getMetaData();
        int colCount = meta.getColumnCount();
        String [] colNames = new String [colCount];
        //print the table name
        System.out.println(meta.getTableName(1));

        //Print out the names of the different fields.
        for(int i = 1; i<=colCount; i++)
        {
          colNames[i-1] = meta.getColumnName(i);
          System.out.print(colNames[i-1] +  "\t");
        }
        System.out.println();

        //while there is a next row to read
        while(rs.next())
        {
          //make an array for the data
          Object [] data = new Object [colCount];
          java.sql.ResultSetMetaData mdata = rs.getMetaData();
          //for each column
          for(int i = 0; i<data.length; i++)
          {
              //get the type of the column, so youknow what type of data to get
              int type = mdata.getColumnType(i+1);
              switch (type)
              {
                  case 4: data[i] = rs.getInt(colNames[i]);
                  break;
                  case 12: data[i] = rs.getString(colNames[i]);
                  break;
                  case -2: data[i] = new binaryString(rs.getBytes(colNames[i]));
                  break;
                  default: System.out.println(type);
                  break;
              }//switch
          }//for
          //for loop to print out the data
          for(int i = 0; i<data.length; i++)
          {
              //if the type of data stored in the object array is actually a 
              //binary string
              if(data[i].getClass().equals(binaryString.class))
              {
                  //cast the object to a binaryString
                  binaryString bs = (binaryString)data[i];
                  //go through each of the byytes and print out a 0 if it is 
                  //equal to 48 and a 1 if it is equal to 49
                  for(int j = 0; j<bs.bytes.length; j++)
                  {
                      int week = 0;
                      if(bs.bytes[j] == 49)
                          week = 1;
                      System.out.print(week);
                  }//for
                  System.out.print("\t");
              }//if
              //otherwise print out the object
              else
              {
                System.out.print(data[i] + "\t");
              }//else
          }
          System.out.println();
        }

    }
    catch(Exception e)
    {
        System.err.println(e);
    }
  }

  /*
   * A function which prints out the contents of the database.
   */
  public static void testPrint()
  {
    try
    {
      Statement print = conn.createStatement();
      //get the metedata of the database
      DatabaseMetaData dbmeta = (DatabaseMetaData) conn.getMetaData();
      String [] types = {"TABLE"};
      ResultSet dbtables = dbmeta.getTables(null, null, "%", types);

      //for each table
      while(dbtables.next())
      {
          //get the table name
          String tableName = dbtables.getString(3);
          //print the contents of the table
          genericQueryDB("SELECT * FROM " + tableName);
      }//while
    }//try
    catch(Exception e)
    {
        System.err.println(e);
    }
  }
}//class
