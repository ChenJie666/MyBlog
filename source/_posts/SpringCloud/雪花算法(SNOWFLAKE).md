---
title: 雪花算法(SNOWFLAKE)
categories:
- SpringCloud
---
SnowFlake 算法，是 Twitter 开源的分布式 id 生成算法。其核心思想就是：使用一个 64 bit 的 long 型的数字作为全局唯一 id。在分布式系统中的应用十分广泛，且ID 引入了时间戳，基本上保持自增的，后面的代码中有详细的注解。

**对比UUID和自增主键**
UUID无序且长度过长，自增主键无法保证分库分表情况下的自增。所以使用雪花算法，保证了自增和高效。


**基本结构**
这 64 个 bit 中（转为十进制位数为18-19位），其中 1 个 bit 是不用的，然后用其中的 41 bit 作为毫秒数，用 10 bit 作为工作机器 id，12 bit 作为序列号。
- 第一个部分，是 1 个 bit：0，这个是无意义的。
- 第二个部分是 41 个 bit：表示的是时间戳。41 bit 可以表示的数字多达 2^41 - 1，也就是可以标识 2 ^ 41 - 1 个毫秒值，换算成年就是表示 69 年的时间。
- 第三个部分是 5 个 bit：表示的是机房 id，10001。最多代表 2 ^ 5 个机房（32 个机房）
- 第四个部分是 5 个 bit：表示的是机器 id，1 1001。每个机房里可以代表 2 ^ 5 个机器（32 台机器）
- 第五个部分是 12 个 bit：表示的序号，就是某个机房某台机器上这一毫秒内同时生成的 id 的序号，0000 00000000。12 bit 可以代表的最大正整数是 2 ^ 12 - 1 = 4096，也就是说可以用这个 12 bit 代表的数字来区分同一个毫秒内的 4096 个不同的 id。

结论：这个算法可以保证，一个机房的一台机器上，在同一毫秒内，生成了一个唯一的 id。可能一个毫秒内会生成多个 id，但是有最后 12 个 bit 的序号来区分开来。

**SnowFlake算法的优点：**
（1）高性能高可用：生成时不依赖于数据库，完全在内存中生成。
（2）容量大：每秒中能生成数百万的自增ID。理论上雪花算法方案的QPS约为409.6w/s。
（3）ID自增：存入数据库中，索引效率高。

**SnowFlake算法的缺点：**
依赖与系统时间的一致性，如果系统时间被回调，或者改变，可能会造成id冲突或者重复。

**解决方案：**
方案一是发现时钟回拨后，算出来回拨多少，保存为时间偏移量，然后后面每次获取时间戳都加上偏移量，每回拨一次更新一次偏移量
方案二是，只在第一次生成id或启动时获取时间戳并保存下来，每生成一个id，就计下数，每个毫秒数能生成的id数是固定的，到生成满了，再把时间戳加一，这样就不依赖于系统时间了，每个毫秒数的使用率也最高


**代码**
```
public class SnowFlake {

 /**
  * 起始的时间戳（可设置当前时间之前的邻近时间）
  */
 private final static long START_STAMP = 1480166465631L;

 /**
  * 序列号占用的位数
  */
 private final static long SEQUENCE_BIT = 12;
 /**
  * 机器标识占用的位数
  */
 private final static long MACHINE_BIT = 5;
 /**
  * 数据中心占用的位数
  */
 private final static long DATA_CENTER_BIT = 5;

 /**
  * 每一部分的最大值
  */
 private final static long MAX_DATA_CENTER_NUM = ~(-1L << DATA_CENTER_BIT);
 private final static long MAX_MACHINE_NUM = ~(-1L << MACHINE_BIT);
 private final static long MAX_SEQUENCE = ~(-1L << SEQUENCE_BIT);

 /**
  * 每一部分向左的位移
  */
 private final static long MACHINE_LEFT = SEQUENCE_BIT;
 private final static long DATA_CENTER_LEFT = SEQUENCE_BIT + MACHINE_BIT;
 private final static long TIMESTAMP_LEFT = DATA_CENTER_LEFT + DATA_CENTER_BIT;

 /**
  * 数据中心ID(0~31)
  */
 private final long dataCenterId;
 /**
  * 工作机器ID(0~31)
  */
 private final long machineId;
 /**
  * 毫秒内序列(0~4095)
  */
 private long sequence = 0L;
 /**
  * 上次生成ID的时间截
  */
 private long lastStamp = -1L;

 public SnowFlake(long dataCenterId, long machineId) {
  if (dataCenterId > MAX_DATA_CENTER_NUM || dataCenterId < 0) {
   throw new IllegalArgumentException("dataCenterId can't be greater than MAX_DATA_CENTER_NUM or less than " +
     "0");
  }
  if (machineId > MAX_MACHINE_NUM || machineId < 0) {
   throw new IllegalArgumentException("machineId can't be greater than MAX_MACHINE_NUM or less than 0");
  }
  this.dataCenterId = dataCenterId;
  this.machineId = machineId;
 }

 /**
  * 产生下一个ID
  */
 public synchronized long nextId() {
  long currStamp = getNewStamp();
  if (currStamp < lastStamp) {
   throw new RuntimeException("Clock moved backwards.  Refusing to generate id");
  }

  if (currStamp == lastStamp) {
   //相同毫秒内，序列号自增
   sequence = (sequence + 1) & MAX_SEQUENCE;
   //同一毫秒的序列数已经达到最大
   if (sequence == 0L) {
    //阻塞到下一个毫秒,获得新的时间戳
    currStamp = getNextMill();
   }
  } else {
   //不同毫秒内，序列号置为0
   sequence = 0L;
  }

  lastStamp = currStamp;

  // 移位并通过或运算拼到一起组成64位的ID
  return (currStamp - START_STAMP) << TIMESTAMP_LEFT //时间戳部分
    | dataCenterId << DATA_CENTER_LEFT       //数据中心部分
    | machineId << MACHINE_LEFT             //机器标识部分
    | sequence;                             //序列号部分
 }

 private long getNextMill() {
  long mill = getNewStamp();
  while (mill <= lastStamp) {
   mill = getNewStamp();
  }
  return mill;
 }

 private long getNewStamp() {
  return System.currentTimeMillis();
 }

 public static void main(String[] args) {
  SnowFlake snowFlake = new SnowFlake(11, 11);

  long start = System.currentTimeMillis();
  for (int i = 0; i < 10; i++) {
   System.out.println(snowFlake.nextId());
  }

  System.out.println(System.currentTimeMillis() - start);
 }
}
```
上述代码中，在算法的核心方法上，通过加synchronized锁来保证线程安全。这样，同一服务器线程是安全的，生成的ID不会出现重复，而不同服务器由于机器码不同，就算同一时刻两台服务器都产生了雪花ID，结果也是不一样的。
