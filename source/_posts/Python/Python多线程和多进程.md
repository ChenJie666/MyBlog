---
title: Python多线程和多进程
categories:
- Python
---
# 一、简介
**什么是线程？**
      线程也叫轻量级进程，是操作系统能够进行运算调度的最小单位，它被包涵在进程之中，是进程中的实际运作单位。
      线程自己不拥有系统资源，只拥有一点儿在运行中必不可少的资源，但它可与同属一个进程的其他线程共享进程所拥有的全部资源。一个线程可以创建和撤销另一个线程，同一个进程中的多个线程之间可以并发执行。

**为什么要使用多线程？**
    线程在程序中是独立的、并发的执行流。与分隔的进程相比，进程中线程之间的隔离程度要小，它们共享内存、文件句柄和其他进程应有的状态。
    因为线程的划分尺度小于进程，使得多线程程序的并发性高。进程在执行过程之中拥有独立的内存单元，而多个线程共享内存，从而极大的提升了程序的运行效率。
    线程比进程具有更高的性能，这是由于同一个进程中的线程都有共性，多个线程共享一个进程的虚拟空间。线程的共享环境包括进程代码段、进程的共有数据等，利用这些共享的数据，线程之间很容易实现通信。
    操作系统在创建进程时，必须为改进程分配独立的内存空间，并分配大量的相关资源，但创建线程则简单得多。因此，使用多线程来实现并发比使用多进程的性能高得要多。

**总结起来，使用多线程编程具有如下几个优点：**
    进程之间不能共享内存，但线程之间共享内存非常容易。
    操作系统在创建进程时，需要为该进程重新分配系统资源，但创建线程的代价则小得多。因此使用多线程来实现多任务并发执行比使用多进程的效率高。python语言内置了多线程功能支持，而不是单纯地作为底层操作系统的调度方式，从而简化了python的多线程编程。

<br>
# 二、创建多线程和多进程
## 2.1 普通方式创建
### 2.1.1 多线程
```
import threading
from threading import Lock,Thread
import time

def run(n):
    print('task', n)
    time.sleep(1)
    print('2s')
    time.sleep(1)
    print('1s')
    time.sleep(1)
    print('0s')
    time.sleep(1)


if __name__ == '__main__':
    t1 = threading.Thread(target=run, args=('t1',))  # target是要执行的函数名（不是函数），args是函数对应的参数，以元组的形式存在
    t2 = threading.Thread(target=run, args=('t2',))
    t1.start()
    t2.start()
```

### 2.1.2 多进程
相比较于threading模块用于创建python多线程，python提供multiprocessing用于创建多进程。先看一下创建进程的两种方式。
```
import time
import multiprocessing

def run(n):
    print('task', n)
    time.sleep(1)
    print('2s')
    time.sleep(1)
    print('1s')
    time.sleep(1)
    print('0s')
    time.sleep(1)

if __name__ == '__main__':
    t1 = multiprocessing.Process(target=run, args=('t1',))
    t2 = multiprocessing.Process(target=run, args=('t2',))
    t1.start()
    t2.start()
```

## 2.2 自定义对象方式创建
### 2.2.1 多线程
继承threading.Thread来定义线程类，其本质是重构Thread类中的run方法
```
import threading
import time


class MyThread(threading.Thread):
    def __init__(self, n):
        super().__init__()
        self.n = n

    def run(self) -> None:
        print('task', self.n)
        time.sleep(1)
        print('2s')
        time.sleep(1)
        print('1s')
        time.sleep(1)
        print('0s')
        time.sleep(1)

if __name__ == '__main__':
    t1 = MyThread('t1')
    t2 = MyThread('t2')
    t1.start()
    t2.start()
```

## 2.2.2 多进程
改变父类为multiprocessing.Process即可。
```
import time
import multiprocessing

# class MyThread(multiprocessing.Process):
    def __init__(self, n):
        super().__init__()
        self.n = n

    def run(self) -> None:
        print('task', self.n)
        time.sleep(1)
        print('2s')
        time.sleep(1)
        print('1s')
        time.sleep(1)
        print('0s')
        time.sleep(1)


if __name__ == '__main__':
    t1 = MyThread('t1')
    t2 = MyThread('t2')
    t1.start()
    t2.start()
```

