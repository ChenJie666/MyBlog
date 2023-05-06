---
title: SqlServer获取字段名
categories:
- 工具
---
```
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class GetSqlserverinfo {
    //获取表名和内部连接方式
    public Map<String, List<String>> getSqlServerColumnInfo(String table){
        Connection conn= null;
        Statement st= null;
        ResultSet rs = null;
        DatabaseMetaData dbmd =null;
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver").newInstance();
            String url="jdbc:sqlserver://192.168.0.2:1433";
            String user="dw";
            String password="hxr,123";
            conn= DriverManager.getConnection(url,user,password);
            st =conn.createStatement();
            dbmd = conn.getMetaData();
            rs = dbmd.getColumns(null, null, table.toUpperCase(), null);
        } catch (SQLException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

        //String sql="select COLUMN_NAME,DATA_TYPE,DATA_LENGTH,DATA_PRECISION,DATA_SCALE,NULLABLE　from user_tab_columns where table_name =UPPER('"+table+"')";
        Map<String,List<String>> map = new LinkedHashMap<String, List<String>>();
        try{
            //rs = st.executeQuery(sql);
            List<String> val = null;
            while(rs.next()){
                val = new ArrayList<String>();
                //列名称
                String columnName = rs.getString("COLUMN_NAME").toLowerCase();//列名
                //数据类型
                int dataType = rs.getInt("DATA_TYPE");//类型
                //数据类型名称
                String dataTypeName = rs.getString("TYPE_NAME").toLowerCase();
                //精度,列的大小
                int precision = rs.getInt("COLUMN_SIZE");//精度
                //小数位数
                int scale = rs.getInt("DECIMAL_DIGITS");// 小数的位数
                //是否为空
                int isNull = rs.getInt("NULLABLE");//是否为空
                //字段默认值
                String defaultValue = rs.getString("COLUMN_DEF");
                map.put(columnName, val);
            }
        }catch (Exception e) {
            e.printStackTrace();
            // TODO: handle exception
        }finally {
            this.close(conn,st,rs);
        }

        return map;
    }


    //关闭连接
    public void close(Connection conn , Statement stmt, ResultSet rs){
        try{
            if(rs != null){
                rs.close();
                rs = null ;
            }
            if(stmt != null){
                stmt.close();
                stmt = null ;
            }
            if(conn != null){
                conn.close();
                conn = null;
            }

        }catch(Exception e){
            System.out.println(e);
        }
    }


    //建立连接
    public static void main(String[] args) {
        String tableName = "SO_SOMain";
        GetSqlserverinfo gli = new GetSqlserverinfo();
        Map<String, List<String>> oracleColumn_info = gli.getSqlServerColumnInfo(tableName);
        for (Map.Entry entry : oracleColumn_info.entrySet()) {
            System.out.println(entry.getKey());


        }
        System.out.println("stop");
    }


}
```
