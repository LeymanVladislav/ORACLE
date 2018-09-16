package db.oracle;

import java.io.*;
import java.sql.*;
import oracle.jdbc.OracleDriver;

public class DBConnection {
    private static Connection connection = null;
    private static String PKG_NAME = "JDBCDriverConnection";
    private static String DBDriver = "jdbc:oracle:thin";
    private static String Host = "LV";
    private static String Port = "1525";
    private static String DBName = "DBMAIN";
    private static String TNSName = "DB_MAIN";
    private static String SSLMode = "sslmode=require";
    private static String User = "CB";
    private static String Pass = "1";
    //private static String url = DBDriver + "://" + Host + ":" + Port + "/" + DBName + "?" + SSLMode;
    String Url = DBDriver + ":@" + Host + ":" + Port + ":" + DBName;


    public static void main(String[] argv) throws IOException {
        //String Url = DBDriver + ":@" + TNSName;

        connect(Host,Port,DBName,User,Pass);
    }

    public static void connect(String Host, String Port, String DBName, String User, String Pass) {
        String DBDriver = "jdbc:oracle:thin";
        String Url = DBDriver + ":@" + Host + ":" + Port + ":" + DBName;

        System.out.println("-------- Oracle JDBC Connection Testing ------");

        try {

            DriverManager.registerDriver(new OracleDriver());
            System.out.println("Oracle JDBC Driver Registered!");


        } catch (SQLException e) {

            System.out.println("Where is your Oracle JDBC Driver?");
            e.printStackTrace();

        }

        try {

            System.out.println("Url: " + Url);
            connection = DriverManager.getConnection(Url, User, Pass);

        } catch (SQLException e) {

            System.out.println("Connection Failed! Check output console");
            e.printStackTrace();
            return;

        }

        if (connection != null) {
            System.out.println("You made it, take control your database now!");
        } else {
            System.out.println("Failed to make connection!");
        }
    }
}
