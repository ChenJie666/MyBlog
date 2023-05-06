---
title: JAVA开发手册节选
categories:
- 系统安全
---
#一、 编程规约
## (一) 命名风格
8. 【强制】POJO 类中的任何布尔类型的变量，都不要加 is 前缀，否则部分框架解析会引起序列
化错误。
说明：在本文 MySQL 规约中的建表约定第一条，表达是与否的值采用 is_xxx 的命名方式，所以，需要在
<resultMap>设置从 is_xxx 到 xxx 的映射关系。
反例：定义为基本数据类型 Boolean isDeleted 的属性，它的方法也是 isDeleted()，框架在反向解析的时候，“误以为”对应的属性名称是 deleted，导致属性获取不到，进而抛出异常。

13.【推荐】在常量与变量的命名时，表示类型的名词放在词尾，以提升辨识度。
正例：startTime / workQueue / nameList / TERMINATED_THREAD_COUNT
反例：startedAt / QueueOfWork / listName / COUNT_TERMINATED_THREAD

14.【推荐】如果模块、接口、类、方法使用了设计模式，在命名时需体现出具体模式。
说明：将设计模式体现在名字中，有利于阅读者快速理解架构设计理念。
正例： public class OrderFactory;
 public class LoginProxy;
 public class ResourceObserver;

18.【参考】各层命名规约：
A) Service/DAO 层方法命名规约
1） 获取单个对象的方法用 get 做前缀。
2） 获取多个对象的方法用 list 做前缀，复数结尾，如：listObjects。 3） 获取统计值的方法用 count 做前缀。 4） 插入的方法用 save/insert 做前缀。
5） 删除的方法用 remove/delete 做前缀。
6） 修改的方法用 update 做前缀。
B) 领域模型命名规约
1） 数据对象：xxxDO，xxx 即为数据表名。
2） 数据传输对象：xxxDTO，xxx 为业务领域相关的名称。
 3/57
Java 开发手册
 4/57
3） 展示对象：xxxVO，xxx 一般为网页名称。
4） POJO 是 DO/DTO/BO/VO 的统称，禁止命名成 xxxPOJO。

## (二) 常量定义
4. 【推荐】常量的复用层次有五层：跨应用共享常量、应用内共享常量、子工程内共享常量、包
内共享常量、类内共享常量。
1） 跨应用共享常量：放置在二方库中，通常是 client.jar 中的 constant 目录下。
2） 应用内共享常量：放置在一方库中，通常是子模块中的 constant 目录下。
反例：易懂变量也要统一定义成应用内共享常量，两位工程师在两个类中分别定义了“YES”的变量：
类 A 中：public static final String YES = "yes";
类 B 中：public static final String YES = "y";
A.YES.equals(B.YES)，预期是 true，但实际返回为 false，导致线上问题。
3） 子工程内部共享常量：即在当前子工程的 constant 目录下。
4） 包内共享常量：即在当前包下单独的 constant 目录下。
5） 类内共享常量：直接在类内部 private static final 定义。

## (四) OOP 规约
6. 【强制】Object 的 equals 方法容易抛空指针异常，应使用常量或确定有值的对象来调用 equals。
正例："test".equals(object);
反例：object.equals("test");
说明：推荐使用 java.util.Objects#equals（JDK7 引入的工具类）。
7. 【强制】所有整型包装类对象之间值的比较，全部使用 equals 方法比较。
说明：对于 Integer var = ? 在-128 至 127 之间的赋值，Integer 对象是在 IntegerCache.cache 产生，
会复用已有对象，这个区间内的 Integer 值可以直接使用==进行判断，但是这个区间之外的所有数据，都
会在堆上产生，并不会复用已有对象，这是一个大坑，推荐使用 equals 方法进行判断。 
Java 开发手册
 8/57
8. 【强制】任何货币金额，均以最小货币单位且整型类型来进行存储。

9. 【强制】浮点数之间的等值判断，基本数据类型不能用==来比较，包装数据类型不能用 equals
来判断。
说明：浮点数采用“尾数+阶码”的编码方式，类似于科学计数法的“有效数字+指数”的表示方式。二进
制无法精确表示大部分的十进制小数，具体原理参考《码出高效》。
反例：
float a = 1.0f - 0.9f;
float b = 0.9f - 0.8f;
if (a == b) {
 // 预期进入此代码快，执行其它业务逻辑
 // 但事实上 a==b 的结果为 false
}
Float x = Float.valueOf(a);
Float y = Float.valueOf(b);
if (x.equals(y)) {
 // 预期进入此代码快，执行其它业务逻辑
 // 但事实上 equals 的结果为 false
}
正例：
(1) 指定一个误差范围，两个浮点数的差值在此范围之内，则认为是相等的。
float a = 1.0f - 0.9f;
float b = 0.9f - 0.8f;
float diff = 1e-6f;
if (Math.abs(a - b) < diff) {
 System.out.println("true");
}
(2) 使用 BigDecimal 来定义值，再进行浮点数的运算操作。
BigDecimal a = new BigDecimal("1.0");
BigDecimal b = new BigDecimal("0.9");
BigDecimal c = new BigDecimal("0.8");
BigDecimal x = a.subtract(b);
BigDecimal y = b.subtract(c);
if (x.equals(y)) {
 System.out.println("true");
}

10.【强制】定义数据对象 DO 类时，属性类型要与数据库字段类型相匹配。
正例：数据库字段的 bigint 必须与类属性的 Long 类型相对应。
反例：某个案例的数据库表 id 字段定义类型 bigint unsigned，实际类对象属性为 Integer，随着 id 越来
越大，超过 Integer 的表示范围而溢出成为负数。

11.【强制】禁止使用构造方法 BigDecimal(double)的方式把 double 值转化为 BigDecimal 对象。
说明：BigDecimal(double)存在精度损失风险，在精确计算或值比较的场景中可能会导致业务逻辑异常。
Java 开发手册
如：BigDecimal g = new BigDecimal(0.1f); 实际的存储值为：0.10000000149
正例：优先推荐入参为 String 的构造方法，或使用 BigDecimal 的 valueOf 方法，此方法内部其实执行了
Double 的 toString，而 Double 的 toString 按 double 的实际能表达的精度对尾数进行了截断。
 BigDecimal recommend1 = new BigDecimal("0.1");
 BigDecimal recommend2 = BigDecimal.valueOf(0.1);

