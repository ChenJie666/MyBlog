---
title: SpEL表达式
categories:
- 编程语言
---
SpEL(Spring Expression Language)支持标准数学运算符,关系运算符,逻辑运算符,条件运算符,集合和正则表达式等。它可用于将bean或bean属性注入另一个bean,还支持bean的方法调用。

###一. 用法
SpEL有三种用法，一种是在注解@Value中；一种是XML配置；最后一种是在代码块中使用Expression。
- @Value
```
    //@Value能修饰成员变量和方法形参
    //#{}内就是表达式的内容
    @Value("#{表达式}")
    public String arg;
```
- <bean>配置
```
<bean id="xxx" class="com.java.XXXXX.xx">
    <!-- 同@Value,#{}内是表达式的值，可放在property或constructor-arg内 -->
    <property name="arg" value="#{表达式}">
</bean>
```
- Expression
```
    /**
     * 验证令牌的权限
     *
     * @param http
     * @throws Exception
     */
    @Override
    public void configure(HttpSecurity http) throws Exception {
        http
                .csrf().disable()
                .authorizeRequests()
                .antMatchers("/**").access("#oauth2.hasScope('all')")  //用户有"all"授权，可以访问所有接口
                .and()
                .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS);
    }
```

<br>

###二. 表达式语法
#####2.1 字面量赋值
```
<!-- 整数 -->
<property name="count" value="#{5}" />
<!-- 小数 -->
<property name="frequency" value="#{13.2}" />
<!-- 科学计数法 -->
<property name="capacity" value="#{1e4}" />
<!-- 字符串  #{"字符串"} 或  #{'字符串'} -->
<property name="name" value="#{'我是字符串'}" />
<!-- Boolean -->
<property name="enabled" value="#{false}" />
```
>注： 
1）字面量赋值必须要和对应的属性类型兼容，否则会报异常。
2）一般情况下我们不会使用 SpEL字面量赋值，因为我们可以直接赋值。

#####2.2 引用Bean、属性和方法（必须是public修饰的）
```
<property name="car" value="#{car}" />
<!-- 引用其他对象的属性 -->
<property name="carName" value="#{car.name}" />
<!-- 引用其他对象的方法 -->
<property name="carPrint" value="#{car.print()}" />
```

#####2.3 运算符
**算术运算符：+,-,\*,/,%,^**
```
<!-- 3 -->
<property name="num" value="#{2+1}" />
<!-- 1 -->
<property name="num" value="#{2-1}" />
<!-- 4 -->
<property name="num" value="#{2*2}" />
<!-- 3 -->
<property name="num" value="#{9/3}" />
<!-- 1 -->
<property name="num" value="#{10%3}" />
<!-- 1000 -->
<property name="num" value="#{10^3}" />
```
**字符串连接符：+**
```
<!-- 10年3个月 -->
<property name="numStr" value="#{10+'年'+3+'个月'}" />
```
**比较运算符：<(<),>(>),==,<=,>=,lt,gt,eq,le,ge**
```
<!-- false -->
<property name="numBool" value="#{10&lt;0}" />
<!-- false -->
<property name="numBool" value="#{10 lt 0}" />
<!-- true -->
<property name="numBool" value="#{10&gt;0}" />
<!-- true -->
<property name="numBool" value="#{10 gt 0}" />
<!-- true -->
<property name="numBool" value="#{10==10}" />
<!-- true -->
<property name="numBool" value="#{10 eq 10}" />
<!-- false -->
<property name="numBool" value="#{10&lt;=0}" />
<!-- false -->
<property name="numBool" value="#{10 le 0}" />
<!-- true -->
<property name="numBool" value="#{10&gt;=0}" />
<!-- true -->
<property name="numBool" value="#{10 ge 0}" />
```
**逻辑运算符：and,or,not,&&(&&),||,!**
```
<!-- false -->
<property name="numBool" value="#{true and false}" />
<!-- false -->
<property name="numBool" value="#{true&amp;&amp;false}" />
<!-- true -->
<property name="numBool" value="#{true or false}" />
<!-- true -->
<property name="numBool" value="#{true||false}" />
<!-- false -->
<property name="numBool" value="#{not true}" />
<!-- false -->
<property name="numBool" value="#{!true}" />
```
**条件运算符：?true:false**
```
<!-- 真 -->
<property name="numStr" value="#{(10>3)?'真':'假'}" />
```
**正则表达式：matches**
```
<!-- true -->
<property name="numBool" value="#{user.email matches '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,4}'}" />
```

