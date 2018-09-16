package com;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class Proportion
{
    private static int SOME_INT_VALUE = 1;
    private static String SOME_STRING_VALUE;
    private static int[] SOME_INT_ARRAY;
    private static double SOME_DOUBLE_VALUE;
    private static String parts;

    public static String Host;
    public static String Port;
    public static String DBName;
    public static String TNSName;
    public static String User;
    public static String Pass;
    public static String Schemas;

    public static void main(String[] args) throws IOException {
        GetProporties();
    }

    public static void GetProporties() throws IOException
    {
        Properties props = new Properties();
        props.load(new FileInputStream(new File("src/config/example.ini")));

        if(!props.isEmpty()) {
            SOME_INT_VALUE = Integer.valueOf(props.getProperty("SOME_INT_VALUE", "1"));
            SOME_STRING_VALUE = props.getProperty("SOME_STRING_VALUE");
            SOME_DOUBLE_VALUE = Double.valueOf(props.getProperty("SOME_DOUBLE_VALUE", "1.0"));


            Host = props.getProperty("HOST");
            Port = props.getProperty("PORT");
            DBName = props.getProperty("DB_NAME");
            TNSName = props.getProperty("TNS_NAME");
            User = props.getProperty("UER");
            Pass = props.getProperty("PASS");

            // Читаем список через точку с запятой
            Schemas = props.getProperty("SCHEMAS");
            if((Schemas != null)&&(Schemas != "")) {
                String[] Arr_Schemas = Schemas.split(";");
                for (int i = 0; i < Arr_Schemas.length; ++i) {
                    System.out.println(Arr_Schemas[i]);
                }
            }

        }
    }

}