## 2.3 守护线程
下面这个例子，这里使用setDaemon(True)把所有的子线程都变成了主线程的守护线程，因此当主线程结束后，子线程也会随之结束，所以当主线程结束后，整个程序就退出了。
    所谓’线程守护’，就是主线程不管该线程的执行情况，只要是其他子线程结束且主线程执行完毕，主线程都会关闭。也就是说: 主线程不等待该守护线程的执行完再去关闭。
```
import time
import threading

def run(n):
    print('task', n)
    time.sleep(1)
    print('3s')
    time.sleep(1)
    print('2s')
    time.sleep(1)
    print('1s')

if __name__ == '__main__':
    t = threading.Thread(target=run, args=('t1',))
    t.setDaemon(True)
    t.start()
    print('end')
```
通过执行结果可以看出，设置守护线程之后，当主线程结束时，子线程也将立即结束，不再执行。
为了让守护线程执行结束之后，主线程再结束，我们可以使用join方法，让主线程等待子线程执行
```
def run(n):
    print('task', n)
    time.sleep(2)
    print('5s')
    time.sleep(2)
    print('3s')
    time.sleep(2)
    print('1s')


if __name__ == '__main__':
    t = threading.Thread(target=run, args=('t1',))
    t.setDaemon(True)  # 把子线程设置为守护线程，必须在start()之前设置
    t.start()
    t.join()  # 设置主线程等待子线程结束
    print('end')
```

## 2.4 资源池
### 2.4.1 线程池
#### 2.4.1.1 threadpool模块
threadpool是一个比较老的模块了，逐渐被其他模块取代
```
import threadpool
import time


def sayhello(a):
    print("hello: " + a)
    time.sleep(2)


if __name__ == '__main__':
    global result
    seed = ["a", "b", "c"]
    # 定义一个线程池
    task_pool = threadpool.ThreadPool(5)
    # 创建了要开启多线程的函数，函数相关参数和回调函数
    requests = threadpool.makeRequests(sayhello, seed)
    # 将所有要运行的请求放到线程池中(参数数量决定任务数量)
    for req in requests:
        task_pool.putRequest(req)
    # 等待所有线程完成后退出
    task_pool.wait()

```

#### 2.4.1.2 concurrent.futures模块
concurrent.futures模块是python3中自带的模块，python2.7以上版本也可以安装使用。
线程池优秀的设计理念在于：他返回的结果并不是执行完毕后的结果，而是futures的对象，这个对象会在未来存储线程执行完毕的结果，这一点也是异步编程的核心。python为了提高与统一可维护性，多线程多进程和协程的异步编程都是采取同样的方式。
```
from concurrent.futures import ThreadPoolExecutor
import time

def sleeper(secs):
    time.sleep(secs)
    print('I slept for {} seconds'.format(secs))
    return secs

with ThreadPoolExecutor(max_workers=3) as executor:
    times = [4, 1, 2]
    start_t = time.time()

    futs = [executor.submit(sleeper, secs) for secs in times]
    for fut in futs:
        print(fut.result())

    print(time.time() - start_t)

# 结果如下
I slept for 1 seconds
I slept for 2 seconds
I slept for 4 seconds
4
1
2
```
上述例子是直接遍历future任务来获取返回结果，可以发现for循环会按顺序遍历所有的future任务，如果有一个任务未执行完会一直堵塞，直到该任务完成后才会继续遍历。
可以通过as_completed方法来避免情况发生，提高效率
```
from concurrent.futures import ThreadPoolExecutor, as_completed
import time

def sleeper(secs):
    time.sleep(secs)
    print('I slept for {} seconds'.format(secs))
    return secs

with ThreadPoolExecutor(max_workers=3) as executor:
    times = [4, 1, 2]
    start_t = time.time()

    futs = [executor.submit(sleeper, secs) for secs in times]
    for fut in as_completed(futs):
        print(fut.result())

    print(time.time() - start_t)


# 结果如下
I slept for 1 seconds
1
I slept for 2 seconds
2
I slept for 4 seconds
4
```
可以发现，as_completed对集合进行了重新排序，将执行完成的任务放到集合的前面，避免了已经执行完成的任务被前面的任务堵塞，导致效率降低。

