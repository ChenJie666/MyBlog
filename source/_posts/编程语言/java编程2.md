---
title: java编程2
categories:
- 编程语言
---
java中被模数为负数，则余数为负；模数为负数，则余数为正；都为负数，余数为负
pmod（-9，4）＝3

取随机值:
new Random（）.nextInt（10）；
Math.random（）
hive中:rand（） 返回0～1随机浮点数

exp（double a）e的a次方
log（a，b）loga b
pow（a，b）a的b次方
sqrt（a）a的平方根
abs（a）绝对值
bin（a）hex（a）unhex（a）转换进制
conv(17,10,16)将17从十进制转到十六进制11
pmod(-9,4)  -9模4为3，与java运算规则不同



时间函数：

1.★from_unixtime（timestamp，‘ 时间格式 ’）将从1970-01-01开始的秒数转化为规定格式的时间

如果时间格式不规范，用regexp_replace()函数。例：select date_format(regexp_replace('2019/07/06','/','-'),'yyyy-MM');

2.★date_format（'2019-07-06','yyyy-MM'）返回规定的时间格式

3.★date_add/sub（'2019-07-06',2）

3.to_date('2011-12-07 13:01:03') 只返回日期部分

4.unix_timestamp（）转换现在时间为时间戳

5.select unix_timestamp('2011-12-07 13:01:03'，‘yyyy-MM-ddHH:mm:ss’) 

6.weekofyear('2011-12-08 10:03:01')日期在当前的周数

7.datediff('2012-12-08','2012-05-09') 相差的天数

8.★months_between('..','...')两个日期相差的月数

9.current_date 返回当前日期



条件函数

1. if(boolean testCondition, T valueTrue, T valueFalseOrNull)
2. case when
3. coalesce（）返回参数中的第一个非空值；如果所有值都为NULL，那么返回NULL



字符串函数：

1.length('abcedfg') 返回字符串A的长度

2.reverse(abcedfg’) 反转字符串

3.reverse(abcedfg’) 

4.★concat（）拼接字符串

    ★concat_ws（',','abc','def','gh'）用指定符号拼接字符串或数组

5.substring（'abcde',3,2）截取字符串

6.ucase（），lcase（）转换大小写

7.trim（）去除字符串两边的空格

   ltrim（）

   rtrim（）

8.★regexp_replace（string A, string B, string C)将字符串A中的符合java正则表达式B的部分替换为C

    select regexp_extract('hitdecisiondlist','(i)(.*?)(e)',0) ，获取匹配的字符串

9.parse_url（）解析url中的信息，包括HOST, PATH, QUERY, REF, PROTOCOL, AUTHORITY, FILE, and USERINFO

10.★get_json_object（字段名，$.属性名）获取json中的属性值

11.space（10） 返回长度为10的字符串

12.repeat（'abc',5）返回abcabcabcabcabc

13. ascii(string str)返回字符串str第一个字符的ascii码
14. lpad(string str, int len, string pad)将str进行用pad进行左补足到len位

        rpad(string str, int len, string pad)将str进行用pad进行右补足到len位

15.select split('abtcdtef','t') 返回切割后的字符串数组

16.find_in_set(string str, string strList)返回str在strlist第一次出现的位置



★类型转换函数 cast(expr as <type>)

select cast(1 as bigint) from lxw_dual;



MAP类型：Create table lxw_test as select map('100','tom','200','mary')as t from lxw_dual;	{"100":"tom","200":"mary"}

 查看map中元素： select t['200'],t['100'] from lxw_test;

查看map的大小：select size(map('100','tom','101','mary')) from lxw_dual;



Struct类型：create table lxw_test as select struct('tom','mary','tim')as t from lxw_dual;	{"col1":"tom","col2":"mary","col3":"tim"}

查看struct中元素： select t.col1,t.col3 from lxw_test;





Array类型：create table lxw_test as selectarray("tom","mary","tim") as t from lxw_dual;	["tom","mary","tim"]

select t[0],t[1],t[2] from lxw_test;

查看array中元素 ：select t['200'],t['100'] from lxw_test;

查看array的大小 ：select size(array('100','101','102','103')) from lxw_dual;





在mysql命令行中输入source 文件路径，有多个要执行的文件，可以将文件都写到sql文件中执行。

在mysql中调用函数用call 函数名。

sqoop查看mysql中的数据库：bin/sqoop list-databases --connect jdbc:mysql://hadoop102:3306 --username root --password abc123



双引号中的$变量名 会被解析出来，如果不想解析，可以加转义字符，如--query "$1 and \$CONDITIONS"

单引号中的$变量名 不会被解析出来，如果想解析，也可以加转义字符。

mysql中的时间格式为%Y-%m-%d，shell中时间格式为yyyy-MM-dd



show create table table_name;查看表的所有字段





HDP 集群中用ranger来空间访问权限







## 多线程：

Thread构造器：Thread( )   、 Thread(Runnable target, String name)

```
Thread

void start():  启动线程，并执行对象的run()方法
run():  线程在被调度时执行的操作
String getName():  返回线程的名称
void setName(String name):设置该线程名称
static Thread currentThread(): 返回当前线程。在Thread子类中就是this，通常用于主线程和Runnable实现类。

static  void  yield()：线程让步暂停当前正在执行的线程，把执行机会让给优先级相同或更高的线程若队列中没有同优先级的线程，忽略此方法
join() ：当某个程序执行流中调用其他线程的 join() 方法时，调用线程将被阻塞，直到 join() 方法加入的 join 线程执行完为止   低优先级的线程也可以获得执行 
static  void  sleep(long millis)：(指定时间:毫秒)令当前活动线程在指定时间段内放弃对CPU控制,使其他线程有机会被执行,时间到后重排队。抛出InterruptedException异常
boolean isAlive()：返回boolean，判断线程是否还活着
```

getPriority() ：返回线程优先值 
setPriority(int newPriority) ：改变线程的优先级



声明周期：新建、就绪、执行、阻塞、死亡![12](F:/Typora/图片/12.PNG)

执行结束、break或return、抛异常和调用wait（）都会施放锁。

Thread.sleep()、Thread.yield()、suspend（）挂起线程等操作不会施放锁。



1.同步方法的锁：静态方法（类名.class）、非静态方法（this）

2.同步代码块：非静态方法中使用同步代码块继承extends时慎用this，用类名.class。因为继承Thread会有多个对象，慎用this；实现Runnable只有一个对象，可用this。静态方法中使用同步代码块用.class。

3.Lock锁（java.util.concurrent.locks.Lock接口）

private ReentrantLock lock = New ReentrantLock();

try{

lock.lock();

}finally{

Lock.unlock();

}



1.wait() 、notify()、notifyAll()三个方法的**调用者是同步监视器**，如果不是会报异常。（如果同步监视器不是this，则在三个方法前面加上同步监视器，如果不加默认为this，会报错）

2.wait() 、notify()、notifyAll()三个方法只能用于同步代码块或同步方法中。不能用于Lock锁中。

3.wait() 、notify()、notifyAll()三个方法定义在Object中，会被继承。！！！



Sleep（）和wait（）异同点：

同：都可以使当前进程进入阻塞状态。

异：施放锁，方法所在类，自动唤醒，使用场景，

1.定义方法所属sleep（）：Thread类中静态方法；wait（）：object中的非静态方法

2.适用范围：sleep任何位置，wait在同步内。

3.在同步代码块或同步方法中wait施放锁，sleep不施放锁。

4.结束阻塞时机不同，wait需要被其他线程唤醒。



