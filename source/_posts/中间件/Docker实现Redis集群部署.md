---
title: Docker实现Redis集群部署
categories:
- 中间件
---
# 一、集群模式
## 1.1 主从模式
Redis的主从模式指的就是主从复制。

用户可以通过 SLAVEOF 命令或者配置的方式，让一个服务器去复制另一个服务器即成为它的从服务器。

## 1.1.1 主从模式架构
![image.png](Docker实现Redis集群部署.assets\62a1bc97d28c49f29dd67c85f8185f30.png)

### 1.1.2 Redis如何实现主从模式？
Redis的从服务器在向主服务器发起同步时，一般会使用 SYNC 或 PSYNC 命令。

**初次同步**
当从服务器收到 SLAVEOF 命令后，会向其主服务器执行同步操作，进入主从复制流程。

1. 从服务器向主服务器发起SYNC 或 PSYNC 命令
2. 主服务器执行 BGSAVE命令，生成RDB文件，并使用缓存区记录从现在开始的所有写命令
3. RDB文件生成完成后，主服务器会将其发送给从服务器
4. 从服务器载入RDB文件，将自己的数据库状态同步更新为主服务器执行 BGSAVE命令时的状态。
5. 主服务器将缓冲区的所有写命令发送给从服务器，从服务将执行这些写命令，数据库状态同步为主服务器最新状态。

![image.png](Docker实现Redis集群部署.assets\1a05b01287794a8bb85b28c5d42b7d6a.png)


**SYNC 与 PSYNC的区别**
当主从同步完成后，如果此时从服务器宕机了一段时间，重新上线后势必要重新同步一下主服务器，SYNC与 PSYNC命令的区别就在于断线后重复制阶段处理的方式不同。

- SYNC
从服务器重新向主服务器发起 SYNC命令，主服务器将所有数据再次重新生成RDB快照发给从服务器开始同步
- PSYNC
从服务器重新向主服务器发起 PSYNC命令。主服务器根据双方数据的偏差量判断是否是需要完整重同步还是仅将断线期间执行过的写命令发给从服务器。

明显可以发先PSYNC相比SYNC效率好很多，要知道同步所有数据是一个非常费资源(磁盘IO,网络)的操作，而如果只是因为短暂网络不稳定就同步所有资源是非常不值的。因此Redis在2.8版本后都开始使用PSYNC进行复制

**PSYNC如何实现部分重同步？**
实现部分重同步主要靠三部分

1. 记录复制偏移量
主服务器与从服务器都会维护一个复制偏移量。
当主服务器向从服务器发送N个字节的数据后，会将自己的复制偏移量+N。
当从服务器收到主服务器N个字节大小数据后，也会将自己的复制偏移量+N。
当主从双方数据是同步时，这个偏移量是相等的。而一旦有个从服务器断线一段时间而少收到了部分数据。那么此时主从双方的服务器偏移量是不相等的，而他们的差值就是少传输的字节数量。如果少传输的数据量不是很大，没有超过主服务器的复制积压缓冲区大小，那么将会直接将缓冲区内容发送给从服务器避免完全重同步。反之还是需要完全重同步的。

2. 复制积压缓冲区
复制积压缓冲区是由主服务器维护的一个先进先出的字节队列，默认大小是1mb。每当向从服务器发送写命令时，都会将这些数据存入这个队列。每个字节都会记录自己的复制偏移量。从服务器在重连时会将自己的复制偏移量发送给主服务器，如果该复制偏移量之后的数据存在于复制积压缓冲区中，则仅需要将之后的数据发送给从服务器即可。

3. 记录服务器ID
当执行主从同步时，主服务器会将自己的服务器ID(一般是自动生成的UUID)发送给从服务器。从服务器在断线恢复后会判断该ID是否为当前连接的主服务器。如果是同一个ID则代表主服务器没变尝试部分重同步。如果不是同一个ID代表主服务有变动，则会与主服务器完全重同步。

具体流程图如下：
![image.png](Docker实现Redis集群部署.assets\da004446877540d19fe4a9710b5f6edf.png)


## 1.2 哨兵模式(Sentinel)
Redis主从模式虽然能做到很好的数据备份，但是他并不是高可用的。一旦主服务器点宕机后，只能通过人工去切换主服务器。因此Redis的哨兵模式也就是为了解决主从模式的高可用方案。

哨兵模式引入了一个Sentinel系统去监视主服务器及其所属的所有从服务器。一旦发现有主服务器宕机后，会自动选举其中的一个从服务器升级为新主服务器以达到故障转义的目的。

同样的Sentinel系统也需要达到高可用，所以一般也是集群，互相之间也会监控。而Sentinel其实本身也是一个以特殊模式允许Redis服务器。

![image.png](Docker实现Redis集群部署.assets\8cb906f129384bbf97390540d77f3502.png)