#####2.4 调用静态方法或静态属性
通过 T() 调用一个类的静态方法，它将返回一个 Class Object，然后再调用相应的方法或属性：
```
<!-- 3.141592653589793 -->
<property name="PI" value="#{T(java.lang.Math).PI}" />
```
#####2.5 获取容器内的变量，可以使用“#bean_id”来获取。有两个特殊的变量，可以直接使用。
- this 使用当前正在计算的上下文
- root 引用容器的root对象
```
 String result2 = parser.parseExpression("#root").getValue(ctx, String.class);  
 
        String s = new String("abcdef");
        ctx.setVariable("abc",s);
        //取id为abc的bean，然后调用其中的substring方法
        parser.parseExpression("#abc.substring(0,1)").getValue(ctx, String.class);
```
#####2.6 方法调用
与Java代码没有什么区别，可见上面的例子
可以自定义方法，如下：
```
        //创建ctx容器
        StandardEvaluationContext ctx = new StandardEvaluationContext();
        //获取java自带的Integer类的parseInt(String)方法
        Method parseInt = Integer.class.getDeclaredMethod("parseInt", String.class);
        //将parseInt方法注册在ctx容器内
        ctx.registerFunction("parseInt", parseInt);
        //再将parseInt方法设为parseInt2
        ctx.setVariable("parseInt2", parseInt);
 
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
        //SpEL语法，比对两个方法执行完成后，结果是否相同
        String expreString = "#parseInt('2') == #parseInt2('3')";
        Expression expression = parser.parseExpression(expreString);
        return expression.getValue(ctx, Boolean.class);    //执行结果为false
 
        /** 如果String expreString = "#parseInt('2') == #parseInt2('3')"，执行结果为true */
        /** 可见SpEL正常执行*/
```
>“registerFunction”和“setVariable”都可以注册自定义函数，但是两个方法的含义不一样，推荐使用“registerFunction”方法注册自定义函数。

#####2.7 Elvis运算符
是三目运算符的特殊写法，可以避免null报错的情况
```
    //SpEL可简写为：
    name?:"other"
 
    //等同于java代码
    name != null? name : "other"
```

#####2.8 安全保证
为了避免操作对象本身可能为null，取属性时报错，可以使用SpEL检验语法
语法： “对象?.变量|方法”
```
    //SpEL表达式简写
    list?.length
 
    //等同于java代码
    list == null? null: list.length
```

#####2.9 直接使用java代码new/instance of
此方法只能是java.lang 下的类才可以省略包名
```
Expression exp = parser.parseExpression("new Spring('Hello World')");
```

#####2.10 集合定义
使用“{表达式，……}”定义List，如“{1,2,3}”
```
    //SpEL的@Value注解设置List
    @Value("1,2,3")
    private List<Integer> f1;
 
    @RequestMapping(value = "/a", method = RequestMethod.POST)
    public List<Integer> a() throws NoSuchMethodException {
 
        //SpEL
        List<Integer> result1 = parser.parseExpression("{1,2,3}").getValue(List.class);
 
        //等同于如下java代码
        Integer[] integer = new Integer[]{1,2,3};
        List<Integer> result2 = Arrays.asList(integer);
 
        return result1;
    }
```
对于字面量表达式列表，SpEL会使用java.util.Collections.unmodifiableList 方法将列表设置为不可修改。
对于列表中只要有一个不是字面量表达式，将只返回原始List


#####2.11 集合访问
SpEL目前支持所有集合类型和字典类型的元素访问
      语法：“集合[索引]”、“map[key]”