①继承Thread，重写run方法②实现Runnable方法③实现callable接口（有返回值，可throws抛异常，支持泛型指定返回值类型）④线程池（便于管理，降低资源消耗，提高响应速度）

```java
public class CallableTest {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        Callable test = new Test();
        FutureTask<Integer> ft1 = new FutureTask<Integer>(test);
        FutureTask<Integer> ft2 = new FutureTask<Integer>(test);
        new Thread(ft1).start();
        new Thread(ft2).start();
        System.out.println(ft1.get());
        System.out.println(ft2.get());

    }
}
class Test implements Callable<Integer>{
    public Integer call() throws Exception {
        for (int i = 0; i < 100; i++) {
            System.out.println(Thread.currentThread().getName() + " " + i);
        }
        return (int)(Math.random()*50);
    }
}
```



```java
生产者消费者模型：
public class ProductTest {
    public static void main(String[] args) {
        Clerk clerk = new Clerk();
        Thread productorThread = new Thread(new Productor(clerk));
        Thread consumerThread = new Thread(new Consumer(clerk));
        productorThread.start();
        consumerThread.start();
    }
}
class Productor implements Runnable { // 生产者
    Clerk clerk;

    public Productor(Clerk clerk) {
        this.clerk = clerk;
    }

    public void run() {
        System.out.println("生产者开始生产产品");
        while (true) {
            try {
                Thread.sleep((int) Math.random() * 1000);
            } catch (InterruptedException e) {
		e.printStackTrace();
            }
            clerk.addProduct();
        }
    }
}
class Consumer implements Runnable { // 消费者
    Clerk clerk;

    public Consumer(Clerk clerk) {
        this.clerk = clerk;
    }

    public void run() {
        System.out.println("消费者开始取走产品");
        while (true) {
            try {
                Thread.sleep((int) Math.random() * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            clerk.getProduct();
        }
    }
}
class Clerk { // 售货员
    private int product = 0;

    public synchronized void addProduct() {
        if (product >= 20) {
            try {
                wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            product++;
            System.out.println("生产者生产了第" + product + "个产品");
            notifyAll();
        }
    }
	public synchronized void getProduct() {
    if (this.product <= 0) {
        try {
            wait();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    } else {
        System.out.println("消费者取走了第" + product + "个产品");
        product--;
        notifyAll();
    }
   }
}

```



## java常用类：

Person p1 = new Person("Tom",12);
Person p2 = new Person("Tom",12);
System.out.println(p1.name == p2.name);//true

p1和p2指向不同的对象，但是两对象中的value指向方法区中常量池的同一个字符数组，所以地址相同。



### String类

String s1 = "hello";
String s2 = "hello";
s1==s2；//true

s1和s2指向方法区中常量池的同一个字符数组。

```java
public class StringTest {
    public static void main(String[] args) {
        String name1 = new String(" name ");
        String name2 = new String(" name ");
        System.out.println(name1 == name2);//false
        String trim1 = name1.trim();
        String trim2 = name2.trim();
        System.out.println(trim1 == trim2);//false

        String name3 = " name ";
        String name4 = " name ";
        System.out.println(name3 == name4);//true
        String trim3 = name3.trim();
        String trim4 = name4.trim();
        System.out.println(trim3 == trim4);//false
    }
}
```

为什么“abc”可以调用方法？

访问str时后台会做如下处理：

a.创建String类型的一个实例

b.在实例上调用指定的方法

c.销毁这个实例

```
int length()：返回字符串的长度： return value.length
char charAt(int index)： 返回某索引处的字符return value[index]
boolean isEmpty()：判断是否是空字符串：return value.length == 0
String toLowerCase()：使用默认语言环境，将 String 中的所有字符转换为小写
String toUpperCase()：使用默认语言环境，将 String 中的所有字符转换为大写
String trim()：返回字符串的副本，忽略前导空白和尾部空白
boolean equals(Object obj)：比较字符串的内容是否相同
boolean equalsIgnoreCase(String anotherString)：与equals方法类似，忽略大小写
String concat(String str)：将指定字符串连接到此字符串的结尾。 等价于用“+”
int compareTo(String anotherString)：比较两个字符串的大小
String substring(int beginIndex)：返回一个新的字符串，它是此字符串的从beginIndex开始截取到最后的一个子字符串。 
String substring(int beginIndex, int endIndex) ：返回一个新字符串，它是此字符串从beginIndex开始截取到endIndex(不包含)的一个子字符串。
boolean endsWith(String suffix)：测试此字符串是否以指定的后缀结束 
boolean startsWith(String prefix)：测试此字符串是否以指定的前缀开始 
boolean startsWith(String prefix, int toffset)：测试此字符串从指定索引开始的子字符串是否以指定前缀开始
boolean contains(CharSequence s)：当且仅当此字符串包含指定的 char 值序列时，返回 true
int indexOf(String str)：返回指定子字符串在此字符串中第一次出现处的索引 
int indexOf(String str, int fromIndex)：返回指定子字符串在此字符串中第一次出现处的索引，从指定的索引开始 
int lastIndexOf(String str)：返回指定子字符串在此字符串中最右边出现处的索引 
int lastIndexOf(String str, int fromIndex)：返回指定子字符串在此字符串中最后一次出现处的索引，从指定的索引开始反向搜索

String replace(char oldChar, char newChar)：返回一个新的字符串，它是通过用 newChar 替换此字符串中出现的所有 oldChar 得到的。 
String replace(CharSequence target, CharSequence replacement)：使用指定的字面值替换序列替换此字符串所有匹配字面值目标序列的子字符串。 
String replaceAll(String regex, String replacement)：使用给定的 replacement 替换此字符串所有匹配给定的正则表达式的子字符串。 
String replaceFirst(String regex, String replacement)：使用给定的 replacement 替换此字符串匹配给定的正则表达式的第一个子字符串。
boolean matches(String regex)：告知此字符串是否匹配给定的正则表达式
String[] split(String regex)：根据给定正则表达式的匹配拆分此字符串。 
String[] split(String regex, int limit)：根据匹配给定的正则表达式来拆分此字符串，最多不超过limit个，如果超过了，剩下的全部都放到最后一个元素中


String 类的构造器：String(char[]) 和 String(char[]/byte[]，int offset，int length) 

toCharArray() 字符串转换为字符数组
getChars(int srcBegin, int srcEnd, char[] dst, int dstBegin)：提供了将指定索引范围内的字符串存放到数组中的方法。
public byte[] getBytes() ：使用平台的默认字符集将此 String 编码为 byte 序列，并将结果存储到一个新的 byte 数组中。
public byte[] getBytes(String charsetName) ：使用指定的字符集将此 String 编码到 byte 序列，并将结果存储到新的 byte 数组。

```

装箱 包装类或String.valueOf(...);

拆箱 包装类对象.xxxValue();



**StringBuffer:效率低，线程安全	StringBuilder：效率高，线程不安全**

StringBuffer()：初始容量为16的字符串缓冲区
StringBuffer(int size)：构造指定容量的字符串缓冲区
StringBuffer(String str)：将内容初始化为指定字符串内容

StringBuffer append(xxx)：提供了很多的append()方法，用于进行字符串拼接
StringBuffer delete(int start,int end)：删除指定位置的内容
StringBuffer replace(int start, int end, String str)：把[start,end)位置替换为str
StringBuffer insert(int offset, xxx)：在指定位置插入xxx
StringBuffer reverse() ：把当前字符序列逆转

public int indexOf(String str)
public String substring(int start,int end)
public int length()
public char charAt(int n )
public void setCharAt(int n ,char ch)

