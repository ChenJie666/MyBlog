---
title: Spring5框架
categories:
- 后端框架
---
<!-- 
1. 循环依赖
2. 事务
3. 生命周期：从Bean的实例化到初始化的过程
4. IOC（控制反转）：重载Bean对象
5. AOP（面向切面编程）：实现一些事务和日志处理
6. 设计模式
7. 传播特性
8. 源码
9. 动态代理(JDK动态代理、CGLIB动态代理)
-->
<br>

**摘要**
1. Spring框架概述
- 轻量级开源JavaEE框架，为了减少企业中项目复杂性，两个核心组成：IOC和AOP

2. IOC容器
- IOC底层原理（工厂，反射等）
- IOC接口（BeanFactory）
- IOC操作Bean管理（基于xml）
- IOC操作Bean管理（基于注解）

3. AOP
- AOP底层原理：动态代理(有接口使用JDK动态代理、无接口使用CGLIB动态代理)
- 术语：连接点、切入点、增强(通知)、切面
- 基于AspectJ实现AOP相关操作

4. JdbcTemplate
- 使用JdbcTemplate实现CRUD和批量操作

5. 事务管理
- 事务概念（传播行为和隔离级别）
- 基于注解/配置文件方式实现事务管理

6. Spring5新功能
- 整合日志框架
- @Nullable注解
- 函数式注册对象
- 整合JUnit5单元测试框架
- SpringWebflux使用


#一、Spring
## 1.1 简介
Spring是一个轻量级控制反转(IOC)和面向切面(AOP)的容器框架。
Spring理念：使现有的技术更加容易使用。本身是一个大杂烩。

![image.png](Spring5框架.assets7333b17cd524d7ebe99072f7d4c508c.png)

**SSH：**Struct2 + Spring + Hibernate(全自动持久化框架)
**SSM：**SpringMVC + Spring + Mybatis(半自动持久化框架)

## 1.2 优点
- Spring是一个开源免费的框架（容器）；
- Spring是一个轻量级的、非入侵式的框架；
- **控制反转（IOC），面向切面编程（AOP）；**
- 支持事务的处理，对框架整合的支持。

## 1.3 入门案例
需要依赖的jar包为
- commons-logging-1.1.1.jar
- spring-beans-5.3.7.RELEASE.jar
- spring-context-5.3.7.RELEASE.jar
- spring-core-5.3.7.RELEASE.jar
- spring-expression-5.3.7.RELEASE.jar

**依赖**
```
<properties>
        <spring-version>5.3.7</spring-version>
        <logging-version>1.1.1</logging-version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-beans</artifactId>
            <version>${spring-version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-context</artifactId>
            <version>${spring-version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-core</artifactId>
            <version>${spring-version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-expression</artifactId>
            <version>${spring-version}</version>
        </dependency>
        <dependency>
            <groupId>commons-logging</groupId>
            <artifactId>commons-logging</artifactId>
            <version>${logging-version}</version>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.10</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
```
**创建Bean文件**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="user" class="com.cj.spring5.User"></bean>

</beans>
```
**测试**
```
public class UserTest {

    @Test
    public void testAdd(){
        // 1.加载spring配置文件
        ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");// 如果在src下可以使用该类获取,即默认在classpath路径下
//        BeanFactory context = new ClassPathXmlApplicationContext("bean1.xml"); // ClassPathXmlApplicationContext实现了BeanFactory
//       ClassPathXmlApplicationContext context = new FileSystemXmlApplicationContext("bean1.xml");  // 1.没有盘符的是项目工作路径,即项目的根目录;2.有盘符表示的是文件绝对路径.  如果要使用classpath路径,需要前缀classpath:

        // 2.获取配置创建的对象
        User user = context.getBean("user", User.class);

        System.out.println(user);
        user.add();
    }

}
```


<br>
# 二、IOC容器
## 2.1 IOC底层原理
控制反转(Inversion of Control)是面向对象编程中的一种设计原则，可以用来减低计算机之间的耦合度。通过控制反转，把对象的创建和对象之间的调用过程，交给Spring进行管理。

第一步：通过xml文件配置需要创建的对象
```
<bean id="dao" class="com.cj.UserDao"></bean>
```
第二步：有service类和dao类，创建工厂类
```
class UserFactory {
  public static UserDao getDao(){
    String classValue = class的属性值;  // 解析xml得到
    Class clazz = Class.forName(classValue);
    return (UserDao)clazz.newInstance();
  }
}
```
步骤：工厂模式+xml解析+反射创建
优点：进一步降低耦合度，只需要修改xml文件中的属性，就可以创建不同的对象。

<br>
## 2.2 IOC接口(BeanFactory)
1. IOC思想基于IOC容器完成，IOC容器底层就是**对象工厂**
2. Spring提供IOC容器实现的两种方式： （两个接口）
- BeanFactory：IOC容器基本实现方式，是Spring内部使用的接口，不提供开发人员进行使用。
**特点：**加载配置文件时，不会创建对象，在获取对象（使用）时才去创建对象。
- ApplicationContext：是BeanFactory接口的子接口，提供了更多更强大的功能，一般由开发人员进行使用。
**特点：**加载配置文件时就会把配置文件对象进行创建。
**分析：**在服务器启动时对对象进行创建，将费时耗资源的操作在启动时完成来的更好。
3. ApplicationContext接口实现类介绍

![image.png](Spring5框架.assets\3008a502cdaa49d18130aac7ef24eb12.png)

有两个常用的实现类
- FileSystemXmlApplicationContext：文件所在的盘符路径，即系统的绝对路径。
- ClassPathXmlApplicationContext：src下的类路径


<br>
## 2.3 IOC操作Bean管理
**Bean管理指的是两个操作：**
- Spring创建对象
- Spring属性注入

**Bean管理操作有两种方式：**
- 基于xml方式管理操作
- 基于注解方式管理操作

### 2.3.1 基于xml方式创建对象
- 在bean中标签有很多属性，介绍常用的属性：id（唯一标识）、class属性（包类路径）、name（同id，但是不支持特殊符号）
- 创建对象时，默认也是执行无参构造方法完成对象创建(通过反射创建)。
- DI依赖注入：就是注入属性。

**第一种注入方式：set方法注入**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="book" class="com.cj.spring5.Book">
        <property name="name" value="深入理解java虚拟机"/>
        <property name="author" value="周志明"/>
    </bean>

</beans>
```
```
public class Book {
    private String name;
    private String author;

    public void setName(String name) {
        this.name = name;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    @Override
    public String toString() {
        return "Book{" +
                "name='" + name + '\'' +
                ", author='" + author + '\'' +
                '}';
    }
}
```
**第二种注入方式：有参构造注入**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="book2" class="com.cj.spring5.Book2">
        <constructor-arg name="name" value="深入理解java虚拟机"/>
        <constructor-arg name="author" value="周志明"/>
        <!--<constructor-arg index="0" value="深入理解java虚拟机"/>-->
        <!--<constructor-arg index="1" value="周志明"/>--> <!--使用参数位置赋值-->
    </bean>

</beans>
```
```
public class Book2 {
    private String name;
    private String author;

    public Book2(String name, String author) {
        this.name = name;
        this.author = author;
    }

    @Override
    public String toString() {
        return "Book{" +
                "name='" + name + '\'' +
                ", author='" + author + '\'' +
                '}';
    }
}
```
**第三种注入方式：p名称空间注入**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:p="http://www.springframework.org/schema/p"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="book" class="com.cj.spring5.Book" p:name="深入理解java虚拟机" p:author="周志明"/> <!--p这个名字可以随意更换-->

</beans>
```