```
EvaluationContext context = new StandardEvaluationContext();

//即list.get(0)
int result1 = parser.parseExpression("{1,2,3}[0]").getValue(int.class);

//list获取某一项
Collection<Integer> collection = new HashSet<Integer>();
collection.add(1);
collection.add(2);

context.setVariable("collection", collection);
int result2 = parser.parseExpression("#collection[1]").getValue(context, int.class);

//map获取
Map<String, Integer> map = new HashMap<String, Integer>();
map.put("a", 1);

context.setVariable("map", map);
int result3 = parser.parseExpression("#map['a']").getValue(context, int.class);
```

#####2.12 集合修改
可以使用赋值表达式或Expression接口的setValue方法修改；
```
//赋值语句
int result = parser.parseExpression("#array[1] = 3").getValue(context, int.class); 
 
//serValue方法
parser.parseExpression("#array[2]").setValue(context, 4);
```

#####2.13 集合选择
通过一定的规则对及格进行筛选，构造出另一个集合
语法：“(list|map).?[选择表达式]”

选择表达式结果必须是boolean类型，如果true则选择的元素将添加到新集合中，false将不添加到新集合中。
```
    parser.parseExpression("#collection.?[#this>2]").getValue(context, Collection.class); 
```
上面的例子从数字的collection集合中选出数字大于2的值，重新组装成了一个新的集合。


#####2.14 集合投影
根据集合中的元素中通过选择来构造另一个集合，该集合和原集合具有相同数量的元素

语法：“SpEL使用“（list|map）.![投影表达式]”
```
public class Book {
 
	public String name;         //书名
	public String author;       //作者
	public String publisher;    //出版社
	public double price;        //售价
	public boolean favorite;    //是否喜欢
}
```
```
public class BookList {
 
    @Autowired
    protected ArrayList<Book> list = new ArrayList<Book>() ;
	
    protected int num = 0;
}
```
将BookList的实例映射为bean：readList，在另一个bean中注入时，进行投影
```
    //从readList的list下筛选出favorite为true的子集合，再将他们的name字段投为新的list
	@Value("#{list.?[favorite eq true].![name]}")
	private ArrayList<String> favoriteBookName;
```