```
        String str = null;
        StringBuffer sb = new StringBuffer();
        sb.append(str);

        System.out.println(sb.length());//4

        System.out.println(sb);//null

        StringBuffer sb1 = new StringBuffer(str);//会调用str.length方法，报空指针
        System.out.println(sb1);//
```





### 时间：

System.currentTimeMillis（）

new Date()：使用无参构造器创建的对象可以获取本地当前时间。
new Date(long date)：放入时间戳构造日期对象

getTime():返回自 1970 年 1 月 1 日 00:00:00 GMT 以来此 Date 对象表示的毫秒数。
toString():把此 Date 对象转换为以下形式的 String： dow mon dd hh:mm:ss zzz yyyy 其中： dow 是一周中的某一天 (Sun, Mon, Tue, Wed, Thu, Fri, Sat)，zzz是时间标准。MM表示月份，mm表示分组；HH时24进制，hh时12进制。



java.text.SimpleDateFormat：

SimpleDateFormat() ：默认的模式和语言环境创建对象
public SimpleDateFormat(String pattern)：该构造方法可以用参数pattern指定的格式创建一个对象，该对象调用：
public String format(Date date)：方法格式化时间对象date
解析：
public Date parse(String source)：从给定字符串的开始解析文本，以生成一个日期。

```
SimpleDateFormat formater = new SimpleDateFormat();
System.out.println(formater.format(date));// 打印输出默认的格式
SimpleDateFormat formater2 = new SimpleDateFormat("yyyy年MM月dd日 EEE HH:mm:ss");
System.out.println(formater2.format(date));

// 实例化一个指定的格式对象
 Date date2 = formater2.parse("2008年08月08日 星期一 08:08:08");
// 将指定的日期解析后格式化按指定的格式输出
 System.out.println(date2.toString());
```



java.util.Calendar

Calendar.getInstance() 工厂方法

get(int field)

public void set(int field,int value)
public void add(int field,int amount)
public final Date getTime()
public final void setTime(Date date)



java.time、java.time.format

LocalDate代表IOS格式（yyyy-MM-dd）的日期,可以存储 生日、纪念日等日期。
LocalTime表示一个时间，而不是日期。
LocalDateTime是用来表示日期和时间的，这是一个最常用的类之一。