### 1.2.1 实现原理
1.Sentinel与主从服务器建立连接
Sentinel服务器启动之后便会创建于主服务器的命令连接，并订阅主服务器的**sentinel:hello频道以创建订阅连接**
Sentinel默认会每10秒向主服务器发送 INFO 命令，主服务器则会返回主服务器本身的信息，以及其所有从服务器的信息。
根据返回的信息，Sentinel服务器如果发现有新的从服务器上线后也会像连接主服务器时一样，向从服务器同时创建命令连接与订阅连接。

2. 判定主服务器是否下线
每一个Sentinel服务器每秒会向其连接的所有实例包括主服务器，从服务器，其他Sentinel服务器)发送 PING命令，根据是否回复 PONG 命令来判断实例是否下线。

   **判定主观下线：**
如果实例在收到 PING命令的down-after-milliseconds毫秒内(根据配置)，未有有效回复。则该实例将会被发起 PING命令的Sentinel认定为主观下线。
   **判定客观下线：**
当一台主服务器没某个Sentinel服务器判定为客观下线时，为了确保该主服务器是真的下线，Sentinel会向Sentinel集群中的其他的服务器确认，如果判定主服务器下线的Sentinel服务器达到一定数量时(一般是N/2+1)，那么该主服务器将会被判定为客观下线，需要进行故障转移。

3. 选举领头Sentinel
当有主服务器被判定客观下线后，Sentinel集群会选举出一个领头Sentinel服务器来对下线的主服务器进行故障转移操作。整个选举其实是基于RAFT一致性算法而实现的，大致的思路如下：
每个发现主服务器下线的Sentinel都会要求其他Sentinel将自己设置为局部领头Sentinel。
接收到的Sentinel可以同意或者拒绝
如果有一个Sentinel得到了半数以上Sentinel的支持则在此次选举中成为领头Sentinel。
如果给定时间内没有选举出领头Sentinel，那么会再一段时间后重新开始选举，直到选举出领头Sentinel。

4. 选举新的主服务器
领头服务器会从从服务中挑选出一个最合适的作为新的主服务器。挑选的规则是：
   - 选择健康状态的从节点，排除掉断线的，最近没有回复过 INFO命令的从服务器。
   - 选择优先级配置高的从服务器
   - 选择复制偏移量大的服务器（表示数据最全）

   挑选出新的主服务器后，领头服务器将会向新主服务器发送 SLAVEOF no one命令将他真正升级为主服务器，并且修改其他从服务器的复制目标，将旧的主服务器设为从服务器，以此来达到故障转移。


## 1.3 Cluster模式
Redis哨兵模式实现了高可用，读写分离，但是其主节点仍然只有一个，即写入操作都是在主节点中，这也成为了性能的瓶颈。

因此Redis在3.0后加入了Cluster模式，它采用去无心节点方式实现，集群将会通过分片方式保存数据库中的键值对。

### 1.3.1 节点

一个Redis集群中会由多个节点组成，每个节点都是互相连接的，会保存自己与其他节点的信息。节点之间通过gossip协议交换互相的状态，以及保新加入的节点信息。

![image.png](Docker实现Redis集群部署.assets8f24bbdf230416faa683e6957a28279.png)

### 1.3.2 数据的Sharding

Redis Cluster的整个数据库将会被分为16384个哈希槽，数据库中的每个键都属于这16384个槽中的其中一个，集群中的每个节点可以处0个或者最多16384个槽。

**设置槽指派**

通过命令 `CLUSTER ADDSLOTS <slot> [slot...]` 命令我们可以将一个或多个槽指派给某个节点。

如 `127.0.0.1:7777> CLUSTER ADDSLOTS 1 2 3 4 5` 命令就是将1，2，3，4，5号插槽指派给本地端口号为7777的节点负责。

设置后节点将会将槽指派的信息发送给其他集群，让其他集群更新信息。

**计算键属于哪个槽**
```
def slot_number(key):
    return CRC16(key) & 16383
```

计算哈希槽位置其实使用的是CRC16算法对键值进行计算后再对16383取模得到最终所属插槽。

也可以使用 `CLUSTER KEYSLOT <key>` 进行查看。

**Sharding流程**
1. 当客户端发起对键值对的操作指令后，将任意分配给其中某个节点
2. 节点计算出该键值所属插槽
3. 判断当前节点是否为该键所属插槽
4. 如果是的话直接执行操作命令
5. 如果不是的话，向客户端返回moved错误，moved错误中将带着正确的节点地址与端口，客户端收到后可以直接转向至正确节点

![image.png](Docker实现Redis集群部署.assets\3e7b5e478d42469480a47b2d7b8013a0.png)


### 1.3.3 Redis Cluster的高可用

Redis的每个节点都可以分为主节点与对应从节点。主节点负责处理槽，从节点负责复制某个主节点，并在主节点下线时，代替下线的主节点。

![image](Docker实现Redis集群部署.assets