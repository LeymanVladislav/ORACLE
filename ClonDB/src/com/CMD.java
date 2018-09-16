package com;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Connection;
import com.Proportion;

public class CMD {
    private static Connection connection = null;
    //private static String url = DBDriver + "://" + Host + ":" + Port + "/" + DBName + "?" + SSLMode;
    String Url;


    public static void main(String[] argv) throws IOException {
        //String Url = DBDriver + ":@" + TNSName;


        Proportion.GetProporties();

        ExecuteDBScript("DBSCRIPTS\\test.sql");

        //connect(Proportion.Host,Proportion.Port,Proportion.DBName,Proportion.User,Proportion.Pass);
        //Url = DBDriver + ":@" + Host + ":" + Port + ":" + DBName;


    }

    public static void ExecuteCMD(String Command) {

        try {
            ProcessBuilder builder = new ProcessBuilder(
                    "cmd.exe", "/c", Command);
            builder.redirectErrorStream(true);
            Process p = builder.start();
            BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream(),"CP1251"));
            String line;
            while (true) {
                line = r.readLine();
                if (line == null) { break; }
                System.out.println(line);
            }

        }
        catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    public static void ExecuteDBScript(String FileName) {
        String Command = "sqlplus " + Proportion.User + "/" + Proportion.Pass + "@" + Proportion.TNSName + " @" + FileName;
        ExecuteCMD(Command);
    }
}