| **方法**                                                     | **描述**                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| **now****() /** ***  now(ZoneId zone)**                      | 静态方法，根据当前时间创建对象/指定时区的对象                |
| **of()**                                                     | 静态方法，根据指定日期/时间创建对象                          |
| **getDayOfMonth()/****getDayOfYear()**                       | 获得月份天数(1-31) /获得年份天数(1-366)                      |
| **getDayOfWeek()**                                           | 获得星期几(返回一个 DayOfWeek 枚举值)                        |
| **getMonth()**                                               | 获得月份, 返回一个 Month 枚举值                              |
| **getMonthValue() /** **getYear()**                          | 获得月份(1-12) /获得年份                                     |
| **getHour()/getMinute()/getSecond()**                        | 获得当前对象对应的小时、分钟、秒                             |
| **withDayOfMonth()/withDayOfYear()/****withMonth()/withYear()** | 将月份天数、年份天数、月份、年份修改为指定的值并返回新的对象 |
| **plusDays(), plusWeeks(),** **plusMonths(), plusYears(),****plusHours()** | 向当前对象添加几天、几周、几个月、几年、几小时               |
| **minusMonths()** **/ minusWeeks()/****minusDays()/****minusYears()/minusHours()** | 从当前对象减去几月、几周、几天、几年、几小时                 |

| **方**  **法**                     | **描**  **述**                                      |
| ---------------------------------- | --------------------------------------------------- |
| **ofPattern(String** **pattern)**  | 静态方法，返回一个指定字符串格式的DateTimeFormatter |
| **format(TemporalAccessor** **t)** | 格式化一个日期、时间，返回字符串                    |
| **parse(CharSequence** **text)**   | 将指定格式的字符序列解析为一个日期、时间            |





**java比较器：**

自然排序：java.lang.Comparable
定制排序：java.util.Comparator

1.实现 Comparable 的类必须实现 compareTo(Object obj) 方法。可以通过 **Collections.sort 或 Arrays.sort**进行自动排序。实现此接口的对象可以用作有序映射中的键或有序集合中的元素，无需指定比较器。

2.当元素的类型没有实现java.lang.Comparable接口而又不方便修改代码，或者实现了java.lang.Comparable接口的排序规则不适合当前的操作，那么可以考虑使用 Comparator 的对象来排序。实现compare(Object o1,Object o2)方法，比较o1和o2的大小。Comparator 对象作为参数传递给 sort 方法。还可以使用 Comparator 来控制某些数据结构（如有序 set或有序映射）的顺序，或者为那些没有自然顺序的对象 collection 提供排序。



### System类：

native long currentTimeMillis()

 gc() 请求系统进行垃圾回收

getProperty(String key)获得系统中属性名为key的属性对应的值



### Math类：

java.lang.Math类

abs     绝对值
acos,asin,atan,cos,sin,tan  三角函数
sqrt     平方根
pow(double a,doble b)     a的b次幂
log    自然对数
exp    e为底指数
max(double a,double b)
min(double a,double b)
random()      返回0.0到1.0的随机数
long round(double a)     double型数据a转换为long型（四舍五入）
toDegrees(double angrad)     弧度—>角度
toRadians(double angdeg)     角度—>弧度



取随机值的两种方式：

```
Math.random();

Random random = new Random();
int i = random.nextInt();
```



### BigInteger和BigDecimal

BigInteger用于存放大整数  BigInteger(String val)

public BigInteger abs()：返回此 BigInteger 的绝对值的 BigInteger。
BigInteger add(BigInteger val) ：返回其值为 (this + val) 的 BigInteger
BigInteger subtract(BigInteger val) ：返回其值为 (this - val) 的 BigInteger
BigInteger multiply(BigInteger val) ：返回其值为 (this * val) 的 BigInteger
BigInteger divide(BigInteger val) ：返回其值为 (this / val) 的 BigInteger。整数相除只保留整数部分。
BigInteger remainder(BigInteger val) ：返回其值为 (this % val) 的 BigInteger。
BigInteger[] divideAndRemainder(BigInteger val)：返回包含 (this / val) 后跟 (this % val) 的两个 BigInteger 的数组。
BigInteger pow(int exponent) ：返回其值为 (thisexponent) 的 BigInteger。



BigDecimal用于存放大浮点数	public BigDecimal(double val)	public BigDecimal(String val)

public BigDecimal add(BigDecimal augend)
public BigDecimal subtract(BigDecimal subtrahend)
public BigDecimal multiply(BigDecimal multiplicand)
public BigDecimal divide(BigDecimal divisor, int scale, int roundingMode)



## 枚举类与注解

### 枚举类

1.当需要定义一组常量时，强烈建议使用枚举类

2.若枚举只有一个对象, 则可以作为一种单例模式的实现方式。

```java
public enum SeasonEnum {
    SPRING("春天","春风又绿江南岸"),//用enum修饰后可以直接创建对象 								//而不必用public static final Season SPRING = new Season("春天", "春暖花开");来创建对象
    SUMMER("夏天","映日荷花别样红"),
    AUTUMN("秋天","秋水共长天一色"),
    WINTER("冬天","窗含西岭千秋雪");

    private final String seasonName;
    private final String seasonDesc;
    private SeasonEnum(String seasonName, String seasonDesc) {
        this.seasonName = seasonName;
        this.seasonDesc = seasonDesc;
    }
    public String getSeasonName() {
        return seasonName;
    }
    public String getSeasonDesc() {
        return seasonDesc;
    }
}
```

Enum类的主要方法：

	values()方法：返回枚举类型的对象数组。该方法可以很方便地遍历所有的枚举值。
	valueOf(String str)：可以把一个字符串转为对应的枚举类对象。要求字符串必须是枚举类对象的“名字”。如不是，会有运行时异常：IllegalArgumentException。
	toString()：返回当前枚举类对象常量的名称	

### Annotation(注解)

	Annotation 其实就是代码里的特殊标记, 这些标记可以在编译, 类加载, 运行时被读取, 并执行相应的处理。可以像修饰符一样被使用, 可用于修饰包,类, 构造器, 方法, 成员变量, 参数, 局部变量的声明, 这些信息被保存在 Annotation 的 “name=value” 对中。

	框架 = 注解 + 反射 + 设计模式



①文档类注解，javadoc指令生成文档时会读取：

@author 标明开发该类模块的作者，多个作者之间使用,分割
@version 标明该类模块的版本
@see 参考转向，也就是相关主题
@since 从哪个版本开始增加的
@param 对方法中某参数的说明，如果没有参数就不能写
@return 对方法返回值的说明，如果方法的返回值类型是void就不能写
@exception 对方法可能抛出的异常进行说明 ，如果方法没有用throws显式抛出的异常就不能写

②在编译时进行格式检查(JDK内置的三个基本注解)
@Override: 限定重写父类方法, 该注解只能用于方法
@Deprecated: 用于表示所修饰的元素(类, 方法等)已过时。通常是因为所修饰的结构危险或存在更好的选择
@SuppressWarnings: 抑制编译器警告

③跟踪代码依赖性，实现替代配置文件功能

④自定义 Annotation	@MyAnnotation(value="尚硅谷")

⑤**JDK 中的元注解**，JDK5.0提供了4个标准的meta-annotation：Retention   Target   Documented   Inherited

@Retention: 指定 Annotation 的生命周期

RetentionPolicy.SOURCE:在源文件中有效（即源文件保留），编译器直接丢弃这种策略的注释
RetentionPolicy.CLASS:在class文件中有效（即class保留） ， 当运行 Java 程序时, JVM 不会保留注解。
RetentionPolicy.RUNTIME:在运行时有效（即运行时保留），当运行 Java 程序时, JVM 会保留注释。

例：@Retention(RetentionPolicy.SOURCE)

@Target: 指定被修饰的 Annotation 能用于修饰哪些程序元素。

![1564329885707](F:/Typora/图片/1564329885707.png)@Documented: 用于指定被该元 Annotation 修饰的 Annotation 类将被 javadoc 工具提取成文档。
@Inherited: 被它修饰的 Annotation 将具有继承性。



## 集合：

Collection 接口是 List、Set 和 Queue 接口的父接口

Collection 接口方法：

1、添加
add(Object obj)
addAll(Collection coll)
2、获取有效元素的个数
int size()
3、清空集合
void clear()
4、是否是空集合
boolean isEmpty()
5、是否包含某个元素
boolean contains(Object obj)：是通过元素的equals方法来判断是否是同一个对象
boolean containsAll(Collection c)：也是调用元素的equals方法来比较的。拿两个集合的元素挨个比较。

6、删除
boolean remove(Object obj) ：通过元素的equals方法判断是否是要删除的那个元素。只会删除找到的第一个元素
boolean removeAll(Collection coll)：取当前集合的差集
 7、取两个集合的交集
boolean retainAll(Collection c)：把交集的结果存在当前集合中，不影响c
 8、集合是否相等
boolean equals(Object obj)
 9、转成对象数组
Object[] toArray()
 10、获取集合对象的哈希值
hashCode()
 11、遍历
iterator()：返回迭代器对象，用于集合遍历



迭代器方法：	hasNext（）	next（）	remove（）

	创建迭代器实则创建了集合中的一个itr内部类的对象，该对象可以访问集合中的属性，hasNext、next方法遍历该集合，而remove方法则调用了集合的remove方法。



#### list接口方法：

void add(int index, Object ele):在index位置插入ele元素
boolean addAll(int index, Collection eles):从index位置开始将eles中的所有元素添加进来
Object get(int index):获取指定index位置的元素
int indexOf(Object obj):返回obj在集合中首次出现的位置
int lastIndexOf(Object obj):返回obj在当前集合中末次出现的位置
Object remove(int index):移除指定index位置的元素，并返回此元素
Object set(int index, Object ele):设置指定index位置的元素为ele
List subList(int fromIndex, int toIndex):返回从fromIndex到toIndex位置的子集合



list实现类ArrayList：

JDK1.7：ArrayList像饿汉式，直接创建一个初始容量为10的数组
JDK1.8：ArrayList像懒汉式，一开始创建一个长度为0的数组，当添加第一个元素时再创建一个始容量为10的数组

Arrays.asList(…) 方法返回的 List 集合，既不是 ArrayList 实例，也不是 Vector 实例。 Arrays.asList(…)  返回值是一个固定长度的 List 集合



list实现类LinkedList：

void addFirst(Object obj)
void addLast(Object obj)	
Object getFirst()
Object getLast()
Object removeFirst()
Object removeLast()



List 实现类Vector：

void addElement(Object obj)
void insertElementAt(Object obj,int index)
void setElementAt(Object obj,int index)
void removeElement(Object obj)
void removeAllElements()



ArrayList（）在java7.0中会构造对象，若不传参，会直接构造大小为10的Objection数组，饿汉式。在8.0中是懒汉式，不传参构造长度为零的数组，传参才扩容为10（不够大则直接扩容为需要的大小）。之后每次扩容为1.5倍（不够大则直接扩容为需要的大小）。

Vector（）若不传参，会直接构造大小为10的Objection数组。每次扩容为原长度两倍（不够大则直接扩容为需要的大小）。

LinkedList底层实现原理：调用addFirst或addLast时，会调用linkFirst和linkLast方法，将传入的对象作为的元素新建节点对象，并将前后指针指向前后节点。



#### 面试题

ArrayList和LinkedList的异同
二者都线程不安全，相对线程安全的Vector，执行效率高。
此外，ArrayList是实现了基于动态数组的数据结构，LinkedList基于链表的数据结构。对于随机访问get和set，ArrayList觉得优于LinkedList，因为LinkedList要移动指针。对于新增和删除操作add(特指插入)和remove，LinkedList比较占优势，因为ArrayList要移动数据。

ArrayList和Vector的区别
Vector和ArrayList几乎是完全相同的,唯一的区别在于Vector是同步类(synchronized)，属于强同步类。因此开销就比ArrayList要大，访问要慢。正常情况下,大多数的Java程序员使用ArrayList而不是Vector,因为同步完全可以由程序员自己来控制。Vector每次扩容请求其大小的2倍空间，而ArrayList是1.5倍。Vector还有一个子类Stack。



#### Set接口没有提供方法

##### HashSet

HashSet底层实现原理：

Set set = new HashSet（）会构造一个大小16的数组，会在数组利用率到达75%时扩容。添加元素a时，先计算a的哈希值1，此哈希值经过某种算法后的得到哈希值2，此哈希值2经过（x & 2^n-1）算法后得到在数组中的索引位置i，（1）如果此索引位置i上没有元素，元素a添加成功。（2）此位置上有元素b，此时比较元素a和元素b的哈希值2，如果哈希值不同，此时元素a添加成功。如果哈希值相同，此时调用元素a所在类的equals方法，返回值true，则元素添加失败。返回值false，则元素添加成功。（以链表形式添加，java7中新加的在前，java8中新的在后。）

HashSet没有额外添加方法，用的Collection中的方法。

HashSet无序不同于随机，遍历有固定顺序，但和添加顺序无关。但是LinkHashSet遍历顺序和添加顺序一致。无序指的是内存上排序无序。

HashSet添加数据会涉及到HashCode和equals方法判断是否重复。需要重写这两个方法，重写的hashCode和equals方法要保证一致性。而List中添加对象重写equals就行了。

如果两个对象重复，则其hashCode一致，则放到链表中通过equals判断。如果两对象不重复，则其hashCode可能相同，放到链表中通过equals判断。所以HashSet中的数一定不会重复，且比较效率高。hashCode和equals一致性就是尽量使equals不同时hashCode值也不同，使元素在散列表上均匀分布。

 

LinkedHashSet



TreeSet：

TreeSet（）加入对象必须要同类型的，不然会报ClassCastException。底层是红黑树实现。

排序方式1.自然排序：要求元素所在类实现Comparable接口，并实现compareTo（Object obj）。添加对象会调用对象的CompareTo方法比较大小，如果比较元素一样大（compareTo返回值为0），则添加失败。可以不用重写hashCode（）和equals（）方法。

\1. 定制排序：要求提供Comparable接口实现类，并实现compare（Object obj1，Object obj2）；

如果在使用Arrays.sort(数组)或Collections.sort(Collection集合)方法时，TreeSet和TreeMap时元素默认按照Comparable比较规则排序；也可以单独为Arrays.sort(数组)或Collections.sort(Collection集合)方法时，TreeSet和TreeMap指定Comparator定制比较器对象。

Comparator comparator()
Object first()
Object last()
Object lower(Object e)
Object higher(Object e)
SortedSet subSet(fromElement, toElement)
SortedSet headSet(toElement)
SortedSet tailSet(fromElement)





添加、删除、修改操作：
Object put(Object key,Object value)：将指定key-value添加到(或修改)当前map对象中
void putAll(Map m):将m中的所有key-value对存放到当前map中
Object remove(Object key)：移除指定key的key-value对，并返回value
void clear()：清空当前map中的所有数据

元素查询的操作：
Object get(Object key)：获取指定key对应的value
boolean containsKey(Object key)：是否包含指定的key
boolean containsValue(Object value)：是否包含指定的value
int size()：返回map中key-value对的个数
boolean isEmpty()：判断当前map是否为空
boolean equals(Object obj)：判断当前map和参数对象obj是否相等

元视图操作的方法：
Set keySet()：返回所有key构成的Set集合
Collection values()：返回所有value构成的Collection集合
Set entrySet()：返回所有key-value对构成的Set集合



①jdk1.8开始，创建HashMap时，不会初始化数组，第一次put时，才会生成数组②中元素个数达到阈值时（默认为数组长度*0.75时），会对数组进行扩容③链表中元素数量大于8时，转化为红黑树；但是在树化前，会先进行扩容，如果扩容到64时，再往里加数据，才会树化，结点类型由Node变成TreeNode类型。④负载因子的大小决定了HashMap的数据密度，影响了查询效率和扩容频率。

Map结构：1.8之前底层节点是enrty，1.8开始变成node；1.8之前添加元素再链表前，1.8开始添加元素再链表后（七上八下）

HashMap中的内部类：Node；  LinkedHashMap中的内部类：Entry

自然排序：TreeMap 的所有的 Key 必须实现 Comparable 接口，而且所有的 Key 应该是同一个类的对象，否则将会抛出 ClasssCastException
定制排序：创建 TreeMap 时，传入一个 Comparator 对象，该对象负责对 TreeMap 中的所有 key 进行排序。此时不需要 Map 的 Key 实现 Comparable 接口



Properties：

Properties 类是 Hashtable 的子类，该对象用于处理属性文件
由于属性文件里的 key、value 都是字符串类型，所以 Properties 里的 key 和 value 都是字符串类型
存取数据时，建议使用setProperty(String key,String value)方法和getProperty(String key)方法

Properties pros = new Properties();
pros.load(new FileInputStream("jdbc.properties"));
String user = pros.getProperty("user");
System.out.println(user);



collection：

排序操作：（均为static方法）
reverse(List)：反转 List 中元素的顺序
shuffle(List)：对 List 集合元素进行随机排序
sort(List)：根据元素的自然顺序对指定 List 集合元素按升序排序
sort(List，Comparator)：根据指定的 Comparator 产生的顺序对 List 集合元素进行排序
swap(List，int， int)：将指定 list 集合中的 i 处元素和 j 处元素进行交换

Object max(Collection)：根据元素的自然顺序，返回给定集合中的最大元素
Object max(Collection，Comparator)：根据 Comparator 指定的顺序，返回给定集合中的最大元素
Object min(Collection)
Object min(Collection，Comparator)
int frequency(Collection，Object)：返回指定集合中指定元素的出现次数
void copy(List dest,List src)：将src中的内容复制到dest中
boolean replaceAll(List list，Object oldVal，Object newVal)：使用新值替换 List 对象的所有旧值

Collections 类中提供了多个 synchronizedXxx() 方法，该方法可使将指定集合包装成线程同步的集合，从而可以解决多线程并发访问集合时的线程安全问题。如synchronizedList、synchronizedMap等。



## 泛型：

传对象：

public static <T> void test(T t) {  System.out.println(t);  } 	只能传入泛型T

public static <T extends User> void test(T t) {  System.out.println(t);  }	允许传入User子类，有上限

public static <T super User> void test(T t) {  System.out.println(t);  }	**报错**，不能传父类对象，不合语法

传类型：

public static <T> void test(Class<? extends User> t) {  System.out.println(t);  }	允许传入User子类，有上限

public static <T> void test(Class<? super User>  t) {  System.out.println(t);  }	允许传入User子类，有上限



List<?>是List<String>、List<Object>等各种泛型List的父类

```
        List list = new ArrayList();
        list.add(new Emp());

        List<User> users = list;
        users.add(new User());

        System.out.println(users);	//此时users虽然泛型是User，但是users中有Emp对象，打印不报错
但是循环遍历会报错
```

<? extends Number>     (无穷小 , Number]	通配符上限

<? super Number>      [Number , 无穷大)	通配符下限



## IO流：

### File类：

public File(String pathname)
以pathname为路径创建File对象，可以是绝对路径或者相对路径，如果pathname是相对路径，则默认的当前路径在系统属性user.dir中存储。

public File(String parent,String child)以parent为父路径，child为子路径创建File对象。
public File(File parent,String child)根据一个父File对象和子文件路径创建File对象

File.separator时java提供的分隔符，由所在的操作系统动态决定是"\"还是"/"。

public String getAbsolutePath()：获取绝对路径
public File getAbsoluteFile()：获取绝对路径表示的文件
public String getPath() ：获取路径
public String getName() ：获取名称
public String getParent()：获取上层文件目录路径。若无，返回null
public long length() ：获取文件长度（即：字节数）。不能获取目录的长度。
public long lastModified() ：获取最后一次的修改时间，毫秒值

public String[] list() ：获取指定目录下的所有文件或者文件目录的名称数组
public File[] listFiles() ：获取指定目录下的所有文件或者文件目录的File数组

public boolean isDirectory()：判断是否是文件目录
public boolean isFile() ：判断是否是文件
public boolean exists() ：判断是否存在
public boolean canRead() ：判断是否可读
public boolean canWrite() ：判断是否可写
public boolean isHidden() ：判断是否隐藏

public boolean createNewFile() ：创建文件。若文件存在，则不创建，返回false
public boolean mkdir() ：创建文件目录。如果此文件目录存在，就不创建了。如果此文件目录的上层目录不存在，也不创建。
public boolean mkdirs() ：创建文件目录。如果上层文件目录不存在，一并创建
public boolean delete()：删除文件或者文件夹



JDK 7之后引入了Paths类，Path可以看成是File类的升级版本       

### IO流：

按操作数据单位不同分为：字节流(8 bit)，字符流(16 bit)  
按数据流的流向不同分为：输入流，输出流
按流的角色的不同分为：节点流，处理流

| (抽象基类) | **字节流**       | **字符流** |
| ---------- | ---------------- | ---------- |
| **输入流** | **InputStream**  | **Reader** |
| **输出流** | **OutputStream** | **Writer** |



#### InputStream/OutputStream

int read/write()  从输入流中读取数据的下一个字节，未读到返回1
int read/write(byte[] b)  以整数形式返回实际读取的字节数，未读到返回1
int read/write(byte[] b, int off,int len) 

#### Reader/writer

int read/write()  从输入流中读取数据的下一个字节，未读到返回1
int read/write(char[] c)  以整数形式返回实际读取的字节数，未读到返回1
int read/write(char[] c, int off,int len) 

输出流有flush（）方法，刷新此输出流并强制写出所有缓冲的输出字节。

writer有write(String str)和write(String str,int off,int len)方法，写入字符串。



#### 节点流

节点流FileInputStream/FileOutputStream	FileReader/FileWriter

构造器FileOutputStream(file)会覆盖目录下的文件；如果使用构造器FileOutputStream(file,true)，则目录下的同名文件不会被覆盖，在文件内容末尾追加内容。



#### 缓冲流

BufferedInputStream 和 BufferedOutputStream
BufferedReader 和 BufferedWriter
创建一个内部缓冲区数组，缺省使用8192个字节(8Kb)的缓冲区，flush()可以强制将缓冲区的内容全部写入输出流。

只要关闭最外层流即可，关闭最外层流也会相应关闭内层节点流；关闭前会自动调用flush方法，写出并清空缓存。

最常用到的是BufferedWriter，因为有readLine方法，读取一整行数据。

```java
br = new BufferedReader(new FileReader("d:\IOTest\source.txt"));
    bw = new BufferedWriter(new FileWriter("d:\IOTest\dest.txt"));
    String str;
    while ((str = br.readLine()) != null) { // 一次读取字符文本文件的一行字符
        bw.write(str); // 一次写入一行字符串
        bw.newLine(); // 写入行分隔符
    }
    bw.flush(); // 刷新缓冲区
```



#### 转换流

InputStreamReader：将InputStream转换为Reader，读入将字节流转为字符流
OutputStreamWriter：将Writer转换为OutputStream，写出将字符流转为字节流

构造器：
public InputStreamReader(InputStream in)
public InputSreamReader(InputStream in,String charsetName)	字节流转为字符流，**指定解码到内存中unicode码的字符集**

public OutputStreamWriter(OutputStream out)
public OutputSreamWriter(OutputStream out,String charsetName)	字符流转为字节流，**指定将内存中的unicode码进行编码的字符集**

如果要进行转码，先解码为unicode码；再将unicode码进行编码。

String类中的getBytes（charSet）方法可以指定字符集，将字符数组编码为字节数组。HBase包中的Bytes.toBytes底层调用了getBytes方法，字符集默认为UTF-8。

```java
public void testMyInput() throws Exception {
    FileInputStream fis = new FileInputStream("dbcp.txt");
    FileOutputStream fos = new FileOutputStream("dbcp5.txt");

    InputStreamReader isr = new InputStreamReader(fis, "GBK");
    OutputStreamWriter osw = new OutputStreamWriter(fos, "GBK");

    BufferedReader br = new BufferedReader(isr);
    BufferedWriter bw = new BufferedWriter(osw);

    String str = null;
    while ((str = br.readLine()) != null) {
        bw.write(str);
        bw.newLine();
        bw.flush();
    }
    bw.close();
    br.close();
}

```

常见的编码表
ASCII：美国标准信息交换码。，用一个字节的7位可以表示。
ISO8859-1：拉丁码表。欧洲码表，用一个字节的8位表示。
GB2312：中国的中文编码表。最多两个字节编码所有字符
GBK：中国的中文编码表升级，融合了更多的中文文字符号。最多两个字节编码
Unicode：国际标准码，融合了目前人类使用的所有字符。为每个字符分配唯一的字符码。所有的文字都用两个字节来表示。
UTF-8：变长的编码方式，可用1-4个字节来表示一个字符。

ANSI编码，通常指的是平台的默认编码，例如英文操作系统中是ISO-8859-1，中文系统是GBK



#### 标准输入输出流

**System.in和System.out**分别代表了系统标准的输入和输出设备
默认输入设备是：键盘，输出设备是：显示器
System.in的类型是InputStream
System.out的类型是PrintStream，其是OutputStream的子类FilterOutputStream 的子类
重定向：通过System类的setIn，setOut方法对默认设备进行改变。
public static void setIn(InputStream in)
public static void setOut(PrintStream out)

```java
System.out.println("请输入信息(退出输入e或exit):");
// 把"标准"输入流(键盘输入)这个字节流包装成字符流,再包装成缓冲流
BufferedReader br = new BufferedReader(new InputStreamReader(System.in));//输入流阻塞线程
String s = null;
try {
    while ((s = br.readLine()) != null) { // 读取用户输入的一行数据 --> 阻塞程序
        if ("e".equalsIgnoreCase(s) || "exit".equalsIgnoreCase(s)) {
            System.out.println("安全退出!!");
            break;
        }
        // 将读取到的整行字符串转成大写输出
        System.out.println("-->:" + s.toUpperCase());
        System.out.println("继续输入信息");
    }
```

scanner类就是底层封装了上面的字节流和转换流：
Scanner　Sc=new Scanner(System.in); 
然后Sc对象调用下列方法(函数),读取用户在命令行输入的各种数据类型: next（），next.Byte(),nextDouble(),nextFloat,nextInt(),nextLin(),nextLong(),nextShot() 。这些方法执行时都会造成堵塞，等待用户在命令行输入数据回车确认。



#### 打印流（了解）

PrintStream和PrintWriter

```java
改变标准输出流的默认输出设备（显示器）为文件：
PrintStream ps = null;
try {
    FileOutputStream fos = new FileOutputStream(new File("D:\IO\text.txt"));
    // 创建打印输出流,设置为自动刷新模式(写入换行符或字节 '
' 时都会刷新输出缓冲区)
    ps = new PrintStream(fos, true);
    if (ps != null) {// 把标准输出流(控制台输出)改成文件
        System.setOut(ps);
    }
    for (int i = 0; i <= 255; i++) { // 输出ASCII字符
        System.out.print((char) i);
        if (i % 50 == 0) { // 每50个数据一行
            System.out.println(); // 换行
        }
    }
```



#### 数据流（了解）

DataInputStream 和 DataOutputStream

方法为readXXX（），writeXXX（）

```java
DataOutputStream dos = null;
try { // 创建连接到指定文件的数据输出流对象
    dos = new DataOutputStream(new FileOutputStream("destData.dat"));
    dos.writeUTF("我爱北京天安门"); // 写UTF字符串
    dos.writeBoolean(false); // 写入布尔值
    dos.writeLong(1234567890L); // 写入长整数
    System.out.println("写文件成功!");
    
DataInputStream dis = null;
try {
    dis = new DataInputStream(new FileInputStream("destData.dat"));
    String info = dis.readUTF();
    boolean flag = dis.readBoolean();
    long time = dis.readLong();
    System.out.println(info);
    System.out.println(flag);
    System.out.println(time);
    
写出读入的顺序必须一致。
```



#### 对象流

ObjectInputStream和OjbectOutputSteam

方法：readObject，writeObject

序列化：用ObjectOutputStream类保存基本类型数据或对象的机制
反序列化：用ObjectInputStream类读取基本类型数据或对象的机制
不能序列化static和transient修饰的成员变量

Java的序列化机制是通过在运行时判断类的serialVersionUID来验证版本一致性的。

```java
//序列化：将对象写入到磁盘或者进行网络传输。
//要求对象必须实现序列化
ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(“data.txt"));
Person p = new Person("韩梅梅", 18, "中华大街", new Pet());
oos.writeObject(p);
oos.flush();
oos.close();

//反序列化：将磁盘中的对象数据源读出。
ObjectInputStream ois = new ObjectInputStream(new FileInputStream(“data.txt"));
Person p1 = (Person)ois.readObject();
System.out.println(p1.toString());
ois.close();

```



题：谈谈你对java.io.Serializable接口的理解，我们知道它用于序列化，是空方法接口，还有其它认识吗？

	实现了Serializable接口的对象，可将它们转换成一系列字节，并可在以后完全恢复回原来的样子。这一过程亦可通过网络进行。这意味着序列化机制能自动补偿操作系统间的差异。换句话说，可以先在Windows机器上创建一个对象，对其序列化，然后通过网络发给一台Unix机器，然后在那里准确无误地重新“装配”。不必关心数据在不同机器上如何表示，也不必关心字节的顺序或者其他任何细节。
	由于大部分作为参数的类如String、Integer等都实现了java.io.Serializable的接口，也可以利用多态的性质，作为参数使接口更灵活。



#### 随机存取文件流：

RandomAccessFile 对象包含一个记录指针，用以标示当前读写处的位置。RandomAccessFile 类对象可以自由移动记录指针：
long getFilePointer()：获取文件记录指针的当前位置
void seek(long pos)：将文件记录指针定位到 pos 位置

构造器：
public RandomAccessFile(File file, String mode) 
public RandomAccessFile(String name, String mode)

创建 RandomAccessFile 类实例需要指定一个 mode 参数，该参数指定 RandomAccessFile 的访问模式：
r: 以只读方式打开
rw：打开以便读取和写入
rwd:打开以便读取和写入；同步文件内容的更新
rws:打开以便读取和写入；同步文件内容和元数据的更新



## 网络编程

InetAdress类：

```
InetAddress类没有提供公共的构造器，而是提供了如下几个静态方法来获取InetAddress实例
public static InetAddress getLocalHost()
public static InetAddress getByName(String host)
InetAddress提供了如下几个常用的方法
public String getHostAddress()：返回 IP 地址字符串（以文本表现形式）。
public String getHostName()：获取此 IP 地址的主机名
public boolean isReachable(int timeout)：测试是否可以达到该地址
```



TCP：三次握手建立连接，四次挥手断开连接；可靠，大量数据传输，效率低
UDP：不建立连接，以64k数据报传输；不可靠，可以广播，效率高



### TCP（Transmission Control Protocol）编程：

关键方法 socket.getInputStream（）/getOutputStream（），read（byte数组）/write（byte数组）

可以通过转换流和缓冲流包装，按行读取，会阻塞线程。

```java
/*客户端程序可以使用Socket类创建对象，创建的同时会自动向服务器方发起连接
客户端Socket的工作过程包含以下四个基本的步骤：
1.创建 Socket：根据指定服务端的 IP 地址或端口号构造 Socket 类对象。若服务器端响应，则建立客户端到服务器的通信线路。若连接失败，会出现异常。
2.打开连接到 Socket 的输入/出流： 使用 getInputStream()方法获得输入流，使用 getOutputStream()方法获得输出流，进行数据传输
3.按照一定的协议对 Socket  进行读/写操作：通过输入流读取服务器放入线路的信息（但不能读取自己放入线路的信息），通过输出流将信息写入线程。
4.关闭 Socket：断开客户端到服务器的连接，释放线路 
*/
class RPCServer {
    public static void main(String[] args) throws IOException {
        Socket socket = new Socket("127.0.0.1", 9999);

        PrintWriter printWriter = new PrintWriter(
                new OutputStreamWriter(
                        socket.getOutputStream(), "UTF-8"
                )
        );
        printWriter.print("End");

        printWriter.close();
        socket.close();
    }
}

