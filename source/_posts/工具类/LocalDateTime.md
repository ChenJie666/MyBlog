---
title: LocalDateTime
categories:
- 工具类
---
**SimpleDateFormat 是线程不安全的类**，一般不要定义为 static 变量，如果定义为 static，必须加锁，或者使用 DateUtils 工具类。
如果是 JDK8 的应用，可以使用 Instant 代替 Date，LocalDateTime 代替 Calendar，DateTimeFormatter 代替 SimpleDateFormat，官方给出的解释：simple beautiful strong immutable thread-safe。

//时间戳转LocalDateTime
LocalDateTime localDateTime = Instant.ofEpochMilli(milliseconds).atZone(ZoneOffset.ofHours(8)).toLocalDateTime(); 

//获取秒数
Long second = LocalDateTime.now().toEpochSecond(ZoneOffset.of("+8"));
//获取毫秒数
Long milliSecond = LocalDateTime.now().toInstant(ZoneOffset.of("+8")).toEpochMilli();

//时区相关
ZoneId Shanghai = ZoneId.of("Asia/Shanghai");
ZonedDateTime now = ZonedDateTime.now(Shanghai);

//格式转化
DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
String strDate = localDateTime.format(df);

//格式和时区转换
```
        DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss");
        Instant date = time.toInstant();
        LocalDateTime localDateTime = LocalDateTime.ofInstant(date, ZoneId.of("GMT+08:00"));
        String formatDate = df.format(localDateTime);
```
//当地时间转为目标时区时间
```
        LocalDateTime dateTime = LocalDateTime.of(2022, 6, 17, 0, 30, 0);
        ZonedDateTime shDatetime = ZonedDateTime.of(dateTime, ZoneId.of("Asia/Shanghai"));
```
//目标时区的时间转为时间戳
```
        // 获取上海时区指定时间对应的时间戳
        ZonedDateTime of = ZonedDateTime.of(2022, 6, 17, 0, 30, 1, 0, ZoneId.of("Asia/Shanghai"));
        System.out.println(of);
        Timestamp timestamp = Timestamp.from(of.toInstant());
        System.out.println(timestamp.getTime());
```
//时间戳转为目标时区的时间
```
public class TimestampInterceptor implements Interceptor {

    private ArrayList<Event> events = new ArrayList<>();

    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {

        Map<String, String> headers = event.getHeaders();
        String log = new String(event.getBody(), StandardCharsets.UTF_8);

        JSONObject jsonObject = JSONObject.parseObject(log);

        Long gmtCreate = jsonObject.getLong("gmtCreate");

        // 获取上海时区当日的日期
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Asia/Shanghai"));

        // 获取上海时区当日指定时间对应的时间戳
        long lineTimestamp = Timestamp.from(ZonedDateTime.of(now.getYear(), now.getMonth().getValue(), now.getDayOfMonth(), 0, 29, 0, 0, ZoneId.of("Asia/Shanghai")).toInstant()).getTime();
        // 获取上海时区当日零点的时间戳
        long zeroTimestamp = Timestamp.from(ZonedDateTime.of(now.getYear(), now.getMonth().getValue(), now.getDayOfMonth(), 0, 0, 0, 1000000, ZoneId.of("Asia/Shanghai")).toInstant()).getTime();

        // 如果当前时间已经超过指定的时间(保证flume可以关闭tmp文件)，但是到达的event的事件时间戳比当日0点的时间戳要小，那么用当日0点的时间戳代替
        if (lineTimestamp <= Timestamp.from(now.toInstant()).getTime() && gmtCreate <= zeroTimestamp) {
            gmtCreate = zeroTimestamp;
        }


        headers.put("timestamp", String.valueOf(gmtCreate));

        return event;
    }

    @Override
    public List<Event> intercept(List<Event> list) {
        events.clear();
        for (Event event : list) {
            events.add(intercept(event));
        }

        return events;
    }

    @Override
    public void close() {

    }

    public static class Builder implements Interceptor.Builder {
        @Override
        public Interceptor build() {
            return new TimestampInterceptor();
        }

        @Override
        public void configure(Context context) {
        }
    }
}
```


