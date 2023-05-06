---
title: JUC并发编程
categories:
- 高并发
---
##**知识点：**
1. 线程生命周期(新建、运行、阻塞、等待(一直等待)、超时等待(超时取消等待)、终止)；
2. Synchronized和Lock锁(Condition)的区别，和8锁问题；
3. 线程安全的集合类：写时复制(`CopyOnWriteArrayList/CopyOnWriteArraySet`)和分段锁（`ConcurrentHashMap`）；
4. Callable方法可以返回值或异常；
5. 多线程限流的辅助类：CountDownLatch(减法计数器)、CyclicBarrier(加法计数器)、Semaphore(限流)；
6. Lock类中的读写锁，可以实现HashMap并发读取，顺序写入。
7. 阻塞队列的api；
8. 通过ThreadPoolExecutor创建线程池，有七大参数和四种拒绝策略(`AbortPolicy`,`DiscardPolicy`,`DiscardOldestPolicy`,`CallRunsPolicy`)；
9. 如何设置最大线程数和队列长度；
- CPU密集型：设置为最大cpu线程数`Runtime.getRuntime().availableProcessors()`；
- IO密集型：判断十分耗IO的线程数n个，最大线程数设置为2n即可。
10. 四个基础函数型接口：`Consumer`、`Function`、`Predicate`、`Supplier`；
11. 流式计算Stream，可以在一行中完成过滤(filter)、数据处理(map)、排序(sorted)、限定个数(limit)等操作。
12. 分治思想forkjoin：可拆分的任务就可以使用forkjoin进行计算(`原理同递归，但是存在任务窃取，所以效率会高`)。
`forkJoinPool.execute(ForkJoinTask<?> task)`。
13. 使用Stream并行流效率是最高的。如计算Long型整数和，可以使用
`LongStream.rangeClose(0L, 10_0000_0000L).parallel().reduce(0, (l1,l2)->{return Long.sum(l1,l2);})`
14. `CompletableFuture`可以进行异步编程，异步执行逻辑后对结果进行异步处理，不会阻塞主线程。有丰富的api和异常处理机制，配合流式编程速度飞起。
15. JMM内存模型约定
- 线程解锁前，必须把共享变量立刻刷回主存
- 线程加锁前，必须读取主存中的最新值到工作内存中
- 加锁和解锁是同一把锁

**Volatile**是轻量级的同步机制，该关键字可以：1. 保证共享变量可见性(CPU嗅探机制通知其他线程共享变量地址失效) 2. 避免指令重排 3. 不保证原子性；
**如何保证原子性：**1. 加锁(lock和synchronized)：线程加锁前必须读取主存中的最新值到工作内存中，并保证原子性  2. 使用CAS原子类，如AtomicInteger；
**保证指令重排：**指令重排包括编译器重排，指令级重排和内存系统重排。会在volatile变量前后添加内存屏障保证该变量顺序不变。
**使用场景：**1. 单例模式防止指令重排 2. cas保证变量可见性 3. concurrenthashmap(1.7)保证value和count值的可见性，做到读不加锁。

<br>
16. 单例懒汉模式：

**方式一：**需要注意①使用类锁，防止并行破坏单例 ②volatile，防止先指向分配空间再创建对象，得到未初始化对象 ③锁之前再判断一次instance==null，防止每次都要获得锁才能获取对象。
```java
public class Singleton {

    private volatile static Singleton instance;

    private Singleton(){
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                Singleton instance = Singleton.getInstance();
            }).start();
        }
    }

}
```
**方式二->内部类：**使用静态内部类中的静态属性来创建对象，然后通过获取属性来得到单例。(内部静态类不会自动初始化，只有调用静态内部类的方法，静态域，或者构造方法的时候才会加载静态内部类。)
**方式三->枚举类：**以上两种方式都可以通过反射进行破坏，而枚举类通过反射创建实例时会抛异常，即不允许反射，所以枚举类是最安全的实现单例模式的方法。

<br>
17. CAS(compare and swap)

**CAS**是通过判断目标值和期望值是否相同进行操作，保证原子性的。
如`getAndAddInt`方法拿到内存位置的最新值v，使用CAS尝试将内存位置的值修改为目标值v+delta，如果修改失败，则获取该内存位置的新值v，然后继续尝试，直至修改成功(自旋锁)。
如atomicReference可以锁对象。

**存在ABA问题**：原子类进行操作时，如果在计算中原始值被修改为其他值马上又被改回来，那么计算还是会执行，但是原始值已经被修改了多次。

使用`AtomicStampedReference`类进行操作，为每个数据添加版本号，每次修改除了比较期望值也会比较版本号(乐观锁)。
>需要注意底层比较是`expectedReference == current.reference &&expectedStamp == current.stamp`，是地址进行比较，需要注意这个大坑

<br>
18. 公平与非公平锁、可重入锁、自旋锁、死锁等。

**死锁排查：** `jstack pid`打印进程的堆栈信息。

**写一个简单的自旋锁**
加锁为原子类AtomicReference赋值当前线程对象，如果失败则进行自旋。
```
class MySpinLock {

    private int count = 0;
    private AtomicReference<Thread> atomicReference = new AtomicReference<>();

    public void lock() {
        Thread thread = Thread.currentThread();
        if (thread == atomicReference.get()) {
            count++;
            System.out.println(Thread.currentThread().getName() + " - 添加锁  重入次数=" + count);
            return;
        }
        while (!atomicReference.compareAndSet(null, thread)) {
        }
        System.out.println(Thread.currentThread().getName() + " - 添加锁");
    }

    public void unlock() {
        Thread thread = Thread.currentThread();
        if (thread == atomicReference.get() && count > 0) {
            count--;
            System.out.println(Thread.currentThread().getName() + " - 释放锁  重入次数=" + count);
            return;
        }
        atomicReference.compareAndSet(thread, null);
        System.out.println(Thread.currentThread().getName() + " - 释放锁");
    }
}
```


<br>
<br>
# 一、 简介
JUC（java.util .concurrent工具包的简称）
- java.util .concurrent 并发包
- java.util .concurrent.atomic 原子类包，CAS类
- java.util .concurrent.locks  锁包
- java.util.function 函数包

Runnable 没有返回值、效率相比于Callable相对较低！

## 1.1 名词解释
**程序(program)**：程序是为完成特定任务、用某种语言编写的一组指令的集合。即指一段静态的代码，静态对象。
**进程(process)**：进程是程序的一次执行过程，或是正在运行的一个程序。是一个动态的过程：有它自身的产生、存在和消亡的过程。——生命周期。进程作为资源分配的单位，系统在运行时会为每个进程分配不同的内存区域
**线程(thread)**：进程可进一步细化为线程，是一个程序内部的一条执行路径。线程作为调度和执行的单位，每个线程拥有独立的运行栈和程序计数器(pc)。

java有两个默认线程：main线程和GC线程
java需要通过native调用本地C++的方法，无法直接操作硬件开启线程。

`并发`是多线程操作同一资源，CPU单核模拟多线程，快速交替。充分利用CPU资源。
`并行`是多核CPU同时执行，可以使用线程池。
Runtime.getRuntime().availableProcessors();//获取CPU核数

**用户级线程（ULT）:**由应用提供创建、同步、调度和管理线程，不需要用户态/核心态切换，速度快。
**内核级线程（KLT）:**线程的创建、调度、

**线程的上下文切换：**
CPU通过时间片段的算法来循环执行线程任务，而循环执行即每个线程允许运行的时间后的切换，而这种循环的切换使各个程序从表面上看是同时进行的。而切换时会保存之前的线程任务状态，当切换到该线程任务的时候，会重新加载该线程的任务状态。而这个从保存到加载的过程称之为上下文切换。

若当前线程还在运行而时间片结束后，CPU将被剥夺并分配给另一个线程。
若线程在时间片结束前阻塞或结束，CPU进行线程切换。而不会造成CPU资源浪费。
因此线程切换是多个线程之间的操作，而线程核心态和用户态切换是一个线程执行时对于CPU使用的不同状态

CPU密集型：CPU要读/写I/O(硬盘/内存)，I/O在很短的时间就可以完成，而CPU还有许多运算要处理，CPU Loading很高。
IO密集型：大部分的状况是CPU在等I/O (硬盘/内存) 的读/写操作，此时CPU Loading并不高。

## 1.2 线程状态
一共有六个线程状态：新建、运行、阻塞、等待(一直等待)、超时等待(超时取消等待)、终止
![线程状态图](JUC并发编程.assets\67c4efbcf7b24256af908b9adb9a2b7b.png)

**sleep()和wait()异同点**
同：都可以使当前进程进入阻塞状态。
异：施放锁，方法所在类，自动唤醒，使用场景，
1.定义方法所属sleep()：Thread类中静态方法；wait()：Object中的非静态方法
2.适用范围：sleep任何位置，wait只能在同步代码块内。
3.在同步代码块或同步方法中wait施放锁，sleep不施放锁。
4.结束阻塞时机不同，wait需要被其他线程唤醒。
sleep()和wait()源码中抛出了InterruptedException异常，所以用的时候要进行处理。

<br>
## 1.3 线程安全
**有三种解决线程安全问题**
- 同步代码块 
- 同步方法 
- jdk 5.0新增：Lock锁。

### 1.3.1 同步代码块
```
synchronized(同步监视器){
             //需要被同步的代码
}
```
**同步监视器俗称锁。**
**要求：**1.任何类的对象都可以充当同步监视器。2.多个线程必须公用同一个同步监视器。
**注意：**1.使用同步代码块接口runnable实现解决同步问题，可以考虑使用this  2.使用同步代码块继承extends时慎用this，用类名.class

### 1.3.2 同步方法
同步方法部分的同步监视器隐藏了，默认是this，要注意this是否唯一。当用同步方法时同步监视器默认是this，但是造成this不唯一。可以用静态方法，同步监视器是类本身，唯一。
静态方法：同步监视器是类本身。
非静态方法：同步监视器是this。


### 1.3.3 Lock锁
```
private ReentrantLock lock = New ReentrantLock();
try{
  lock.lock();
}finally{
  Lock.unlock();
}
```
一般统一将调用的lock方法放在try内,跟上代码块，跟上finally语句执行unlock方法，保证即使出意外也一定会释放锁。

<br>
## 1.4 synchronized和Lock锁
### 1.4.1 对比
**Lock锁和synchronized区别：**
Synchronized涉及同步监视器，多个线程公用唯一的同步监视器。出括号后会自动释放同步监视器。
Lock锁：提供具体的Lock锁的实现类对象。此对象唯一，多个线程共享。必须手动调用unlock释放锁。

- 1.wait() 、notify()、notifyAll()三个方法的调用者是同步监视器，如果不是会报异常。（如果同步监视器不是this，则在三个方法前面加上同步监视器，如果不加默认为this，会报错）
- 2.wait() 、notify()、notifyAll()三个方法只能用于同步代码块或同步方法中。不能用于Lock锁中。
- 3.wait() 、notify()、notifyAll()三个方法定义在Object中，会被继承。！！！

**Synchronized和lock的区别：**
1.Synchronized是内置java关键字，Lock是一个java类；
2.Synchronized无法判断获取锁的状态，Lock可以判断是否获取到锁；
3.Synchronized会自动释放锁(如执行完毕或发生异常)，Lock必须手动释放锁。如果不释放锁，会造成死锁；
4.Synchronized 线程1（获得锁，阻塞）、线程2（等待，直到获取锁）；Lock锁就不一定等待下去，lock.tryLock()；
5.Synchronized，可重入锁，不可以中断的，非公平的；Lock，可重入锁，可以判断锁，设置公平非公平锁；
6.Synchronized 适合锁少量的代码同步问题；Lock适合锁大量的同步代码。
7. Lock锁支持线程的精准唤醒，读写锁等功能。

