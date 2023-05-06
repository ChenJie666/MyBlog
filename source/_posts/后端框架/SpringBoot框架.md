---
title: SpringBoot框架
categories:
- 后端框架
---

#二、自动配置
###06集
@AutoConfigurtionPackage  自动配置包
@Import(AutoConfigurationPackages.Register.class)：Spring的底层注解@Import(AutoConfigurationImportSelector.class)导入自动配置类，给容器汇总导入自动配置类，就是给容器中导入的这个场景需要的所有组件，并配置好这些组件。
`将主配置类（@SpringBootApplication标注的类）的所在包及下面所有子包里面的所有组件扫描到Spring容器中。`

###12.13集
@PropertySource(value = {"classpath:person.yml"})   加载指定的yml/properties文件中的内容并绑定到类对象中。这样可以将配置信息放在另一个文件中而非Springboot的配置文件。

@ImportResource(locations = {"classpath:beans.xml"})   标注在配置类上，可以导入Spring的xml配置文件，让配置文件中的内容生效。
通过xml文件想容器中注入helloService对象
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans .....>
  <bean id="helloService" class="com.atguigu.service.HelloService"></bean>
</beans>
```
```java
// 判断容器中是否有helloSrevice
@Autowired
ApplicationContext  ioc;   // 获取容器

@Test
public void testHelloService(){
  ioc.containsBean("helloService");
}
```

###14
**yml中的占位符：**
获取随机值
\${random.uuid}  
\${random.int}  
获取之前配置的值，可以指定缺省值
\${server.port}   获取前面定义的属性，如果不存在则不进行占位，值为该表达式
\${server.port:9999}   可以指定默认值，如果不存在，则值为默认值


###多profile文件 
application.yml
application-{profile}.yml
默认使用application.yml文件。可以在application.yml文件中添加spring.profiles.active=dev来激活对应环境下的配置文件，激活的配置参数会覆盖原参数形成互补。

**多文档块**
可以使用 --- 将一个配置文件分成多个文档块，添加spring.profiles: dev 指定该文档块的环境。
如下配置文件，分为了三个文档块，默认读取第一个文档块。可以为每个文档块设置环境然后在第一个文档块中进行激活。
```yml
server:
  port: 8080
spring:
  profiles:
    active: dev

---
server:
  port: 8081
spring:
  profile: dev

---
server:
  port: 8082
spring:
  profile: prod

```

可以在启动时添加启动命令，在VM options中添加-Dspring.profiles.active=dev或program arguments参数框中添加 --spring.profiles.active=dev来激活dev环境。会使配置文件中的激活配置失效。

**springboot配置文件的加载位置**
springboot启动会扫描一下位置 的application.properties或者application.yml文件作为Springboot的默认配置文件。优先级由高到低，高优先级会覆盖低优先级形成互补配置。
- file:./config/
- file:./
- classpath:/config/
- classpath:/

配置项目的访问路径：
server.context-path=/path

也可以指定配置文件的位置，该配置文件优先级高于默认配置，会与默认的访问路径中的配置文件形成互补。
spring.config.location=G:/application.properties


###自动配置原理@@@
1.springboot启动时加载主配置类，开启了@SpringBootApplication的@EnableAutoConfiguration注解中的自动配置功能。在@EnableAutoConfiguration注解的作用是导入了选择器@Import(AutoConfigurationImportSelector.class)，利用AutoConfigurationImportSelector的selectImports()方法给容器中导入一些组件。
```java
	@Override
	public String[] selectImports(AnnotationMetadata annotationMetadata) {
		if (!isEnabled(annotationMetadata)) {
			return NO_IMPORTS;
		}
		// 通过
		AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
				.loadMetadata(this.beanClassLoader);
		AutoConfigurationEntry autoConfigurationEntry = getAutoConfigurationEntry(autoConfigurationMetadata,
				annotationMetadata);
		return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
	}
```
```java
	protected static final String PATH = "META-INF/spring-autoconfigure-metadata.properties";
	//扫描该路径下的所有的资源
	static AutoConfigurationMetadata loadMetadata(ClassLoader classLoader) {
		return loadMetadata(classLoader, PATH);
	}

	static AutoConfigurationMetadata loadMetadata(ClassLoader classLoader, String path) {
		try {
			Enumeration<URL> urls = (classLoader != null) ? classLoader.getResources(path)
					: ClassLoader.getSystemResources(path);
			Properties properties = new Properties();
			while (urls.hasMoreElements()) {
				properties.putAll(PropertiesLoaderUtils.loadProperties(new UrlResource(urls.nextElement())));
			}
			return loadMetadata(properties);
		}
		catch (IOException ex) {
			throw new IllegalArgumentException("Unable to load @ConditionalOnClass location [" + path + "]", ex);
		}
	}