17.【强制】禁止在 POJO 类中，同时存在对应属性 xxx 的 isXxx()和 getXxx()方法。
说明：框架在调用属性 xxx 的提取方法时，并不能确定哪个方法一定是被优先调用到，神坑之一。

18.【推荐】使用索引访问用 String 的 split 方法得到的数组时，需做最后一个分隔符后有无内容
的检查，否则会有抛 IndexOutOfBoundsException 的风险。
说明：
String str = "a,b,c,,";
String[] ary = str.split(",");
// 预期大于 3，结果是 3
System.out.println(ary.length);

22.【推荐】循环体内，字符串的连接方式，使用 StringBuilder 的 append 方法进行扩展。
说明：下例中，反编译出的字节码文件显示每次循环都会 new 出一个 StringBuilder 对象，然后进行 append
操作，最后通过 toString 方法返回 String 对象，造成内存资源浪费。
反例：
String str = "start";
for (int i = 0; i < 100; i++) {
 str = str + "hello"; }

23.【推荐】final 可以声明类、成员变量、方法、以及本地变量，下列情况使用 final 关键字：
1） 不允许被继承的类，如：String 类。
2） 不允许修改引用的域对象，如：POJO 类的域变量。 3） 不允许被覆写的方法，如：POJO 类的 setter 方法。
4） 不允许运行过程中重新赋值的局部变量。
5） 避免上下文重复使用一个变量，使用 final 可以强制重新定义一个变量，方便更好地进行重构。

24.【推荐】慎用 Object 的 clone 方法来拷贝对象。
说明：对象 clone 方法默认是浅拷贝，若想实现深拷贝需覆写 clone 方法实现域对象的深度遍历式拷贝。

25.【推荐】类成员与方法访问控制从严：
1） 如果不允许外部直接通过 new 来创建对象，那么构造方法必须是 private。 2） 工具类不允许有 public 或 default 构造方法。
3） 类非 static 成员变量并且与子类共享，必须是 protected。 4） 类非 static 成员变量并且仅在本类使用，必须是 private。 5） 类 static 成员变量如果仅在本类使用，必须是 private。 6） 若是 static 成员变量，考虑是否为 final。7） 类成员方法只供类内部调用，必须是 private。 8） 类成员方法只对继承类公开，那么限制为 protected。
说明：任何类、方法、参数、变量，严控访问范围。过于宽泛的访问范围，不利于模块解耦。思考：如果
是一个 private 的方法，想删除就删除，可是一个 public 的 service 成员方法或成员变量，删除一下，不
得手心冒点汗吗？变量像自己的小孩，尽量在自己的视线内，变量作用域太大，无限制的到处跑，那么你
会担心的。

## (五) 日期时间
1. 【强制】日期格式化时，传入 pattern 中表示年份统一使用小写的 y。
说明：日期格式化时，yyyy 表示当天所在的年，而大写的 YYYY 代表是 week in which year（JDK7 之后
引入的概念），意思是当天所在的周属于的年份，一周从周日开始，周六结束，只要本周跨年，返回的 YYYY
就是下一年。
正例：表示日期和时间的格式如下所示：
new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
2. 【强制】在日期格式中分清楚大写的 M 和小写的 m，大写的 H 和小写的 h 分别指代的意义。
说明：日期格式中的这两对字母表意如下：
1） 表示月份是大写的 M； 2） 表示分钟则是小写的 m； 3） 24 小时制的是大写的 H； 4） 12 小时制的则是小写的 h。

3. 【强制】获取当前毫秒数：System.currentTimeMillis(); 而不是 new Date().getTime()。
说明：如果想获取更加精确的纳秒级时间值，使用 System.nanoTime 的方式。在 JDK8 中，针对统计时间
等场景，推荐使用 Instant 类。

4. 【强制】不允许在程序任何地方中使用：1）java.sql.Date 2）java.sql.Time 3）
java.sql.Timestamp。
说明：第 1 个不记录时间，getHours()抛出异常；第 2 个不记录日期，getYear()抛出异常；第 3 个在构造
方法 super((time/1000)*1000)，fastTime 和 nanos 分开存储秒和纳秒信息。
反例： java.util.Date.after(Date)进行时间比较时，当入参是 java.sql.Timestamp 时，会触发 JDK 
BUG(JDK9 已修复)，可能导致比较时的意外结果。

5. 【强制】不要在程序中写死一年为 365 天，避免在公历闰年时出现日期转换错误或程序逻辑
错误。
正例：
// 获取今年的天数
int daysOfThisYear = LocalDate.now().lengthOfYear();
// 获取指定某年的天数
LocalDate.of(2011, 1, 1).lengthOfYear();
反例：
// 第一种情况：在闰年 366 天时，出现数组越界异常
int[] dayArray = new int[365];
// 第二种情况：一年有效期的会员制，今年 1 月 26 日注册，硬编码 365 返回的却是 1 月 25 日
Calendar calendar = Calendar.getInstance();
calendar.set(2020, 1, 26);
calendar.add(Calendar.DATE, 365)

6. 【推荐】避免公历闰年 2 月问题。闰年的 2 月份有 29 天，一年后的那一天不可能是 2 月 29
日。

7. 【推荐】使用枚举值来指代月份。如果使用数字，注意 Date，Calendar 等日期相关类的月份
month 取值在 0-11 之间。
说明：参考 JDK 原生注释，Month value is 0-based. e.g., 0 for January.
正例： Calendar.JANUARY，Calendar.FEBRUARY，Calendar.MARCH 等来指代相应月份来进行传参或比较。

## (六) 集合处理
1. 【强制】关于 hashCode 和 equals 的处理，遵循如下规则：
1） 只要重写 equals，就必须重写 hashCode。 2） 因为 Set 存储的是不重复的对象，依据 hashCode 和 equals 进行判断，所以 Set 存储的对象必须重写
这两个方法。
3） 如果自定义对象作为 Map 的键，那么必须覆写 hashCode 和 equals。
说明：String 因为重写了 hashCode 和 equals 方法，所以我们可以愉快地使用 String 对象作为 key 来使
用。
2. 【强制】判断所有集合内部的元素是否为空，使用 isEmpty()方法，而不是 size()==0 的方式。
说明：前者的时间复杂度为 O(1)，而且可读性更好。
正例：
Map<String, Object> map = new HashMap<>();
if(map.isEmpty()) {
 System.out.println("no element in this map.");
}