****
测试案例
```
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.expression.Expression;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
 
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
 
/**
 *
 */
@Slf4j
@RestController
@RequestMapping("/SpEL")
public class SpELController {
 
    @Value("#{'Hello World1'}")
    String helloWorld1;        //变量word赋值直接量：字符串"Hello World"
 
    @Value("Hello World2")
    String helloWorld2;        //变量word赋值直接量：字符串"Hello World"
 
    //注入list
    @Value("7,2,3,5,1")
    private List<Integer> fList;
 
 
    /**
     * {@code @Value} 注入String
     *
     * @return
     */
    @RequestMapping(value = "/valueAnnoString", method = RequestMethod.POST)
    public String valueAnnoString() {
        return helloWorld1 + " & " + helloWorld2;
    }
 
 
    /**
     * {@code @Value} 注入List
     *
     * @return
     * @throws NoSuchMethodException
     */
    @RequestMapping(value = "/valueAnnoList", method = RequestMethod.POST)
    public List<Integer> valueAnnoList() {
        return fList;
    }
 
 
    /**
     * 测试通过ExpressionParser调用SpEL表达式
     * @return
     */
    @RequestMapping(value = "/expressionParse", method = RequestMethod.POST)
    public List<Integer> expressionParse() {
 
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
        List<Integer> result1 = parser.parseExpression("{4,5,5,6}").getValue(List.class);
        return result1;
    }
 
 
 
    /**
     * 使用java代码
     * @return
     */
    @RequestMapping(value = "/javaCode", method = RequestMethod.POST)
    public Integer javaCode() {
 
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
 
        //等同于直接用java代码，还有方法调用
        String str = parser.parseExpression("new String('Hello World').substring(3)").getValue(String.class);
        log.info("str=={}", str);
 
        //TType 等同于java的Integer.MAX_VALUE
        Integer integer = parser.parseExpression("T(Integer).MAX_VALUE").getValue(Integer.class);
        log.info("integer=={}", integer);
        return integer;
    }
 
 
 
 
    /**
     * 注入并调用method方法
     * @return
     * @throws NoSuchMethodException
     */
    @RequestMapping("methodInvoke")
    private boolean methodInvoke() throws NoSuchMethodException {
        //创建ctx容器
        StandardEvaluationContext ctx = new StandardEvaluationContext();
        //获取java自带的Integer类的parseInt(String)方法
        Method parseInt = Integer.class.getDeclaredMethod("parseInt", String.class);
        //将parseInt方法注册在ctx容器内, 推荐这样使用
        ctx.registerFunction("parseInt", parseInt);
        //再将parseInt方法设为parseInt2
        ctx.setVariable("parseInt2", parseInt);
 
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
        //SpEL语法，比对两个方法执行完成后，结果是否相同
        String expreString = "#parseInt('2') == #parseInt2('3')";
        //执行SpEL
        Expression expression = parser.parseExpression(expreString);
        Boolean value = expression.getValue(ctx, Boolean.class);
        return value;
    }
 
 
 
    /**
     * 运算符
     * @return
     */
    @RequestMapping(value = "/operator", method = RequestMethod.POST)
    public boolean operator() {
 
        //创建ctx容器
        StandardEvaluationContext ctx = new StandardEvaluationContext();
        //将字符串defg放在 ctx容器内
        ctx.setVariable("abc", new String("defg"));
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
        String abc = parser.parseExpression("#abc").getValue(ctx, String.class);
        log.info("abc=={}", abc);
 
        //运算符判断
        Boolean result = parser.parseExpression("#abc.length() > 3").getValue(ctx, Boolean.class);
        log.info("result=={}", result);
        return result;
    }
 
 
    /**
     * Elvis等用法
     * @return
     */
    @RequestMapping(value = "/elvis", method = RequestMethod.POST)
    public void elvis(){
        //创建ctx容器
        StandardEvaluationContext ctx = new StandardEvaluationContext();
        //将字符串defg放在 ctx容器内
        ctx.setVariable("name", null);
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
        String name = parser.parseExpression("#name?:'other'").getValue(ctx, String.class);
        log.info("name=={}",name);
        log.info("saved length() == {}", parser.parseExpression("#name?.lenth()").getValue(ctx));
 
        //将字符串defg放在 ctx容器内
        ctx.setVariable("name", "abc");
        name = parser.parseExpression("#name?:'other'").getValue(ctx, String.class);
        log.info("changed name=={}",name);
        log.info("changed saved length() == {}", parser.parseExpression("#name?.length()").getValue(ctx));
 
 
        //map获取
        Map<String, Integer> map = new HashMap<String, Integer>();
        map.put("a", 1);
        ctx.setVariable("map", map);
        int mapA = parser.parseExpression("#map['a']").getValue(ctx, int.class);
        log.info("map['a']=={}", mapA);
        //修改
        parser.parseExpression("#map['a']").setValue(ctx, 6);
        mapA = parser.parseExpression("#map['a']").getValue(ctx, int.class);
        log.info("changed map['a']=={}", mapA);
 
        return ;
    }
 
 
    @RequestMapping("/listFunction")
    private void listFunction() {
        //创建ctx容器
        StandardEvaluationContext ctx = new StandardEvaluationContext();
        //创建ExpressionParser解析表达式
        ExpressionParser parser = new SpelExpressionParser();
 
        //list过滤
        ctx.setVariable("aList",fList);
        List<Integer> cList = parser.parseExpression("#aList.?[#this>3]").getValue(ctx, List.class);
        log.info("filter list=={}", cList);
 
 
        List<Book> books = new ArrayList<>();
        books.add(new Book("JAVA Program", 2000, 102.5));
        books.add(new Book("C Program", 1985, 36));
        books.add(new Book("scala", 2015, 60));
 
        //object过滤
        ctx.setVariable("books", books);
        List<Book> filterBooks1 = (List<Book>) parser.parseExpression("#books.?[year>2000]").getValue(ctx);
        log.info("filterBooks1=={}", filterBooks1);
 
        //投影
        List<String> filterBooksName = parser.parseExpression("#books.?[price<100].![name]").getValue(ctx, List.class);
        log.info("filterBooksName=={}", filterBooksName);
 
        return;
    }
 
 
 
    @Data
    class Book{
        private String name;
        private int year;
        private double price;
 
        public Book(String name, int year, double price) {
            this.name = name;
            this.year = year;
            this.price = price;
        }
    }
 
}
```