工具类
```java
/*
 * @author kingboy
 * @Date 2017/7/22 下午2:12
 * @Description LocalDateTimeUtils is used to Java8中的时间类
 */
public class LocalDateTimeUtils {

    //获取当前时间的LocalDateTime对象
    //LocalDateTime.now();

    //根据年月日构建LocalDateTime
    //LocalDateTime.of();

    //比较日期先后
    //LocalDateTime.now().isBefore(),
    //LocalDateTime.now().isAfter(),

    //Date转换为LocalDateTime
    public static LocalDateTime convertDateToLDT(Date date) {
        return LocalDateTime.ofInstant(date.toInstant(), ZoneId.systemDefault());
    }

    //LocalDateTime转换为Date
    public static Date convertLDTToDate(LocalDateTime time) {
        return Date.from(time.atZone(ZoneId.systemDefault()).toInstant());
    }


    //获取指定日期的毫秒
    public static Long getMilliByTime(LocalDateTime time) {
        return time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
    }

    //获取指定日期的秒
    public static Long getSecondsByTime(LocalDateTime time) {
        return time.atZone(ZoneId.systemDefault()).toInstant().getEpochSecond();
    }

    //获取指定时间的指定格式
    public static String formatTime(LocalDateTime time,String pattern) {
        return time.format(DateTimeFormatter.ofPattern(pattern));
    }

    //获取当前时间的指定格式
    public static String formatNow(String pattern) {
        return  formatTime(LocalDateTime.now(), pattern);
    }

    //日期加上一个数,根据field不同加不同值,field为ChronoUnit.*
    public static LocalDateTime plus(LocalDateTime time, long number, TemporalUnit field) {
        return time.plus(number, field);
    }

    //日期减去一个数,根据field不同减不同值,field参数为ChronoUnit.*
    public static LocalDateTime minu(LocalDateTime time, long number, TemporalUnit field){
        return time.minus(number,field);
    }

    /**
     * 获取两个日期的差  field参数为ChronoUnit.*
     * @param startTime
     * @param endTime
     * @param field  单位(年月日时分秒)
     * @return
     */
    public static long betweenTwoTime(LocalDateTime startTime, LocalDateTime endTime, ChronoUnit field) {
        Period period = Period.between(LocalDate.from(startTime), LocalDate.from(endTime));
        if (field == ChronoUnit.YEARS) return period.getYears();
        if (field == ChronoUnit.MONTHS) return period.getYears() * 12 + period.getMonths();
        return field.between(startTime, endTime);
    }

    //获取一天的开始时间，2017,7,22 00:00
    public static LocalDateTime getDayStart(LocalDateTime time) {
        return time.withHour(0)
                .withMinute(0)
                .withSecond(0)
                .withNano(0);
    }

    //获取一天的结束时间，2017,7,22 23:59:59.999999999
    public static LocalDateTime getDayEnd(LocalDateTime time) {
        return time.withHour(23)
                .withMinute(59)
                .withSecond(59)
                .withNano(999999999);
    }

}
```

测试类
```java
/**
 * @author kingboy
 * @Date 2017/7/22 下午7:16
 * @Description LocaDateTimeUtilsTest is used to 测试LocalDateTime工具
 */
public class LocaDateTimeUtilsTest {

    @Test
    public void format_test() {
        System.out.println(LocalDateTimeUtils.formatNow("yyyy年MM月dd日 HH:mm:ss"));
    }

    @Test
    public void betweenTwoTime_test() {
        LocalDateTime start = LocalDateTime.of(1993, 10, 13, 11, 11);
        LocalDateTime end = LocalDateTime.of(1994, 11, 13, 13, 13);
        System.out.println("年:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.YEARS));
        System.out.println("月:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.MONTHS));
        System.out.println("日:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.DAYS));
        System.out.println("半日:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.HALF_DAYS));
        System.out.println("小时:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.HOURS));
        System.out.println("分钟:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.MINUTES));
        System.out.println("秒:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.SECONDS));
        System.out.println("毫秒:" + LocalDateTimeUtils.betweenTwoTime(start, end, ChronoUnit.MILLIS));
        //=============================================================================================
        /*
                                      年:1
                                      月:13
                                      日:396
                                      半日:792
                                      小时:9506
                                      分钟:570362
                                      秒:34221720
                                      毫秒:34221720000
        */
    }

    @Test
    public void plus_test() {
        //增加二十分钟
        System.out.println(LocalDateTimeUtils.formatTime(LocalDateTimeUtils.plus(LocalDateTime.now(),
                20,
                ChronoUnit.MINUTES), "yyyy年MM月dd日 HH:mm"));
        //增加两年
        System.out.println(LocalDateTimeUtils.formatTime(LocalDateTimeUtils.plus(LocalDateTime.now(),
                2,
                ChronoUnit.YEARS), "yyyy年MM月dd日 HH:mm"));
        //=============================================================================================
        /*
                                        2017年07月22日 22:53
                                        2019年07月22日 22:33
         */
    }

    @Test
    public void dayStart_test() {
        System.out.println(getDayStart(LocalDateTime.now()));
        System.out.println(getDayEnd(LocalDateTime.now()));
        //=============================================================================================
        /*
                                        2017-07-22T00:00
                                2017-07-22T23:59:59.999999999
         */
    }

}
```