3. 【强制】在使用 java.util.stream.Collectors 类的 toMap()方法转为 Map 集合时，一定要使
用含有参数类型为 BinaryOperator，参数名为 mergeFunction 的方法，否则当出现相同 key
值时会抛出 IllegalStateException 异常。
说明：参数 mergeFunction 的作用是当出现 key 重复时，自定义对 value 的处理策略。
正例：
List<Pair<String, Double>> pairArrayList = new ArrayList<>(3);
pairArrayList.add(new Pair<>("version", 6.19));
pairArrayList.add(new Pair<>("version", 10.24));
pairArrayList.add(new Pair<>("version", 13.14));
Map<String, Double> map = pairArrayList.stream().collect(
// 生成的 map 集合中只有一个键值对：{version=13.14}
Collectors.toMap(Pair::getKey, Pair::getValue, (v1, v2) -> v2));
反例：
String[] departments = new String[] {"iERP", "iERP", "EIBU"};
// 抛出 IllegalStateException 异常
Map<Integer, String> map = Arrays.stream(departments)
 .collect(Collectors.toMap(String::hashCode, str -> str));

4. 【强制】在使用 java.util.stream.Collectors 类的 toMap()方法转为 Map 集合时，一定要注
意当 value 为 null 时会抛 NPE 异常。
说明：在 java.util.HashMap 的 merge 方法里会进行如下的判断：
if (value == null || remappingFunction == null)
throw new NullPointerException();
反例：
List<Pair<String, Double>> pairArrayList = new ArrayList<>(2);
pairArrayList.add(new Pair<>("version1", 4.22));
pairArrayList.add(new Pair<>("version2", null));
Map<String, Double> map = pairArrayList.stream().collect(
// 抛出 NullPointerException 异常
Collectors.toMap(Pair::getKey, Pair::getValue, (v1, v2) -> v2));

5. 【强制】ArrayList 的 subList 结果不可强转成 ArrayList，否则会抛出 ClassCastException 异 常：java.util.RandomAccessSubList cannot be cast to java.util.ArrayList。
说明：subList 返回的是 ArrayList 的内部类 SubList，并不是 ArrayList 而是 ArrayList 的一个视图，对
于 SubList 子列表的所有操作最终会反映到原列表上。

6. 【强制】使用 Map 的方法 keySet()/values()/entrySet()返回集合对象时，不可以对其进行添
加元素操作，否则会抛出 UnsupportedOperationException 异常。

7. 【强制】Collections 类返回的对象，如：emptyList()/singletonList()等都是 immutable list，
不可对其进行添加或者删除元素的操作。
反例：如果查询无结果，返回 Collections.emptyList()空集合对象，调用方一旦进行了添加元素的操作，就
会触发 UnsupportedOperationException 异常。

8. 【强制】在 subList 场景中，高度注意对父集合元素的增加或删除，均会导致子列表的遍历、
增加、删除产生 ConcurrentModificationException 异常。

9. 【强制】使用集合转数组的方法，必须使用集合的 toArray(T[] array)，传入的是类型完全一
致、长度为 0 的空数组。
反例：直接使用 toArray 无参方法存在问题，此方法返回值只能是 Object[]类，若强转其它类型数组将出现
ClassCastException 错误。
正例：
List<String> list = new ArrayList<>(2);
list.add("guan");
list.add("bao");
String[] array = list.toArray(new String[0]);
 说明：使用 toArray 带参方法，数组空间大小的 length， 1） 等于 0，动态创建与 size 相同的数组，性能最好。
2） 大于 0 但小于 size，重新创建大小等于 size 的数组，增加 GC 负担。
3） 等于 size，在高并发情况下，数组创建完成之后，size 正在变大的情况下，负面影响与 2 相同。
4） 大于 size，空间浪费，且在 size 处插入 null 值，存在 NPE 隐患。

10.【强制】在使用 Collection 接口任何实现类的 addAll()方法时，都要对输入的集合参数进行
NPE 判断。
说明：在 ArrayList#addAll 方法的第一行代码即 Object[] a = c.toArray(); 其中 c 为输入集合参数，如果
为 null，则直接抛出异常。

11.【强制】使用工具类 Arrays.asList()把数组转换成集合时，不能使用其修改集合相关的方法，
它的 add/remove/clear 方法会抛出 UnsupportedOperationException 异常。
说明：asList 的返回对象是一个 Arrays 内部类，并没有实现集合的修改方法。Arrays.asList 体现的是适配
器模式，只是转换接口，后台的数据仍是数组。
 String[] str = new String[] { "yang", "hao" };
 List list = Arrays.asList(str);
第一种情况：list.add("yangguanbao"); 运行时异常。
第二种情况：str[0] = "changed"; 也会随之修改，反之亦然。

12.【强制】泛型通配符<? extends T>来接收返回的数据，此写法的泛型集合不能使用 add 方法， 而<? super T>不能使用 get 方法，两者在接口调用赋值的场景中容易出错。
说明：扩展说一下 PECS(Producer Extends Consumer Super)原则：第一、频繁往外读取内容的，适合用
<? extends T>。第二、经常往里插入的，适合用<? super T>

13.【强制】在无泛型限制定义的集合赋值给泛型限制的集合时，在使用集合元素时，需要进行
instanceof 判断，避免抛出 ClassCastException 异常。
说明：毕竟泛型是在 JDK5 后才出现，考虑到向前兼容，编译器是允许非泛型集合与泛型集合互相赋值。
反例：
List<String> generics = null;
List notGenerics = new ArrayList(10);
notGenerics.add(new Object());
notGenerics.add(new Integer(1));
generics = notGenerics;
// 此处抛出 ClassCastException 异常
String string = generics.get(0)

14.【强制】不要在 foreach 循环里进行元素的 remove/add 操作。remove 元素请使用 Iterator
方式，如果并发操作，需要对 Iterator 对象加锁。
正例：
List<String> list = new ArrayList<>();
list.add("1");
list.add("2");
Iterator<String> iterator = list.iterator();
while (iterator.hasNext()) {
 String item = iterator.next();
 if (删除元素的条件) {
 iterator.remove();
 } }
反例：
for (String item : list) {
 if ("1".equals(item)) {
 list.remove(item);
 } }