还可以使用回调函数来进行后序处理，使用的是同一个线程
```
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import threading

def sleeper(secs):
    print("threadPool:" + str(threading.currentThread()))
    time.sleep(secs)
    print('I slept for {} seconds'.format(secs))
    return secs

def call_back(arg):
    print("callback")

with ThreadPoolExecutor(max_workers=3) as executor:
    print("Main:" + str(threading.currentThread()))
    times = [4, 1, 2]
    start_t = time.time()

    futs = [executor.submit(sleeper, secs) for secs in times]
    for fut in as_completed(futs):
        fut.add_done_callback(call_back)
        print(fut.result())

    print(time.time() - start_t)

# 结果如下
I slept for 1 seconds
callback
1
I slept for 2 seconds
callback
2
I slept for 4 seconds
callback
4
```

### 2.4.1.3 自定义线程池
```
import threading
import Queue
import hashlib
import logging
from utils.progress import PrintProgress
from utils.save import SaveToSqlite


class ThreadPool(object):
    def __init__(self, thread_num, args):

        self.args = args
        self.work_queue = Queue.Queue()
        self.save_queue = Queue.Queue()
        self.threads = []
        self.running = 0
        self.failure = 0
        self.success = 0
        self.tasks = {}
        self.thread_name = threading.current_thread().getName()
        self.__init_thread_pool(thread_num)

    # 线程池初始化
    def __init_thread_pool(self, thread_num):
        # 下载线程
        for i in range(thread_num):
            self.threads.append(WorkThread(self))
        # 打印进度信息线程
        self.threads.append(PrintProgress(self))
        # 保存线程
        self.threads.append(SaveToSqlite(self, self.args.dbfile))

    # 添加下载任务
    def add_task(self, func, url, deep):
        # 记录任务，判断是否已经下载过
        url_hash = hashlib.new('md5', url.encode("utf8")).hexdigest()
        if not url_hash in self.tasks:
            self.tasks[url_hash] = url
            self.work_queue.put((func, url, deep))
            logging.info("{0} add task {1}".format(self.thread_name, url.encode("utf8")))

    # 获取下载任务
    def get_task(self):
        # 从队列里取元素，如果block=True,则一直阻塞到有可用元素为止。
        task = self.work_queue.get(block=False)

        return task

    def task_done(self):
        # 表示队列中的某个元素已经执行完毕。
        self.work_queue.task_done()

    # 开始任务
    def start_task(self):
        for item in self.threads:
            item.start()

        logging.debug("Work start")

    def increase_success(self):
        self.success += 1

    def increase_failure(self):
        self.failure += 1

    def increase_running(self):
        self.running += 1

    def decrease_running(self):
        self.running -= 1

    def get_running(self):
        return self.running

    # 打印执行信息
    def get_progress_info(self):
        progress_info = {}
        progress_info['work_queue_number'] = self.work_queue.qsize()
        progress_info['tasks_number'] = len(self.tasks)
        progress_info['save_queue_number'] = self.save_queue.qsize()
        progress_info['success'] = self.success
        progress_info['failure'] = self.failure

        return progress_info

    def add_save_task(self, url, html):
        self.save_queue.put((url, html))

    def get_save_task(self):
        save_task = self.save_queue.get(block=False)

        return save_task

    def wait_all_complete(self):
        for item in self.threads:
            if item.isAlive():
                # join函数的意义，只有当前执行join函数的线程结束，程序才能接着执行下去
                item.join()

# WorkThread 继承自threading.Thread
class WorkThread(threading.Thread):
    # 这里的thread_pool就是上面的ThreadPool类
    def __init__(self, thread_pool):
        threading.Thread.__init__(self)
        self.thread_pool = thread_pool

    #定义线程功能方法，即，当thread_1，...，thread_n，调用start（）之后，执行的操作。
    def run(self):
        print (threading.current_thread().getName())
        while True:
            try:
                # get_task()获取从工作队列里获取当前正在下载的线程，格式为func,url,deep
                do, url, deep = self.thread_pool.get_task()
                self.thread_pool.increase_running()

                # 判断deep，是否获取新的链接
                flag_get_new_link = True
                if deep >= self.thread_pool.args.deep:
                    flag_get_new_link = False

                # 此处do为工作队列传过来的func，返回值为一个页面内容和这个页面上所有的新链接
                html, new_link = do(url, self.thread_pool.args, flag_get_new_link)

                if html == '':
                    self.thread_pool.increase_failure()
                else:
                    self.thread_pool.increase_success()
                    # html添加到待保存队列
                    self.thread_pool.add_save_task(url, html)

                # 添加新任务，即，将新页面上的不重复的链接加入工作队列。
                if new_link:
                    for url in new_link:
                        self.thread_pool.add_task(do, url, deep + 1)

                self.thread_pool.decrease_running()
                # self.thread_pool.task_done()
            except Queue.Empty:
                if self.thread_pool.get_running() <= 0:
                    break
            except Exception, e:
                self.thread_pool.decrease_running()
                # print str(e)
                break
```

