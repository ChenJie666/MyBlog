---
title: MyBatisPlus代码自动生成器
categories:
- SpringBoot
---
[官网demo](https://mp.baomidou.com/guide/generator.html#%E4%BD%BF%E7%94%A8%E6%95%99%E7%A8%8B)



AutoGenerator是MyBatis-Plus的代码生成器，通过AutoGenerator可以快速生成Entity、Mapper、Mapper XML、Service、Controller等各个模块的代码。

**依赖**
```yml
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-boot-starter</artifactId>
            <version>${mybatis-plus.version}</version>
        </dependency>
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-generator</artifactId>
            <version>${mybatis-plus.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.velocity</groupId>
            <artifactId>velocity-engine-core</artifactId>
            <version>2.0</version>
        </dependency>
```

**代码自动生成类**
```java
public class MyAutoGenerator {

    public static void main(String[] args) {
        // 代码生成器
        AutoGenerator mpg = new AutoGenerator();

        // 1.全局配置
        GlobalConfig gc = new GlobalConfig();
        String projectPath = System.getProperty("user.dir");

        gc.setOutputDir(projectPath + "/src/main/java");
        gc.setAuthor("CJ");
        gc.setOpen(false); //是否打开输出目录
        gc.setSwagger2(true);

        gc.setFileOverride(false);  //是否覆盖
        gc.setServiceName("%sService");  //去掉Service的I前缀，各层文件名称方式，例如： %sAction 生成 UserAction为占位符
        gc.setIdType(IdType.ID_WORKER_STR);    //主键生成算法
        gc.setDateType(DateType.ONLY_DATE); //设置日期类型

        mpg.setGlobalConfig(gc);

        // 2.配置数据源
        DataSourceConfig dsc = new DataSourceConfig();
        dsc.setDriverName("com.mysql.cj.jdbc.Driver");
        dsc.setUrl("jdbc:mysql://116.62.148.11:3306/bookkeeping?useSSL=false&useUnicode=true&characterEncoding=utf-8&serverTimezone=GMT%2B8");
        dsc.setUsername("root");
        dsc.setPassword("abc123");

        mpg.setDataSource(dsc);

        // 3.包配置
        PackageConfig pc = new PackageConfig();
        pc.setModuleName("blog");
        pc.setParent("com.cj.demo");
        pc.setController("controller");
        pc.setService("service");
        pc.setMapper("mapper");
        pc.setEntity("entities");

        mpg.setPackageInfo(pc);

        // 4.策略配置
        StrategyConfig sc = new StrategyConfig();
        sc.setInclude("bookkeep"); //需要读取的表名，允许正则表达式（与exclude二选一配置）
        sc.setNaming(NamingStrategy.underline_to_camel); //表名映射到实体的命名策略(下划线转驼峰)
        sc.setColumnNaming(NamingStrategy.underline_to_camel); //表字段映射到实体的命名策略
        sc.setEntityLombokModel(true); //自动添加lombok
        sc.setLogicDeleteFieldName("deleted"); //设置逻辑删除字段的名字
        sc.setVersionFieldName("version"); //设置乐观锁
        TableFill createTime = new TableFill("create_time", FieldFill.INSERT);
        TableFill updateTime = new TableFill("update_time", FieldFill.INSERT_UPDATE);
        sc.setTableFillList(Arrays.asList(createTime, updateTime)); //设置自动填充字段

        sc.setRestControllerStyle(true);
        sc.setControllerMappingHyphenStyle(true); //请求路径中的驼峰转下划线

        mpg.setStrategy(sc);

        // 5.最后执行该生成器
        mpg.execute();

    }

}
```