说明：以上代码的执行结果肯定会出乎大家的意料，那么试一下把“1”换成“2”，会是同样的结果吗？

15.【强制】在 JDK7 版本及以上，Comparator 实现类要满足如下三个条件，不然 Arrays.sort，
Collections.sort 会抛 IllegalArgumentException 异常。
说明：三个条件如下 1） x，y 的比较结果和 y，x 的比较结果相反。
2） x>y，y>z，则 x>z。 3） x=y，则 x，z 比较结果和 y，z 比较结果相同。
反例：下例中没有处理相等的情况，交换两个对象判断结果并不互反，不符合第一个条件，在实际使用中
可能会出现异常。
new Comparator<Student>() {
 @Override
 public int compare(Student o1, Student o2) {
 return o1.getId() > o2.getId() ? 1 : -1;
 }
};

17.【推荐】集合初始化时，指定集合初始值大小。
说明：HashMap 使用 HashMap(int initialCapacity) 初始化，如果暂时无法确定集合大小，那么指定默
认值（16）即可。
正例：`initialCapacity = (需要存储的元素个数 / 负载因子) + 1`。注意负载因子（即 loader factor）默认
为 0.75，如果暂时无法确定初始值大小，请设置为 16（即默认值）。
反例：HashMap 需要放置 1024 个元素，由于没有设置容量初始大小，随着元素不断增加，容量 7 次被迫
扩大，resize 需要重建 hash 表。当放置的集合元素个数达千万级别时，不断扩容会严重影响性能。

19.【推荐】高度注意 Map 类集合 K/V 能不能存储 null 值的情况，如下表格：
集合类 Key Value Super 说明
Hashtable 不允许为 null 不允许为 null Dictionary 线程安全
ConcurrentHashMap 不允许为 null 不允许为 null AbstractMap 锁分段技术（JDK8:CAS）
TreeMap 不允许为 null 允许为 null AbstractMap 线程不安全
HashMap 允许为 null 允许为 null AbstractMap 线程不安全
反例：由于 HashMap 的干扰，很多人认为 ConcurrentHashMap 是可以置入 null 值，而事实上，存储
null 值时会抛出 NPE 异常。

20.【参考】合理利用好集合的有序性(sort)和稳定性(order)，避免集合的无序性(unsort)和不稳
定性(unorder)带来的负面影响。
说明：有序性是指遍历的结果是按某种比较规则依次排列的。稳定性指集合每次遍历的元素次序是一定的。
如：ArrayList 是 order/unsort；HashMap 是 unorder/unsort；TreeSet 是 order/sort。

21.【参考】利用 Set 元素唯一的特性，可以快速对一个集合进行去重操作，避免使用 List 的
contains()进行遍历去重或者判断包含操作。



## (七) 并发处理
1. 【强制】获取单例对象需要保证线程安全，其中的方法也要保证线程安全。
说明：资源驱动类、工具类、单例工厂类都需要注意。

2. 【强制】创建线程或线程池时请指定有意义的线程名称，方便出错时回溯。
正例：自定义线程工厂，并且根据外部特征进行分组，比如，来自同一机房的调用，把机房编号赋值给whatFeaturOfGroup
```
public class UserThreadFactory implements ThreadFactory {
 private final String namePrefix;
 private final AtomicInteger nextId = new AtomicInteger(1);

 // 定义线程组名称，在 jstack 问题排查时，非常有帮助
 UserThreadFactory(String whatFeaturOfGroup) {
  namePrefix = "From UserThreadFactory's " + whatFeaturOfGroup + "-Worker-";
 }
 @Override
 public Thread newThread(Runnable task) {
  String name = namePrefix + nextId.getAndIncrement();
  Thread thread = new Thread(null, task, name, 0, false);
  System.out.println(thread.getName());
  return thread;
 }
}
```

3. 【强制】线程资源必须通过线程池提供，不允许在应用中自行显式创建线程。
说明：线程池的好处是减少在创建和销毁线程上所消耗的时间以及系统资源的开销，解决资源不足的问题。
如果不使用线程池，有可能造成系统创建大量同类线程而导致消耗完内存或者“过度切换”的问题。

4. 【强制】线程池不允许使用 Executors 去创建，而是通过 ThreadPoolExecutor 的方式，这
样的处理方式让写的同学更加明确线程池的运行规则，规避资源耗尽的风险。
说明：Executors 返回的线程池对象的弊端如下： 1） FixedThreadPool 和 SingleThreadPool：
允许的请求队列长度为 Integer.MAX_VALUE，可能会堆积大量的请求，从而导致 OOM。 2） CachedThreadPool：
允许的创建线程数量为 Integer.MAX_VALUE，可能会创建大量的线程，从而导致 OOM。

5. 【强制】SimpleDateFormat 是线程不安全的类，一般不要定义为 static 变量，如果定义为 static，
必须加锁，或者使用 DateUtils 工具类。
正例：注意线程安全，使用 DateUtils。亦推荐如下处理：
```
private static final ThreadLocal<DateFormat> df = new ThreadLocal<DateFormat>() {
 @Override
 protected DateFormat initialValue() {
  return new SimpleDateFormat("yyyy-MM-dd");
 }
};
```
>说明：如果是 JDK8 的应用，可以使用 Instant 代替 Date，LocalDateTime 代替 Calendar，`DateTimeFormatter` 代替 SimpleDateFormat，官方给出的解释：simple beautiful strong immutable 
thread-safe。

6. 【强制】必须回收自定义的 ThreadLocal 变量，尤其在线程池场景下，线程经常会被复用，
如果不清理自定义的 ThreadLocal 变量，可能会影响后续业务逻辑和造成内存泄露等问题。
尽量在代理中使用 try-finally 块进行回收。
正例：
```
objectThreadLocal.set(userInfo);
try {
 // ...
} finally {
 objectThreadLocal.remove();
}
```

7. 【强制】高并发时，同步调用应该去考量锁的性能损耗。能用无锁数据结构，就不要用锁；能锁区块，就不要锁整个方法体；能用对象锁，就不要用类锁。
说明：尽可能使加锁的代码块工作量尽可能的小，避免在锁代码块中调用 RPC 方法。