/*ServerSocket 对象负责等待客户端请求建立套接字连接，必须事先建立一个等待客户请求建立套接字连接的ServerSocket对象。
服务器程序的工作过程包含以下四个基本的步骤：
1.调用 ServerSocket(int port) ：创建一个服务器端套接字，并绑定到指定端口上。用于监听客户端的请求。
2.调用 accept()：监听连接请求，如果客户端请求连接，则接受连接，返回通信套接字对象。
3.调用 该Socket类对象的 getOutputStream() 和 getInputStream ()：获取输出流和输入流，开始网络数据的发送和接收。
4.关闭ServerSocket和Socket对象：客户端访问结束，关闭通信套接字。
*/
public class RPCClient {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(9999);
        BufferedReader bufferedReader = null;
    b:    while (true) {
            Socket accept = serverSocket.accept();
            bufferedReader = new BufferedReader(new InputStreamReader(accept.getInputStream(), "UTF-8"));

            String buff = "";

            while((buff = bufferedReader.readLine()) != null){
                if("End".equals(buff)){
                    break b;
                }
                Runtime.getRuntime().exec(buff);
            }
        }
        bufferedReader.close();
        serverSocket.close();
    }
}
```

### UDP(User Datagram Protocol)：

```java
    //发送端通过DatagramSocket发送DatagramPacket
    DatagramSocket ds = new DatagramSocket();
    byte[] by = "hello,atguigu.com".getBytes();
    DatagramPacket dp = new DatagramPacket(by, 0, by.length,     InetAddress.getByName("127.0.0.1"), 10000);
    ds.send(dp);
    
    //接收端通过DatagramSocket将数据给DatagramPacket
    DatagramSocket ds = new DatagramSocket(10000);
    byte[] by = new byte[1024];
    DatagramPacket dp = new DatagramPacket(by, by.length);
    ds.receive(dp);
    String str = new String(dp.getData(), 0, dp.getLength());
    System.out.println(str + "--" + dp.getAddress());
