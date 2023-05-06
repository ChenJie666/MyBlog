---
title: 单元测试TESTNG
categories:
- SpringBoot
---
# 一、TestNg简介
## 1. 概念
TestNg也是一套测试框架，它的灵感来源于Junit(java的单元测试框架)和Nunit(.net的单元测试框架)。但是它又在此基础上引入了新的东西，使得它更加强大。

TestNg表示下一代(next genaration)，它不仅可以做单元测试，还可以做集成测试。
```
<!-- testng单元测试类 -->
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>RELEASE</version>
    <scope>test</scope>
</dependency>
```
## 1.2 TestNg优于Junit的地方：

**1.允许分组测试**
```
@Test(groups="group1")

public void groupTest(){

}
```
然后在testng.xml中定义要包含哪些group，不包含哪些group。

<br>
**2.TestNg允许只运行失败的例子**
执行完testng后，会在test-output目录下生成一些测试结果文件。如果此次测试有失败的例子，我们调试完，想再运行一下这些失败的例子时，可以运行testng-failed.xml文件。这个文件就是记录了上一次所有执行失败的例子。
 
<br>
**3.TestNg允许依赖测试（类似于ant的依赖）**

可依赖测试方法：
```
    @Test(dependsOnMethods = { "test2" })
    public void test1() {
    }
    @Test
    public void test2() {
    }
也可依赖群组：
    @Test(groups = { "init.1" })
    public void test1() {
    }
    @Test(groups = { "init.2" })
    public void test2() {
    }
    @Test(dependsOnGroups = { "init.*" })
    public void test2() { 
    }
```

<br>
**4.TestNg支持并行测试（支持测试方法(methods)，测试类(classes)，小的测试套件（tests），可以大大提高测试效率**

在testng.xml文件中定义线程的个数：
```
<suite name="Test-class Suite" parallel="classes" thread-count="2" >

  <test name="Test-class test" >

    <classes>

      <class name="class1" />

      <class name="class2" />

    </classes>

  </test>

</suite>
```
则开了两个线程一个运行class1，一个运行class2。

<br>
**5.注解比junit丰富**
| 注解              | 描述                                                         |
| ----------------- | ------------------------------------------------------------ |
| **@BeforeSuite**  | 注解的方法将只运行一次，运行所有测试前此套件中。             |
| **@AfterSuite**   | 注解的方法将只运行一次此套件中的所有测试都运行之后。         |
| **@BeforeClass**  | 注解的方法将只运行一次先行先试在当前类中的方法调用。         |
| **@AfterClass**   | 注解的方法将只运行一次后已经运行在当前类中的所有测试方法。   |
| **@BeforeTest**   | 注解的方法将被运行之前的任何测试方法属于内部类的 <test>标签的运行。 |
| **@AfterTest**    | 注解的方法将被运行后，所有的测试方法，属于内部类的<test>标签的运行。 |
| **@BeforeGroups** | 组的列表，这种配置方法将之前运行。此方法是保证在运行属于任何这些组第一个测试方法，该方法被调用。 |
| **@AfterGroups**  | 组的名单，这种配置方法后，将运行。此方法是保证运行后不久，最后的测试方法，该方法属于任何这些组被调用。 |
| **@BeforeMethod** | 注解的方法将每个测试方法之前运行。                           |
| **@AfterMethod**  | 被注释的方法将被运行后，每个测试方法。                       |
| **@DataProvider** | 标志着一个方法，提供数据的一个测试方法。注解的方法必须返回一个Object[] []，其中每个对象[]的测试方法的参数列表中可以分配。该@Test 方法，希望从这个DataProvider的接收数据，需要使用一个dataProvider名称等于这个注解的名字。 |
| **@Factory**      | 作为一个工厂，返回TestNG的测试类的对象将被用于标记的方法。该方法必须返回Object[]。 |
| **@Listeners**    | 定义一个测试类的监听器。                                     |
| **@Parameters**   | 介绍如何将参数传递给@Test方法。                              |
| **@Test**         | 标记一个类或方法作为测试的一部分。                           |
@BeforeSuite和@AfterSuite是继承树上最先和最后执行的方法。
@BeforeClass和@AfterClass是该类最先和最后执行的方法。
@BeforeMethod和@AfterMethod在每次@Test方法执行时都会先后执行
**即@BeforeSuite>@BeforeClass>@BeforeMethod>@Test>@AfterMethod>@BeforeMethod>@Test>@AfterMethod>@AfterClass>@AfterSuite**