### 1.4.2 各自的代码实现
**分类**
分为ReentrantLock可重入锁和ReentranReadWriteLock.ReadLock、ReentranReadWriteLock.WriteLock可重入读写锁

ReentranLock和ReentranReadWriteLock锁又可以分为FairSync()公平锁和NonfairSync()非公平锁：
- FairSync()：先来后到，按时间进行排队
- NonfairSync()：可以插队（默认）


**使用**
```
//创建锁对象
Lock lock = new ReentrantLock();
Condition condition = lock.newCondition();
//加锁
lock.lock(); //加锁
lock.tryLock(); //尝试获取锁，不会一直等待
//等待和唤醒
condition.await();
condition.signalAll();
//解锁
lock.unlock(); 
```

**Synchronized实现消费者和生产者代码**
```java
public class Main {
    public static void main(String[] args) {
        Data data = new Data();

        new Thread(()->{for(int i=1;i<=10;i++) {data.increment();}}).start();
        new Thread(()->{for(int i=1;i<=10;i++) {data.increment();}}).start();
        new Thread(()->{for(int i=1;i<=10;i++) {data.decrement();}}).start();
        new Thread(()->{for(int i=1;i<=10;i++) {data.decrement();}}).start();
    }

}

class Data{

    private int number = 0;

    public synchronized void increment(){
        while(number != 0){
            try {
                this.wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        number++;
        System.out.println(Thread.currentThread().getName()+"->"+number);

        this.notifyAll();
    }

    public synchronized void decrement(){
        while (number == 0) {
            try {
                this.wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        number--;
        System.out.println(Thread.currentThread().getName()+"->"+number);

        this.notifyAll();
    }

}
```
>**虚假唤醒：**当一个条件满足时,很多线程都被唤醒了,但是只有其中部分是有用的唤醒,其它的唤醒都是无用唤醒。此处唤醒的线程中有部分是不满足条件的无效线程，需要再次作判断，所以此处需要使用while，使用if会导致结果异常。

**Lock 实现消费者和生产者代码**
```java
public class Main {
    public static void main(String[] args) {
        Data data = new Data();

        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.increment(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.increment(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.decrement(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.decrement(); }}).start();

    }
}

class Data {

    private int number = 0;

    private Lock lock = new ReentrantLock();

    Condition condition = lock.newCondition();

    public void increment() {
        lock.lock();
        try {
            while (number != 0) {
                condition.await();
            }
            number++;
            System.out.println(Thread.currentThread().getName() + "->" + number);

            condition.signalAll();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }

    }


    public void decrement() {
        lock.lock();
        try {
            while (number == 0) {
                condition.await();
            }
            number--;
            System.out.println(Thread.currentThread().getName() + "->" + number);

            condition.signalAll();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            lock.unlock();
        }
    }

}
```
Condition优势：condition监视器实现精准通知唤醒线程
```java
public class Main {
    public static void main(String[] args) {
        Data data = new Data();

        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.printA(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.printA(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.printB(); }}).start();
        new Thread(() -> {for (int i = 1; i <= 10; i++) {data.printC(); }}).start();

    }
}

class Data {

    private int number = 0;

    private Lock lock = new ReentrantLock();

    Condition condition1 = lock.newCondition();
    Condition condition2 = lock.newCondition();
    Condition condition3 = lock.newCondition();

    public void printA(){
        lock.lock();
        try {
            while (number%3 != 0) {
                condition1.await();
            }
            number++;
            System.out.println(Thread.currentThread().getName() + "=>" + "AAAAA");

            condition2.signal();
        } catch (Exception e) {
            e.printStackTrace();
        }finally{
            lock.unlock();
        }
    }

    public void printB(){
        lock.lock();
        try {
            while (number%3 != 1) {
                condition2.await();
            }
            System.out.println(Thread.currentThread().getName() + "=>" + "BBBBB");
            number++;

            condition3.signal();
        } catch (Exception e) {
            e.printStackTrace();
        }finally{
            lock.unlock();
        }
    }

    public void printC(){
        lock.lock();
        try {
            while (number%3 != 2) {
                condition3.await();
            }
            System.out.println(Thread.currentThread().getName() + "=>" + "CCCCC");
            number++;

            condition1.signal();
        } catch (Exception e) {
            e.printStackTrace();
        }finally{
            lock.unlock();
        }
    }

}
```

<br>
## 1.5 八锁问题
关于synchronized锁的八个问题：
- 两个线程调用同一个对象的方法，先拿到锁的先执行方法；
- 两个线程调用同一个对象的方法，先拿到锁的先执行方法，与方法内部处理的时间无关；
- 加锁方法和不加锁方法互不影响；
- 调用的两个不同对象的加锁方法，不存在争抢锁的情况，互不影响；
- 如果加锁方法是静态方法，那么获取的锁是类锁而不是对象锁，锁的是Class，全局唯一；
- 如果加锁方法是静态方法，且用不同的类对象调用方法，结果是先调用的先执行，因为静态方法的锁是Class锁，而不是对象锁；
- 如果一个是静态方法，一个是普通方法，那么用同一个类对象调用两个方法时是没有锁冲突的。因为一个是反射类锁，一个是类的对象锁。
- 同理如果一个是静态方法，一个是普通方法，那么用不同的类对象调用两个方法时是没有锁冲突的。因为一个是反射类锁，一个是类的对象锁。