### 2.4.2 进程池
进程池同样使用multiprocessing模块
```
from multiprocessing import Pool
import time,os

def worker(arg):
    print("子进程{}执行中, 父进程{}".format(os.getpid(),os.getppid()))
    time.sleep(2)
    print("子进程{}终止".format(os.getpid()))

if __name__ == "__main__":
    print("本机为",os.cpu_count(),"核 CPU")
    print("主进程{}执行中, 开始时间={}".format(os.getpid(), time.strftime('%Y-%m-%d %H:%M:%S')))
    start = time.time()

    l = Pool(processes=5)
    # 创建子进程实例
    for i in range(10):
        # l.apply(worker,args=(i,))      # 同步执行（Python官方建议废弃）
        l.apply_async(worker,args=(i,))  # 异步执行

    # 关闭进程池，停止接受其它进程
    l.close()
    # 阻塞进程
    l.join()
    
    stop = time.time()
    print("主进程终止,结束时间={}".format(time.strftime('%Y-%m-%d %H:%M:%S')))
    print("总耗时 %s 秒" % (stop - start))
```
可以通过异步回调来进行后序操作
```
from multiprocessing import Process,Pool
import os
import time
import random
 
#子进程任务
def download(f):
    print('__进程池中的进程——pid=%d,ppid=%d'%(os.getpid(),os.getppid()))
    for i in range(3):
        print(f,'--文件--%d'%i)
        time.sleep(random.randint(1, 9))
        # time.sleep(1)
    return {"result": 1, "info": '下载完成！'}
 
#主进程调用回调函数
def alterUser(msg):
    print("----callback func --pid=%d"%os.getpid())
    print("get result:", msg["info"])
 
if __name__ == "__main__":
    p = Pool(3)
    p.apply_async(func=download, args=(1111,), callback=alterUser)
    p.apply_async(func=download, args=(2222,), callback=alterUser)
    p.apply_async(func=download, args=(3333,), callback=alterUser)
    #当func执行完毕后，return的东西会给到回调函数callback
    print("---start----")
    p.close()#关闭进程池，关闭后，p不再接收新的请求。
    p.join()
    print("---end-----")
```

## 2.5 Subprocess模块
python提供了Sunprocess模块可以在程序执行过程中，调用外部的程序。
如我们可以在python程序中打开记事本，打开cmd，或者在某个时间点关机:
```
>>> import subprocess
>>> subprocess.Popen(['cmd'])
<subprocess.Popen object at 0x0339F550>
>>> subprocess.Popen(['notepad'])
<subprocess.Popen object at 0x03262B70>
>>> subprocess.Popen(['shutdown', '-p'])
```

