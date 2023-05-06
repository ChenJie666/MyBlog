---
title: Flink写出-MySql-控制事务，保证Exactly_Once
categories:
- 大数据实时
---
# 一、MySql Sink
要想使用TwoPhaseCommitSinkFunction，存储系统必须支持事务

Mysql Sink继承TwoPhaseCommitSinkFunction抽象类，分两个阶段提交Sink，保证Exactly_Once：

①做checkpoint
② 提交事务



# 二、控制事务代码

#### 1、主线代码

参数详解：
*   ① 输入的类型
*   ② connection数据库连接对象
*   ③ 什么都不指定，为了泛型，写void

```
public class MySqlTwoPhaseCommitSink extends TwoPhaseCommitSinkFunction<Tuple2<String, Integer>,
        MySqlTwoPhaseCommitSink.ConnectionState, Void> {

    // 定义可用的构造函数
    public MySqlTwoPhaseCommitSink() {
        super(new KryoSerializer<>(MySqlTwoPhaseCommitSink.ConnectionState.class, new ExecutionConfig()),
                VoidSerializer.INSTANCE);
    }


    @Override
    protected ConnectionState beginTransaction() throws Exception {
        System.out.println("=====> beginTransaction... ");
        //使用连接池，不使用单个连接
        //Class.forName("com.mysql.jdbc.Driver");
        //Connection conn = DriverManager.getConnection("jdbc:mysql://172.16.200
        // .101:3306/bigdata?characterEncoding=UTF-8", "root", "123456");
        Connection connection = DruidConnectionPool.getConnection();
        connection.setAutoCommit(false);//设定不自动提交
        return new ConnectionState(connection);
    }


    @Override
    protected void invoke(ConnectionState transaction, Tuple2<String, Integer> value, Context context) throws Exception {

        Connection connection = transaction.connection;
        PreparedStatement pstm = connection.prepareStatement("INSERT INTO t_wordcount (word, counts) VALUES (?, ?) ON" +
                " DUPLICATE KEY UPDATE counts = ?");
        pstm.setString(1, value.f0);
        pstm.setInt(2, value.f1);
        pstm.setInt(3, value.f1);
        pstm.executeUpdate();
        pstm.close();

    }


    // 先不做处理
    @Override
    protected void preCommit(ConnectionState transaction) throws Exception {
        System.out.println("=====> preCommit... " + transaction);
    }

	//提交事务
    @Override
    protected void commit(ConnectionState transaction) {
        System.out.println("=====> commit... ");
        Connection connection = transaction.connection;
        try {
            connection.commit();
            connection.close();
        } catch (SQLException e) {
            throw new RuntimeException("提交事物异常");
        }
    }

	//回滚事务
    @Override
    protected void abort(ConnectionState transaction) {
        System.out.println("=====> abort... ");
        Connection connection = transaction.connection;
        try {
            connection.rollback();
            connection.close();
        } catch (SQLException e) {
            throw new RuntimeException("回滚事物异常");
        }
    }

    //定义建立数据库连接的方法
    public static class ConnectionState {
        private final transient Connection connection;

        public ConnectionState(Connection connection) {
            this.connection = connection;
        }
    }
}
```

#### 2、[Druid](https://so.csdn.net/so/search?q=Druid&spm=1001.2101.3001.7020) 数据库连接池类

为什么要用连接池？

*   **因为每个数据库连接都要控制事务**
```
import com.alibaba.druid.pool.DruidDataSourceFactory;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

public class DruidConnectionPool {

    private transient static DataSource dataSource = null;
    private transient static Properties props = new Properties();

    // 静态代码块
    static {
        props.put("driverClassName", "com.mysql.jdbc.Driver");
        props.put("url", "jdbc:mysql://localhost:3306/day01?characterEncoding=utf8");
        props.put("username", "root");
        props.put("password", "123456");
        try {
            dataSource = DruidDataSourceFactory.createDataSource(props);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private DruidConnectionPool() {
    }

    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }
}
```