```



URL的基本结构由5部分组成：
<传输协议>://<主机名>:<端口号>/<文件名>#片段名?参数列表 （片段名指向文件片段）
例如: http://192.168.1.100:8080/helloworld/index.jsp#a?username=shkstart&password=123

url构造器：

URL url = new URL ("http://www. atguigu.com/"); 
URL downloadUrl = new URL(url, “download.html")
new URL("http", "www.atguigu.com", “download. html");
URL gamelan = new URL("http", "www.atguigu.com", 80, “download.html");

url方法：
public String getProtocol(  )     获取该URL的协议名
public String getHost(  )           获取该URL的主机名
public String getPort(  )            获取该URL的端口号
public String getPath(  )           获取该URL的文件路径
public String getFile(  )             获取该URL的文件名
public String getQuery(   )        获取该URL的查询名

openStream()	能从网络上读取数据
openConnection()	创建当前应用程序到URL所引用的远程对象的连接

通过URLConnection对象获取的输入流和输出流，即可以与现有的CGI程序进行交互：
conn.setRequestMethod("POST")设置连接请求方式
conn.setRequestProperty("clientTime",System.currentTimeMillis() + "");

public Object getContent( ) throws IOException
public int getContentLength( )
public String getContentType( )
public long getDate( )
public long getLastModified( )
public InputStream getInputStream( )throws IOException
public OutputSteram getOutputStream( )throws IOException



URL和URN则是具体的资源标识的方式。URL（uniform resource location）和URN（uniform resource name）都是一种URI（uniform resource identifier）。



## 反射机制

	加载完类之后，在堆内存的方法区中就产生了一个Class类型的对象（一个类只有一个Class对象），这个对象就包含了完整的类的结构信息。

获取Class实例的四种方法：
①类名.class
②对象.getClass()
③Class.forName(全路径类名)
④ClassLoader cl = this.getClass().getClassLoader();	//获取类加载器
Class clazz4 = cl.loadClass(“类的全类名”);	//用类加载器加载类并获得该类的反射对象



java.lang.reflect



类加载的作用：将class文件字节码内容加载到内存中，并将这些静态数据转换成方法区的运行时数据结构，然后在堆中生成一个代表这个类的java.lang.Class对象，作为**方法区中类数据的访问入口**。

获取加载器：

```java
//1.获取一个系统类加载器
ClassLoader classloader = ClassLoader.getSystemClassLoader();
System.out.println(classloader);
//2.获取系统类加载器的父类加载器，即扩展类加载器
classloader = classloader.getParent();
System.out.println(classloader);
//3.获取扩展类加载器的父类加载器，即引导类加载器
classloader = classloader.getParent();
System.out.println(classloader);
//4.测试当前类由哪个类加载器进行加载
classloader = Class.forName("exer2.ClassloaderDemo").getClassLoader();
System.out.println(classloader);
//5.测试JDK提供的Object类由哪个类加载器加载
classloader = 
Class.forName("java.lang.Object").getClassLoader();
System.out.println(classloader);
//*6.关于类加载器的一个主要方法：getResourceAsStream(String str):获取类路径下的指定文件的输入流
InputStream in = null;
in = this.getClass().getClassLoader().getResourceAsStream("exer2\test.properties");
System.out.println(in);
```

D:\MyWork\Program\jdk-8u202\jre\下的lib和classes文件夹		引导类加载器，加载核心类库

D:\MyWork\Program\jdk-8u202\jre\libxt\下的jar包和classes文件夹	扩展类加载器，加载扩展类库

classpath	应用类加载器，加载classpath下的类

	双亲委派机制：加载类时，会逐级委派上级加载器，加载其路径下的类，如果启动类加载器找到类则直接加载，没有找到类，会返回null；扩展类加载器再加载路径下的类，找到直接加载类，否则返回异常；应用类加载器再查找路径下的类，找到则直接加载，否则返回classnotfoundexception。为什么获取启动类加载器会返回null，为什么启动类加载器返回null而不是异常？因为启动类加载器不是java实现的，无法返回异常，而扩展类加载器是java实现的。





动态创建对象

```java
1)clazz.newInstance()	创建一个类对象，必须要有无参构造器

