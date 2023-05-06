---
title: maven依赖的范围
categories:
- SpringBoot
---
maven常用的scope有compile,provided,runtime,test。

- compile是默认值，表示在build,test,runtime阶段的classpath下都有依赖关系。

- test表示只在test阶段有依赖关系，例如junit

- provided表示在build,test阶段都有依赖，在runtime时并不输出依赖关系而是由容器提供，例如web war包都不包括servlet-api.jar，而是由tomcat等容器来提供
```
<dependency>
    <groupId>javax.servlet</groupId>
    <artifactId>servlet-api</artifactId>
    <version>3.0.1</version>
    <scope>provided</scope>
</dependency>
 ```

- runtime表示在构建编译阶段不需要，只在test和runtime需要。这种主要是指代码里并没有直接引用而是根据配置在运行时动态加载并实例化的情况。虽然用runtime的地方改成compile也不会出大问题，但是runtime的好处是可以避免在程序里意外地直接引用到原本应该动态加载的包。例如JDBC连接池
```
		<dependency>
			<groupId>commons-dbcp</groupId>
			<artifactId>commons-dbcp</artifactId>
			<version>1.4</version>
			<scope>runtime</scope>
		</dependency>
```
**spring applicationContext.xml**
```
	<!-- mysql -->
	<bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
		<property name="dataSource">
			<ref bean="dataSource" />
		</property>
	</bean>
	<!-- Connection Pool -->
	<bean id="dataSource" destroy-method="close"
		class="org.apache.commons.dbcp.BasicDataSource">
		<property name="driverClassName" value="${ckm.jdbc.driver}" />
		<property name="url" value="${ckm.jdbc.url}" />
		<property name="username" value="${ckm.jdbc.username}" />
		<property name="password" value="${ckm.jdbc.password}" />
		<property name="initialSize" value="6" />
	</bean>
```