>以下是一些使用注释的好处：
>- TestNG的标识的方法关心寻找注解。因此，方法名并不限于任何模式或格式。
>- 我们可以通过额外的参数注解。
>- 注释是强类型的，所以编译器将标记任何错误。
>- 测试类不再需要任何东西（如测试案例，在JUnit3）扩展。

注：testNg中@BeforeTest针对的不是被@Test标记的方法，而是在testNg.xml中定义的test

![image](单元测试TESTNG.assetsb0eefabe2e94eb9a81d438847b80513.png)

@BeforeMethod才是针对的被@Test标记的方法，和junit中@BeforeTest是同一用法。

<br>
**6.testng被@BeforeClass 和@AfterClass注释的方法可以不写成static方法**


<br>
**7.被@Test标记的方法可以有输入参数，而在junit中是不行的**
```
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
 
public class ParameterizedTest1 {
    @Test
    @Parameters("myName")
    public void parameterTest(String myName) {
        System.out.println("Parameterized value is : " + myName);
    }
}
在testng.xml文件中定义参数的值
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE suite SYSTEM "http://testng.org/testng-1.0.dtd" >
<suite name="Suite1">
    <test name="test1">
          <parameter name="myName" value="qiuqiu"/> 
          <classes>
              <class name="ParameterizedTest1" />
              </classes>
    </test>
</suite>
```
可在<suite>标签或<test>标签下声明了参数。如果两个参数同名，在<test>标签下定义的参数优先

<br>
**8.testNg可以通过标注的方式来顺序执行**
@Test(priority=0)
priority为0,1,2,3这样定义，然后就会按照数字从小到大那样依次执行

<br>
**9.testng中子类不会运行父类中的@BeforeClass和@AfterClass
而在junit中会先运行父类的@BeforeClass，再运行自己的@BeforeClass；而@AfterClass是先运行自己的，再运行父类的。**

<br>
## 1.3 TestNg和Junit的相同点
**1.都可以做忽略测试，可以忽略某个测试方法(在方法上面注释)，也可以忽略某个测试类(在类的上面注释)**
testNg使用@Test(enabled = false)；
Junit使用@Ingore。
 
<br>
**2.都支持数据驱动测试，只是用法不一样**
- testng中可以用@DataProvider，参数化是在测试级别的，不需要通过构造函数来传递参数，它会自动映射。
举例：
```
//表示这个方法将提供数据给任何声明它的data provider名为“test1”的测试方法中
@DataProvider(name = "test1")  
public Object[][] createData1() {  
 return new Object[][] {  

   { "Cedric", new Integer(36) },  

   { "Anne", new Integer(37)},  
 };  
} 
//下面这个方法将要调用名为test1的data provider提供的数据
@Test(dataProvider="test1")
public void verifyDta(String n1,Integer n2){
 System.out.println(n1 + " " + n2); 
}
```
需要注意的是@Test(dataProvider=)和@DataProvider(name=)可以在同一个类中，使用方法就如上；如果不在同一个类中，那么必须把@DataProvider(name=)所在的类的这个方法定义成static静态方法。
并且在@Test使用的时候需要制定类。用法就是@Test(dataProvider="",dataProviderClass=（@DataProvider所在的类）.class)

- 而在junit中就麻烦多了。junit中的参数化是在类级别的，需要通过构造函数来传递参数。
如下：
```
package demo;

public class Try {
     public  int result=3;
     public  int add(int n) {
        result += n;
        return result;
    }
}
```
 