<br>
### 2.3.2 基于xml方式注入不同类型属性
1. 注入字面量
1）null值
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="book" class="com.cj.spring5.Book">
        <property name="name" value="深入理解java虚拟机"/>
        <property name="author" value="周志明"/>
        <property name="address">
            <null/>
        </property>
    </bean>

   </beans>
   ```
   2）属性值包含特殊符号
如需要正确赋值如下语句
   ```
        <property name="address" value="<<南京>>"/>
   ```
   - 把<>进行转义：使用&lt;和&gt;代替
   ```
        <property name="address" value="&lt;&lt;南京&gt;&gt;"/>
   ```
   - 把带特殊符号内容写到CDATA
   ```
        <property name="address">
            <value>"<![CDATA[<<南京>>]]>"</value>
        </property>
   ```

2. 注入属性-外部bean
创建两个类service类和dao类，通过ref属性注入外部的bean。
   ```xml
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="userService" class="com.cj.spring5.service.ServiceImpl">
        <property name="userDao" ref="userDao"/>
    </bean>
    <bean id="userDao" class="com.cj.spring5.dao.UserDaoImpl"/>
    
   </beans>
   ```

3. 注入属性-内部bean和级联赋值
1）一对多关系：部门和员工
2）在实体类之间表示一对多的关系
使用内部bean赋值
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="emp" class="com.cj.spring5.entity.Emp">
        <property name="ename" value="zhangsan"/>
        <property name="gender" value="男"/>
        <property name="dep">
            <bean class="com.cj.spring5.entity.Dep">
                <property name="dname" value="开发部"/>
            </bean>
        </property>
    </bean>
    
   </beans>
   ```
   外部bean赋值，获取bean的属性值并修改(级联赋值)
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="emp" class="com.cj.spring5.entity.Emp">
        <property name="ename" value="zhangsan"/>
        <property name="gender" value=""/>
        <property name="dep" ref="dep"/>
        <!--级联赋值-->
        <property name="dep.dname" value="人事部"/>
    </bean>
    <bean id="dep" class="com.cj.spring5.entity.Dep">
        <property name="dname" value="财务部"/>
    </bean>

   </beans>
   ```

4. 注入集合属性
①String类型集合
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="stu" class="com.cj.spring5.entity.Stu">
        <!--注入数组类型属性-->
        <property name="strings">
            <array>
                <value>java</value>
                <value>python</value>
            </array>
        </property>
        <!--注入List集合类型属性-->
        <property name="list">
            <list>
                <value>scala</value>
                <value>c++</value>
            </list>
        </property>
        <!--注入Set集合类型属性-->
        <property name="set">
            <set>
                <value>c</value>
                <value>go</value>
            </set>
        </property>
        <!--注入Map集合类型属性-->
        <property name="map">
            <map>
                <entry key="name" value="flink"/>
                <entry key="desc" value="实时处理框架"/>
            </map>
        </property>
    </bean>

   </beans>
   ```
   ②集合属性是自定义类的情况
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="stu" class="com.cj.spring5.entity.Stu">
        <property name="courseList">
            <list>
                <ref bean="course1"/>
                <ref bean="course2"/>
            </list>
        </property>
    </bean>
    <bean id="course1" class="com.cj.spring5.entity.Course">
        <property name="cname" value="math"/>
    </bean>
    <bean id="course2" class="com.cj.spring5.entity.Course">
        <property name="cname" value="chinese"/>
    </bean>

   </beans>
   ```

   ③把集合注入部分提取出来
   首先需要创建名称空间util，使用util保存集合，然后其他bean中就可以应用这个公共集合。
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:util="http://www.springframework.org/schema/util"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/util  http://www.springframework.org/schema/util/spring-util.xsd">

    <util:list id="courseList">
        <ref bean="course1"/>
        <ref bean="course2"/>
    </util:list>
    <bean id="course1" class="com.cj.spring5.entity.Course">
        <property name="cname" value="math"/>
    </bean>
    <bean id="course2" class="com.cj.spring5.entity.Course">
        <property name="cname" value="chinese"/>
    </bean>

    <bean id="stu" class="com.cj.spring5.entity.Stu">
        <property name="courseList" ref="courseList"/>
    </bean>

   </beans>
   ```

<br>
### 2.3.3 Bean类型
Spring有两种类型bean，普通bean和工厂bean(FactoryBean)
- 普通bean：在配置文件中定义bean类型就是返回类型
- 工厂bean：在配置文件定义bean类型可以和返回类型不同
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="mybean" class="com.cj.spring5.entity.MyBean"/>

   </beans>
   ```
   ```
    @Test
    public void test9(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean8.xml");
        Course course = context.getBean("mybean", Course.class);
        System.out.println(course);
    }
   ```

<br>
### 2.3.4 bean作用域
在Spring中，默认创建的bean是单实例的，即获取的同类bean的地址相同。
如何设置bean为多实例呢？可以在xml文件中指定其作用域scope。
- **singleton：**表示单实例(默认)，会在加载xml文件时创建实例。
- **prototype：**表示多实例，加载spring配置文件时不创建实例，而是在getBean时创建实例。
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="user" class="com.cj.spring5.User" scope="prototype"/>

</beans>
```
>在Web中，scope还可以填写request和session两个值。request表示一次请求，创建的对象会放到请求中；session表示一次会话，创建的对象会放到会话中。

<br>
### 2.3.5 bean生命周期
**不加bean的后置处理器，bean的生命周期有五步：**
1. 通过构造器创建bean实例（无参数构造）
2. 为bean的属性设置值和对其他bean应用（调用set方法）
3. 调用bean的初始化的方法（配置init-method）
4. 获取bean（getBean获取对象）
5. 当容器关闭时，调用bean的销毁方法（需要调用close方法，就会调用配置的destroy-method方法）

**如果加了bean的后置处理器，bean的生命周期就会有七步：**
1. 通过构造器创建bean实例（无参数构造）
2. 为bean的属性设置值和对其他bean应用（调用set方法）
3. 把bean实例传递给bean后置处理器，调用postProcessBeforeInitialization方法
4. 调用bean的初始化的方法（配置init-method）
5. 把bean实例传递给bean后置处理器，调用postProcessAfterInitialization方法
6. 获取bean（getBean获取对象）
7. 当容器关闭时，调用bean的销毁方法（需要调用close方法，就会调用配置的destroy-method方法）

**添加后置处理器步骤：**
1. 创建类，实现接口BeanPostProcessor
2. 创建后置处理器类
3. xml文件中配置后置处理器，为所有实现接口BeanPostProcessor的bean添加后置处理器
4. 加载xml文件，获取bean，最后close。

①创建bean类
```
public class Teacher {
    private String name;

    public Teacher(){
        System.out.println("第一步：执行无参构造");
    }

    public void setName(String name) {
        System.out.println("第二步：set设置属性");
        this.name = name;
    }

    @Override
    public String toString() {
        return "第六步：Teacher{" +
                "name='" + name + '\'' +
                '}';
    }

    public void initMethod() {
        System.out.println("第四部：执行初始化方法");
    }

    public void destroyMethod() {
        System.out.println("第七步：执行销毁方法");
    }
}
```
②创建后置处理器
```
public class MyBeanPostProcessor implements BeanPostProcessor {

    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("第三步：执行postProcessBeforeInitialization");
        return null;
    }

    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("第五步：执行postProcessAfterInitialization");
        return null;
    }
}
```
③配置bean类和后置过滤器
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="teacher" class="com.cj.spring5.entity.Teacher" init-method="initMethod" destroy-method="destroyMethod">
        <property name="name" value="zhangsan"/>
    </bean>
    <bean id="myBeanPost" class="com.cj.spring5.entity.MyBeanPostProcessor"/>
</beans>
```
④加载xml文件，获取bean，最后close
```
    @Test
    public void test10(){
        ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("bean9.xml");
        Teacher teacher = context.getBean("teacher", Teacher.class);
        System.out.println(teacher);
        context.close();
    }
```
打印结果如下：
```
第一步：执行无参构造
第二步：set设置属性
第三步：执行postProcessBeforeInitialization
第四部：执行初始化方法
第五步：执行postProcessAfterInitialization
第六步：Teacher{name='zhangsan'}
第七步：执行销毁方法
```

<br>
### 2.3.6 bean自动装配
- 手动装配：通过<property/>标签手动对bean的属性进行赋值；

- 自动装配：通过bean标签属性autowire配置自动装配
   - byName根据属性名称注入，注入值bean的id值和类属性名称一样
   - byType根据属性类型注入，注入值类属性名称一样
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="userService" class="com.cj.spring5.service.ServiceImpl" autowire="byName">
<!--        <property name="userDao" ref="userDao"/>-->
    </bean>
    <bean id="userDao" class="com.cj.spring5.dao.UserDaoImpl"/>
    
</beans>
```

<br>
### 2.3.7 外部属性文件
对于如数据库连接等配置，可以写在xml文件中，也可以写在外部属性文件中，进行集中管理，然后引入到xml文件中。

引入druid依赖
```
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid</artifactId>
            <version>1.0.9</version>
        </dependency>
```

- 内部配置数据库连接
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource"  destroy-method="close">
        <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
        <property name="url" value="jdbc:mysql://chenjie.asia:3306/test"/>
        <property name="username" value="root"/>
        <property name="password" value="cj"/>
    </bean>

   </beans>
   ```
- 外部属性文件配置数据库连接
   ```
   prop.driverClass=com.mysql.jdbc.Driver
   prop.url=jdbc:mysql://chenjie.asia:3306/test
   prop.username=root
   prop.password=cj
   ```
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">
    <!--引入外部属性文件-->
    <context:property-placeholder location="classpath:jdbc.properties"/>
    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${prop.driverClass}"/>
        <property name="url" value="${prop.url}"/>
        <property name="username" value="${prop.username}"/>
        <property name="password" value="${prop.password}"/>
    </bean>
   </beans>
   ```

<br>
## 2.3.8 基于注解方式实现bean创建
创建对象时使用的四个注解如下，四个注解功能是一样的，都可以用来创建bean实例。
- @Component
- @Service
- @Controller
- @Repository

