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
      System.out.println("ID\tModuleCode\tAT1\tAT2\tAT3\tAT4\tPrintName");
      while(rs.next())
      {
          String id = rs.getString("ID");
          String code = rs.getString("ModuleCode");
          int at1 = rs.getInt("ActivityTemplate");
          int at2 = rs.getInt("ActivityTemplate2");
          int at3 = rs.getInt("ActivityTemplate3");
          int at4 = rs.getInt("ActivityTemplate4");
          String name = rs.getString("PrintName");
          System.out.println(id + "\t" + code + "\t" + at1 + "\t" + at2 + "\t"
                             + at3 + "\t" + at4 + "\t" + name);
      }
      System.out.println();
      
      rs = print.executeQuery("SELECT * FROM tblActivity");
      System.out.println("tblActivity");
      System.out.println("ID\tPrintName\tSemester\tWeekPattern\tDay\tStart\t"
                         + "Duration\tLocation");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          String name = rs.getString("PrintName");
          int sem = rs.getInt("Semester");
          String week = rs.getString("WeekPattern");
          int day = rs.getInt("Day");
          int start = rs.getInt("Start");
          int duration = rs.getInt("Duration");
          int loc = rs.getInt("Location");
          System.out.println(id + "\t" + name + "\t" + sem + "\t" + week +
                             "\t"+ day + "\t" + start + "\t" + duration + "\t"
                             + loc);
      }
      System.out.println();
      
      rs = print.executeQuery("SELECT * FROM tblAllocation");
      System.out.println("tblEnrollment");
      System.out.println("ID\tStudent\tActivity");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          int student = rs.getInt("Student");
          String activity = rs.getString("Activity");
          System.out.println(id + "\t" + student + "\t" + activity);
      }
      System.out.println();

      rs = print.executeQuery("SELECT * FROM tblActivityTemplate");
      System.out.println("tblActivityTemplate");
      System.out.println("ID\tPrintName\tA1\tA2\tA3\tA4");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          String name = rs.getString("PrintName");
          int activity = rs.getInt("Activity1");
          int activity2 = rs.getInt("Activity2");
          int activity3 = rs.getInt("Activity3");
          int activity4 = rs.getInt("Activity4");
          System.out.println(id + "\t" + name + "\t" + activity + "\t" +
                             activity2 + "\t" + activity3 + "\t" + activity4);
      }
      System.out.println();

      rs = print.executeQuery("SELECT * FROM tblLocation");
      System.out.println("tblLocation");
      System.out.println("ID\tPrintName\tCapacity");
      while(rs.next())
      {
          int id = rs.getInt("ID");
          int capacity = rs.getInt("Capacity");
          String name = rs.getString("PrintName");
          System.out.println(id + "\t" + name + "\t" + capacity);
      }
    }
    catch(Exception e)
    {
        System.err.println(e);
    }
  }
}//class