8. 【强制】对多个资源、数据库表、对象同时加锁时，需要保持一致的加锁顺序，否则可能会造
成死锁。
说明：线程一需要对表 A、B、C 依次全部加锁后才可以进行更新操作，那么线程二的加锁顺序也必须是 A、 B、C，否则可能出现死锁。

9. 【强制】在使用阻塞等待获取锁的方式中，必须在 try 代码块之外，并且在加锁方法与 try 代
码块之间没有任何可能抛出异常的方法调用，避免加锁成功后，在 finally 中无法解锁。
说明一：如果在 lock 方法与 try 代码块之间的方法调用抛出异常，那么无法解锁，造成其它线程无法成功
获取锁。
说明二：如果 lock 方法在 try 代码块之内，可能由于其它方法抛出异常，导致在 finally 代码块中，unlock
对未加锁的对象解锁，它会调用 AQS 的 tryRelease 方法（取决于具体实现类），抛出
IllegalMonitorStateException 异常。
说明三：在 Lock 对象的 lock 方法实现中可能抛出 unchecked 异常，产生的后果与说明二相同。
- 正例：
```
Lock lock = new XxxLock();
// ...
lock.lock();
try {
 doSomething();
 doOthers();
} finally {
 lock.unlock();
}
```
- 反例：
```
Lock lock = new XxxLock();
// ...
try {
 // 如果此处抛出异常，则直接执行 finally 代码块
 doSomething();
 // 无论加锁是否成功，finally 代码块都会执行
 lock.lock();
 doOthers();
} finally {
 lock.unlock();
}
```

10. 【强制】在使用尝试机制来获取锁的方式中，进入业务代码块之前，必须先判断当前线程是否
持有锁。锁的释放规则与锁的阻塞等待方式相同。
说明：Lock 对象的 unlock 方法在执行时，它会调用 AQS 的 tryRelease 方法（取决于具体实现类），如果
当前线程不持有锁，则抛出 IllegalMonitorStateException 异常。
正例：
```
Lock lock = new XxxLock();
// ...
boolean isLocked = lock.tryLock();
if (isLocked) {
 try {
 doSomething();
 doOthers();
 } finally {
 lock.unlock();
 } }
```

11.【强制】并发修改同一记录时，避免更新丢失，需要加锁。要么在应用层加锁，要么在缓存加锁，要么在数据库层使用乐观锁，使用 version 作为更新依据。
说明：如果每次访问冲突概率小于 20%，推荐使用乐观锁，否则使用悲观锁。乐观锁的重试次数不得小于3 次。

`12.【强制】多线程并行处理定时任务时，Timer 运行多个 TimeTask 时，只要其中之一没有捕获抛
出的异常，其它任务便会自动终止运行，使用 ScheduledExecutorService 则没有这个问题。`

13.【推荐】资金相关的金融敏感信息，使用悲观锁策略。
说明：乐观锁在获得锁的同时已经完成了更新操作，校验逻辑容易出现漏洞，另外，乐观锁对冲突的解决策
略有较复杂的要求，处理不当容易造成系统压力或数据异常，所以资金相关的金融敏感信息不建议使用乐观
锁更新。
正例：悲观锁遵循一锁二判三更新四释放的原则

14.【推荐】使用 CountDownLatch 进行异步转同步操作，每个线程退出前必须调用 countDown 方法，线程执行代码注意 catch 异常，确保 countDown 方法被执行到，避免主线程无法执行至await 方法，直到超时才返回结果。
说明：注意，子线程抛出异常堆栈，不能在主线程 try-catch 到。

15.【推荐】避免 Random 实例被多线程使用，虽然共享该实例是线程安全的，但会因竞争同一 seed 导致的性能下降。
说明：Random 实例包括 java.util.Random 的实例或者 Math.random()的方式。
正例：在 JDK7 之后，可以直接使用 API ThreadLocalRandom，而在 JDK7 之前，需要编码保证每个线程持有一个单独的 Random 实例。

16.【推荐】通过双重检查锁（double-checked locking）（在并发场景下）实现延迟初始化的优化
问题隐患(可参考 The "Double-Checked Locking is Broken" Declaration)，推荐解决方案中较为
简单一种（适用于 JDK5 及以上版本），将目标属性声明为 volatile 型（比如修改 helper 的属
性声明为`private volatile Helper helper = null;`）。
反例：
```
public class LazyInitDemo {
 private Helper helper = null;
 public Helper getHelper() {
 if (helper == null) {
 synchronized (this) {
 if (helper == null) { helper = new Helper(); }
 }
 }
 return helper;
 }
 // other methods and fields... 
}
```

`17.【参考】volatile 解决多线程内存不可见问题。对于一写多读，是可以解决变量同步问题，但
是如果多写，同样无法解决线程安全问题。
说明：如果是 count++操作，使用如下类实现：AtomicInteger count = new AtomicInteger(); 
count.addAndGet(1); 如果是 JDK8，推荐使用 LongAdder 对象，比 AtomicLong 性能更好（减少乐观锁的重试次数）。`

18.【参考】HashMap 在容量不够进行 resize 时由于高并发可能出现死链，导致 CPU 飙升，在
开发过程中注意规避此风险。

19.【参考】ThreadLocal 对象使用 static 修饰，ThreadLocal 无法解决共享对象的更新问题。
说明：这个变量是针对一个线程内所有操作共享的，所以设置为静态变量，所有此类实例共享此静态变量，
也就是说在类第一次被使用时装载，只分配一块存储空间，所有此类的对象(只要是这个线程内定义的)都可以操控这个变量。