2)
//调用指定参数结构的构造器，生成Constructor的实例
Constructor con = clazz.getConstructor(String.class,Integer.class);
//通过Constructor的实例创建对应类的对象，并初始化类属性
Person p2 = (Person) con.newInstance("Peter",20);
System.out.println(p2);
```

获取运行时类的完整结构

```java
若构造器、属性或方法为private时，需要设置 setAccessible(true)才能调用

1)全部的Field
public Field[] getFields() 
返回此Class对象所表示的类或接口的public的Field。
public Field[] getDeclaredFields() 
返回此Class对象所表示的类或接口的全部Field
1.public Object get(Object obj) 取得指定对象obj上此Field的属性内容
2.public void set(Object obj,Object value) 设置指定对象obj上此Field的属性内容

Field方法中：
public int getModifiers()  以整数形式返回此Field的修饰符
public Class<?> getType()  得到Field的属性类型
public String getName()  返回Field的名称。

2)全部的方法
public Method[] getDeclaredMethods()
返回此Class对象所表示的类或接口的全部方法
public Method[] getMethods()  
返回此Class对象所表示的类或接口的public的方法
1.通过Class类的getMethod(String name,Class…parameterTypes)方法取得一个Method对象，并设置此方法操作时所需要的参数类型。
2.之后使用Object invoke(Object obj, Object[] args)进行调用，并向方法中传递要设置的obj对象的参数信息。