[https://blog.csdn.net/iME_cho/article/details/105357714](https://blog.csdn.net/iME_cho/article/details/105357714)


<br>
# 二、集合类不安全
## 2.1 常用集合类的并发安全
### 2.1.1 List的并发安全类(CopyOnWriteArrayList)
多线程对ArrayList对象进行修改会抛`ConcurrentModificationException`异常。

解决方案：
- 使用Vector集合，线程安全。但是多线程时产生的每个迭代器对象不同，也可能抛出异常？？？
- `Collections.synchronizedList(new ArrayList<>());` 将list对象进行包装，将每个方法都加上了锁，线程安全但是效率比COW低。
- `CopyOnWriteArrayList<>() ` 写入时复制（COW）
多个线程调用相同资源时，读取的时候是固定的，修改资源的内容时，系统会复制一份专用副本（private copy）给该调用者，而其他调用者所见到的最初的资源仍然保持不变。即所有的修改方法都加上了锁，读方法不加锁。
![COW源码](JUC并发编程.assets\4c6c5ab953a542b0aad52323dac9b062.png)
>加锁保证了修改操作时串行的，写时复制保证了写入时可以对原数据进行读操作，而不会对原数组的modCount进行修改，导致modCount与expectedModCount不一致使得ConcurrentModificationException异常抛出。

**COW缺点：**
- COW 会造成数据错误，不能实时保证数据一致性，但是可以保证最终一致性；
- 因为设计表结构的操作都要 copy，所以会造成内存占用偏高。

### 2.1.2 Set的并发安全类(CopyOnWriteArraySet)
- Set<Object> set = Collections.synchronizedSet(new HashSet<>());
- `CopyOnWriteArraySet<>() ` 写入时复制

### 2.1.3 Map的并发安全类(ConcurrentHashMap)
java目前没有提供CopyOnWriteMap类，可以仿照CopyOnWriteArrayList自定义。
可以使用：
- HashTable
- Map<Object, Object> map = Collections.synchronizedMap(new HashMap<>());
- `new ConcurrentHashMap<>();` 
ConcurrentHashMap在线程安全的基础上提供了更好的写并发能力，但同时降低了对读一致性的要求。采用了分段锁Segment的设计（jdk7），减小锁粒度，写操作添加锁，读操作不加锁。

<br>
# 三、开启线程
## 3.1 继承Thread类
新建类继承Thread类，重写run（）方法，new类对象，调用start（）方法。
start（）方法两个作用：1.启动一个新线程  2.执行run（）方法
但是一个对象的start（）只能执行一次。

Setname是静态么？为什么可以用currentThread调用，也可以对象调用。
重写Run方法中不能抛异常，因为父类没抛异常。

System.out.println(Thread.currentThread().getName() + " " + num++); 此处直接写getName也可以，就是this调用getName方法，但是Thread.currentThread()是什么，写的是本地的文件，为什么能调用getName（）方法，和this什么区别？？？？？static Thread currentThread(): 返回当前线程。在Thread子类中就是this，通常用于主线程和Runnable实现类。因为Runnable实现类一般只有run方法，没有其他属性和方法。


Join怎么在别的线程里调用其他线程的join？？？在主线程中调用分线程的join方法。

## 3.2 实现Runnable方法
实现Runnable方式优于继承Thread类
区别：1.java类的单继承性的局限性2.实现Runnable接口的方式更适合多线程有共享数据的方式
共同点：Thread也实现了Runable接口，可以将实现Runnable看作是代理模式。实现Runnable的类是被代理类，Thread是代理类，Runnable是接口。为了执行实现Runnable类的方法，通过new Thread的对象来调用Thread中的方法,若传入了target对象，使target不为null，则调用实现类中的方法。

继承Thread类就是写Thread的子类，然后重写run方法。new子类并调用其中继承与父类的start方法，start方法开启新线程并执行run方法。
实现Runnable类就是Thread和实现类都实现了Runnale接口（只有一个run方法）中的run方法，new实现类的对象target。通过new Thread将实现类的引用target作为参数给到new的对象，将target赋给Thread中的Runnable型属性，该对象调用其类中的start方法建立新线程，并调用run方法，判断参数target是否是null，不是null则调用target中的run方法，在新线程中运行重写后的run方法。
![image.png](JUC并发编程.assets\9c6d6727feea49c7a9e03582efaace09.png)
Thread关联了实现类，可以通过Thread类代理进行实现类的run方法。返回值可通过FutureTask的get（）方法获得。注意：一个FutureTask对象只能被执行一次，每个FutureTask对象包含一个返回值。

几个线程就要写几个Tread继承类，分布start开启线程，所以不能用对象（this）作为同步锁（不唯一），用类的反射对象作为同步锁。
而实现Runnable方法只需要一个实现类，给多个Thread类作参数，开启多线程是共用一个run方法，所以可以用this（即实现类的对象）作为同步锁。

## 3.3 实现Callable方法
相较于Runnable创建多线程的方式，Callable方式更灵活  
1.call（）方法可以声明返回值   
2.call（）方法是可以使用throws的方式处理。 
3.可以使用泛型指定call（）返回值类型。
Callable多线程的执行，需要借助FutureTask类（FutureTask是Future类的唯一实现类，且FutureTask是Runnable的唯一实现类），FutureTask实现了Runnable接口，然后再用Thread类。
底层实现：Thread对象调用start方法，start方法建立新线程并调用run方法，run方法判断target是否为null，因为构造Thread对象时调用的传入target构造器，所以target不为null，则调用target对象（即图中f）的run方法，FutureTask的run方法会调用r的call方法，最终实现call方法。（FutureTask类中关联了Callable属性，构造FutureTask对象时调用了传入Callable对象的构造器）。

注意：
- 用get()接收Callable返回值会阻塞直到获取返回值，将该方法写到最后或使用异步通讯(RabbitMQ等)。
- 同一FutureTask开启线程只会执行一次，会将结果缓存。
```java
public class Main {

    public static void main(String[] args) throws ExecutionException, InterruptedException {

        MyThread myThread = new MyThread();
        FutureTask<Integer> futureTask = new FutureTask<>(myThread);
        new Thread(futureTask).start();
        new Thread(futureTask).start();//新线程不会执行，有缓存
        // 接收Callable返回值，此处get方法会阻塞直到获取返回值
        Integer integer = futureTask.get();
        System.out.println("获取返回值：" + integer);
    }

}

class MyThread implements Callable<Integer>{

    @Override
    public Integer call(){
        System.out.println("并发调用了call方法");
        return 1024;
    }
}
```

<br>
# 四、常用多线程辅助类
## 4.1 CountDownLatch
`减法计数器`:允许一个或多个线程等待直到在其他线程中执行的一组操作完成的同步辅助。
作用：阻塞线程直到所有的线程任务完成后再继续执行。
```java
public class CountDownLatchDemo {
    public static void main(String[] args) throws InterruptedException {
        //创建一个倒计数为6的计数器
        CountDownLatch countDownLatch = new CountDownLatch(6);

        for (int i = 0; i < 6; i++) {
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + " is out!");
                countDownLatch.countDown(); //数量减1
            }, String.valueOf(i)).start();
        }

        countDownLatch.await(); //等待计数器归零，再向下执行

        System.out.println("close door");
    }
}
```

## 4.2 CyclicBarrier
`加法计数器`:创建一个CyclicBarrier对象，设置累计值，在线程中设置await阻塞线程，只有当阻塞数达到累计值的时候，阻塞的线程才会继续执行，否则一直阻塞。
```java
public class CyclicBarrierDemo {

    public static void main(String[] args) {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(7, () -> {
            System.out.println("召唤神龙成功");
        });

        for (int i = 0; i < 6; i++) {
            final int temp = i;

            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + " 收集" + temp + "个龙珠");

                try {
                    cyclicBarrier.await(); //等待
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }

            }).start();

        }
    }

}
```


## 4.3 Semaphore(用于限流)
`线程占用`：.acquire()可以获取semaphore资源，如果acquire达到semaphore上限，.acquire()方法会阻塞线程，直到其他线程.release()释放semaphore资源。用于对线程进行限流。

```java
public class SemaphoreDemo {

    public static void main(String[] args) {
        Semaphore semaphore = new Semaphore(3);

        for (int i = 0; i < 6; i++) {
            new Thread(()->{
                try {
                    semaphore.acquire();
                    System.out.println(Thread.currentThread().getName() + "抢到车位");
                    TimeUnit.SECONDS.sleep(2);
                    System.out.println(Thread.currentThread().getName() + "离开车位");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }finally {
                    semaphore.release();
                }
            }).start();
        }
    }

}
```
>semaphore.acquire()：获得，加入已经满了，等待，直到有线程被释放；
semaphore.release()：释放，会将当前的信号量释放 +1，然后唤醒等待的线程。

<br>
#五、ReadWriteLock读写锁
更加细粒度的控制，为方法添加读写锁。排他写锁不能加其他锁，共享读锁只能加共享读锁。读操作可以并行，写操作只能串行。读时不能写，写时不能读。
```java
public class MyCacheLockDemo {

    private volatile Map<String, Object> map = new HashMap<>();


    public static void main(String[] args) {
        MyCacheLock myCache = new MyCacheLock();

        for (int i = 0; i < 10; i++) {
            final Integer tmp = i;
            new Thread(() -> {
                myCache.put(tmp + "",tmp + "");
            }).start();
        }

        for (int i = 0; i < 10; i++) {
            final Integer tmp = i;
            new Thread(()->{
                myCache.get(tmp + "");
            }).start();
        }

    }

}

//添加读写锁的自定义缓存(排他写锁，共享读锁。排他写锁不能加其他锁，共享读锁只能加共享读锁)
class MyCacheLock {

    private volatile Map<String, Object> Map = new HashMap<>();

    //读写锁
    private ReadWriteLock readWriteLock = new ReentrantReadWriteLock();

    public void put(String key, Object value) {
        readWriteLock.writeLock().lock();
        System.out.println(Thread.currentThread().getName() + "写入" + key);
        Map.put(key, value);
        System.out.println(Thread.currentThread().getName() + "写入完成");
        readWriteLock.writeLock().unlock();
    }

    public void get(String key) {
        readWriteLock.readLock().lock();
        System.out.println(Thread.currentThread().getName() + "读取" + key);
        Object o = Map.get(key);
        System.out.println(Thread.currentThread().getName() + "读取完成");
        readWriteLock.readLock().unlock();
    }

}

//自定义缓存(未添加读写锁，所以写入操作可能存在并发的情况)
class MyCache {

    private volatile Map<String, Object> Map = new HashMap<>();

    public void put(String key, Object value) {
        System.out.println(Thread.currentThread().getName() + "写入" + key);
        Map.put(key, value);
        System.out.println(Thread.currentThread().getName() + "写入完成");
    }

    public void get(String key) {
        System.out.println(Thread.currentThread().getName() + "读取" + key);
        Object o = Map.get(key);
        System.out.println(Thread.currentThread().getName() + "读取完成");
    }

}
```

<br>
#六、队列和线程池
BlockingQueue：阻塞队列
Deque：双端队列
AbstractQueue：非阻塞队列

![image.png](JUC并发编程.assets\8222f6924cd44e879c11602156a3ec58.png)

什么情况下使用阻塞队列：多线程并发处理，线程池！

## 6.1 阻塞队列BlockingQueue
**阻塞队列BlockingQueue及其子类的API：**
| 方式       | 抛出异常 | 不抛异常返回bool或null | 阻塞等待 | 超时等待                        |
| ---------- | -------- | ---------------- | -------- | ------------------------------- |
| 添加       | add      | offer            | put      | `offer("d", 2, TimeUnit.SECONDS)` |
| 移除       | remove   | poll             | take     | `poll(2, TimeUnit.SECONDS)`     |
| 判断队列首 | element  | peek             | -        | -                               |

阻塞队列中可以使用offer和poll方法指定超时时间，进行超时等待。

<br>
## 6.2 同步队列SynchronousQueue
`容量为1，只能存储一个元素，只有取出元素后才能再放入元素。` 
SynchronousQueue是BlockingQueue的子类，阻塞队列的API同样适用于SynchronousQueue。

<br>
#七、 线程池
**池化技术：**事先准备好资源，需要用时取出，用完之后放回。
一般有线程池、连接池、内存池、对象池等。

**好处：**降低资源消耗、提高响应速度、方便管理(线程复用、控制最大并发数)


**线程池：**`三大方法`、`7大参数`、`4种拒绝策略`

### 7.1 三大方法
`Executors.newSingleThreadExecutor(); `//单个线程的线程池
`Executors.newFixedThreadPool(5);` //创建一个固定数量线程的线程池
`Executors.newCachedThreadPool();`  //可伸缩的线程池，最大会创建21亿个线程，导致崩溃
```java
public static ExecutorService newSingleThreadExecutor() {
        return new FinalizableDelegatedExecutorService(new ThreadPoolExecutor(1, 1,
                                    0L, TimeUnit.MILLISECONDS,
                                    new LinkedBlockingQueue<Runnable>()));
}

public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>());
}

public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>());
}
```
>可以发现通过Executors静态方法创建线程池，底层还是使用ThreadPoolExecutor类进行创建的。因此阿里巴巴java开发规约中建议使用ThreadPoolExecutor创建线程池。
![java开发规约](JUC并发编程.assets69f35635a5a41979dcdc11ad58c6084.png)

<br>
## 7.2 七大参数
`int corePoolSize`:  核心线程池大小
`int maximumPoolSize`:  最大核心线程池大小
`long keepAliveTime`:  闲置的线程超时释放时间
`TimeUnit unit`:  超时时间单位
`BlockingQueue<Runnable> workQueue`:  阻塞队列
`ThreadFactory threadFactory`:  线程工厂，创建线程的，一般不用动
`RejectedExecutionHandler handler`:  拒绝策略
**理解**：corePoolSize核心线程池大小即是线程池中对用数量的线程数；如果BlockingQueue阻塞队列满了，那么就会创建一个新的线程放入池中用于处理队列中的请求，以此类推，直到总线程数为maximumPoolSize最大核心线程池大小。如果线程都被占用且阻塞队列满了， 那么会根据指定的拒绝策略处理新的线程请求。

```java
public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
        if (corePoolSize < 0 ||
            maximumPoolSize <= 0 ||
            maximumPoolSize < corePoolSize ||
            keepAliveTime < 0)
            throw new IllegalArgumentException();
        if (workQueue == null || threadFactory == null || handler == null)
            throw new NullPointerException();
        this.acc = System.getSecurityManager() == null ?
                null :
                AccessController.getContext();
        this.corePoolSize = corePoolSize;
        this.maximumPoolSize = maximumPoolSize;
        this.workQueue = workQueue;
        this.keepAliveTime = unit.toNanos(keepAliveTime);
        this.threadFactory = threadFactory;
        this.handler = handler;
    }
```

<br>
## 7.3 四种拒绝策略
线程都被占用且阻塞队列满了，那么就会调用拒绝策略对新的线程请求进行处理。
AbortPolicy：丢弃请求，并抛出异常；
DiscardPolicy：丢弃请求，不抛出异常；
DiscardOldestPolicy：丢弃队列最前面的任务，然后重新提交被拒绝的任务 ，不抛出异常；
CallRunsPolicy：将请求发回原线程进行处理，即如果是main线程发起的线程请求，将请求发还给main线程，由main线程处理该逻辑；
>核心线程数+队列长度=可以接收的线程请求数，如果超过这个值，就会新建线程用于处理线程请求。如果最大线程数+队列长度<可以接收的线程请求数，就会根据拒绝策略拒绝超出的线程请求。


```java
//如下参数，核心线程为2，最大线程为5，队列大小为5，一次性启动11个线程会抛出RejectedExecutionException异常
ThreadPoolExecutor threadPool = new ThreadPoolExecutor(2, 5, 2, TimeUnit.SECONDS, new ArrayBlockingQueue<>(5), Executors.defaultThreadFactory(), new ThreadPoolExecutor.AbortPolicy());
```

```java
//参数同上，一次性启动11个线程会将第11个线程请求打回给main线程，由main线程执行。
public class ThreadTest {
    public static void main(String[] args) {
        ThreadPoolExecutor threadPool = new ThreadPoolExecutor(2, 5, 2, TimeUnit.SECONDS, new ArrayBlockingQueue<>(5), Executors.defaultThreadFactory(), new ThreadPoolExecutor.CallerRunsPolicy());
        for (int i = 0; i < 15; i++) {
            final int temp = i;
            threadPool.execute(()->{
                System.out.println(Thread.currentThread().getName() + "=>" + temp);
            });
        }
    }
}
```

<br>

**最大线程数如何设置**
- CPU密集型：指系统大部分时间是在做程序正常的计算任务，这些处理都需要CPU来完成。线程池大小与CPU虚拟内核数保持一致，可以保证CPU效率最高。
获取CPU核数System.out.println(Runtime.getRuntime().availableProcessors());

- IO密集型：系统大部分时间在跟I/O交互，而这个时间线程不会占用CPU来处理。判断程序中十分消耗IO的线程，将线程数设置为IO消耗线程数的两倍。

- 混合型：混合型的话，是指两者都占有一定的时间。

<br>

#八、四大函数式接口
>**需要掌握的jdk8新特性**
>- lambda表达式
>- 链式编程
>- 函数式接口
>- Stream流式计算

>**什么是函数式接口?**
接口有且仅有一个抽象方法
允许定义静态方法
允许定义默认方法
允许java.lang.Object中的public方法
该注解不是必须的，如果一个接口符合"函数式接口"定义，那么加不加该注解都没有影响。加上该注解能够更好地让编译器进行检查。如果编写的不是函数式接口，但是加上了@FunctionInterface，那么编译器会报错。

**示例如下**
```java
// 正确的函数式接口
@FunctionalInterface
public interface TestInterface {
 
    // 抽象方法
    public void sub();
 
    // java.lang.Object中的public方法
    public boolean equals(Object var1);
 
    // 默认方法
    public default void defaultMethod(){
    
    }
 
    // 静态方法
    public static void staticMethod(){
 
    }
}

// 错误的函数式接口(有多个抽象方法)
@FunctionalInterface
public interface TestInterface2 {

    void add();
    
    void sub();
}
```


<br>

**lambda表达式**
```java
Function function = (str)->{return str;};
```
```java
@Test
public void test(){
        List<String> list = Arrays.asList("zhangsan", "lisi", "wangwu");
        
        list.forEach(str->{
            System.out.println(str);
        });
        //例1：遍历数组并打印的简写
        list.forEach(System.out::println);

        Long sum = LongStream.rangeClosed(0L, 10_0000_0000L).parallel().reduce(0, (l1,l2)->{return Long.sum(l1,l2);});
        //例2：求和的简写
        Long sum = LongStream.rangeClosed(0L, 10_0000_0000L).parallel().reduce(0, Long::sum);
}
```
>**原理**
>可以将str->{System.out.println(str)} 简写为 System.out::println 。
查看println方法的源码得知println是PrintStream类中的一个非静态方法，因此按照方法引用的逻辑，它肯定可以使用，“函数式接口 变量名 = 类实例::方法名” 的方式对该方法进行引用，而System.out的作用肯定就是来获取PrintStream类的一个类实例,


<br>

**四个基础函数型接口：Consumer、Function、Predicate、Supplier**
其他函数型接口如BiConsumer接口是Consumer接口的强化版本，可以传入两个参数。

注：Runnable没有参数和返回值

- Function接口 => 输入参数T和返回值R
```java
@FunctionalInterface
public interface Function<T,R> {
  R apply(T t);
}
```
Function function = (str)->{return str;};

- Predicate接口 => 输入参数T，返回值固定位Boolean类型
```java
@FunctionalInterface
public interface Predicate<T>{
  boolean test(T t);
}
```
Predicate predicate = (str)->(str.isEmpty(););

- Consumer接口 => 只有输入参数T，没有返回值
```java
@FunctionalInterface
public interface Consumer<T> {
  void accept(T t);
}
```
Consumer consumer = (str)->(System.out.println(str););

foreach函数是消费者类的函数式接口

- Supplier接口 => 没有输入参数，只有返回值T
```java
@FunctionalInterface
public interface Supplier<T> {
  T get();
}
```
Supplier supplier = ()->(return "abc");

<br>
#九、Stream流式计算
计算都应该交给流来计算，通过如下例题进行Stream数据处理和链式编程。
```java
/**
 * 要求：
 * 1. ID必须是偶数
 * 2. 年龄必须大于17岁
 * 3. 用户名转为大写
 * 4. 用户名倒叙排列
 * 5. 只输出一个用户
 */
public class StreamTest {
    @Test
    public void test(){
        User user1 = new User(1, "zhangsan", 18);
        User user2 = new User(2, "lisi", 19);
        User user3 = new User(3, "wangwu", 22);
        User user4 = new User(4, "zhaoliu", 25);
        User user5 = new User(5, "tianqi", 21);
        List<User> users = Arrays.asList(user1, user2, user3, user4, user5);

        users.stream() //得到Stream<User>,泛型为User
                .filter(u->(u.getId()%2 == 0))
                .filter(u->(u.getAge() > 17))
                .map(u->{return u.getName().toUpperCase();})  //得到Stream<String>,泛型为String
                .sorted((u1,u2)->{return u1.compareTo(u2);})
                .limit(1)
                .forEach(System.out::println);
    }
}

@Data
@AllArgsConstructor
class User{
    private Integer id;
    private String name;
    private Integer age;
}
```

对于数字的计算可以使用流计算类IntStream、LongStream、DoubleStream。效率可以提高几十倍。
```java
//计算0到10亿之和
Long sum = LongStream.rangeClosed(0L, 10_0000_0000L).parallel().reduce(0, Long::sum);
```

<br>
#十、ForkJoin分之合并(jdk1.7)
![image.png](JUC并发编程.assets\9ff7444b851041859ff8e27cd9f31b5c.png)

**ForkJoin特点：**
- 分治思想
- 工作窃取：维护双端队列，每个小规模里面的问题解决完之后，会从别的地方后面拿取处理完成并归还。

![image.png](JUC并发编程.assets\61c8e2f6568c487ba2c2f006a14d7ec3.png)


为异步执行给定任务的排列`forkJoinPool.execute(ForkJoinTask<?> task)`


**ForkJoinTask的两个抽象子类：**
- 递归事件  `RecursiveAction`：没有返回值，可以通过get方法获取，会阻塞线程。
- 递归任务 `RecursiveTask`：有返回值

**以下是Forkjoin计算任务类的代码**
```java
//计算类
public class ForkJoinDemo extends RecursiveTask<Long> {

    private Long start;
    private Long end;

    private Long temp = 10000L;

    public ForkJoinDemo(Long start, Long end){
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {
        // 递归边界
        if (end - start < temp) {
            Long sum = 0L;
            for (Long i = start; i <= end; i++) {
                sum += i;
            }
            return sum;
        }else{
        // 递归
            Long middle = (start + end)/2;
            ForkJoinDemo task1 = new ForkJoinDemo(start, middle);
            ForkJoinDemo task2 = new ForkJoinDemo(middle + 1, end);
            task1.fork();
            task2.fork();
            return task1.join() + task2.join();
        }
    }

}
```
以下是通过三种方式计算0到10亿之和的计算时间
```java
public class ForkJoinTest {

    @Test //执行时间为6875
    public void test1(){
        long start = System.currentTimeMillis();
        Long sum = 0L;
        for (Long i = 0L; i < 10_0000_0000L; i++) {
            sum += i;
        }
        long end = System.currentTimeMillis();
        System.out.println("sum = " + sum + "  时间：" + (end - start));
    }

    @Test  //执行时间为5139
    public void test2() throws ExecutionException, InterruptedException {
        long start = System.currentTimeMillis();
        ForkJoinPool forkJoinPool = new ForkJoinPool();
        ForkJoinTask<Long> forkJoinDemo = new ForkJoinDemo(0L, 10_0000_0000L);
        ForkJoinTask<Long> submit = forkJoinPool.submit(forkJoinDemo);
        Long sum = submit.get();

        long end = System.currentTimeMillis();
        System.out.println("sum = " + sum + "  时间：" + (end - start));
    }

    @Test   //执行时间为154
    public void test3(){
        long start = System.currentTimeMillis();
        //流计算.范围为0到10亿(左闭右开).并行计算.处理方式()
//        Long sum = LongStream.rangeClosed(0L, 10_0000_0000L).parallel().reduce(0, Long::sum);
        Long sum = LongStream.rangeClosed(0L, 10_0000_0000L).parallel().reduce(0, (l1,l2)->{return Long.sum(l1,l2);});

        long end = System.currentTimeMillis();
        System.out.println("sum = " + sum + "  时间：" + (end - start));
    }

}
```

<br>
# 十一、ExecutorCompletionService（java5）
[高并发编程-ExecutorCompletionService深入解析](https://cloud.tencent.com/developer/article/1444259)
![image.png](JUC并发编程.assets\65b3ec99cf86438faf2c47caa8767dde.png)

**要点解说**
假设现在有一大批需要进行计算的任务，为了提高整批任务的执行效率，你可能会使用线程池，向线程池中不断submit异步计算任务，同时你需要保留与每个任务关联的Future，最后遍历这些Future，通过调用Future接口实现类的get方法获取整批计算任务的各个结果。

虽然使用了线程池提高了整体的执行效率，但遍历这些Future，调用Future接口实现类的get方法是阻塞的，也就是和当前这个Future关联的计算任务真正执行完成的时候，get方法才返回结果，如果当前计算任务没有执行完成，而有其它Future关联的计算任务已经执行完成了，就会白白浪费很多等待的时间，所以最好是遍历的时候谁先执行完成就先获取哪个结果，这样就节省了很多持续等待的时间。

而ExecutorCompletionService可以实现这样的效果，它的内部有一个先进先出的阻塞队列，用于保存已经执行完成的Future，通过调用它的take方法或poll方法可以获取到一个已经执行完成的Future，进而通过调用Future接口实现类的get方法获取最终的结果。
```java
@Test
public void test() throws InterruptedException, ExecutionException {
    Executor executor = Executors.newFixedThreadPool(3);
    CompletionService<String> service = new ExecutorCompletionService<>(executor);
    for (int i = 0 ; i < 5 ;i++) {
        int seqNo = i;
        service.submit(new Callable<String>() {
            @Override
            public String call() throws Exception {
                return "HelloWorld-" + seqNo + "-" + Thread.currentThread().getName();
            }
        });
    }
    for (int j = 0 ; j < 5; j++) {
        System.out.println(service.take().get());
    }
}
```
**执行结果**
```java
HelloWorld-2-pool-1-thread-3
HelloWorld-1-pool-1-thread-2
HelloWorld-3-pool-1-thread-2
HelloWorld-4-pool-1-thread-3
HelloWorld-0-pool-1-thread-1 
```

**方法解析**
ExecutorCompletionService实现了CompletionService接口，在CompletionService接口中定义了如下这些方法：

Future<V> submit(Callable<V> task):提交一个Callable类型任务，并返回该任务执行结果关联的Future；
Future<V> submit(Runnable task,V result):提交一个Runnable类型任务，并返回该任务执行结果关联的Future；
Future<V> take():从内部阻塞队列中获取并移除第一个执行完成的任务，阻塞，直到有任务完成；
Future<V> poll():从内部阻塞队列中获取并移除第一个执行完成的任务，获取不到则返回null，不阻塞；
Future<V> poll(long timeout, TimeUnit unit):从内部阻塞队列中获取并移除第一个执行完成的任务，阻塞时间为timeout，获取不到则返回null；

****

<br>
#十二、异步回调CompletableFuture（java8，Future的实现类）
[参考文章](https://blog.csdn.net/ff00yo/article/details/88778535)

![image.png](JUC并发编程.assets\4701c24249e24cfa842c5115f6ed0d64.png)

可以配合线程池和Stream流式编程使用，高效。
## 12.1 引入异步回调原因
**存在的问题：**如果采用`threadPool.submit(futureTask)`开启支线程任务，获取返回值时会等待结果导致阻塞线程。回调无法放到与任务不同的线程中执行。传统回调最大的问题就是不能将控制流分离到不同的事件处理器中。例如主线程等待各个异步执行的线程返回的结果来做下一步操作，则必须阻塞在future.get()的地方等待结果返回。这时候又变成同步了。

**Future设计的初衷：**对将来的某个时间的结果进行建模。使用Future获得异步执行结果时，要么调用阻塞方法get()，要么轮询看isDone()是否为true，这两种方法都不是很好，因为主线程也会被迫等待。
`CompletableFuture`是Future和CompletionStage的实现，异步的任务完成后，需要用其结果继续操作时，无需等待。可以直接通过thenAccept、thenApply、thenCompose等方式将前面异步处理的结果交给另外一个异步事件处理线程来处理。一个控制流的多个异步事件处理能无缝的连接在一起。

## 12.2 CompletableFuture的优点
- 异步任务结束时，会自动回调某个对象的方法；异步任务出错时，会自动回调某个对象的方法；
- 主线程设置好回调后，不再关心异步任务的执行，异步处理的结果自动交给另外一个异步事件处理线程来处理。

CompletableFuture提供了非常强大的Future的扩展功能，可以帮助我们简化异步编程的复杂性，并且提供了函数式编程的能力，可以通过回调的方式处理计算结果。
CompletableFuture是Future的实现类，用于异步回调。

## 12.3 API介绍
- 方法是否带Async，是则由上面的线程继续执行，不是则将任务继续交给线程池去执行。
- 如果没有指定线程池，就会使用默认线程池来执行，即`ForkJoinPool.commonPool`。
如`whenComplete`和`whenCompleteAsync`方法的区别在于：前者是由上面的线程继续执行，而后者是将whenCompleteAsync的任务继续交给线程池去做决定。
### 12.3.1 异步启动任务
```
public static CompletableFuture<Void> runAsync(Runnable runnable)
public static CompletableFuture<Void> runAsync(Runnable runnable, Executor executor)
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier)
public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor executor)
```
>`runAsync()` 是没有返回值的异步回调方法，
>`supplyAsync()` 是有返回值的，

<br>
### 12.3.2 异步处理计算结果
当CompletableFuture的计算结果完成，或者抛出异常的时候，可以通过一下方法将计算结果进行【异步】处理，而不阻塞线程：
```
public CompletableFuture<T> whenComplete(BiConsumer<? super T,? super Throwable> action)
public CompletableFuture<T> whenCompleteAsync(BiConsumer<? super T,? super Throwable> action)
public CompletableFuture<T> whenCompleteAsync(BiConsumer<? super T,? super Throwable> action, Executor executor)
public CompletableFuture<T> exceptionally(Function<Throwable,? extends T> fn)
```
>`whenComplete`方法表示，某个任务执行完成后，执行的回调方法，无返回值；并且`whenComplete`方法返回的CompletableFuture的result是**上个任务的结果**，而不是`whenComplete`方法返回的结果。
`exceptionally`则是上面的任务执行抛出异常后，所要执行的方法。
此类的回调方法，哪怕主线程已经执行结束，已经跳出外围的方法体，然后回调方法依然可以继续等待异步任务执行完成再触发，丝毫不受外部影响。

**例1：**
```java
public class FutureDemo {

    @Test
    public void test() throws ExecutionException, InterruptedException {
        //无返回值的结果的异步回调
        CompletableFuture<Void> runCompletableFuture = CompletableFuture.runAsync(() -> {
            System.out.println("supplyAsync=>Void");
        });

        //有返回值的结果
        CompletableFuture<Integer> supplyCompletableFuture = CompletableFuture.supplyAsync(() -> {
//            int i = 10/0;
            System.out.println(Thread.currentThread().getName() + "supplyAsync=>Integer");
            return 1024;
        });

        Integer result = supplyCompletableFuture.whenComplete((t, e) -> {
            System.out.println("t=>" + t); //正常返回值结果
            System.out.println("e=>" + e); //错误信息
        }).exceptionally((e) -> {
            System.out.println(e.getMessage());
            return 500; //如果异常，可以捕获并指定返回结果
        }).get();

        System.out.println("返回结果" + result);

    }

}

// 最终输出结果为：   返回结果1024
```

<br>
### 12.3.3 任务间依赖
**thenApply 和 handle 方法**
如果两个任务之间有依赖关系，比如B任务依赖于A任务的执行结果，那么就可以使用这两个方法
```
public <U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)
public <U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn)
public <U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn, Executor executor)

public <U> CompletionStage<U> handle(BiFunction<? super T, Throwable, ? extends U> fn);
public <U> CompletionStage<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn);
public <U> CompletionStage<U> handleAsync(BiFunction<? super T, Throwable, ? extends U> fn,Executor executor);
```
>这两个方法，效果是一样的，区别在于，当A任务执行出现异常时，`thenApply`方法不会执行，而`handle`方法一样会去执行，因为在handle方法里，我们可以处理异常，而前者不行。

**thenAccept 和 thenRun方法**
```
public CompletableFuture<Void> thenAccept(Consumer<? super T> action) 
public CompletableFuture<Void> thenAcceptAsync(Consumer<? super T> action) 
public CompletableFuture<Void> thenAcceptAsync(Consumer<? super T> action, Executor executor) 

public CompletableFuture<Void> thenRun(Runnable action)
public CompletableFuture<Void> thenRunAsync(Runnable action)
public CompletableFuture<Void> thenRunAsync(Runnable action, Executor executor)
```
>这里延伸两个方法 `thenAccept` 和 `thenRun`。其实 和上面两个方法差不多，都是等待前面一个任务执行完 再执行。
>区别就在于是否接受上次执行结果和有无返回值：thenAccept接收前面任务的结果，且无返回值；而thenRun只要前面的任务执行完成，它就执行，不关心前面的执行结果如何，也无返回值。
如果前面的任务抛了异常，非正常结束，这两个方法是不会执行的，所以处理不了异常情况。

**例2：**
```
 CompletableFuture.supplyAsync(()->{
        return 5;
    }).thenApply((r)->{
        r = r + 1;
        return r;
    });
    
    //出现了异常，handle方法可以拿到异常 e
    CompletableFuture.supplyAsync(()->{
        int i = 10/0;
        return 5;
    }).handle((r, e)->{
        System.out.println(e);
        r = r + 1;
        return r;
    });
```

<br>
### 12.3.4 多任务组合关系
#### 12.3.4.1 AND
![image.png](JUC并发编程.assets\64cfac3db6904e83b484dc2d7177df04.png)
**thenCombine 和 thenAcceptBoth**
我们常常需要合并两个任务的结果，在对其进行统一处理，简言之，这里的回调任务需要等待两个任务都完成后再会触发。
```
public <U,V> CompletionStage<V> thenCombine(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn);
public <U,V> CompletionStage<V> thenCombineAsync(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn);
public <U,V> CompletionStage<V> thenCombineAsync(CompletionStage<? extends U> other,BiFunction<? super T,? super U,? extends V> fn,Executor executor);

public <U> CompletionStage<Void> thenAcceptBoth(CompletionStage<? extends U> other,BiConsumer<? super T, ? super U> action);
public <U> CompletionStage<Void> thenAcceptBothAsync(CompletionStage<? extends U> other,BiConsumer<? super T, ? super U> action);
public <U> CompletionStage<Void> thenAcceptBothAsync(CompletionStage<? extends U> other,BiConsumer<? super T, ? super U> action,     Executor executor);

public CompletableFuture<Void> runAfterBoth(CompletionStage<?> other, Runnable action);
public CompletableFuture<Void> runAfterBothAsync(CompletionStage<?> other, Runnable action);
public CompletableFuture<Void> runAfterBothAsync(CompletionStage<?> other, Runnable action, Executor executor);
```
>两个任务都完成了才会调用合并操作方法，传入已完成方法的结果值进行处理。
>`thenCombine`会将已完成任务的返回值作为参数，且有返回值；
>`thenAcceptBoth`会将已完成任务的返回值作为参数，没有返回值；
>`runAfterBoth`不会将已完成任务的返回值作为参数，且没有返回值；

**例3：**
```
private static void thenCombine() throws Exception {

        CompletableFuture<String> future1 = CompletableFuture.supplyAsync(()->{
            try {
                Thread.sleep(4000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            return "future1";
        });
        CompletableFuture<String> future2 = CompletableFuture.supplyAsync(()->{
            return "future2";
        });

        CompletableFuture<String> result = future1.thenCombine(future2, (r1, r2)->{
            return r1 + r2;
        });

        //这里的get是阻塞的，需要等上面两个任务都完成
        System.out.println(result.get());
    }
```

<br>
#### 12.3.4.2 OR

```
    public <U> CompletableFuture<U> applyToEither(CompletionStage<? extends T> other, Function<? super T, U> fn);
    public <U> CompletableFuture<U> applyToEitherAsync(CompletionStage<? extends T> other, Function<? super T, U> fn);
    public <U> CompletableFuture<U> applyToEitherAsync(CompletionStage<? extends T> other, Function<? super T, U> fn, Executor executor);

    public CompletableFuture<Void> acceptEither(CompletionStage<? extends T> other, Consumer<? super T> action);
    public CompletableFuture<Void> acceptEitherAsync(CompletionStage<? extends T> other, Consumer<? super T> action);
    public CompletableFuture<Void> acceptEitherAsync(CompletionStage<? extends T> other, Consumer<? super T> action, Executor executor);

    public CompletableFuture<Void> runAfterEither(CompletionStage<?> other, Runnable action);
    public CompletableFuture<Void> runAfterEitherAsync(CompletionStage<?> other, Runnable action);
    public CompletableFuture<Void> runAfterEitherAsync(CompletionStage<?> other, Runnable action, Executor executor);
```
>两个任务其中一个完成了就会调用操作方法。
>`applyToEither`会将已完成任务的返回值作为参数，且有返回值；
>`acceptEither`会将已完成任务的返回值作为参数，没有返回值；
>`runAfterEither`不会将已完成任务的返回值作为参数，且没有返回值；

<br>
#### 12.3.4.3 ALLOF （重点）
很多时候，不止存在两个异步任务，可能有几十上百个。我们需要等这些任务都完成后，再来执行相应的操作。那怎么集中监听所有任务执行结束与否呢？ allOf方法可以帮我们完成。
```
public static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs);
```
>它接收一个可变入参，既可以接收CompletableFuture单个对象，可以接收其数组对象。

**例4：**
```
public static void main(String[] args) throws Exception{
        long start = System.currentTimeMillis();
        CompletableFutureTest test = new CompletableFutureTest();
        // 结果集
        List<String> list = new ArrayList<>();

        List<Integer> taskList = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        // 全流式处理转换成CompletableFuture[]
        CompletableFuture[] cfs = taskList.stream()
                .map(integer -> CompletableFuture.supplyAsync(() -> test.calc(integer))
                        .thenApply(h->Integer.toString(h))
                        .whenComplete((s, e) -> {
                            System.out.println("任务"+s+"完成!result="+s+"，异常 e="+e+","+new Date());
                            list.add(s);
                        })
                ).toArray(CompletableFuture[]::new);
        
        CompletableFuture.allOf(cfs).join();
        
        System.out.println("list="+list+",耗时="+(System.currentTimeMillis()-start));
    }

    public int calc(Integer i) {
        try {
            if (i == 1) {
                Thread.sleep(3000);//任务1耗时3秒
            } else if (i == 5) {
                Thread.sleep(5000);//任务5耗时5秒
            } else {
                Thread.sleep(1000);//其它任务耗时1秒
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return i;
    }
```
全流式写法，综合了以上的一些方法，使用allOf集中阻塞，等待所有任务执行完成，取得结果集list。 这里有些CountDownLatch的感觉。

### 12.3.5 其他api
`get(5, TimeUnit.SECONDS);`   // 在该线程中获取异步处理的结果，如果超时抛出异常。
`cancel(true);`   // 使用 cancel() 方法来cancel task，并抛出 CancellationException 异常。boolean参数是一个无效值。

### 12.3.6 CompletableFuture使用有哪些注意点
#### 12.3.6.1 Future需要获取返回值，才能获取异常信息
Future需要获取返回值，才能获取到异常信息。如果不加 get()/join()方法，看不到异常信息。get()/join()时需要考虑是否加try...catch...或者使用exceptionally方法。

**join()和get()方法都是用来获取CompletableFuture异步之后的返回值，他们的区别是什么呢？**
get()方法抛出的是经过检查的异常，ExecutionException, InterruptedException 需要用户手动处理（抛出或者 try catch）；
join()方法抛出的是uncheck异常（即未经检查的异常)，不会强制开发者抛出。

#### 12.3.6.2 CompletableFuture的get()/join()方法是阻塞的。
CompletableFuture的get()方法是阻塞的，如果使用它来获取异步调用的返回值，需要添加超时时间。
```
CompletableFuture.get(5, TimeUnit.SECONDS);
```

#### 12.3.6.3 默认线程池的注意点
CompletableFuture代码中又使用了默认的线程池，处理的线程个数是电脑CPU核数-1。在大量请求过来的时候，处理逻辑复杂的话，响应会很慢。一般建议使用自定义线程池，优化线程池配置参数。

#### 12.3.6.4 自定义线程池时，注意饱和策略
CompletableFuture的get()方法是阻塞的，我们一般建议使用future.get(3, TimeUnit.SECONDS)。并且一般建议使用自定义线程池。

但是如果线程池拒绝策略是DiscardPolicy或者DiscardOldestPolicy，当线程池饱和时，会直接丢弃任务，不会抛弃异常。因此建议，CompletableFuture线程池策略最好使用`AbortPolicy`，然后耗时的异步线程，做好线程池隔离。

<br>
## 12.4 实际案例
**例5：**
```java
public void renderPage(CharSequence source) { 
        List<ImageInfo> info = scanForImageInfo(source); 
        info.forEach(imageInfo -> 
               CompletableFuture 
       		.supplyAsync(imageInfo::downloadImage) 
       		.thenAccept(this::renderImage)); 
        renderText(source); 
 }
```
>工厂方法supplyAsync返回一个新的CF，未指定线程池，就ForkJoinPool中运行指定的Supplier，完成时，Supplier的结果将会作为CF的结果。方法thenAccept会返回一个新的CompletableFuture，它将会执行指定的Consumer，在本例中也就是渲染给定的图片，即supplyAsync方法所产生的CompletableFuture的结果。
>- thenCompose：针对返回值为CompletableFuture的函数；
>- thenApply：针对返回值为其他类型的函数；
>- thenAccept：Consumer函数，接收上一阶段的输出作为本阶段的输入，返回值为 void 的函数；
>- thenRun：Runnable参数，不关心前一阶段的计算结果，无输入参数；
>- thenCombine：整合两个计算结果，示例如下
>```java
>    @Test
>    public void thenCombine() {
>        CompletableFuture
>                .supplyAsync(() -> "Hello")
>                .thenApply(s -> s + " MEANS")
>                .thenApply(String::toUpperCase)
>                .thenCombine(/*CompletableFuture.completeFuture("Java")*/CompletableFuture.supplyAsync(() -> " NIHAO"), (s1, s2) -> s1 + s2)
>                .thenAccept(System.out::println);
>    }
>```
>函数在处理的过程中，可能正常结束也可能异常退出。CF能够通过方法来分别组合这两种情况：
>- handle：针对接受一个值和一个 Throwable，并有返回值的函数；
>- whenComplete：针对接受一个值和一个 Throwable，并返回 void 的函数。

**例6：**
```java
Function<ImageInfo, ImageData> infoToData = imageInfo -> { 
   CompletableFuture<ImageData> imageDataFuture = 
       CompletableFuture.supplyAsync(imageInfo::downloadImage, executor); 
   try { 
       return imageDataFuture.get(5, TimeUnit.SECONDS); 
   } catch (InterruptedException e) { 
       Thread.currentThread().interrupt(); 
       imageDataFuture.cancel(true); 
       return ImageData.createIcon(e); 
   } catch (ExecutionException e) { 
       throw launderThrowable(e.getCause()); 
   } catch (TimeoutException e) { 
       return ImageData.createIcon(e); 
   } 
}
```
>**问题：当图片下载超时或失败时，我们想使用一个图标作为可见的指示器?**
CF暴露了一个名为get(long, TimeUnit)的方法，如果 CF在指定的时间内没有完成的话，将会抛出TimeoutException异常。我们可以使用它来定义一个函数，这个函数会将 ImageInfo转换为ImageData

**例7：**
```java
public void renderPage(CharSequence source) throws InterruptedException { 
       List<ImageInfo> info = scanForImageInfo(source); 
       info.forEach(imageInfo -> 
           CompletableFuture.runAsync(() -> 
               renderImage(infoToData.apply(imageInfo)), executor)); 
}
```
>页面可以通过连续调用infoToData来进行渲染。其中每个调用都会同步返回一个下载的图片，所以要并行下载的话，需要为它们各自创建一个新的异步任务。要实现这一功能，合适的工厂方法是CompletableFuture.runAsync()，它与supplyAsync类似，但是接受的参数是Runnable而不是Supplier（Runnable没有参数和返回值）。

<br>
#十三、JMM内存模型(java memory model)
## 13.1 什么是Volatile
Volatile是Java虚拟机提供`轻量级的同步机制`(不涉及到用户态和内核态切换，而是使用CPU嗅探)，没有synchronized强大。
1.`保证可见性`
2.`不保证原子性`
3.`禁止指令重排`

## 13.2 什么是JMM
JMM：Java内存模型，是一种概念和约定
1. **线程解锁前，必须把共享变量立刻刷回主存**
2. **线程加锁前，必须读取主存中的最新值到工作内存中**
3. **加锁和解锁是同一把锁**

## 13.3 共享变量的八种操作
![image.png](JUC并发编程.assets\db3113bb1b8743abbaad68b4d0c7fd0a.png)
- lock     （锁定）：作用于主内存的变量，把一个变量标识为线程独占状态
- unlock （解锁）：作用于主内存的变量，它把一个处于锁定状态的变量释放出来，释放后的变量才可以被其他线程锁定
- read    （读取）：作用于主内存变量，它把一个变量的值从主内存传输到线程的工作内存中，以便随后的load动作使用
- load     （载入）：作用于工作内存的变量，它把read操作从主存中变量放入工作内存中
- use      （使用）：作用于工作内存中的变量，它把工作内存中的变量传输给执行引擎，每当虚拟机遇到一个需要使用到变量的值，就会使用到这个指令
- assign  （赋值）：作用于工作内存中的变量，它把一个从执行引擎中接受到的值放入工作内存的变量副本中
- store    （存储）：作用于主内存中的变量，它把一个从工作内存中一个变量的值传送到主内存中，以便后续的write使用
- write 　（写入）：作用于主内存中的变量，它把store操作从工作内存中得到的变量的值放入主内存的变量中

`问题：线程B修改了主存的值，但是线程A不能即时可见`

JMM对这八种指令的使用，制定了如下规则：

- 不允许read和load、store和write操作之一单独出现。即使用了read必须load，使用了store必须write
- 不允许线程丢弃他最近的assign操作，即工作变量的数据改变了之后，必须告知主存
- 不允许一个线程将没有assign的数据从工作内存同步回主内存
- 一个新的变量必须在主内存中诞生，不允许工作内存直接使用一个未被初始化的变量。就是怼变量实施use、store操作之前，必须经过assign和load操作
- 一个变量同一时间只有一个线程能对其进行lock。多次lock后，必须执行相同次数的unlock才能解锁
- 如果对一个变量进行lock操作，会清空所有工作内存中此变量的值，在执行引擎使用这个变量前，必须重新load或assign操作初始化变量的值
- 如果一个变量没有被lock，就不能对其进行unlock操作。也不能unlock一个被其他线程锁住的变量
- 对一个变量进行unlock操作之前，必须把此变量同步回主内存

## 13.4 Volatile三大特性解析
- **①可见性**：可见性又叫读写可见。即一个共享变量N，当有两个线程T1、T2同时获取了N的值，T1修改N的值，而T2读取N的值，可见性规范要求T2读取到的值必须是T1修改后的值。
CPU都会有自己的高速缓存区，CPU发现共享变量被volatile修饰会立即做两件事：①`当前内核中线程工作内存中该共享变量刷新到主存`②`通知其他内核高速缓存区的该共享变量内存地址无效，需要从主存中获取变量`。
```java
public class JMMDemo {
    //不加volatile程序就会死循环，加volatile可以保证可见性
    private static int num = 0;
    public static void main(String[] args) {
        new Thread(()->{ //该线程对主线程修改了主内存的值是不知道的
            while(num == 0){

            }
        }).start();

        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        //将num修改为1，希望开启的线程能终止循环
        num = 1;
        System.out.println(num);
    }

}
```
>可以发现虽然修改了num的值，但是子线程的循环不终止，因为`子程序不知道主内存的值被修改过了`。此时需要使用**Volatile**，将`private static int num = 0`修改为`private volatile static int num = 0`即可。保证了共享变量的`可见性`。

**加锁同样可以保证变量的内存可见性：** 因为当一个线程进入 synchronizer 代码块后，线程获取到锁，会清空本地内存，然后从主内存中拷贝共享变量的最新值到本地内存作为副本，执行代码，又将修改后的副本值刷新到主内存中，最后线程释放锁。

<br>

- **②不保证原子性**：不能保证线程在执行任务的时候不被打扰也不被分割。

```java
public class JMMDemo2 {

    private volatile static int num = 0;

    public static void add(){
        num++;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                for (int j = 0; j < 500; j++) {
                    add();
                }
            }).start();
        }

        while(Thread.activeCount() > 2){ //java默认线程有两个，main和gc
            System.out.println("yield()");
            Thread.yield();
        }

        System.out.println(num);
    }

}
```
>如果是原子操作，那么最后的值为10000，但是实际打印经常小于10000。因为`num++不是原子操作`，导致多线程情况下产生并发问题；volatile无法改变操作的原子性。![方法底层操作步骤：获取值、加一、写回值](JUC并发编程.assets\89ca9f6b0d18495e909c77ec2fcb230c.png)
>- 可以通过加锁来解决；
>- 通过`原子类`解决，将int改为`private volatile static AtomicInteger num = new AtomicInteger()`，num++改为`num.getAndIncrement()`，保证变量操作的原子性。这些类的底层通过`Unsafe类`直接和操作系统挂钩，在内存中修改值而不是CPU中进行计算，`性能比加锁高得多`。

<br>

- **③禁止指令重排**：计算机执行顺序并不是按照程序顺序进行的。
源代码->编译器优化->指令并行也可能会重排->内存系统也会重排->执行
![image.png](JUC并发编程.assets\803152e0447a4bdf9de445ee08117913.png)
>为了避免因为线程A指令重排导致线程B的变量被线程A提前修改，需要引入指令重排。
被Volatile修饰的变量的前后会加上内存屏障，禁止指令顺序的交换。
>[内存屏障介绍](https://www.jianshu.com/p/64240319ed60)

## 13.5 Volatile最常用的地方
1. DCL饿汉式单例模式中，因为创建对象不是原子操作，指令重排可能导致线程拿到的对象是空对象，因此需要用volatile修饰实例对象。
2. cas保证变量可见性 
3. concurrenthashmap(1.7)的HashEntry的value用volatile修饰，保证其可见性。


<br>
#十四、单例模式
饿汉式、DCL懒汉式、内部类饿汉单例模式、枚举类饿汉单例模式

- **饿汉式**
```java

public class Singleton {

    //1.创建类的唯一实例，使用private static修饰
	private static Singleton instance=new Singleton();

	//2.将构造方法私有化，不允许外部直接创建对象
	private Singleton(){		
	}
	
	//3.提供一个用于获取实例的方法，使用public static修饰
	public static Singleton getInstance(){
		return instance;
	}
}
```

- **DCL懒汉式**
最初版本
 ```java
public class Singleton {

    private static Singleton instance;

    private Singleton(){
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                Singleton instance = Singleton.getInstance();
            }).start();
        }
    }

}
```
>会因为并发问题导致出现多个实例对象，所以不能用。

改进如下：
```java
public class Singleton {

    private static Singleton instance;

    private Singleton(){
        System.out.println(Thread.currentThread().getName());
    }
    //加锁进行多重判断，保证了效率和单例
    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                Singleton instance = Singleton.getInstance();
            }).start();
        }
    }

}
```
>但是instance = new Singleton()不是原子性操作，会执行
>- 1.分配内存空间 （实例化）
>- 2.执行构造方法  （初始化）
>- 3.将对象指向这个空间
可能因为指令重排导致线程A执行顺序为132，即先将空对象指向内存空间。那么线程B判断instance不为null，导致获取到空对象使得程序出错，因此需要禁止指令重排。

最终版DCL(Double Check Lock)懒汉单例模式如下
```java
public class Singleton {

    private volatile static Singleton instance;

    private Singleton(){
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) {
        for (int i = 0; i < 20; i++) {
            new Thread(()->{
                Singleton instance = Singleton.getInstance();
            }).start();
        }
    }

}
```

<br>

**内部类实现饿汉单例模式**
```java
public class Holder {

    private Holder(){};

    public static Holder  getInstance(){
        return InnerClass.HOLDER;
    }

    private static class InnerClass{
        private static final Holder HOLDER = new Holder();
    }

}
```
>静态内部类的优点是：外部类加载时并不需要立即加载内部类，内部类不被加载则不去初始化INSTANCE，故而不占内存。即当SingleTon第一次被加载时，并不需要去加载SingleTonHoler，只有当getInstance()方法第一次被调用时，才会去初始化INSTANCE,第一次调用getInstance()方法会导致虚拟机加载SingleTonHoler类，这种方法不仅能确保线程安全，从jvm虚拟机上保证了单例，并且也是懒式加载。


**通过反射破坏单例模式**
```java
public class Singleton {

    private volatile static Singleton instance;

    private Singleton(){
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        Singleton instance = Singleton.getInstance();
        Constructor<Singleton> declaredConstructor = Singleton.class.getDeclaredConstructor();
        declaredConstructor.setAccessible(true);
        Singleton singleton = declaredConstructor.newInstance();

        System.out.println(instance);
        System.out.println(singleton);
    }

}
```
>通过反射模式调用私有的构造器，在已有单例的情况下再次创建实例对象，破坏单例模式。

**防止反射破坏单例模式**
```java
public class Singleton {

    private volatile static Singleton instance;

    private Singleton(){
        if (instance != null) {
            throw new RuntimeException("不要试图破坏单例模式");
        }
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        Singleton instance = Singleton.getInstance();
        Constructor<Singleton> declaredConstructor = Singleton.class.getDeclaredConstructor();
        declaredConstructor.setAccessible(true);
        Singleton singleton = declaredConstructor.newInstance();

        System.out.println(instance);
        System.out.println(singleton);
    }

}
```
>在构造器中判断实例是否存在，如果存在还是调用了构造器，那么一定是通过反射机制进行调用的，那么抛出异常即可。
**再次破坏单例模式**
```java
public class Singleton {

    private volatile static Singleton instance;

    private Singleton(){
        if (instance != null) {
            throw new RuntimeException("不要试图破坏单例模式");
        }
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
//        Singleton instance = Singleton.getInstance();
        Constructor<Singleton> declaredConstructor = Singleton.class.getDeclaredConstructor();
        declaredConstructor.setAccessible(true);
        Singleton instance1 = declaredConstructor.newInstance();
        Singleton instance2 = declaredConstructor.newInstance();

        System.out.println(instance1);
        System.out.println(instance2);
    }

}
```
>如果不调用创建单例的方法，而直接使用反射创建多个实例对象，那么单例模式又被破坏了。

**再次防止单例模式被破坏**
```java
public class Singleton {

    private volatile static Singleton instance;

    private static boolean flag = false;

    private Singleton(){
        if (flag) {
            throw new RuntimeException("不要试图破坏单例模式");
        } else {
            flag = true;
        }
        System.out.println(Thread.currentThread().getName());
    }

    private static Singleton getInstance(){
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // volatile修饰后禁止指令重排
                }
            }
        }
        return instance;
    }

    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
//        Singleton instance = Singleton.getInstance();
        Constructor<Singleton> declaredConstructor = Singleton.class.getDeclaredConstructor();
        declaredConstructor.setAccessible(true);
        Singleton instance1 = declaredConstructor.newInstance();
        Singleton instance2 = declaredConstructor.newInstance();

        System.out.println(instance1);
        System.out.println(instance2);
    }

}
```
>不使用对象是否存在来判断，而是`使用标志位`，保证私有的构造方法只会被调用一次。但是有可能标志位的名字被搞事者知道，使用反射重置标志位，造成单例模式被破坏。因此DCL单例模式并不是饿汉式单例模式的最佳实现。


**枚举类实现单例模式**
```java
public enum EnumSingle {

    INSTANCE;

    public EnumSingle getInstance(){
        return INSTANCE;
    }

    public void doSomething(){
        System.out.println("doSomething");
    }

}

class Test {
    public static void main(String[] args) throws NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        //正常获取实例对象
        EnumSingle instance1 = EnumSingle.INSTANCE.getInstance();
        //通过反射获取实例对象
        Constructor<EnumSingle> declaredConstructor = EnumSingle.class.getDeclaredConstructor(null);
        declaredConstructor.setAccessible(true);
        EnumSingle instance2 = declaredConstructor.newInstance();//通过反射调用构造方法会抛异常NoSuchMethodException

        System.out.println(instance1);
        System.out.println(instance2);
    }
}
```
>如果对枚举类使用反射构造对象，会抛出`throw new IllegalArgumentException("Cannot reflectively create enum objects")`;![反射调用构造器方法部分源码](JUC并发编程.assets\83962ada20d547acbc5b86e98e26843f.png)
>
>但是当我们通过反射调用无参构造器时抛出异常为NoSuchMethodException；因此通过javap -p xxx.class反编译字节码得到源码如下![反编译源码](JUC并发编程.assetsadaf904e38e41cb80ab0f81a6a52dbf.png)
>
>事实证明javap和jd-gui.exe反编译软件不行，通过jad进行反编译jad.exe -sjava xxx.class得到源码。
>```java
>public final class EnumSingle extends Enum
>{
>
>    public static EnumSingle[] values()
>    {
>        return (EnumSingle[])$VALUES.clone();
>    }
>
>    public static EnumSingle valueOf(String name)
>    {
>        return (EnumSingle)Enum.valueOf(com/cj/schedule/EnumSingle, name);
>    }
>
>    private EnumSingle(String s, int i)
>    {
>        super(s, i);
>    }
>
>    public EnumSingle getInstance()
>    {
>        return INSTANCE;
>    }
>
>    public static final EnumSingle INSTANCE;
>    private static final EnumSingle $VALUES[];
>
>    static 
>    {
>        INSTANCE = new EnumSingle("INSTANCE", 0);
>        $VALUES = (new EnumSingle[] {
>            INSTANCE
>        });
>    }
>}
>```
>发现枚举类中的构造器其实是有参构造器

**结论：**
使用枚举类实现饿汉式单例模式是最好的，不会因为反射造成单例模式失效。

<br>


#十五、CAS
## 15.1 什么是CAS
**CAS：**compareAndSwap是原子类的底层方法。当且仅当内存地址V的值与预期值A相等时，将内存地址V的值修改为B，否则就什么都不做。整个比较并替换的操作是一个原子操作。
getAndAddInt方法解析：拿到内存位置的最新值v，使用CAS尝试修将内存位置的值修改为目标值v+delta，如果修改失败，则获取该内存位置的新值v，然后继续尝试，直至修改成功(自旋锁)。

**缺点：**
- 循环会耗时
- 一次只能保证一个共享变量的原子性
- 存在ABA问题 

**应用：**
- 实现原子操作
- 自定义自旋锁

CAS比较与交换的伪代码可以表示为：![image.png](JUC并发编程.assets3c90a0225648fa9121f5e1180b17e2.png)

```java
do{

备份旧数据；

基于旧数据构造新数据；

}while(!CAS( 内存地址，备份的旧数据，新数据 ))
```
>因为t1和t2线程都同时去访问同一变量56，所以他们会把主内存的值完全拷贝一份到自己的工作内存空间，所以t1和t2线程的预期值都为56。
假设t1在与t2线程竞争中线程t1能去更新变量的值，而其他线程都失败。（失败的线程并不会被挂起，而是被告知这次竞争中失败，并可以再次发起尝试）。t1线程去更新变量值改为57，然后写到内存中。此时对于t2来说，内存值变为了57，与预期值56不一致，就操作失败了（想改的值不再是原来的值）。
（上图通俗的解释是：CPU去更新一个值，但如果想改的值不再是原来的值，操作就失败，因为很明显，有其它操作先改变了这个值。）
就是指当两者进行比较时，如果相等，则证明共享数据没有被修改，替换成新值，然后继续往下运行；如果不相等，说明共享数据已经被修改，放弃已经所做的操作，然后重新执行刚才的操作。`首先var1是`。

**我的理解：**getAndAddInt方法将自身对象var1、物理偏移量valueOffset和改变的增量var4作为参数，getIntVolatile方法因为volatile保证了可见性，读取到的是主存中的真实值var5，将自身对象var1、物理偏移量valueOffset、主存中的值var5和计算后的最终值作为参数执行compareAndSwapInt方法，如果工作内存中的值和主存中的值相同，则将最终值并写入到主存。否则再次读取var5的值，重复执行compareAndSwapInt方法.（原理和乐观锁相同，只是加了自旋）
![image](JUC并发编程.assets\6c98e82c22224b7aa23877420676ed6c.png)


## 15.2 Unsafe类
Java无法操作内存，Java可以调用C++(Native)，C++可以操作内存，而Java可以通过Unsafe类操作内存。
```java
public class CASDemo {


    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(2020);

        //如果期望的值达到了，那么更新为指定的值;否则不更新
        boolean flag = atomicInteger.compareAndSet(2020, 2021);
        System.out.println(atomicInteger.get());

        atomicInteger.getAndIncrement()
    }

}
```
>atomicInteger.getAndIncrement()的源码分析
>```java
>public final int getAndIncrement() {
>    return unsafe.getAndAddInt(this, valueOffset, 1);
>}
>```
>```java
>public final int getAndAddInt(Object var1, long var2, int var4) {
>    int var5;
>    //这是一个自旋锁
>    do {
>        var5 = this.getIntVolatile(var1, var2); //通过对象v1和偏移量v2获取内存地址中的值
>    } while(!this.compareAndSwapInt(var1, var2, var5, var5 + var4));//再次通过对象v1和偏移量v2计算是否等于v5，等于则将该值加1
>
>    return var5;
>    }
>```
>

## 15.3 ABA问题(狸猫换太子)
在原子类进行操作时会判断原始值和期望值是否相同，相同则进行计算。如果在计算中原始值被修改为其他值马上又被改回来，那么计算还是会执行，但是原始值已经被修改了多次。
通过添加版本号（乐观锁）来解决，原子类提供了带版本号的计算类`AtomicStampedReference`。
```java
public class ABADemo {
    public static void main(String[] args) {
        AtomicStampedReference<Integer> integerAtomicStampedReference = new AtomicStampedReference<>(100,1);

        new Thread(()->{
            int stamp = integerAtomicStampedReference.getStamp();
            System.out.println("a1->" + stamp);

            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            boolean f1 = integerAtomicStampedReference.compareAndSet(100, 101, stamp, stamp + 1);
            System.out.println("修改->" + f1 + "  stamp->" + integerAtomicStampedReference.getStamp());
            System.out.println(integerAtomicStampedReference.getReference());

            boolean f2 = integerAtomicStampedReference.compareAndSet(101, 100, integerAtomicStampedReference.getStamp(), integerAtomicStampedReference.getStamp() + 1);
            System.out.println("修改->" + f2 + "  stamp->" + integerAtomicStampedReference.getStamp());
            System.out.println(integerAtomicStampedReference.getReference());
        }).start();

        new Thread(()->{
            int stamp = integerAtomicStampedReference.getStamp();
            System.out.println("b1->" + stamp);

            boolean f1 = integerAtomicStampedReference.compareAndSet(100, 101, stamp, stamp + 1);
            System.out.println("修改->" + f1 + "  stamp->" + integerAtomicStampedReference.getStamp());
            System.out.println(integerAtomicStampedReference.getReference());

        }).start();
    }
}
```
>结果：
a1->1
b1->1
修改->true  stamp->2
101
修改->false  stamp->2
101
>修改->true  stamp->3
100
>
>需要注意的是在子类内部通过`expectedReference == current.reference &&expectedStamp == current.stamp`判断，即比较对象地址而不是对象的值，需要注意这个大坑。。Integer和Long会创建值为-128到127的对象进行复用。因此上述例子中值需要在-128到127之间，或使用String类型而非包装类。

<br>
<br>
#十六、Java中的锁
## 16.1 公平和非公平锁
**非公平锁：可以插队**
```java
    public ReentrantLock() {
        sync = new NonfairSync();
    }
```
**公平锁：不能插队**
```java
    public ReentrantLock(boolean fair) {
        sync = fair ? new FairSync() : new NonfairSync();
    }
```

<br>

##16.2 可重入锁
可重入锁(递归锁)：拿到外面的锁之后就可以自动获得里面的锁。
```java
/*
 * Synchronized是可重入锁
 */
public class ReentrantLockDemo {
    public static void main(String[] args) {
        Phone phone = new Phone();
        
        new Thread(()->{
            phone.sms();
        },"A").start();

        new Thread(()->{
            phone.sms();
        },"B").start();
    }
}

class Phone{
    public synchronized void sms(){
        System.out.println(Thread.currentThread().getName() + "-> sms");
        call();
    }

    public synchronized void call(){
        System.out.println(Thread.currentThread().getName() + "-> call");
    }
}
```
>结果：
A-> sms
A-> call
B-> sms
B-> call
>
>线程A获取到对象锁执行sms方法，调用里面的call方法也需要锁，因为调用对象就是锁，所以可以执行该方法。方法结束后释放锁，线程B获取对象锁继续执行。

<br>

```java
public class ReentrantLockDemo1 {
    public static void main(String[] args) {
        Phone1 phone1 = new Phone1();

        new Thread(()->{
            phone1.sms();
        },"A").start();

        new Thread(()->{
            phone1.sms();
        },"B").start();
    }
}

class Phone1{
    ReentrantLock lock = new ReentrantLock();

    public void sms(){
        lock.lock();
        try {
            System.out.println(Thread.currentThread().getName() + "-> sms");
            call();
        } catch (Exception e) {
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }

    public void call(){
        lock.lock();
        try {
            System.out.println(Thread.currentThread().getName() + "-> call");
        } catch (Exception e) {
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }
}
```
>结果：
A-> sms
A-> call
B-> sms
B-> call
>
>结果相同，但是原理与Synchronized不同；因为两个方法都创建的各自的锁，在获取A线程的锁调用sms方法时，内部的call方法也需要锁。因此

<br>

## 16.3 自旋锁SpinLock
**优点：**
- 自旋锁不会使线程状态发生切换，一直处于用户态，即线程一直都是active的；不会使线程进入阻塞状态，减少了不必要的上下文切换，执行速度快。
非自旋锁在获取不到锁的时候会进入阻塞状态，从而进入内核态，当获取到锁的时候需要从内核态恢复，需要线程上下文切换。 （线程被阻塞后便进入内核（Linux）调度状态，这个会导致系统在用户态与内核态之间来回切换，严重影响锁的性能）

**缺点：**
- 如果某个线程持有锁的时间过长，就会导致其它等待获取锁的线程进入循环等待，消耗CPU。使用不当会造成CPU使用率极高。
- 上面Java实现的自旋锁不是公平的，即无法满足等待时间最长的线程优先获取锁。不公平的锁就会存在“线程饥饿”问题。

**自定义非公平不可重入自旋锁**
```java
public class SpinLockDemo {
    public static void main(String[] args) {
        Phone2 phone2 = new Phone2();

        new Thread(()->{
            phone2.call();
        },"A").start();

        new Thread(()->{
            phone2.call();
        },"B").start();
    }
}

class Phone2{
    SpinLock lock = new SpinLock();

    public void call(){
        lock.lock();
        System.out.println(Thread.currentThread().getName() + "->call");
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        lock.unlock();
    }

}

class SpinLock{

    private AtomicReference<Thread> atomicReference = new AtomicReference<>();

    public void lock(){
        Thread thread = Thread.currentThread();
        while (!atomicReference.compareAndSet(null, thread)) {
        }
        System.out.println(thread.getName() + "->lock");
    }

    public void unlock(){
        Thread thread = Thread.currentThread();
        atomicReference.compareAndSet(thread, null);
        System.out.println(thread.getName() + "->unLock");
    }
}
```
>`使用原子类判断锁是否被占用`。创建Phone2对象，该对象属性中包含自旋锁。调用Phone2对象的call方法，会调用lock方法将原子类置为当前线程。当其他线程再次调用该方法时会尝试上锁，原子类的值不为null，所以一直自旋，直到上锁的线程调用unlock方法将原子类的值置为null，其他线程才能再次上锁。

**自定义非公平可重入自旋锁**
```java
public class ReentrantSpinLock {

    private AtomicReference cas = new AtomicReference();
    private int count;

    public void lock() {
        Thread current = Thread.currentThread();
        if (current == cas.get()) { // 如果当前线程已经获取到了锁，线程数增加一，然后返回
            count++;
            return;
        }
        // 如果没获取到锁，则通过CAS自旋
        while (!cas.compareAndSet(null, current)) {

        }
    }

    public void unlock() {
        Thread cur = Thread.currentThread();
        if (cur == cas.get()) {
            if (count > 0) {// 如果大于0，表示当前线程多次获取了该锁，释放锁通过count减一来模拟
                count--;
            } else {// 如果count==0，可以将锁释放，这样就能保证获取锁的次数与释放锁的次数是一致的了。
                cas.compareAndSet(cur, null);
            }
        }
    }
}
```

<br>

## 16.4 死锁
排除死锁的四要素：
- 互斥：某种资源一次只允许一个进程访问，即该资源一旦分配给某个进程，其他进程就不能再访问，直到该进程访问结束。
- 占有且等待：一个进程本身占有资源（一种或多种），同时还有资源未得到满足，正在等待其他进程释放该资源。
- 不可抢占：不能抢占其他线程已有的某项资源。
- 循环等待：存在一个进程链，使得每个进程都占有下一个进程所需的至少一种资源。
```java
public class DeadLockDemo {

    public static void main(String[] args) {
        DeadLockDemo p1 = new DeadLockDemo();
        DeadLockDemo p2 = new DeadLockDemo();

        new Thread(() -> {
            while (true) {
                synchronized (p1) {
                    System.out.println("线程A" + "-获取p1锁-等待p2锁");
                    try {
                        TimeUnit.SECONDS.sleep(3);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    synchronized (p2) {
                        System.out.println("线程A" + "-获取p2锁");
                    }
                }
            }
        }, "A").start();

        new Thread(() -> {
            while (true) {
                synchronized (p2) {
                    System.out.println("线程B" + "-获取p2锁-等待p1锁");
                    try {
                        TimeUnit.SECONDS.sleep(2);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    synchronized (p1) {
                        System.out.println("线程B" + "-获取p1锁");
                    }
                }
            }
        }, "B").start();
    }
}
```

>结果：
线程A-获取p1锁-等待p2锁
线程B-获取p2锁-等待p1锁
>
>线程A持有p1锁等待线程B释放p2锁；线程B持有p2锁等待线程A释放p1锁。相互僵持造成线程阻塞，形成死锁。

```java
public class DeadLockDemo {

    public static void main(String[] args) {
        ReentrantLock lock1 = new ReentrantLock();
        ReentrantLock lock2 = new ReentrantLock();

        new Thread(() -> {
            while (true) {
                lock1.lock();
                System.out.println("线程A" + "-获取p1锁-等待p2锁");
                try {
                    TimeUnit.SECONDS.sleep(3);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                lock2.lock();
                System.out.println("线程A" + "-获取p2锁");
                lock2.unlock();
                lock1.unlock();
            }

        }, "A").start();

        new Thread(() -> {
            while (true) {
                lock2.lock();
                System.out.println("线程B" + "-获取p2锁-等待p1锁");
                try {
                    TimeUnit.SECONDS.sleep(2);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                lock1.lock();
                System.out.println("线程B" + "-获取p1锁");
                lock1.unlock();
                lock2.unlock();
            }
        }, "B").start();
    }
}
```
>ReentrantLock锁也是同理

<br>

**判断代码中是否有死锁情况**
1.使用jps查看所有的java进程，记录进程号。
2.执行jstack 19088，查看该进程是否有死锁问题
```
Found one Java-level deadlock:
=============================
"B":
  waiting for ownable synchronizer 0x000000076b0a41b0, (a java.util.concurrent.locks.ReentrantLock$NonfairSync),

  which is held by "A"
"A":
  waiting for ownable synchronizer 0x000000076b0a41e0, (a java.util.concurrent.locks.ReentrantLock$NonfairSync),

  which is held by "B"

Found 1 deadlock.
```
**排除问题：**
1.查看日志
2.查看堆栈信息
>win中通过指令 `jps -l | findstr xxx` 查询到程序进程号，然后通过`jstack pid` 打印堆栈信息
centos中通过指令`jps | grep xxx`查询到程序进程号，然后通过`jstack pid` 打印堆栈信息
![image.png](JUC并发编程.assets\6e7e15afd3ab495f8428a5d753fba9ae.png)