## (八) 控制语句
2. 【强制】当 switch 括号内的变量类型为 String 并且此变量为外部参数时，必须先进行 null
判断。
反例：如下的代码输出是什么？
```
public class SwitchString {
 public static void main(String[] args) {
 method(null);
 }
 public static void method(String param) {
 switch (param) {
 // 肯定不是进入这里
 case "sth":
 System.out.println("it's sth");
 break;
 // 也不是进入这里
 case "null":
 System.out.println("it's null");
 break;
 // 也不是进入这里
 default:
 System.out.println("default");
 }
 } }
```
4. 【强制】三目运算符 condition? 表达式 1 : 表达式 2 中，高度注意表达式 1 和 2 在类型对齐时，可能抛出因自动拆箱导致的 NPE 异常。
说明：以下两种场景会触发类型对齐的拆箱操作：
1） 表达式 1 或表达式 2 的值只要有一个是原始类型。
2） 表达式 1 或表达式 2 的值的类型不一致，会强制拆箱升级成表示范围更大的那个类型。
反例：
Integer a = 1;
Integer b = 2;
Integer c = null;
Boolean flag = false;
// a*b 的结果是 int 类型，那么 c 会强制拆箱成 int 类型，抛出 NPE 异常
Integer result=(flag? a*b : c);
5. 【强制】在高并发场景中，避免使用”等于”判断作为中断或退出的条件。
说明：如果并发控制没有处理好，容易产生等值判断被“击穿”的情况，使用大于或小于的区间判断条件来代替。
反例：判断剩余奖品数量等于 0 时，终止发放奖品，但因为并发处理错误导致奖品数量瞬间变成了负数，
这样的话，活动无法终止。
6. 【推荐】当某个方法的代码行数超过 10 行时，return / throw 等中断逻辑的右大括号后加一个空行。
说明：这样做逻辑清晰，有利于代码阅读时重点关注。
7. 【推荐】表达异常的分支时，少用 if-else 方式，这种方式可以改写成：
if (condition) { 
 ...
 return obj; }
// 接着写 else 的业务逻辑代码; 
说明：如果非使用 if()...else if()...else...方式表达逻辑，避免后续代码维护困难，请勿超过 3 层。
正例：超过 3 层的 if-else 的逻辑判断代码可以使用卫语句、策略模式、状态模式等来实现，其中卫语句
示例如下：
public void findBoyfriend (Man man){
 if (man.isUgly()) {
 System.out.println("本姑娘是外貌协会的资深会员");
 return;
 }
 if (man.isPoor()) {
 System.out.println("贫贱夫妻百事哀");
 return;
 }
 if (man.isBadTemper()) {
 System.out.println("银河有多远，你就给我滚多远");
 return; }
 System.out.println("可以先交往一段时间看看");
}

12.【推荐】接口入参保护，这种场景常见的是用作批量操作的接口。
反例：某业务系统，提供一个用户批量查询的接口，API 文档上有说最多查多少个，但接口实现上没做任何
保护，导致调用方传了一个 1000 的用户 id 数组过来后，查询信息后，内存爆了。

13.【参考】下列情形，需要进行参数校验： 1） 调用频次低的方法。
2） 执行时间开销很大的方法。此情形中，参数校验时间几乎可以忽略不计，但如果因为参数错误导致 
中间执行回退，或者错误，那得不偿失。
3） 需要极高稳定性和可用性的方法。
4） 对外提供的开放接口，不管是 RPC/API/HTTP 接口。
5） 敏感权限入口。

14.【参考】下列情形，不需要进行参数校验： 1） 极有可能被循环调用的方法。但在方法说明里必须注明外部参数检查。
2） 底层调用频度比较高的方法。毕竟是像纯净水过滤的最后一道，参数错误不太可能到底层才会暴露
问题。一般 DAO 层与 Service 层都在同一个应用中，部署在同一台服务器中，所以 DAO 的参数校验，可
以省略。
3） 被声明成 private 只会被自己代码所调用的方法，如果能够确定调用方法的代码传入参数已经做过检
查或者肯定不会有问题，此时可以不校验参数。

##(九) 注释规约
1. 【强制】类、类属性、类方法的注释必须使用 Javadoc 规范，使用/**内容*/格式，不得使用
// xxx 方式。
说明：在 IDE 编辑窗口中，Javadoc 方式会提示相关注释，生成 Javadoc 可以正确输出相应注释；在 IDE
中，工程调用方法时，不进入方法即可悬浮提示方法、参数、返回值的意义，提高阅读效率。
5. 【强制】所有的枚举类型字段必须要有注释，说明每个数据项的用途。

9. 【参考】谨慎注释掉代码。在上方详细说明，而不是简单地注释掉。如果无用，则删除。
说明：代码被注释掉有两种可能性：1）后续会恢复此段代码逻辑。2）永久不用。前者如果没有备注信息，
难以知晓注释动机。后者建议直接删掉即可，假如需要查阅历史代码，登录代码仓库即可。
12.【参考】特殊注释标记，请注明标记人与标记时间。注意及时处理这些标记，通过标记扫描，
经常清理此类标记。线上故障有时候就是来源于这些标记处的代码。
1） 待办事宜（TODO）:（标记人，标记时间，[预计处理时间]）
表示需要实现，但目前还未实现的功能。这实际上是一个 Javadoc 的标签，目前的 Javadoc 还没有实现，但已经被广泛使用。只能应用于类，接口和方法（因为它是一个 Javadoc 标签）。
2） 错误，不能工作（FIXME）:（标记人，标记时间，[预计处理时间]）
在注释中用 FIXME 标记某代码是错误的，而且不能工作，需要及时纠正的情况。

##(十) 其它
1. 【强制】在使用正则表达式时，利用好其预编译功能，可以有效加快正则匹配速度。
说明：不要在方法体内定义：Pattern pattern = Pattern.compile(“规则”);
正确：
```
private static final Pattern pattern = Pattern.compile(regexRule);
 
private void func(...) {
    Matcher m = pattern.matcher(content);
    if (m.matches()) {
        ...
    }
}
```
2. 【强制】避免用 Apache Beanutils 进行属性的 copy。
说明：Apache BeanUtils 性能较差，可以使用其他方案比如 Spring BeanUtils, Cglib BeanCopier，注意
均是浅拷贝。
3. 【强制】velocity 调用 POJO 类的属性时，直接使用属性名取值即可，模板引擎会自动按规范
调用 POJO 的 getXxx()，如果是 boolean 基本数据类型变量（boolean 命名不需要加 is 前缀），
会自动调用 isXxx()方法。
说明：注意如果是 Boolean 包装类对象，优先调用 getXxx()的方法。

`4. 【强制】后台输送给页面的变量必须加$!{var}——中间的感叹号。
说明：如果 var 等于 null 或者不存在，那么${var}会直接显示在页面上。`

5. 【强制】注意 Math.random() 这个方法返回是 double 类型，注意取值的范围 0≤x<1（能够
取到零值，注意除零异常），如果想获取整数类型的随机数，不要将 x 放大 10 的若干倍然后
取整，直接使用 Random 对象的 nextInt 或者 nextLong 方法。

