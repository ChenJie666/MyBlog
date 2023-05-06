---
title: 注解@EnableAutoConfiguration
categories:
- 后端框架
---
###@EnableAutoConfiguration注解解析
@EnableAutoConfiguration重要的只有三个Annotation：

@Configuration（@SpringBootConfiguration点开查看发现里面还是应用了@Configuration）
@EnableAutoConfiguration
@ComponentScan
如果在启动类使用这个三个注解，整个SpringBoot应用依然可以与之前的启动类功能一样。但每次写这3个比较啰嗦，所以写一个@SpringBootApplication方便点。

这三个注解中@Configuration和@ComponentScan对我们来说并不陌生，今天我们的主角是@EnableAutoConfiguration。
```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
    String ENABLED_OVERRIDE_PROPERTY = "spring.boot.enableautoconfiguration";

    Class<?>[] exclude() default {};

    String[] excludeName() default {};
}
```

其中最关键的要属@Import(AutoConfigurationImportSelector.class)，借助AutoConfigurationImportSelector，@EnableAutoConfiguration可以帮助SpringBoot应用将所有符合条件的@Configuration配置都加载到当前SpringBoot创建并使用的IoC容器。

借助于Spring框架原有的一个工具类：SpringFactoriesLoader的支持，@EnableAutoConfiguration可以智能的自动配置功效才得以大功告成！

在AutoConfigurationImportSelector类中可以看到通过 SpringFactoriesLoader.loadFactoryNames()
把 spring-boot-autoconfigure.jar/META-INF/spring.factories中每一个xxxAutoConfiguration文件都加载到容器中，spring.factories文件里每一个xxxAutoConfiguration文件一般都会有下面的条件注解:

@ConditionalOnClass ： classpath中存在该类时起效
@ConditionalOnMissingClass ： classpath中不存在该类时起效
@ConditionalOnBean ： DI容器中存在该类型Bean时起效
@ConditionalOnMissingBean ： DI容器中不存在该类型Bean时起效
@ConditionalOnSingleCandidate ： DI容器中该类型Bean只有一个或@Primary的只有一个时起效
@ConditionalOnExpression ： SpEL表达式结果为true时
@ConditionalOnProperty ： 参数设置或者值一致时起效
@ConditionalOnResource ： 指定的文件存在时起效
@ConditionalOnJndi ： 指定的JNDI存在时起效
@ConditionalOnJava ： 指定的Java版本存在时起效
@ConditionalOnWebApplication ： Web应用环境下起效
@ConditionalOnNotWebApplication ： 非Web应用环境下起效

###SpringFactoriesLoader
SpringFactoriesLoader属于Spring框架私有的一种扩展方案(类似于Java的SPI方案java.util.ServiceLoader)，其主要功能就是从指定的配置文件META-INF/spring-factories加载配置，spring-factories是一个典型的java properties文件，只不过Key和Value都是Java类型的完整类名，比如：
```
example.MyService=example.MyServiceImpl1,example.MyServiceImpl2
```
对于`@EnableAutoConfiguration`来说，SpringFactoriesLoader的
用途稍微不同一些，其本意是为了提供SPI扩展的场景，而在`@EnableAutoConfiguration`场景中，它更多提供了一种配置查找的功能支持，即根据`@EnableAutoConfiguration`的完整类名`org.springframework.boot.autoconfig.EnableAutoConfiguration`作为查找的Key，获得对应的一组`@Configuration`类。

SpringFactoriesLoader是一个抽象类，类中定义的静态属性定义了其加载资源的路径`public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories"`，此外还有三个静态方法：

loadFactories：加载指定的factoryClass并进行实例化。
loadFactoryNames：加载指定的factoryClass的名称集合。
instantiateFactory：对指定的factoryClass进行实例化。
在loadFactories方法中调用了loadFactoryNames以及instantiateFactory方法。
```
public static <T> List<T> loadFactories(Class<T> factoryClass, ClassLoader classLoader) {
   Assert.notNull(factoryClass, "'factoryClass' must not be null");
   ClassLoader classLoaderToUse = classLoader;
   if (classLoaderToUse == null) {
      classLoaderToUse = SpringFactoriesLoader.class.getClassLoader();
   }
   List<String> factoryNames = loadFactoryNames(factoryClass, classLoaderToUse);
   if (logger.isTraceEnabled()) {
      logger.trace("Loaded [" + factoryClass.getName() + "] names: " + factoryNames);
   }
   List<T> result = new ArrayList<T>(factoryNames.size());
   for (String factoryName : factoryNames) {
      result.add(instantiateFactory(factoryName, factoryClass, classLoaderToUse));
   }
   AnnotationAwareOrderComparator.sort(result);
   return result;
}
```
loadFactories方法首先获取类加载器，然后调用`loadFactoryNames`方法获取所有的指定资源的名称集合、接着调用`instantiateFactory`方法实例化这些资源类并将其添加到result集合中。最后调用`AnnotationAwareOrderComparator.sort`方法进行集合的排序。
