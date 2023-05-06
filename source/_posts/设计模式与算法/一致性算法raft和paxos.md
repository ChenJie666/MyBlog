---
title: 一致性算法raft和paxos
categories:
- 设计模式与算法
---
# 一、一致性算法
一致性算法主要解决的就是脑裂问题，包括raft，zab等算法，这些算法都是脱胎于Paxos算法。

# 二、 raft一致性算法
**见网页动画**
[http://thesecretlivesofdata.com/raft/](http://thesecretlivesofdata.com/raft/)
[https://raft.github.io/](https://raft.github.io/)

**raft**是一个共识算法（consensus algorithm），所谓共识，就是多个节点对某个事情达成一致的看法，即使是在部分节点故障、网络延时、网络分割的情况下。
### 2.1 原理
### 2.1.1 节点状态
**每个节点有三个状态，分别为follower、candidate和leader。存在两个时间，自旋时间和心跳时间。**
1. 如果follower在**自旋时间**内没有收到来自leader的**心跳**，（也许此时还没有选出leader，大家都在等；也许leader挂了；也许只是leader与该follower之间网络故障）；
2. 会切换状态为candidate，参与leader的竞选；
3. 如果竞选成功就会切换状态为leader，失败则切换为follower。

![image.png](一致性算法raft和paxos.assets\dc1e8f9a5d3c41f98735d40f3dedff60.png)


### 2.1.2 选举
如果follower在election timeout内没有收到来自leader的心跳，（也许此时还没有选出leader，大家都在等；也许leader挂了；也许只是leader与该follower之间网络故障），则会主动发起选举。步骤如下：

- 增加节点本地的 current term ，切换到candidate状态
- 投自己一票
- 并行给其他节点发送 RequestVote RPCs
- 等待其他节点的回复

**在这个过程中，根据来自其他节点的消息，可能出现三种结果**
1. 收到大部分的投票（含自己的一票），则赢得选举，成为leader
2. 被告知别人已当选，那么自行切换到follower
3. 一段时间内没有收到majority投票，则保持candidate状态，重新发出选举

**①第一种情况**
赢得了选举之后，新的leader会立刻给所有节点发消息，广而告之，避免其余节点触发新的选举。在这里，先回到投票者的视角，投票者如何决定是否给一个选举请求投票呢，有以下约束：
- 在任一任期内，单个节点最多只能投一票
- 候选人知道的信息不能比自己的少（这一部分，后面介绍log replication和safety的时候会详细介绍）
- first-come-first-served 先来先得

**②第二种情况**
比如有三个节点A B C。A B同时发起选举，而A的选举消息先到达C，C给A投了一票，当B的消息到达C时，已经不能满足上面提到的第一个约束，即C不会给B投票，而A和B显然都不会给对方投票。A胜出之后，会给B,C发心跳消息，节点B发现节点A的term不低于自己的term，知道有已经有Leader了，于是转换成follower。

**③没有任何节点获得majority投票**
偶数个节点可能出现平票的情况，所以节点一般设置为奇数个。

### 2.1.3 写操作
客户端的一切请求来发送到leader，leader来调度这些并发请求的顺序，并且保证leader与followers状态的一致性。leader将客户端请求（command）封装到一个个log entry，将这些log entries复制（replicate）到所有follower节点，然后大家按相同顺序应用（apply）log entry中的command，则状态肯定是一致的。

**当系统（leader）收到一个来自客户端的写请求，到返回给客户端，整个过程从leader的视角来看会经历以下步骤：**
- leader将请求操作写入日志(leader append log entry)
- leader通过心跳将日志并行发给follower(leader issue AppendEntries RPC in parallel)
- leader等待大部分的follower的预写入完成响应(leader wait for majority response)
- leader提交操作(leader apply entry to state machine)
- leader回复客户端操作成功(leader reply to client)
- leader通知所有的follower提交操作(leader notify follower apply log)

可以看到**日志的提交过程有点类似两阶段提交(2PC)**，不过与2PC的区别在于，leader只需要大多数（majority）节点的回复即可，这样只要超过一半节点处于工作状态则系统就是可用的。

在上面的流程中，leader只需要日志被复制到大多数节点即可向客户端返回，一旦向客户端返回成功消息，那么系统就必须保证log（其实是log所包含的command）在任何异常的情况下都不会发生回滚。这里有两个词：commit（committed），apply(applied)，前者是指日志被复制到了大多数节点后日志的状态；而后者则是节点将日志应用到状态机，真正影响到节点状态。

### 2.1.4 读操作
只会从leader进行读取，因为leader的数据肯定是最新的。如果连接的节点是follower，指令会被转发到leader节点。
- 记录下当前日志的commitIndex => readIndex
- 执行读操作前要向集群广播一次心跳，并得到majority的反馈
- 等待状态机的applyIndex移动过readIndex
- 通过查询状态机来执行读操作并返回客户端最终结果。

**总结：**最终从leader读取数据，集群广播一次心跳是为了防止读取的是被分区的小集群，读到过期数据。

### 2.1.5 可以容忍分区错误
![image.png](一致性算法raft和paxos.assets\5a4e53e5c8eb4c9ca25e622d6bc9a986.png)

1. 失去连接的部分节点会重新选举leader，然后成为一个新集群。旧集群的leader因为得不到大多节点的响应，所以不会提交日志，一直回复客户端操作失败；而新集群的leader能得到大多节点的响应，所以能正常提交客户端请求。
2. 等到连接恢复后，会出现有两个leader的情况，旧leader会自动让位给新选举的leader。
3. 如图A和B会回滚所有未提交的日志，并同步新leader的日志。

**即分区错误会分裂成多个集群，但是恢复后最终结果还是正确的。**

### 2.1.6 脑裂问题
在集群中，如果部分节点与leader发生通讯故障，这部分节点重新选举了leader，导致一个集群中有多个leader。
raft算法保证了多数节点同意的情况下才能选举为leader或进行数据的修改，保证了一致性。

### 2.1.7 偶数节点的危害
- 选举时平票情况出现，一直等过期重新选举导致服务不可用；
- 如果分区错误平分了节点变成两个集群，那么这两个集群都无法提供服务，导致服务一直不可用。
- 写操作和读操作需要majority进行确认。

<br>
## 三、Paxos算法


<br>
## 四、Zab算法
Zookeeper的一致性算法

<br>
## 五、具体实现
| 功能 | etcd | Zookeeper |
| --- | --- | --- |
| 分布式锁 | 有 | 有 |
| watcher	| 有 | 有 |
| 一致性算法 | raft | zab |
| 选举 | 有 | 有 |
| 元数据(metadata)存储 | 有 | 有 |

Zookeeper和etcd解决的问题是一样的，都解决分布式系统的协调和元数据的存储，所以它们都不是一个存储组件，或者说都不是一个分布式数据库。etcd灵感来源于Zookeeper，但在实现的时候有了很多的改进。
- 更轻量级、更易用
- 高负载下的稳定读写
- 数据模型的多版本并发控制
- 稳定的watcher功能，通知订阅者监听值的变化
- 客户端协议使用gRPC协议，支持go、C++、Java等，而Zookeeper的RPC协议是自定制的，目前只支持C和Java
- 可以容忍脑裂现象的发生