<br>
# 三、资源和锁（多线程）
线程时进程的执行单元，进程时系统分配资源的最小执行单位，所以在同一个进程中的多线程是共享资源的。
  由于线程之间是进行随机调度，并且每个线程可能只执行n条执行之后，当多个线程同时修改同一条数据时可能会出现脏数据，所以出现了线程锁，即同一时刻允许一个线程执行操作。线程锁用于锁定资源，可以定义多个锁，像下面的代码，当需要独占某一个资源时，任何一个锁都可以锁定这个资源，就好比你用不同的锁都可以把这个相同的门锁住一样。
  由于线程之间是进行随机调度的，如果有多个线程同时操作一个对象，如果没有很好地保护该对象，会造成程序结果的不可预期，我们因此也称为“线程不安全”。
  为了防止上面情况的发生，就出现了锁（Lock）。

## 3.1 互斥锁
此处有一个公共资源，就是n。如果是单线程执行，那么最终n会被扣除到0，但是多线程下资源不安全，最终结果不是0；所以我们需要添加锁来保证资源安全。
```
def work():
    global n
    lock.acquire()   # 注销掉锁会导致线程不安全
    temp = n
    time.sleep(0.1)
    n = temp-1
    lock.release()  # 注销掉锁会导致线程不安全


if __name__ == '__main__':
    lock = threading.Lock()
    n = 100
    l = []
    for i in range(100):
        p = threading.Thread(target=work)
        l.append(p)
        p.start()
    for p in l:
        p.join()

    print(n)
```

## 3.2 递归锁（可重入锁）
RLcok类的用法和Lock类一模一样，但它支持嵌套，在多个锁没有释放的时候一般会使用RLock类。
```
import threading
import time

def func1():
    global gl_num
    rlock.acquire()
    gl_num += 1
    time.sleep(1)
    print(gl_num)
    print("enter func1")
    func2()
    rlock.release()  # 直到RLock所有锁释放后，其他线程才能获取锁

def func2():
    rlock.acquire()  # 线程获取锁后可以再次获取相同的锁
    print("enter func2")
    rlock.release()

if __name__ == '__main__':
    gl_num = 0
    rlock = threading.RLock()   # 此处换成Lock锁，则会造成死锁
    for i in range(5):
        t = threading.Thread(target=func1)
        t.start()
```

## 3.3 信号量（BoundedSemaphore类）
    互斥锁同时只允许一个线程更改数据，而Semaphore是同时允许一定数量的线程更改数据，比如加油站有5个油箱，那最多只允许5辆车停放加油，后面的车只能等里面有车出来了才能再进去。
如下程序，有20辆车和5个油箱，每辆车停放3秒完成加油后开走，下一辆再停入加油，直到所有车都完成加油开走。
```
import threading
import time

def run(n):
    semaphore.acquire()   #加锁
    print(f'车辆 {n} 停放加油')
    time.sleep(5)
    print(f'车辆 {n} 离开')
    semaphore.release()    #释放


if __name__== '__main__':
    num=0
    semaphore = threading.BoundedSemaphore(5)   #最多允许5个线程同时运行
    for i in range(20):
        t = threading.Thread(target=run, args={i})
        time.sleep(0.5)
        t.start()
    while threading.active_count() > 1:
        pass
    else:
        print('----------所有车辆完成加油-----------')
```


## 3.4 主线程控制其他线程的执行
 python线程的事件用于主线程控制其他线程的执行，事件是一个简单的线程同步对象，其主要提供以下的几个方法：
- clear：将flag设置为 False
- set：将flag设置为 True
- is_set：判断是否设置了flag

wait会一直监听flag，如果没有检测到flag就一直处于阻塞状态。
事件处理的机制：全局定义了一个Flag，当Flag的值为False，那么event.wait()就会阻塞，当flag值为True，那么event.wait()便不再阻塞.
```
import threading
import time

def lighter():
    count = 0
    event.set()  # 初始者为绿灯
    while True:
        if count % 20 > 10:
            event.clear()  # 红灯，清除标志位
            print('红灯亮，停止通行')
        else:
            event.set()  # 绿灯，设置标志位
            print('绿灯亮，可以通行')

        time.sleep(1)
        count += 1


def car(name):
    while True:
        if event.is_set():  # 判断是否设置了标志位
            print(f'{name} 通行')
            time.sleep(1)
        else:
            print(f'{name} 停止通行')
            event.wait()  # 阻塞直到标志位被设置为True
            print(f'{name} 通行')


if __name__ == "__main__":
    event = threading.Event()
    light = threading.Thread(target=lighter, )
    light.start()

    car = threading.Thread(target=car, args=('司机',))
    car.start()
```