```

2.将类路径下的META-INF的spring-autoconfigure-metadata.properties中的所有的url加载到容器中。每一个这样的xxxAutoConfiguration类都是容器中的一个组件，都加入到容器中，用他们来做自动配置。

![image.png](SpringBoot框架.assets411cc5617f24d6fadc2fc2cd08151f6.png)

3.每一个自动配置类进行自动配置功能，以HttpEncodingAutoConfiguration为例解释自动配置原理
```java
@Configuration  
@EnableConfigurationProperties(HttpProperties.class) // 启用指定类的ConfigurationProperties功能，将配置文件中对应的值和HttpProperties绑定起来
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET) //Spring底层@Conditional注解，根据不同的条件，如果满足指定的条件，整个配置类里面的配置就会生效。 判断当前应用是否是web应用，如果是，当前配置生效。
@ConditionalOnClass(CharacterEncodingFilter.class) //判断当前项目有没有CharacterEncodingFilter这个类(这个类是SpringMVC中进行乱码解决的过滤器)
@ConditionalOnProperty(prefix = "spring.http.encoding", value = "enabled", matchIfMissing = true) //判断配置文件中是否存在某个配置 spring.http.encoding.enabled；如果不存在，判断也是成立的
public class HttpEncodingAutoConfiguration {...}
```
根据当前不同的条件判断，决定这个配置类是否生效？如上述的@ConditionalOnClass判断容器中是否存储在CharacterEncodingFilter类，如果存在则该配置类生效。我们可以通过debug: true 属性来让控制台打印自动配置报告。


4.所有在配置文件中能配置的属性都是在xxxProperties类中封装着，配置文件能配置什么就可以参照某个功能对应的这个属性类。
```java
@ConfigurationProperties(prefix = "spring.http")
public class HttpProperties {
```

<br>
#三、日志
###1. 日志原理
日志
![蓝色的是接口层，墨绿的是适配层，蓝色的是实现层](SpringBoot框架.assets1e893d49e3241249a0a5884916c7380.png)


![image.png](SpringBoot框架.assets8d2aa05fd3f49279c3b72df52df9413.png)
Springboot框架中的Spring-boot-starter-logging会自动引入各个框架（jul、jcl、log4j）的slf4j的适配层，最终用logback实现，所以如果其他框架有引入不同的日志框架，需要进行排除，否则会有冲突。

###2. 其他日志框架的适配
每个日志的实现框架都有自己的配置文件，使用SLF4j之后，配置文件还是做成日志实现框架自己本身的配置文件。
如何使其他日志框架也能统一使用SLF4j+logback的日志框架？
![日志框架诗配图](SpringBoot框架.assets7059817b278471190579756048c3ce7.png)
1. 可以先**排除框架中的原日志接口层**的包
2.然后使用SLF4j提供的对应的**替换包来替换原有的包**。这样原接口没有消失，但是会调用SLF4j的方法进行统一的输出。（spring-boot-starter中默认已经导入）
3. 再导入SLF4j其他的实现。

![image.png](SpringBoot框架.assets\4e074295adfe4ed38be615ec1f4e0de8.png)

**总结**
1. Springboot底层也是使用SLF4j+logback的方式进行日志记录。
2. Springboot也把其他日志都替换成了SLF4j
3. 如果我们引入其他框架，需要将这个框架的默认的日志依赖移除掉。如Springboot依赖了spring-core框架，但是将spirng-core框架中的common-logging日志框架直接移除掉。

**也可以将springboot的默认的spring-boot-starter-logging包替换为spring-boot-starter-log4j2包，来实现对log4j2的支持。**

###3. slf4j的使用
**日志的级别**
从低到高分别为
logger.trace();
logger.debug();
logger.info();
logger.warn();
logger.error();
可以进行设置后让控制台打印指定级别的高级别的日志（Springboot默认使用的是info级别）。

**调整指定包下的类的打印级别**
logging.level.com.hxr: warn

**将日志输出到指定的目录中**
指定日志输出的目录，生成的文件名为默认的spring.log
logging.path: /spring/log

**将日志输出到指定目录的指定文件中**
不指定目录在当前文件夹下生成，指定路径则生成到对应路径下。会覆盖logging.path设置。
logging.file: G:/springboot.log

**在控制台输出的日志的格式**
logging.pattern.console: %d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n

**在文件中输出的日志的格式**
logging.pattern.console: %d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n

注：
%d表示日期时间
%thread表示线程名
%-5level  级别从左显示5个字符宽度
%logger{50} 表示logger名字最长50个字符，否则按照句点分割
%msg  日志消息
%n 换行符

![logback的默认配置文件](SpringBoot框架.assets\4a108941195d409c8a26e2274eea0e09.png)

<br>
**如何覆盖框架默认的配置文件**
![image.png](SpringBoot框架.assets