/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package naturallangfrontenddb;

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
    
  public static void connect(String Url, String DbName, String UserName, String Password)
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
    }
    catch (Exception e)
    {
      System.err.println("Could not connect to the database " + e);
    }
  }//connect
  
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
  
  public static void testPrint()
  {
    try
    {
      Statement print = conn.createStatement();
      ResultSet rs = print.executeQuery("SELECT * FROM tblStudents");
      System.out.println("tblStudents");
      System.out.println("ID\tForename\tSurname");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          String forename = rs.getString("Forename");
          String surname = rs.getString("Surname");
          System.out.println(id + "\t" + forename + "\t" + surname);
      }      
      System.out.println();
      
      rs = print.executeQuery("SELECT * FROM tblModule");
      System.out.println("tblModule");
      System.out.println("ModuleID\tModuleTitle\t\t\tModuleLeader");
      while(rs.next())
      {
          String id = rs.getString("ModuleID");
          String title = rs.getString("ModuleTitle");
          String leader = rs.getString("ModuleLeader");
          System.out.println(id + "\t" + title + "\t" + leader);
      }
      System.out.println();
      
      rs = print.executeQuery("SELECT * FROM tblActivity");
      System.out.println("tblActivity");
      System.out.println("ID\tModule\t\tType");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          String module = rs.getString("Module");
          String type = rs.getString("Type");
          System.out.println(id + "\t" + module + "\t" + type);
      }
      System.out.println();
      
      rs = print.executeQuery("SELECT * FROM tblEnrollment");
      System.out.println("tblEnrollment");
      System.out.println("ID\tStudent\tModule");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          int student = rs.getInt("Student");
          String module = rs.getString("Module");
          System.out.println(id + "\t" + student + "\t" + module);
      }
    }
    catch(Exception e)
    {
        System.err.println(e);
    }
  }
}//class