## 3.5 线程间的通信
在一个进程中，不同子线程负责不同的任务，t1子线程负责获取到数据，t2子线程负责把数据保存的本地，那么他们之间的通信使用Queue来完成。因为再一个进程中，数据变量是共享的，即多个子线程可以对同一个全局变量进行操作修改，Queue是加了锁的安全消息队列。
```
import threading
import time
import queue
 
q = queue.Queue(maxsize=5)   #q在t1和t2两个子线程之间通信共享，一个存入数据，一个使用数据。
def t1(q):
    while 1:
        for i in range(10):
            q.put(i)
def t2(q):
    while not q.empty():
        print('队列中的数据量：'+str(q.qsize()))
        # q.qsize()是获取队列中剩余的数量
        print('取出值:'+str(q.get()))
        # q.get()是一个堵塞的，会等待直到获取到数据
        print('-----')
        time.sleep(0.1)
t1 = threading.Thread(target=t1,args=(q,))
t2 = threading.Thread(target=t2,args=(q,))
t1.start()
t2.start()
```

<br>
# 四、相关概念
## 4.1 GIL  全局解释器
在非python环境中，如java和c，单核情况下，同时只能有一个任务执行，多核时可以支持多个线程同时执行。但是在python中，无论有多少个核，一个进程中同时只能执行一个线程。究其原因，这就是由于GIL的存在导致的。
        GIL的全称是全局解释器，来源是python设计之初的考虑，为了数据安全所做的决定。某个线程想要执行，必须先拿到GIL，我们可以把GIL看做是“通行证”，并且在一个python进程之中，GIL只有一个。
        拿不到通行证的线程，就不允许进入CPU执行。GIL只在cpython中才有，因为cpython调用的是c语言的原生线程，所以他不能直接操作cpu，而只能利用GIL保证同一时间只能有一个线程拿到数据。而在pypy和jpython中是没有GIL的。
        python在使用多线程的时候，调用的是c语言的原生过程。

**示例如下**
累加数字到100000000，比较单线程和双线程的时间。
```
import threading
import multiprocessing
import time

def tstart(n):
    var = 0
    for i in range(n):
        var += 1

if __name__ == '__main__':
    t1 = threading.Thread(target=tstart, args=(50000000,))
    # t1 = multiprocessing.Process(target=tstart, args=(50000000,))
    t2 = threading.Thread(target=tstart, args=(50000000,))
    # t2 = multiprocessing.Process(target=tstart, args=(50000000,))
    start_time = time.time()
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    print("Two thread cost time: %s" % (time.time() - start_time))
    start_time = time.time()
    tstart(100000000)
    print("Main thread cost time: %s" % (time.time() - start_time))

# 结果如下：
# Two thread cost time: 5.507142066955566
# Main thread cost time: 5.363916635513306
```
这里多线程耗时比单线程耗时要多，原因就是GIL锁导致的即使多线程也只有一个核在进行运算，线程间的切换导致了耗时增加，起到了反作用。

多进程耗时如下
```
import threading
import multiprocessing
import time

def tstart(n):
    var = 0
    for i in range(n):
        var += 1

if __name__ == '__main__':
    # t1 = threading.Thread(target=tstart, args=(50000000,))
    t1 = multiprocessing.Process(target=tstart, args=(50000000,))
    # t2 = threading.Thread(target=tstart, args=(50000000,))
    t2 = multiprocessing.Process(target=tstart, args=(50000000,))
    start_time = time.time()
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    print("Two thread cost time: %s" % (time.time() - start_time))
    start_time = time.time()
    tstart(100000000)
    print("Main thread cost time: %s" % (time.time() - start_time))

# 结果如下：
# Two thread cost time: 2.793893337249756
# Main thread cost time: 5.109605073928833
```
可以看到多线程将执行时间减少了将近一半。