测试代码：
```
package demo;
import static org.junit.Assert.assertEquals;
import java.util.Arrays;
import java.util.Collection;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
//步骤1.指定特殊的运行器Parameterized.class
@RunWith(Parameterized.class)
public class TryTest {
               // 步骤2：为测试类声明几个变量，分别用于存放期望值和测试所用数据。此处我只放了测试所有数据，没放期望值。
               private int param, result;
               // 步骤3：申明构造函数
               public TryTest(int param, int result) {
                               super();
                               this.param = param;
                               this.result = result;
               }
               // 步骤4：定义测试数据的集合,该方法可以任意命名
               // 但是必须使用@Parameters标注进行修饰
               // 这个方法的框架就不予解释了，大家只需要注意其中的数据，是一个二维数组，数据两两一组
               // 每组中的这两个数据，一个是参数，一个是你预期的结果。
               // 比如我们的第一组{4, 7}，4就是参数，7就是预期的结果。分别对应上面构造函数的param和result
               @Parameters
               public static Collection<Object[]> testDate() {
                               Object[][] object = { { 1, 4 }, { 3, 6 }, { 1, 3 } };
                               return Arrays.asList(object);
               }
               // 步骤5：编写测试方法，使用定义的变量作为参数进行测试
               // 这里的编写方法和以前的测试方法一样
               @Test
               public void testAdd() {
                               Try test = new Try();
                               assertEquals(result, test.add(param));
               }
}
```

<br>
**3.超时测试，就是在规定时间内如果没有测试完成，就认定测试失败**
@Test(timeout=100)

<br>
**4.异常测试，就是在运行这个单元测试的时候应该要捕获到指定的异常，才算测试成功**


#二、实际使用
如果希望在Springboot框架中使用，需要让测试类extends AbstractTestNGSpringContextTests。如果希望每个测试自动回滚extends AbstractTransactionalTestNGSpringContextTests。
```
@SpringBootTest(classes = SmartcookApplication.class)
@WebAppConfiguration
public class NutrientServiceTest extends AbstractTestNGSpringContextTests {

    @Resource
    private NutrientService nutrientService;

    private static Long id;
    private static String nutrientParameterCode;
    private static String nutrientParameterValue;
    private static String nutrientName;
    private static String unitParameterCode;
    private static String unitParameterValue;

    private static Integer page;
    private static Integer pageSize;

    @BeforeSuite
    public void initData(){
        nutrientParameterCode = "HXR_UNIT_TEST";
        nutrientParameterValue = "HXR_UNIT_TEST";
        nutrientName = "HXR_UNIT_TEST";
        unitParameterCode = "HXR_UNIT_TEST";
        unitParameterValue = "HXR_UNIT_TEST";

        page = 1;
        pageSize = 5;
    }

    @Test(priority = 2)
    public void listNutrientTest(){
        PageListVO<NutrientVO> nutrientVOPageListVO = nutrientService.listNutrient(page, pageSize);
        List<NutrientVO> records = nutrientVOPageListVO.getRecords();
        Assert.assertFalse(Collections.isEmpty(records));
    }

    @Test(priority = 1)
    public void insertNutrientTest(){
        NutrientBO nutrientBO = new NutrientBO(nutrientParameterCode, nutrientParameterValue,
                nutrientName, unitParameterCode, unitParameterValue);
        id = nutrientService.insertNutrient(nutrientBO);
        Assert.assertNotNull(id);
    }

    @Test(priority = 99)
    public void deleteNutrientTest(){
        boolean isSuccess = nutrientService.deleteNutrient(Lists.newArrayList(id));
        Assert.assertTrue(isSuccess);
    }

    @Test(priority = 3)
    public void updateNutrientTest(){
        NutrientBO nutrientBO = new NutrientBO(nutrientParameterCode, nutrientParameterValue,
                nutrientName, unitParameterCode, unitParameterValue);
        boolean isSuccess = nutrientService.updateNutrient(id, nutrientBO);
        Assert.assertTrue(isSuccess);
    }

}
```