`6. 【推荐】不要在视图模板中加入任何复杂的逻辑。
说明：根据 MVC 理论，视图的职责是展示，不要抢模型和控制器的活。`

7. 【推荐】任何数据结构的构造或初始化，都应指定大小，避免数据结构无限增长吃光内存。

8. 【推荐】及时清理不再使用的代码段或配置信息。
说明：对于垃圾代码或过时配置，坚决清理干净，避免程序过度臃肿，代码冗余。
正例：对于暂时被注释掉，后续可能恢复使用的代码片断，在注释代码上方，统一规定使用三个斜杠(///)
来说明注释掉代码的理由。如：
 public static void hello() {
 /// 业务方通知活动暂停
 // Business business = new Business();
 // business.active();
 System.out.println("it's finished");
}

#二、异常日志
##(一) 错误码
3. 【强制】全部正常，但不得不填充错误码时返回五个零：00000。

4. 【强制】错误码为字符串类型，共 5 位，分成两个部分：错误产生来源+四位数字编号。
说明：错误产生来源分为 A/B/C，A 表示错误来源于用户，比如参数错误，用户安装版本过低，用户支付
超时等问题；B 表示错误来源于当前系统，往往是业务逻辑出错，或程序健壮性差等问题；C 表示错误来源
于第三方服务，比如 CDN 服务出错，消息投递超时等问题；四位数字编号从 0001 到 9999，大类之间的
步长间距预留 100，参考文末附表 3。

5. 【强制】编号不与公司业务架构，更不与组织架构挂钩，一切与平台先到先申请的原则进行，
审批生效，编号即被永久固定。

7. 【强制】错误码不能直接输出给用户作为提示信息使用。
说明：堆栈（stack_trace）、错误信息(error_message)、错误码（error_code）、提示信息（user_tip）
是一个有效关联并互相转义的和谐整体，但是请勿互相越俎代庖。

9. 【推荐】在获取第三方服务错误码时，向上抛出允许本系统转义，由 C 转为 B，并且在错误信
息上带上原有的第三方错误码。

10.【参考】错误码分为一级宏观错误码、二级宏观错误码、三级宏观错误码。
说明：在无法更加具体确定的错误场景中，可以直接使用一级宏观错误码，分别是：A0001（用户端错误）、B0001（系统执行出错）、C0001（调用第三方服务出错）。
正例：调用第三方服务出错是一级，中间件错误是二级，消息服务出错是三级。

13.【参考】错误码即人性，感性认知+口口相传，使用纯数字来进行错误码编排不利于感性记忆
和分类。
说明：数字是一个整体，每位数字的地位和含义是相同的。 反例：一个五位数字 12345，第 1 位是错误等级，第 2 位是错误来源，345 是编号，人的大脑不会主动地
分辨每位数字的不同含义。

##(二) 异常处理
1. 【强制】Java 类库中定义的可以通过预检查方式规避的 RuntimeException 异常不应该通过
catch 的方式来处理，比如：NullPointerException，IndexOutOfBoundsException 等等。
说明：无法通过预检查的异常除外，比如，在解析字符串形式的数字时，可能存在数字格式错误，不得不
通过 catch NumberFormatException 来实现。
正例：if (obj != null) {...}
反例：try { obj.method(); } catch (NullPointerException e) {…}

2. 【强制】异常不要用来做流程控制，条件控制。
说明：异常设计的初衷是解决程序运行中的各种意外情况，且异常的处理效率比条件判断方式要低很多。

3. 【强制】catch 时请分清稳定代码和非稳定代码，稳定代码指的是无论如何不会出错的代码。
对于非稳定代码的 catch 尽可能进行区分异常类型，再做对应的异常处理。
说明：对大段代码进行 try-catch，使程序无法根据不同的异常做出正确的应激反应，也不利于定位问题，
这是一种不负责任的表现。
正例：用户注册的场景中，如果用户输入非法字符，或用户名称已存在，或用户输入密码过于简单，在程
序上作出分门别类的判断，并提示给用户。

5. 【强制】事务场景中，抛出异常被 catch 后，如果需要回滚，一定要注意手动回滚事务。

`6. 【强制】finally 块必须对资源对象、流对象进行关闭，有异常也要做 try-catch。
说明：如果 JDK7 及以上，可以使用 try-with-resources 方式。`

7. 【强制】不要在 finally 块中使用 return。
说明：try 块中的 return 语句执行成功后，并不马上返回，而是继续执行 finally 块中的语句，如果此处存
在 return 语句，则在此直接返回，无情丢弃掉 try 块中的返回点。
反例：
private int x = 0;
public int checkReturn() {
 try {
 // x 等于 1，此处不返回
 return ++x;
 } finally {
 // 返回的结果是 2
 return ++x;
 } }

9. 【强制】在调用 RPC、二方包、或动态生成类的相关方法时，捕捉异常必须使用 Throwable
类来进行拦截。
说明：通过反射机制来调用方法，如果找不到方法，抛出 NoSuchMethodException。什么情况会抛出
NoSuchMethodError 呢？二方包在类冲突时，仲裁机制可能导致引入非预期的版本使类的方法签名不匹配，
或者在字节码修改框架（比如：ASM）动态创建或修改类时，修改了相应的方法签名。这些情况，即使代
码编译期是正确的，但在代码运行期时，会抛出 NoSuchMethodError。
10.【推荐】方法的返回值可以为 null，不强制返回空集合，或者空对象等，必须添加注释充分说
明什么情况下会返回 null 值。
说明：本手册明确防止 NPE 是调用者的责任。即使被调用方法返回空集合或者空对象，对调用者来说，也
并非高枕无忧，必须考虑到远程调用失败、序列化失败、运行时异常等场景返回 null 的情况。
11.【推荐】防止 NPE，是程序员的基本修养，注意 NPE 产生的场景：
1） 返回类型为基本数据类型，return 包装数据类型的对象时，自动拆箱有可能产生 NPE。
 反例：public int f() { return Integer 对象}， 如果为 null，自动解箱抛 NPE。 2） 数据库的查询结果可能为 null。 3） 集合里的元素即使 isNotEmpty，取出的数据元素也可能为 null。 4） 远程调用返回对象时，一律要求进行空指针判断，防止 NPE。 5） 对于 Session 中获取的数据，建议进行 NPE 检查，避免空指针。6） 级联调用 obj.getA().getB().getC()；一连串调用，易产生 NPE。
正例：使用 JDK8 的 Optional 类来防止 NPE 问题。

12.【推荐】定义时区分 unchecked / checked 异常，避免直接抛出 new RuntimeException()，
更不允许抛出 Exception 或者 Throwable，应使用有业务含义的自定义异常。推荐业界已定
义过的自定义异常，如：DAOException / ServiceException 等。

13.【参考】对于公司外的 http/api 开放接口必须使用“错误码”；而应用内部推荐异常抛出；
跨应用间 RPC 调用优先考虑使用 Result 方式，封装 isSuccess()方法、“错误码”、“错误
简短信息”；而应用内部推荐异常抛出。
说明：关于 RPC 方法返回方式使用 Result 方式的理由：
1）使用抛异常返回方式，调用方如果没有捕获到就会产生运行时错误。
2）如果不加栈信息，只是 new 自定义异常，加入自己的理解的 error message，对于调用端解决问题
的帮助不会太多。如果加了栈信息，在频繁调用出错的情况下，数据序列化和传输的性能损耗也是问题。
14.【参考】避免出现重复的代码（Don't Repeat Yourself），即 DRY 原则。
说明：随意复制和粘贴代码，必然会导致代码的重复，在以后需要修改时，需要修改所有的副本，容易遗漏。
必要时抽取共性方法，或者抽象公共类，甚至是组件化。
正例：一个类中有多个 public 方法，都需要进行数行相同的参数校验操作，这个时候请抽取：
private boolean checkParam(DTO dto) {...}

##(三) 日志规约
1. 【强制】应用中不可直接使用日志系统（Log4j、Logback）中的 API，而应依赖使用日志框架
（SLF4J、JCL--Jakarta Commons Logging）中的 API，使用门面模式的日志框架，有利于维护和
各个类的日志处理方式统一。
说明：日志框架（SLF4J、JCL--Jakarta Commons Logging）的使用方式（推荐使用 SLF4J）
 使用 SLF4J：
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
private static final Logger logger = LoggerFactory.getLogger(Test.class);
使用 JCL：
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
private static final Log log = LogFactory.getLog(Test.class);

2. 【强制】所有日志文件至少保存 15 天，因为有些异常具备以“周”为频次发生的特点。对于
当天日志，以“应用名.log”来保存，保存在/home/admin/应用名/logs/</font>目录下，
过往日志格式为: {logname}.log.{保存日期}，日期格式：yyyy-MM-dd
说明：以 mppserver 应用为例，日志保存在/home/admin/mppserver/logs/mppserver.log，历史日志
名称为 mppserver.log.2016-08-01
3. 【强制】应用中的扩展日志（如打点、临时监控、访问日志等）命名方式：
appName_logType_logName.log。logType:日志类型，如 stats/monitor/access 等；logName:日志描
Java 开发手册
 31/57
述。这种命名的好处：通过文件名就可知道日志文件属于什么应用，什么类型，什么目的，也有利于归类查
找。
说明：推荐对日志进行分类，如将错误日志和业务日志分开存放，便于开发人员查看，也便于通过日志对系
统进行及时监控。
正例：mppserver 应用中单独监控时区转换异常，如：mppserver_monitor_timeZoneConvert.log

4. 【强制】在日志输出时，字符串变量之间的拼接使用占位符的方式。
说明：因为 String 字符串的拼接会使用 StringBuilder 的 append()方式，有一定的性能损耗。使用占位符仅
是替换动作，可以有效提升性能。
正例：logger.debug("Processing trade with id: {} and symbol: {}", id, symbol);

`5. 【强制】对于 trace/debug/info 级别的日志输出，必须进行日志级别的开关判断。
说明：虽然在 debug(参数)的方法体内第一行代码 isDisabled(Level.DEBUG_INT)为真时（Slf4j 的常见实现
Log4j 和 Logback），就直接 return，但是参数可能会进行字符串拼接运算。此外，如果 debug(getName())
这种参数内有 getName()方法调用，无谓浪费方法调用的开销。
正例：
// 如果判断为真，那么可以输出 trace 和 debug 级别的日志
if (logger.isDebugEnabled()) {
 logger.debug("Current ID is: {} and name is: {}", id, getName());
}`

6. 【强制】避免重复打印日志，浪费磁盘空间，务必在 log4j.xml 中设置 additivity=false。
正例：<logger name="com.taobao.dubbo.config" additivity="false">

7. 【强制】生产环境禁止直接使用 System.out 或 System.err 输出日志或使用e.printStackTrace()打印异常堆栈。
说明：标准日志输出与标准错误输出文件每次 Jboss 重启时才滚动，如果大量输出送往这两个文件，容易
造成文件大小超过操作系统大小限制。

8. 【强制】异常信息应该包括两类信息：案发现场信息和异常堆栈信息。如果不处理，那么通过
关键字 throws 往上抛出。
正例：logger.error(各类参数或者对象 toString() + "_" + e.getMessage(), e);

9. 【强制】日志打印时禁止直接用 JSON 工具将对象转换成 String。
说明：如果对象里某些 get 方法被重写，存在抛出异常的情况，则可能会因为打印日志而影响正常业务流
程的执行。
正例：打印日志时仅打印出业务相关属性值或者调用其对象的 toString()方法。

10.【推荐】谨慎地记录日志。生产环境禁止输出 debug 日志；有选择地输出 info 日志；如果使用
warn 来记录刚上线时的业务行为信息，一定要注意日志输出量的问题，避免把服务器磁盘撑
爆，并记得及时删除这些观察日志。
说明：大量地输出无效日志，不利于系统性能提升，也不利于快速定位错误点。记录日志时请思考：这些
日志真的有人看吗？看到这条日志你能做什么？能不能给问题排查带来好处？

11.【推荐】可以使用 warn 日志级别来记录用户输入参数错误的情况，避免用户投诉时，无所适
从。如非必要，请不要在此场景打出 error 级别，避免频繁报警。
说明：注意日志输出的级别，error 级别只记录系统逻辑出错、异常或者重要的错误信息。
12.【推荐】尽量用英文来描述日志错误信息，如果日志中的错误信息用英文描述不清楚的话使用
中文描述即可，否则容易产生歧义。
说明：国际化团队或海外部署的服务器由于字符集问题，使用全英文来注释和描述日志错误信息。

#三、单元测试