使用注解方式需要额外引入依赖
- spring-aop-5.3.7.RELEASE.jar

在xml文件中指定需要扫描的包，开启组件扫描(如果扫描多个包，多个包使用逗号隔开；也可以直接扫描包上层目录)
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.cj.spring5.service"/>

</beans>
```
添加@Service注解（@Component/@Controller/@Repository效果相同），value缺省值为类名首字母小写。
```
@Service(value = "userService")
public class UserService {
    public void add(){
        System.out.println("userService add...");
    }
}
```
```
    @Test
    public void test11(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean12.xml");
        UserService userService = context.getBean("userService", UserService.class);
        userService.add();
    }
```

如果需要扫描包下指定注解，则可以舍弃默认的过滤器，使用自己配置的过滤器。
如扫描指定的注解：
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.cj.spring5.service" use-default-filters="false">
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
    </context:component-scan>

</beans>
```
不扫描指定的注解（如下不但会扫描@Controller的bean，还会扫描@Component、@Service、@Repository的bean）：
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.cj.spring5.service" use-default-filters="false">
        <context:exclude-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
    </context:component-scan>

</beans>
```

<br>
### 2.3.9 基于注解方式实现属性注入
**注入属性的三个注解**
- @Autowired：根据属性类型进行自动装配；
- @Qualifier：根据属性名称进行注入。需要和@Autowired一起使用；
- @Resource：可以根据类型注入，也可以根据名称注入；
- @Value：注入普通类型属性；

NOTE：Resource包路径为javax.annotation.Resource，而其他三个注解都是org.springframework包下的类。

**使用@Autowired和@Qualifier完成注入**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.cj.spring5" use-default-filters="false">
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Service"/>
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Component"/>
    </context:component-scan>

</beans>
```
@Qualifier(value = "userDaoImpl1") 指定属性名称进行注入
```
@Service(value = "userService")
public class UserService {

    @Autowired
    @Qualifier(value = "userDaoImpl1")
    private UserDao userDao;

    public void add(){
        System.out.println("add...");
        userDao.add();
    }
}
```
接口
```
public interface UserDao {
    void add();
}
```
向容器中注入UserDao对象
```
@Component(value = "userDaoImpl1")
public class UserDaoImpl implements UserDao {

    public void add() {
        System.out.println("dao add...");
    }
}
```

**使用@Resource完成注入**
将@Autowired和@Qualifier(value = "userDaoImpl1")替换为@Resource(name = "userDaoImpl1")完成相同效果，实现根据属性名称进行注入。
```
@Service(value = "userService")
public class UserService {

    @Resource(name = "userDaoImpl1")
    private UserDao userDao;

    public void add(){
        System.out.println("add...");
        userDao.add();
    }
}
```
如果@Resource注解缺省name属性，则默认根据类型进行注入。

**使用@Value完成普通类型注入**
```
@Service(value = "userService")
public class UserService {

    @Value(value = "zhangsan")
    private String name;

    public String getName(){
        return this.name;
    }
}
```

<br>
### 2.3.10 纯注解开发
1. 创建配置类，替代xml配置文件
```
@Configuration
@ComponentScan(basePackages = {"com.cj.spring5"})
public class SpringConfig {
}
```
2. 使用AnnotationConfigApplicationContext类来加载配置类
```
    @Test
    public void test13(){
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(SpringConfig.class);
        UserService userService = context.getBean("userService", UserService.class);
        userService.add();
    }
```

<br>
# 三、AOP
**概念：**面向切面编程，利用AOP可以对业务逻辑的各个部分进行隔离，从而使业务逻辑各部分之间的耦合度降低，提高程序的可重用性，提高开发效率。
**通俗理解：**不通过修改源代码方式，在主干功能里添加新功能。
**使用场景：**日志记录、性能统计、安全控制、事务处理、异常处理等代码从业务逻辑代码中划分出来。
**AOP原理：**底层使用动态代理。

## 3.1 两种情况的动态代理
- 有接口的情况，使用JDK动态代理：创建接口实现类的代理对象
- 没有接口情况，使用CGLIB动态代理：创建当前类子类的代理对象

### 3.1.1 JDK动态代理
1. 创建接口和实现类
```
public interface UserDao {
    int add(int a, int b);
    String update(String id);
}
```
```
public class UserDaoImpl implements UserDao {
    public int add(int a, int b) {
        return a + b;
    }

    public String update(String id) {
        return id;
    }
}

```

2. 调用newProxyInstance方法对实现类进行代理，在调用原方法之前和之后可以添加处理逻辑，实现对原方法的逻辑增强。
```
public class UserJDKProxy {
    public static void main(String[] args) {

        Class[] interfaces = {UserDao.class};
        UserDaoImpl userDaoImpl = new UserDaoImpl();
        UserDao userDao = (UserDao)Proxy.newProxyInstance(UserJDKProxy.class.getClassLoader(), interfaces, new MyInvocationHandler(userDaoImpl));
        int add = userDao.add(1, 2);
        System.out.println(add);
    }
}

class MyInvocationHandler implements InvocationHandler {

    private Object obj;

    public MyInvocationHandler(Object obj) {
        this.obj = obj;
    }

    public Object invoke(Object o, Method method, Object[] args) throws Throwable {

        System.out.println("方法名：" + method.getName() + " --- 参数：" + Arrays.toString(args));

        Object res = method.invoke(obj, args);

        System.out.println("方法执行后...");

        return res;
    }
}
```

<br>
### 3.1.2 CGLIB动态代理


<br>
## 3.2 AOP术语
1. 连接点：类中的哪些方法可以被增强，这些方法称为连接点；
2. 切入点：实际真正被增强的方法，称为切入点；
3. 通知(增强)：实际增强的逻辑部分称为通知；通知有多种类型
   - 前置通知：
   - 后置通知：
   - 环绕通知：
   - 异常通知：
   - 最终通知：
4. 切面：是动作，把通知应用到切入点的过程。

<br>
## 3.3 AspectJ
Spring框架一般都是基于AspectJ实现AOP操作。

什么是AspectJ ? AspectJ不是Spring组成部分，是一个独立AOP框架，一般把AspectJ和Spring框架一起使用，进行AOP操作。

**需要引入新的包**
- spring-aspects-5.3.7.RELEASE.jar
- com.springsource.net.sf.cglib-2.2.0.jar
- com.springsource.org.aopalliance-1.0.0.jar
- com.springsource.org.aspectj.weaver-1.6.8.RELEASE.jar

**切入点表达式**
execution([权限修饰符] [返回类型] [类全路径] [方法名称] ([参数列表]) )

例1：对com.cj.dao.UserDao类中的add方法进行增强
execution(* com.cj.dao.UserDao.add(..))
例2：对com.cj.dao.UserDao类中的所有public修饰的方法进行增强
execution(public com.cj.dao.UserDao.*(..))
例3：对com.cj.dao包中的所有类的方法进行增强
execution(* com.cj.dao.*.*(..))


### 3.3.1 AspectJ注解实现
**注解：**
- @Aspect  注解在增强类上，开启动态代理，生成代理对象
- @Around  环绕通知(在@Before之前和@After之前环绕)
- @Before  前置通知(方法前执行)
- @After  最终通知(无论是否异常，都会执行)
- @AfterThrowing  异常通知(发生异常执行)
- @AfterReturning  后置通知(发生异常不执行)

#### 3.3.1.1 实现
1. xml文件配置注解扫描和生成代理对象
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
                        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">
    <!--开启注解扫描-->
    <context:component-scan base-package="com.cj.spring5"/>
    <!--开启Aspect生成代理对象-->
    <aop:aspectj-autoproxy/>

</beans>
```
也可以不使用如上xml配置，直接用配置类实现，使用@ComponentScan和@EnableAspectJAutoProxy注解。
```
@Configuration
@ComponentScan(basePackages = "com.cj.spring5")
@EnableAspectJAutoProxy(proxyTargetClass = true)
public class SpringConfig {
}
```
>@ComponentScan注解不要扫描默认被扫描的包，会导致访问404问题。如在Application类上用@ComponentScan注解扫描子包，导致重复扫描，发生404问题。
2. 创建被增强类(被代理类)和增强类(代理类)
```
@Component
public class User {
    public void add(){
        System.out.println("add......");
    }
}
```
```
@Component
@Aspect
public class UserProxy {