也印证了`CPU密集型的任务不能用多线程执行，而应该用多进程执行。而IO密集型的任务在CPU可以使用多线程进行操作，效果比较理想`。

## 4.2 多线程和多进程
每个进程都包含至少一个线程：主线程，每个主线程可以开启多个子线程，由于GIL锁机制的存在，每个进程里的若干个线程同一时间只能有一个被执行；但是使用多进程就可以保证多个线程被多个CPU同时执行。
python编写多进程能更充分地利用多核CPU的性能，大大提升程序的运行速度。

**多进程必须注意的是，要加上**
```
if __name__ == '__main__':
	pass
```

python多线程和多进程不存在优劣之分，两者都有着各自的应用环境。
- 线程几乎不占资源，系统开销少，切换速度快，而且同一个进程的多个线程之间能很容易地实现数据共享
- 而创建进程需要为它分配单独的资源，系统开销大，切换速度慢，而且不同进程之间的数据默认是不可共享的。

掌握了两者各自的特点，才能在实际编程中根据任务需求采取更加适合的方案。
- `多进程：消耗CPU操作，CPU密集计算。`
- `多线程：适合大量的IO操作。`

## 4.3 线程与进程区别
下面简单的比较一下线程与进程

- 进程是资源分配的基本单位，线程是CPU执行和调度的基本单位；
- 通信/同步方式：
   - **进程**
通信方式：管道，FIFO，消息队列，信号，共享内存，socket，stream流；
同步方式：PV信号量，管程
   - **线程**
同步方式：互斥锁，递归锁，条件变量，信号量
通信方式：位于同一进程的线程共享进程资源，因此线程间没有类似于进程间用于数据传递的通信方式，线程间的通信主要是用于线程同步。
- CPU上真正执行的是线程，线程比进程轻量，其切换和调度代价比进程要小；
- 线程间对于共享的进程数据需要考虑线程安全问题，由于进程之间是隔离的，拥有独立的内存空间资源，相对比较安全，只能通过上面列出的IPC(Inter-Process Communication)进行数据传输；
- 系统有一个个进程组成，每个进程包含代码段、数据段、堆空间和栈空间，以及操作系统共享部分 ，有等待，就绪和运行三种状态；
- 一个进程可以包含多个线程，线程之间共享进程的资源（文件描述符、全局变量、堆空间等），寄存器变量和栈空间等是线程私有的；
- 操作系统中一个进程挂掉不会影响其他进程，如果一个进程中的某个线程挂掉而且OS对线程的支持是多对一模型，那么会导致当前进程挂掉；
- 如果CPU和系统支持多线程与多进程，多个进程并行执行的同时，每个进程中的线程也可以并行执行，这样才能最大限度的榨取硬件的性能；

## 4.4 线程和进程的上下文切换
进程切换过程切换牵涉到非常多的东西，寄存器内容保存到任务状态段TSS，切换页表，堆栈等。简单来说可以分为下面两步：

1. 页全局目录切换，使CPU到新进程的线性地址空间寻址；
2. 切换内核态堆栈和硬件上下文，硬件上下文包含CPU寄存器的内容，存放在TSS中；

线程运行于进程地址空间，切换过程不涉及到空间的变换，只牵涉到第二步；

## 4.5 密集型任务类型
python针对不同类型的代码执行效率也是不同的，任务可以分为I/O密集型和计算密集型，而多线程在切换中又分为I/O切换和时间切换。
- CPU密集型任务（各种循环处理、计算等），在这种情况下，由于计算工作多，ticks技术很快就会达到阀值，然后出发GIL的释放与再竞争（多个线程来回切换当然是需要消耗资源的），所以python下的多线程对CPU密集型代码并不友好。
- IO密集型任务（文件处理、网络爬虫等设计文件读写操作），多线程能够有效提升效率（单线程下有IO操作会进行IO等待，造成不必要的时间浪费，而开启多线程能在线程A等待时，自动切换到线程B，可以不浪费CPU的资源，从而能提升程序的执行效率）。所以python的多线程对IO密集型代码比较友好。