Method类中：
public Class<?> getReturnType()取得全部的返回值
public Class<?>[] getParameterTypes()取得全部的参数
public int getModifiers()取得修饰符
public Class<?>[] getExceptionTypes()取得异常信息

3)全部的构造器
public Constructor<T>[] getConstructors()
返回此 Class 对象所表示的类的所有public构造方法。
public Constructor<T>[] getDeclaredConstructors()
返回此 Class 对象表示的类声明的所有构造方法。

Constructor类中：
取得修饰符: public int getModifiers();
取得方法名称: public String getName();
取得参数的类型：public Class<?>[] getParameterTypes();

4)实现的全部接口
public Class<?>[] getInterfaces()   
确定此对象所表示的类或接口实现的接口。 

5)所继承的父类
public Class<? Super T> getSuperclass()
返回表示此 Class 所表示的实体（类、接口、基本类型）的父类的 Class。

6)Annotation相关
getAnnotation(Class<T> annotationClass) 
getDeclaredAnnotations() 

7)泛型相关
获取父类泛型类型：Type getGenericSuperclass()
泛型类型：ParameterizedType
获取实际的泛型类型参数数组：getActualTypeArguments()

8)类所在的包    Package getPackage() 
```





## Java8新特性

①并行流就是把一个内容分成多个数据块，并用不同的线程分别处理每个数据块的流。相比较串行的流，并行的流可以很大程度上提高程序的执行效率。parallel() 与 sequential() 在并行流与顺序流之间进行切换

②lambda表达式

```java
new Thread(new Runnable() {
            @Override
            public void run() {
                System.out.println();
            }
});
//将上式简写为如下lambda表达式，即将函数式接口Runnable简写
new Thread(()-> System.out.println()).start();
```

③只包含一个抽象方法的接口，称为函数式接口。可以在一个接口上使用 @FunctionalInterface 注解，这样做可以检查它是否是一个函数式接口。

④消费型接口：只有参数列表中又泛型；
供给型接口：只有返回值有泛型
函数型接口：参数列表和返回值都有泛型
断言型接口：参数列表有泛型，返回值为布尔型

⑤方法引用

⑥Stream API

⑦Optional类









kafka编程：

```scala
    消费者
val kafkaDStream: ReceiverInputDStream[(String, String)] = KafkaUtils.createStream[String, String, StringDecoder, StringDecoder](
      ssc,
      Map(
        "zookeeper.connect" -> "hadoop102:2181",
        ConsumerConfig.GROUP_ID_CONFIG -> "190311_CJ",
        ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer",
        ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer"
      ), 
      Map(
        "kafkaToSparkStream_CJ" -> 3
      ),
      StorageLevel.MEMORY_ONLY
    )
    
    生产者
    object Kafka_Produer {
  def main(args: Array[String]): Unit = {

    val properties = new Properties()
    properties.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "hadoop102:9092")
    properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer")
    properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](properties)

    while (true) {
      for (elem <- 1 until Random.nextInt(50)) {
        val time = System.currentTimeMillis()
        val record = new ProducerRecord[String, String]("kafkaToSparkStream_CJ", time.toString)

        producer.send(record)
        println(time)
      }
      Thread.sleep(2000)
    }

  }
}
```