    @Around(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void around(ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
        System.out.println("环绕前...");
        proceedingJoinPoint.proceed();
        System.out.println("环绕后...");
    }

    @Before(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void before(){
        System.out.println("before...");
    }

    @After(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void after(){
        System.out.println("after...");
    }

    @AfterThrowing(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void afterThrowing() {
        System.out.println("afterThrowing...");
    }

    @AfterReturning(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void afterReturning(){
        System.out.println("afterReturning...");
    }
}
```
3. 测试
```
    @Test
    public void test(){
        // ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(SpringConfig.class);

        User user = context.getBean("user", User.class);
        user.add();
    }
```
**结果：**
```
环绕前...
before...
add......
afterReturning...
after...
环绕后...
```
**如果被增强方法中抛出异常，结果如下：**
```
环绕前...
before...
afterThrowing...
after...
```
抛出异常后，@AfterThrowing执行，@AfterReturning和@Round环绕后方法不执行，@After不管抛不抛异常都正常执行。

#### 3.3.1.2 优化
1. **抽取相同切入点**
注解 `@Pointcut(value = "execution(* com.cj.spring5.entity.User.add(..))" )`  用于相同切入点抽取

   优化后代理类如下
   ```
   @Component
   @Aspect
   public class UserProxy {

    @Pointcut(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void point(){};

    @Around(value = "point()")
    public void around(ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
        System.out.println("环绕前...");
        proceedingJoinPoint.proceed();
        System.out.println("环绕后...");
    }

    @Before(value = "point()")
    public void before(){
        System.out.println("before...");
    }

    @After(value = "point()")
    public void after(){
        System.out.println("after...");
    }

    @AfterThrowing(value = "point()")
    public void afterThrowing() {
        System.out.println("afterThrowing...");
    }

    @AfterReturning(value = "point()")
    public void afterReturning(){
        System.out.println("afterReturning...");
    }
   }
   ```

<br>
2. **同一个方法有多个增强类，设置增强类的优先级**
注解 @Order(数字类型值)  实现优先级设置，数字类型值越小优先级越高。
   ```
   @Component
   @Aspect
   @Order(3)
   public class PersonProxy {

    @Before(value = "execution(* com.cj.spring5.entity.User.add(..))")
    public void before(){
        System.out.println("personProxy before......");
    }

   }
   ```

<br>
### 3.3.2 AspectJ配置文件实现
1. 创建被增强类(被代理类)和增强类(代理类)
   ```  
   public class Book {
    public void buy(){
        System.out.println("buy......");
    }
   }
   ```
   ```
   public class BookProxy {
    public void before(){
        System.out.println("before......");
    }
   }
   ```

2. xml文件配置切入点
   ```
   <?xml version="1.0" encoding="UTF-8" ?>
   <beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">

    <bean id="book" class="com.cj.spring5.entity.Book"/>
    <bean id="bookProxy" class="com.cj.spring5.entity.BookProxy"/>

    <aop:config>
        <!--提取切入点方法-->
        <aop:pointcut id="p" expression="execution(* com.cj.spring5.entity.Book.buy(..))"/>

        <aop:aspect ref="bookProxy">
            <!--method是增强类中的前置执行方法,pointcut-ref是提取的切入点,pointcut是切入点方法-->
            <aop:before method="before" pointcut-ref="p"/>
        </aop:aspect>
    </aop:config>

   </beans>
   ```

<br>
# 四、JdbcTemplate
**引入依赖**
- mysql-connector-java-5.1.7
- druid-1.1.9
- spring-jdbc-5.3.7.RELEASE
- spring-orm-5.3.7.RELEASE
- spring-tx-5.3.7.RELEASE

**配置数据库连接池，配置jdbcTemplate对象，注入DataSource**
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="com.cj.spring5"/>

    <bean id="datasource" class="com.alibaba.druid.pool.DruidDataSource" destroy-method="close">
        <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
        <property name="url" value="jdbc:mysql://chenjie.asia:3306/test?characterEncoding=utf8&amp;useUnicode=true&amp;useSSL=false&amp;serverTimezone=UTC&amp;allowMultiQueries=true"/>
        <property name="username" value="root"/>
        <property name="password" value="cj"/>
    </bean>

    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
<!--        <constructor-arg name="dataSource" ref="datasource"/>-->
        <property name="dataSource" ref="datasource"/>
    </bean>

</beans>
```
>注意：注入DataSource时，可以使用有参构造注入，也可以通过set方法注入，所以使用property或constructor-arg标签都可以。

<br>
**创建BookDaoImpl类，注入JdbcTemplate对象。通过JdbcTemplate对数据库进行操作。用到的方法如下：**
- update(String sql, Object[] args) 进行增删改操作；
- queryForObject(String sql, Class<Integer> requiredType) 返回制定类型的单个值；
- queryForObject(String sql, RowMapper<?> RowMapper, Object... args)  查询并返回单个对象(RowMapper是接口，使用该接口的实现类BeanPropertyRowMapper完成返回数据的对象封装)；
- query(String sql, RowMapper<?> RowMapper, Object... args)  查询并返回对象集合；
- batchUpdate(String sql, List<Object[]> batchArgs)  批量操作，原理是对List中的每个元素都执行一次操作（是否会有效率问题和事务问题？？？）

**代码如下**
```
@Component
public class BookDaoImpl implements BookDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public int addBook(Book book) {
        String sql = "insert into t_book values(?,?,?)";
        int rows = jdbcTemplate.update(sql, book.getBookId(), book.getBookName(), book.getBstatus());

        return rows;
    }

    public int updateBook(Book book) {
        String sql = "update t_book set book_name=?,bstatus=? where book_id=?";
        int rows = jdbcTemplate.update(sql, book.getBookName(), book.getBstatus(), book.getBookId());

        return rows;
    }

    public int deleteBook(String bookId) {
        String sql = "delete from t_book where book_id=?";
        int rows = jdbcTemplate.update(sql, bookId);

        return rows;
    }

    // 查询并返回单个值
    public int selectCount() {
        String sql = "select count(*) from t_book";
        return jdbcTemplate.queryForObject(sql, Integer.class);
    }

    // 查询并返回对象
    public Book selectBook(String bookId) {
        String sql = "select * from t_book where book_id=?";
        return jdbcTemplate.queryForObject(sql, new BeanPropertyRowMapper<Book>(Book.class), bookId);
    }

    // 查询并返回对象集合
    public List<Book> selectBooks() {
        String sql = "select * from t_book";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<Book>(Book.class));
    }

    // 批量添加
    public int[] batchAddBook(List<Object[]> batchArgs) {
        String sql = "insert into t_book values(?,?,?)";
        return jdbcTemplate.batchUpdate(sql, batchArgs);
    }

    // 批量修改
    public int[] batchUpdateBook(List<Object[]> batchArgs) {
        String sql = "update t_book set book_name=?,bstatus=? where book_id=?";
        return jdbcTemplate.batchUpdate(sql, batchArgs);
    }

    // 批量删除
    public int[] batchDeleteBook(List<Object[]> batchArgs) {
        String sql = "delete from t_book where book_id=?";
        return jdbcTemplate.batchUpdate(sql, batchArgs);
    }
}
```
```
public interface BookDao {
    int addBook(Book book);

    int updateBook(Book book);

    int deleteBook(String bookId);

    int selectCount();

    Book selectBook(String bookId);

    List<Book> selectBooks();

    int[] batchAddBook(List<Object[]> batchArgs);

    int[] batchUpdateBook(List<Object[]> batchArgs);

    int[] batchDeleteBook(List<Object[]> batchArgs);
}
```
```
@Service
public class BookService {

    @Autowired
    private BookDao bookDao;

    public int addBook(Book book){
        return bookDao.addBook(book);
    }

    public int updateBook(Book book) {
        return bookDao.updateBook(book);
    }

    public int deleteBook(String bookId) {
        return bookDao.deleteBook(bookId);
    }

    public int selectCount(){
        return bookDao.selectCount();
    }

    public Book selectBook(String bookId){
        return bookDao.selectBook(bookId);
    }

    public List<Book> selectBooks() {
        return bookDao.selectBooks();
    }

    public int[] batchAddBook(List<Object[]> batchArgs) {
        return bookDao.batchAddBook(batchArgs);
    }

    public int[] batchUpdateBook(List<Object[]> batchArgs) {
        return bookDao.batchUpdateBook(batchArgs);
    }

    public int[] batchDeleteBook(List<Object[]> batchArgs) {
        return bookDao.batchDeleteBook(batchArgs);
    }
}
```
**测试**
```
public class JdbcTemplateTest {

    @Test
    public void addBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Book book = new Book();
//        book.setBookId("1");
        book.setBookId("2");
//        book.setBookName("java开发手册");
        book.setBookName("深入理解Java虚拟机");
        book.setBstatus("1");

        int rows = bookService.addBook(book);
        System.out.println(rows);
    }

    @Test
    public void updateBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Book book = new Book();
        book.setBookId("1");
        book.setBookName("深入理解Java虚拟机");
        book.setBstatus("2");

        int rows = bookService.updateBook(book);
        System.out.println(rows);
    }

    @Test
    public void deleteBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        int rows = bookService.deleteBook("1");
        System.out.println(rows);
    }

    @Test
    public void selectCount(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        int count = bookService.selectCount();
        System.out.println(count);
    }

    @Test
    public void selectBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Book book = bookService.selectBook("1");
        System.out.println(book);
    }

    @Test
    public void selectBooks(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        List<Book> books = bookService.selectBooks();
        System.out.println(books);
    }

    @Test
    public void batchAddBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Object[] o1 = {"3", "数据结构", "3"};
        Object[] o2 = {"4", "计算机操作系统", "3"};
        Object[] o3 = {"5", "计算机网络", "3"};
        List<Object[]> batchArgs = Arrays.asList(o1, o2, o3);

        int[] ints = bookService.batchAddBook(batchArgs);
        System.out.println(Arrays.toString(ints));
    }

    @Test
    public void batchUpdateBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Object[] o1 = {"hive调优", "a", "3"};
        Object[] o2 = {"计算机组成", "b", "4"};
        Object[] o3 = {"C语言程序设计", "c", "5"};
        List<Object[]> batchArgs = Arrays.asList(o1, o2, o3);

        int[] ints = bookService.batchUpdateBook(batchArgs);
        System.out.println(Arrays.toString(ints));
    }

    @Test
    public void batchDeleteBook(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        BookService bookService = context.getBean("bookService", BookService.class);

        Object[] o1 = {"3"};
        Object[] o2 = {"4"};
        Object[] o3 = {"5"};
        List<Object[]> batchArgs = Arrays.asList(o1, o2, o3);

        int[] ints = bookService.batchDeleteBook(batchArgs);
        System.out.println(Arrays.toString(ints));
    }

}
```

<br>
# 五、事务
在转账等场景中需要引入事务，通过代码实现事务的开启、提交或回滚。
而在Spring中是如何进行事务操作的呢?
有两种方式

- 编程式事务管理：需要为每个事务都添加事务操作代码。
手动回滚的方法：`currentTransactionStatus().setRollbackOnly();`

- 声明式事务管理（推荐使用）
   - 基于注解方式（推荐使用）
   - 基于xml配置文件方式


## 5.1 声明式事务管理
在Spring进行声明式事务管理，底层使用AOP原理。

### 5.1.1 Spring事务管理API
1. 提供一个接口，代表事务管理器，这个接口针对不同的框架提供不用的实现类。如下图所示，使用mybatis框架时使用DataSourceTransactionManager实现类。![image.png](Spring5框架.assetsf0964c7a4ff40b6b2a8b9cd51b48202.png)

<br>
### 5.1.2 事务操作（注解方式实现）
#### 代码
配置文件配置。为DataSourceTransactionManager配置DataSource，添加tx命名空间并为事务注解配置事务管理器。
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:tx="http://www.springframework.org/schema/tx"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
                           http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd">

    <context:component-scan base-package="com.cj.spring5"/>
    <context:property-placeholder location="mysql.properties"/>

    <bean id="datasource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${prop.driver}"/>
        <property name="url" value="${prop.url}"/>
        <property name="username" value="${prop.username}"/>
        <property name="password" value="${prop.password}"/>
    </bean>

    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
<!--        <property name="dataSource" ref="datasource"/>-->
        <constructor-arg name="dataSource" ref="datasource"/>
    </bean>

    <!--创建事务管理器-->
    <bean id="dataSourceTransactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <!--注入数据源-->
        <property name="dataSource" ref="datasource"/>
    </bean>

    <!--开启事务注解-->
    <tx:annotation-driven transaction-manager="dataSourceTransactionManager"/>

</beans>
```
在需要开启事务的类或方法上添加事务注解`@Transactional`。
如果把注解添加到类上面，这个类里面的所有方法都会开启事务。
如果把注解添加到方法上，那么只有这个方法会开启事务。
```
@Service
public class UserService {

    @Autowired
    private UserDao userDao;

    public Long getBalance(String userId) {
        return userDao.getBalance(userId);
    }

    @Transactional
    public void transfer(String aUserID, String bUserId, Long money) {
        userDao.subBalance(aUserID, money);
        int i = 1/0;
        userDao.addBalance(bUserId, money);
    }

}
```
```
@Component
public class UserDaoImpl implements UserDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public Long getBalance(String userId) {
        String sql = "select balance from t_bank where user_id=?";
        return jdbcTemplate.queryForObject(sql, Long.class, userId);
    }

    public int addBalance(String userId, Long money) {
        String sql = "update t_bank set balance=balance+? where user_id = ?";
        return jdbcTemplate.update(sql, money, userId);
    }

    public int subBalance(String userId, Long money) {
        String sql = "update t_bank set balance=balance-? where user_id = ?";
        return jdbcTemplate.update(sql, money, userId);
    }
}
```
测试
```
    @Test
    public void test2(){
        ApplicationContext context = new ClassPathXmlApplicationContext("bean1.xml");
        UserService useService = context.getBean("userService", UserService.class);
        // 由用户1向用户2转账200元
        useService.transfer("1", "2" ,200L);
    }
```
结果：用户1账户扣钱后发生了异常，然后发生了回滚。最终结果是转账失败，保持原样。

<br>
#### @Transactional注解
@Transactional属性
- @AliasFor("transactionManager")
    String value() default "";
- @AliasFor("value")
    String transactionManager() default "";
- String[] label() default {};
- Propagation propagation() default Propagation.REQUIRED;  
解释：事务的传播行为
- Isolation isolation() default Isolation.DEFAULT;
解释：事务的隔离级别
- int timeout() default -1;
解释：事务的超时时间
- String timeoutString() default "";
- boolean readOnly() default false;
解释：是否只读
- Class<? extends Throwable>[] rollbackFor() default {};
解释：回滚
- String[] rollbackForClassName() default {};
- Class<? extends Throwable>[] noRollbackFor() default {};
解释：不回滚
- String[] noRollbackForClassName() default {};

<br>
**事务的传播行为**
事务方法：对数据库表数据进行变化的操作，如添加/修改/删除。
传播行为用于解决多事务方法之间进行调用的管理，如事务方法调用非事务方法，或非事务方法调用事务方法应该怎么做。

| 事务传播行为类型          | 说明                                                         |
| ------------------------- | ------------------------------------------------------------ |
| **PROPAGATION.REQUIRED**      | 调用另一个事务方法时，如果当前没有事务，就新建一个事务，如果已经存在一个事务中，则加入到这个事务中。这是最常见的选择。 |
| PROPAGATION.SUPPORTS      | 支持当前事务，如果当前没有事务，就以非事务方式执行。         |
| PROPAGATION.MANDATORY     | 使用当前的事务，如果当前没有事务，就抛出异常。               |
| **PROPAGATION.REQUIRES_NEW**  | 调用另一个事务方法时，会新建事务，如果当前存在事务，把当前事务挂起。                 |
| PROPAGATION.NOT_SUPPORTED | 以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。   |
| PROPAGATION.NEVER         | 以非事务方式执行，如果当前存在事务，则抛出异常。             |
| PROPAGATION.NESTED        | 如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则执行与PROPAGATION.REQUIRED类似的操作。 |

<br>
**事务的隔离级别**
脏读：一个未提交事务读取到另一个未提交事务的数据；通过MVCC快照解决。
不可重复读：一个未提交的事务读取到了另一个提交事务修改数据；可通过加共享读锁实现。
幻读：一个未提交的事务读取到了另一个提交事务添加的数据。通过间隙锁或串行化实现。

可以通过设置事务隔离级别，解决读的问题。
| 隔离级别 | 说明 |
|---|---|
| DEFAULT | 使用数据库的隔离级别 |
| READ_UNCOMMITTED | 读未提交 |
| READ_COMMITTED | 读已提交 |
| REPEATABLE_READ | 可重复读 |
| SERIALIZABLE | 串行化 |

**事务的超时时间**
事务需要在一定时间内提交，如果不提交进行回滚。默认值是-1，设置时间单位是秒。

**readOnly**
是否只读。默认为false，即可以执行查询和增删改。如果设置为true，则只能查询。

**rollbackFor**
设置出现哪些异常，进行回滚。

**noRollbackFor**
设置出现哪些异常，不进行回滚

<br>
### 5.1.3 事务操作（xml方式实现）
步骤：
1. 配置jdbcTemplate和事务管理器，开启注解扫描
2. 先配置通知，描述切面时需要进行的操作
3. 提取切入点，配置切面，即在切入点上需要进行的操作。
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:tx="http://www.springframework.org/schema/tx"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
                           http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd
                           http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">

    <context:property-placeholder location="mysql.properties"/>

    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${prop.driver}"/>
        <property name="url" value="${prop.url}"/>
        <property name="username" value="${prop.username}"/>
        <property name="password" value="${prop.password}"/>
    </bean>


    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
        <property name="dataSource" ref="dataSource"/>
    </bean>

    <!--配置事务管理器-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>

    <context:component-scan base-package="com.cj.spring5"/>

    <!--配置通知-->
    <tx:advice id="txAdvice">
        <tx:attributes>
            <tx:method name="transfer" propagation="REQUIRED" isolation="DEFAULT"/>
        </tx:attributes>
    </tx:advice>

    <!--配置切入点和切面-->
    <aop:config>
        <!--提取切入点-->
        <aop:pointcut id="pt" expression="execution(* com.cj.spring5.service.UserService.*(..))"/>
        <!--配置切面-->
        <aop:advisor advice-ref="txAdvice" pointcut-ref="pt"/>
    </aop:config>

</beans>
```

<br>
## 5.1.4 完全注解开发
其他不变，就是将xml文件中的配置用配置类代替。通过@Bean注解将DataSource、jdbcTemplate和dataSourceTransactionManager注入到容器中。
```
@Configuration
@ComponentScan(basePackages = {"com.cj.spring5"})  // 扫描包路径
@EnableTransactionManagement  // 开启事务
@PropertySource("mysql.properties")
public class TxConfig {

    @Value("${prop.driver}")
    public String driver;

    @Value("${prop.url}")
    public String url;

    @Value("${prop.username}")
    public String username;

    @Value("${prop.password}")
    public String password;

    @Bean
    public DataSource dataSource(){
        DruidDataSource dataSource = new DruidDataSource();
        dataSource.setDriverClassName(driver);
        dataSource.setUrl(url);
        dataSource.setUsername(username);
        dataSource.setPassword(password);
        return dataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource){
        return new JdbcTemplate(dataSource);
    }

    @Bean
    public DataSourceTransactionManager dataSourceTransactionManager(){
        return new DataSourceTransactionManager(dataSource());
    }
}
```
测试
```
    @Test
    public void test4() {
        ApplicationContext context = new AnnotationConfigApplicationContext(TxConfig.class);
        UserService userService = context.getBean("userService", UserService.class);
        userService.transfer("1", "2", 500L);
    }
```

<br>
# 六、Spring5新特性
## 6.1 整合日志
Spring5基于jkd1.8，兼容更高的jdk版本。但是在Spring5中已经移除了Log4jConfigListener，官方建议使用Log4j2。
下面来整合Log4j2。

**引入依赖**
- log4j-api-2.1.1.2.jar
- log4j-core-2.1.1.2.jar
- log4j-slf4j-impl-2.11.2.jar
- slf4j-api-1.7.30.jar

**创建Log4j2文件**
添加log4j2.xml文件到类路径下
```
<?xml version="1.0" encoding="UTF-8" ?>
<!-- 日志级别以及优先级排序：OFF > FATAL > ERROR > WARN > INFO > DEBUG > TRACE > ALL -->
<!-- Configuration后面的status关于设置log4j2自身内部的信息输出，可以不设置，设为trace时，可以看到log4j2内部各种详细输出 -->
<configuration status="INFO">
    <!-- 先定义所有的appender -->
    <appenders>
        <!-- 输出日志信息到控制台 -->
        <console name="Console" target="SYSTEM_OUT">
            <!-- 控制日志输出的格式 -->
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </console>
    </appenders>
    <!-- 然后定义logger，只有定义了logger并引入的appender，appender才会生效 -->
    <!-- root：用于指定项目的根目录，如果没有单独指定Logger，则会使用root作为默认的日志输出 -->
    <loggers>
        <root level="info">
            <appender-ref ref="Console"/>
        </root>
    </loggers>
</configuration>
```

可以通过如下输出自定义的日志
```
    public static final Log log = LogFactory.getLog(UserService.class);

    @Test
    public void test5(){
        log.warn("log test......");
    }
```

<br>
## 6.2 Nullable注解
@Nullable注解可以使用在方法、属性和参数上，表示方法返回可以为空，属性可以为空，参数可以为空。 

<br>
## 6.3 向Spring容器中注入自定义对象
使用GenericApplicationContext完成自定义对象的注册和管理。
```
    @Test
    public void test6() {
        GenericApplicationContext context = new GenericApplicationContext();
        context.refresh();
        context.registerBean("user1", User.class, () -> new User());
        User user1 = context.getBean("user1", User.class);
        System.out.println(user1);
    }
```

<br>
## 6.4 JUnit5
Spring5 支持整合 JUnit5。

**先使用JUnit4进行整合**
依赖
```
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13-beta-3</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-test</artifactId>
            <version>${spring-version}</version>
        </dependency>
```

可以将配置文件写在注解中，启动时直接创建bean对象并完成注入。
```
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration("classpath:bean2.xml")
public class JTest4 {

    @Autowired
    public UserService userService;

    @Test
    public void test(){
        Long balance = userService.getBalance("1");
        System.out.println(balance);
    }

}
```

**下面整合Junit5**
```
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-test</artifactId>
            <version>${spring-version}</version>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>5.3.1</version>
            <scope>test</scope>
        </dependency>
```
使用Junit5进行测试
```
@ExtendWith(SpringExtension.class)
@ContextConfiguration("classpath:bean2.xml")
public class JTest5 {

    @Autowired
    private UserService userService;

    @Test
    public void test(){
        Long balance = userService.getBalance("1");
        System.out.println(balance);
    }

}
```
注解为`@ExtendWith(SpringExtension.class)`。可以使用`@SpringJUnitConfig(locations = "classpath:bean2.xml")`注解来整合@ExtendWith和@ContextConfiguration注解。
```
//@ExtendWith(SpringExtension.class)
//@ContextConfiguration("classpath:bean2.xml")
@SpringJUnitConfig(locations = "classpath:bean2.xml")
public class JTest5 {

    @Autowired
    private UserService userService;

    @Test
    public void test() {
        Long balance = userService.getBalance("1");
        System.out.println(balance);
    }

}
```

<br>
# 七、SpringWebflux
## 7.1 概念
**SpringWebflux：**SpringWebflux是Spring5添加的新模块，用于web开发的，功能类似SpringMVC，webflux是使用当前一种比较流行的**响应式编程**的框架。
传统的web框架，比如SpringMVC，基于Servlet容器；Webflux是一种**异步非阻塞**的**响应式编程**框架，异步非阻塞的框架在Servlet3.1以后才支持。核心是基于Reactor的相关API实现的(Reactor是基于Java9的Flow实现的)。

- SpringMVC是通过`同步阻塞方式`实现，基于`SpringMVC`+`Servlet`+`Tomcat`；
- SpringWebflux是通过`同步非阻塞方式`实现，基于`SpringWebflux`+`Reactor`+`Netty`；

>**同步和异步：**针对调用者，调用者发送请求，如果一直等待对方响应才结束，就是同步；如果发送请求后不等待对方响应就执行其他任务，就是异步，被调用者通过状态、通知来通知调用者，或通过回调函数处理这个调用。
**阻塞和非阻塞：**针对被调用者，被调用者收到请求后，做完请求任务后才给出反馈就是阻塞；被调用者收到请求后，马上给出反馈然后再去处理任务就是非阻塞。

<br>
**使用场景**
Spring WebFlux 是一个异步非阻塞式的 Web 框架，所以并不能使接口的响应时间缩短，它仅仅能够提升吞吐量和伸缩性，它特别适合应用在 IO 密集型的服务中，比如微服务网关这样的应用中。WebFlux 不是 Spring MVC 的替代方案！
> IO 密集型包括：磁盘IO密集型, 网络IO密集型，微服务网关就属于网络 IO 密集型，使用异步非阻塞式编程模型，能够显著地提升网关对下游服务转发的吞吐量。

<br>
## 7.2 Webflux特点
**非阻塞式：**在有限的资源下，提高系统的吞吐量和伸缩性，以Reactor为基础实现响应式编程；
**函数式编程：**Spring5框架基于JDK1.8，可以使用函数式编程；

**与SpringMVC的异同：**
1. 都可以使用注解方式，都运行在Tomcat等容器中。
2. SpringMVC采用命令式编程；Webflux采用异步响应式编程。

![image.png](Spring5框架.assets5206146017e45d8836bcc889f32adc2.png)

**应用：**SpringCloud Gateway就是基于Webflux框架实现的，响应式的框架提高系统的吞吐量和伸缩性。

响应式和非阻塞通常来讲也不会使应用运行的更快。相反，非阻塞方式要求做更多的事情，而且还会稍微增加一些必要的处理时间。响应式和非阻塞的关键好处是，在使用很少固定数目的线程和较少的内存情况下的扩展能力。


<br>
## 7.3 响应式编程
**响应式编程：**响应式编程是一种面向数据流和变化传播的编程范式。这意味着可以在编程语言中很方便的表达静态或动态的数据流，而相关计算模型会自动将变化的值通过数据流进行传播。类似excel表格中的计算式，如果变量发生变化，结果会响应为正确的结果。也类似Vue中的数据绑定。

### 7.3.1 Observer/Observable
响应式变成是观察者模式的一种实现，在Java8中提供了观察者模式的两个类Observer和Observable。

Java8及其之前的版本中，可以使用Observer和Observable两个接口类，实现响应式编程。
```
public class ObserverDemo extends Observable {

    public static void main(String[] args) {
        ObserverDemo observable = new ObserverDemo();

        // 添加两个观察者并重写观察者的回调方法
        observable.addObserver(new Observer() {
            public void update(Observable o, Object arg) {
                System.out.println("回调处理1");
            }
        });
        observable.addObserver(new Observer() {
            public void update(Observable o, Object arg) {
                System.out.println("回调处理2");
            }
        });

        observable.setChanged();  // 将被观察者标记为已修改
        observable.notifyObservers();  // 如果被观察者已被修改，则通知观察者并回调观察者的update方法
    }

}
```

<br>
### 7.3.2 Flow
Java9之后使用Flow实现响应式编程
```
public class FlowDemo {
    public static void main(String[] args) {
        // 发布
        Flow.Publisher<String> publisher = new Flow.Publisher<String>() {
            @Override
            public void subscribe(Flow.Subscriber<? super String> subscriber) {
                // 发布内容
                subscriber.onNext("1");
                subscriber.onNext("2");
                // 发布异常
                subscriber.onError(new RuntimeException("subscribe error"));
            }
        };

        // 订阅
        publisher.subscribe(new Flow.Subscriber<>(){
            @Override
            public void onSubscribe(Flow.Subscription subscription) {
                subscription.cancel();
            }

            @Override
            public void onNext(String item) {
                // 订阅收到内容
                System.out.println("item: " + item);
            }

            @Override
            public void onError(Throwable throwable) {
                System.out.println("订阅收到异常");
            }

            @Override
            public void onComplete() {
                System.out.println("publish complete");
            }
        });
    }
}
```

>Reactor框架基于Flow响应式编程基础上进行了功能扩展，使其功能更加强大。

<br>
### 7.3.3 Reactor
#### 7.3.3.1 基础概念
**Reactor 有两个核心类，Mono和Flux，这两个类实现接口Publisher，提供了丰富操作符。**
- Flux对象实现发布者，返回N个元素；
- Mono实现发布者，返回0或1个元素。

**Flux和Mono都是数据流的发布者，使用Flux和Mono都可以发出三种数据信号：**
- 元素值：
- 错误信号：表示终止信号，终止数据流同时把错误信息传递给订阅者；
- 完成信号：表示终止信号，用于告诉订阅者数据流结束了。

**信号的三个特点：**
- 错误信号和完成信号都是终止信号，不能共存。；
- 如果没有发送任何元素值，而是直接发送错误或者完成信号，表示是空数据流；
- 如果没有错误信号，没有完成信号，表示无线数据流。

**代码demo**
引入依赖
```
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-core</artifactId>
            <version>3.1.8.RELEASE</version>
        </dependency>
```
```
public class FluxDemo {

    public static void main(String[] args) {
        // Subscribe会订阅并输出。
        Flux.just(1, 2, 3, 4, 5).subscribe(System.out::print);
        Mono.just(1).subscribe(System.out::print);

        List<Integer> list = Arrays.asList(6, 7, 8);
        Flux.fromIterable(list);

        Flux.fromArray(list.toArray());

        Flux.fromStream(list.stream());

    }

}
```


<br>
#### 7.3.3.2 同步非阻塞IO
Reactor是基于Netty的NIO框架。

**BIO**
每个线程都会进行一个socket连接(长连接)，线程会被一直占用直到关闭该连接，所以这是同步阻塞IO。
![image.png](Spring5框架.assets\1df1741b887d4961b535cde29a50add2.png)

**NIO**
每个操作都是一个Channel，Channel会向Selector(多路复用器)进行注册，有4个状态(Connect/Accept/Read/Write)。通过响应式方式返回结果。
![image.png](Spring5框架.assets\1e739bc3d83642f8b98a1cf76c521629.png)

<br>
### 7.3.4 SpringWebflux
#### 7.3.4.1 SpringWebflux组件与API
**SpringWebflux主要组件：**
- DispatchHandler主要负责请求的处理。
- HandlerMapping：匹配到请求的对应处理方法
- HandlerAdapter：真正负责请求处理
- HandlerResultHandler：响应结果进行处理



**DispatchHandler的源码：**
SpringWebflux核心控制器DispatchHandler，实现接口WebHandler。
```
public interface WebHandler {

	/**
	 * Handle the web server exchange.
	 * @param exchange the current server exchange
	 * @return {@code Mono<Void>} to indicate when request handling is complete
	 */
	Mono<Void> handle(ServerWebExchange exchange);

}
```

WebHandler的目标是提供web应用中广泛使用的通用特性，如Session、表单数据和附件等等，也是为了更容易和上层代码对接。其封装了更底层的类HttpHandler，该类用于响应式HTTP请求的处理。
参数类型是ServerWebExchange，可以这样理解，你发一个请求，给你一个响应，相当于用请求交换了一个响应，而且是在服务器端交换的。
其实，整个web请求的处理过程是一个链式的，最后才是一个WebHandler，它前面可以插入多个错误处理器，WebExceptionHandler，多个过滤器，WebFilter。
```
Mono<java.lang.Void> handle(ServerHttpRequest request, ServerHttpResponse response);
```
HttpHandler是一个通用的接口，目标是抽象出来和不同HTTP服务器对接。它是有意设计成最小化的，只有一个方法，主要唯一目的就是在不同的HTTP服务器API上面成为一个最小化的抽象。
WebHandler是构建于HttpHandler之上的，换句话说WebHandler的处理会通过一个适配器HttpWebHandlerAdapter最终代理给HttpHandler来执行。

通过对下抽象一个HttpHandler接口，抹平了不同服务器的差异。对上抽象一个接口，可以用于支撑不同的编程模型。

Webflux包含一个轻量级函数式编程模型，函数被用来参与处理请求，它是相对于基于注解编程模型的另一种选择，这种编程模型叫做函数式端点，functional endpoints，是构建于上面提到的WebHandler之上的。使用HandlerFunction来处理一个HTTP请求的，这是一个函数式接口，也称处理函数。
```
@FunctionalInterface
public interface HandlerFunction<T extends ServerResponse> {
    reactor.core.publisher.Mono<T> handle(ServerRequest request);
}
```
带有一个ServerRequest参数，返回一个Mono<ServerResponse>，其中request和response对象都是不可变的，HandlerFunction就等价于Controller中的@RequestMapping标记的方法。
实际当中，请求很多，处理函数也很多，如何知道一个请求过来后，该由哪个处理函数去处理呢？这要用到另一个函数式接口RouterFunction来搞定，称为路由函数：
```
@FunctionalInterface
public interface RouterFunction<T extends ServerResponse> {
    reactor.core.publisher.Mono<HandlerFunction<T>> route(ServerRequest request);
}
```
带有一个ServerRequest参数，返回一个Mono<HandlerFunction>。就是它把一个请求路由到一个HandlerFunction的，当路由函数匹配时，就返回一个处理函数，否则返回一个空的Mono。RouterFunction等价于@RequestMapping注解，但主要不同的是路由函数提供的不仅是数据，还有行为。

下面通过一些示例，来更加直观的帮助大家认识这两个函数式接口。
因处理函数是函数式接口，所以可以直接用一个lambda表达式来处理请求，如下：
```
HandlerFunction<ServerResponse> handler = request -> Response.ok().body("Hello World");
```
这就表示当任何一个请求过来时，都返回Hello World作为响应。



<br>
#### 7.3.4.2 Webflux编程模型替代SpringMVC

**引入依赖**
```
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
```
**DispatchHandler的handler实现方法**
```
	@Override
	public Mono<Void> handle(ServerWebExchange exchange) {  // 放置http请求响应信息
		if (this.handlerMappings == null) {
			return createNotFoundError();
		}
		return Flux.fromIterable(this.handlerMappings)
				.concatMap(mapping -> mapping.getHandler(exchange))  // 根据请求地址获取对应mapping
				.next()
				.switchIfEmpty(createNotFoundError())
				.flatMap(handler -> invokeHandler(exchange, handler))  // 调用具体的业务方法
				.flatMap(result -> handleResult(exchange, result));  // 返回处理结果
	}
```

SpringWebflux实现方式有两种：注解编程模型和函数式编程模型。
使用注解编程模型方式和SpringMVC使用相似，只需要把相关依赖配置到项目中，SpringBoot自动配置相关运行容器，默认情况下使用Netty服务器。

<br>
##### 注解式编程模型
**配置文件**
mysql.properties
```
prop.driver: com.mysql.jdbc.Driver
prop.url: jdbc:mysql://chenjie.asia:3306/test?useUnicode=true&characterEncoding=utf8
prop.username: root
prop.password: cj
```
bean.xml
```
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
                           http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd">

    <!--    <context:property-placeholder location="classpath*: mysql.properties"/>-->
    <!--springboot 项目中，不能使用property-placeholder来引入其他配置文件，应该使用如下形式-->
    <bean id="propertyPlaceholderConfigurer"
          class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <list>
                <value>classpath:mysql.properties</value>
            </list>
        </property>
    </bean>
    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource">
        <property name="driverClassName" value="${prop.driver}"/>
        <property name="url" value="${prop.url}"/>
        <property name="username" value="${prop.username}"/>
        <property name="password" value="${prop.password}"/>
        <!--        <property name="driverClassName" value="com.mysql.jdbc.Driver"/>-->
        <!--        <property name="url" value="jdbc:mysql://chenjie.asia:3306/test?useUnicode=true&amp;characterEncoding=utf8"/>-->
        <!--        <property name="username" value="root"/>-->
        <!--        <property name="password" value="cj"/>-->
    </bean>

    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
        <property name="dataSource" ref="dataSource"/>
    </bean>

</beans>
```
**controller**
```
@RestController
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping("/getUser/{id}")
    public Mono<User> getUser(@PathVariable("id") Integer id) {
        System.out.println("controller - getUser");
        return userService.getUserById(id);
    }

    @GetMapping("/getAllUser")
    public Flux<User> getAllUser() {
        System.out.println("controller - getAllUser");
        return userService.getAllUser();
    }

    @PostMapping("/saveUserInfo")
    public void saveUserInfo(@RequestBody User user) {
        Mono<User> userMono = Mono.just(user);
        userService.saveUserInfo(userMono);
    }
}
```
**service**
```
public interface UserService {

    Mono<User> getUserById(int id);  // 返回0或1个，使用Mono

    Flux<User> getAllUser();  // 返回N个元素，使用Flux

    Mono<Void> saveUserInfo(Mono<User> user);

}
```
```
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserDao userDao;

    @Override
    public Mono<User> getUserById(int id) {
        User user = userDao.getUserById(id);
        return Mono.justOrEmpty(user);
    }

    @Override
    public Flux<User> getAllUser() {
        System.out.println("service - getAllUser");
        List<User> users = userDao.getAllUser();
        return Flux.fromIterable(users);
    }

    @Override
    public Mono<Void> saveUserInfo(Mono<User> userMono) {
        return userMono.doOnNext(user -> {
//            jdbcTemplate.update(sql, user.getName(), user.getGender(), user.getAge());
            System.out.println(user);
        }).thenEmpty(Mono.empty());
    }
}
```
**dao**
```
public interface UserDao {
    User getUserById(int id);
    List<User> getAllUser();
    Mono<Void> saveUserInfo(Mono<User> user);
}

```
```
@Component
public class UserDaoImpl implements UserDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public User getUserById(int id) {
        String sql = "select * from t_user where id=?";
        User user = jdbcTemplate.queryForObject(sql, new BeanPropertyRowMapper<>(User.class), id);
        return user;
    }

    @Override
    public List<User> getAllUser() {
        String sql = "select * from t_user";
        List<User> users = jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(User.class));
        System.out.println("dao - getAllUser");

        return users;
    }

    @Override
    public Mono<Void> saveUserInfo(Mono<User> userMono) {
        String sql = "insert into t_user(name,gender,age) values(?,?,?)";
        return userMono.doOnNext(user -> {
            System.out.println(user);
        }).thenEmpty(Mono.empty());
    }

}
```
**启动类**
```
@SpringBootApplication
@ImportResource(locations = {"classpath:bean.xml"})
public class WebfluxApplication {
    public static void main(String[] args) {
        SpringApplication.run(com.cj.WebfluxApplication.class, args);
    }
}
```

<br>
##### 函数式编程模型
1. 在使用函数式编程模型操作时，需要自己初始化服务器；
2. SpringWebflux要实现函数式编程，有两个重要接口，`RouterFunction`(路由处理)和`HandlerFunction`(处理函数)；
3. SpringWebflux请求和响应不再是ServletRequest和ServletResponse，而是ServerRequest和ServerResponse。

![image.png](Spring5框架.assets\d1c15bca754643ccabc713794477db12.png)

**代码实现**
依赖
```
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.5.RELEASE</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>
    </dependencies>
```
Service类
```
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class UserServiceImpl {

    public Mono<User> getUserById(int id) {
        User user = new User(11, "11", "11",11 );
        return Mono.justOrEmpty(user);
    }

    public Flux<User> getAllUser() {
        System.out.println("dao - getAllUser");
        User user = new User(11, "11", "11",11 );
        List<User> users = Arrays.asList(user);
        return Flux.fromIterable(users);
    }

    public Mono<Void> saveUserInfo(Mono<User> userMono) {
        return userMono.doOnNext(user -> {
//            jdbcTemplate.update(sql, user.getName(), user.getGender(), user.getAge());
            System.out.println(user);
        }).thenEmpty(Mono.empty());
    }
}
```
handler类
```
import com.cj.webflux2.entity.User;
import com.cj.webflux2.service.UserService;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public class UserHandler {

    private final UserService userService;

    public UserHandler(UserService userService) {
        this.userService = userService;
    }

    /**
     * 根据id查询user
     *
     * @param request
     * @return Mono<ServerResponse>
     */
    public Mono<ServerResponse> getUserById(ServerRequest request) {
        String id = request.pathVariable("id");
        Mono<User> userMono = userService.getUserById(Integer.parseInt(id));

        return userMono.flatMap(user ->
                ServerResponse.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(BodyInserters.fromValue(user)))
                .switchIfEmpty(ServerResponse.notFound().build());
    }

    /**
     * 查询所有
     */
    public Mono<ServerResponse> getAllUser(ServerRequest request) {
        Flux<User> users = userService.getAllUser();
        return ServerResponse.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(users,User.class);
    }

    /**
     * 添加
     */
    public Mono<ServerResponse> saveUser(ServerRequest request) {
        Mono<User> userMono = request.bodyToMono(User.class);
        return ServerResponse.ok().build(this.userService.saveUserInfo(userMono));  // build方法进行订阅，如果发生变化则触发添加方法
    }

}
```
路由、适配器和启动服务类
```
import com.cj.webflux2.handler.UserHandler;
import com.cj.webflux2.service.impl.UserServiceImpl;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.HttpHandler;
import org.springframework.http.server.reactive.ReactorHttpHandlerAdapter;
import org.springframework.web.reactive.function.server.*;
import reactor.netty.http.server.HttpServer;

public class Server {

    public static void main(String[] args) throws IOException {
        Server server = new Server();
        server.createReactorServer();
        System.out.println("enter to exit");
        System.in.read();
    }

    // 1.创建Router路由
    public RouterFunction<ServerResponse> routingFunction() {
        UserServiceImpl userService = new UserServiceImpl();
        UserHandler handler = new UserHandler(userService);

        // 配置访问路径与调用方法的映射
        RequestPredicate getUserPredicate = RequestPredicates
                .GET("/getUser/{id}")
                .and(RequestPredicates.accept(MediaType.APPLICATION_JSON));

        RequestPredicate getAllUserPredicate = RequestPredicates
                .GET("/getAllUser")
                .and(RequestPredicates.accept(MediaType.APPLICATION_JSON));

        RequestPredicate saveUserPredicate = RequestPredicates
                .GET("/saveUser")
                .and(RequestPredicates.accept(MediaType.APPLICATION_JSON));

        return RouterFunctions.route(getUserPredicate, handler::getUserById)
                .andRoute(getAllUserPredicate, handler::getAllUser)
                .andRoute(saveUserPredicate, handler::saveUser);
    }

    // 2.创建服务器，完成适配
    public void createReactorServer() {
        // 获得路由
        RouterFunction<ServerResponse> route = routingFunction();
        // 获得handler的适配
        HttpHandler httpHandler = RouterFunctions.toHttpHandler(route);
        ReactorHttpHandlerAdapter adapter = new ReactorHttpHandlerAdapter(httpHandler);
        // 创建服务器
        HttpServer httpServer = HttpServer.create();
        httpServer.handle(adapter).bindNow();

    }

}
```
启动后端口随机生成
```
18:18:35.946 [reactor-http-nio-1] DEBUG reactor.netty.tcp.TcpServer - [id: 0x189ee28e, L:/0:0:0:0:0:0:0:0:4675] Bound new server
```
WebClient是客户端，可以请求
```
public class Client {
    public static void main(String[] args) {
        // 调用服务器地址
        WebClient client = WebClient.create("http://127.0.0.1:9343");

        String id = "1";
        // 根据di查询
        User user = client.get().uri("/getUser/{id}", id)
                .accept(MediaType.APPLICATION_JSON)
                .retrieve().bodyToMono(User.class)
                .block();

        System.out.println(user);

        // 查询所有
        Flux<User> userFlux = client.get().uri("/getAllUser")
                .accept(MediaType.APPLICATION_JSON)
                .retrieve().bodyToFlux(User.class);

        userFlux.map(User::getName).buffer()
                .doOnNext(System.out::println)
                .blockFirst();

    }

}
```
