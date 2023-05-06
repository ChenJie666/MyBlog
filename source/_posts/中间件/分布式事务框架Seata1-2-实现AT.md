---
title: 分布式事务框架Seata1-2-实现AT
categories:
- 中间件
---
# 一、Seata介绍
全局的跨数据库的多数据源的统一调度。
微服务环境下，原来的多个模块被拆分为多个独立的应用，分别使用多个独立的数据源。因此每个服务内部的数据一致性由本地事务来保证，但是全局的数据一致性问题需要分布式事务来保证。
Seata在微服务架构下提供高性能的分布式事务服务。

## 1.1 Seata AT原理
### 1.1.1 概念梳理
**本地锁：**本地事务进行操作时添加的排它锁。
**全局锁：**本地提交需要先获取全局锁，提交之后释放全局锁。数据的修改将被互斥开来。也就不会造成写入脏数据。全局锁可以让分布式修改中的写数据隔离。

### 1.1.2 分布式事务的一ID+三组件模型
1. 全局唯一的事务ID：TransactionID XID
2. 三组件概念
- TC(Transaction Coordinator)：事务协调者，维护全局和分支事务的状态，驱动全局事务提交和回滚。
- TM(Transaction Manager)：事务管理器，定义全局事务的范围，开始全局事务、提交或回滚全局事务。
- RM(Resource Manager)：资源管理器，管理分支事务处理的资源，与TC交谈以注册分支事务和报告分支事务的状态，并驱动分支事务提交或回滚。

![image.png](分布式事务框架Seata1-2-实现AT.assets\934ab6b812ee4fce90e66db7ac4c2ff0.png)

####步骤：
1. TM向TC申请开启一个全局事务，全局事务创建成功并生成一个全局唯一的XID；
2. XID在微服务调用链路的上下文中传播；
3. RM向TC注册分支事务，将其纳入XID对应的全局事务的管辖；
4. TM向TC发起针对XID的全局提交或回滚决议；
5. TC调度XID下管辖的全部分支事务完成提交或回滚请求。
- 全局事务提交：TM向TC发起全局事务提交请求，TC收到后，向各个分支事务发起提交请求，分支事务接收到请求，只需要删除全局事务的undo_log记录即可
- 全局事务回滚：TM向TC发起全局事务回滚请求，TC收到后，向各个分支事务发起回滚请求，分支事务接收到请求，只需要根据XID对应的undo_log表记录进行回滚即可。

####数据库表：
- **global_table表：**
TM 向 TC 请求发起（Begin）、提交（Commit）、回滚（Rollback）全局事务，注册并获取xid。
![image.png](分布式事务框架Seata1-2-实现AT.assets7e2c4f4945a474b9c0074894cd7616e.png)

- **branch_table表：**
TM 把代表全局事务的 XID 绑定到分支事务上，本地事务提交前，RM 向 TC 注册分支事务，把分支事务关联到 XID 代表的全局事务中。
![image.png](分布式事务框架Seata1-2-实现AT.assets\2eaafa77bd10426a99a42202a8f7baca.png)

- **lock_table表：**
为了防止脏读等情况的发生，需要为表记录添加全局锁。本地事务提交前向TC申请全局锁。
![image.png](分布式事务框架Seata1-2-实现AT.assets0f8ce8bafbc4039bcec8141378c20ed.png)

- **undo_log表：**
rollback_info中记录了beforeImage和afterImage的信息，用于脏数据校验和回滚数据。
![image.png](分布式事务框架Seata1-2-实现AT.assets\527e6eda633d4bb8b1548276aa325ea1.png)
**roll_back信息如下：**记录了beforeImage和afterImage
```
{
	"@class": "io.seata.rm.datasource.undo.BranchUndoLog",
	"xid": "192.168.32.128:8091:3954260645732352",
	"branchId": 3954261379735553,
	"sqlUndoLogs": ["java.util.ArrayList", [{
		"@class": "io.seata.rm.datasource.undo.SQLUndoLog",
		"sqlType": "UPDATE",
		"tableName": "t_account",
		"beforeImage": {
			"@class": "io.seata.rm.datasource.sql.struct.TableRecords",
			"tableName": "t_account",
			"rows": ["java.util.ArrayList", [{
				"@class": "io.seata.rm.datasource.sql.struct.Row",
				"fields": ["java.util.ArrayList", [{
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "id",
					"keyType": "PRIMARY_KEY",
					"type": -5,
					"value": ["java.lang.Long", 1]
				}, {
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "residue",
					"keyType": "NULL",
					"type": 3,
					"value": ["java.math.BigDecimal", 1000]
				}, {
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "used",
					"keyType": "NULL",
					"type": 3,
					"value": ["java.math.BigDecimal", 0]
				}]]
			}]]
		},
		"afterImage": {
			"@class": "io.seata.rm.datasource.sql.struct.TableRecords",
			"tableName": "t_account",
			"rows": ["java.util.ArrayList", [{
				"@class": "io.seata.rm.datasource.sql.struct.Row",
				"fields": ["java.util.ArrayList", [{
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "id",
					"keyType": "PRIMARY_KEY",
					"type": -5,
					"value": ["java.lang.Long", 1]
				}, {
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "residue",
					"keyType": "NULL",
					"type": 3,
					"value": ["java.math.BigDecimal", 900]
				}, {
					"@class": "io.seata.rm.datasource.sql.struct.Field",
					"name": "used",
					"keyType": "NULL",
					"type": 3,
					"value": ["java.math.BigDecimal", 100]
				}]]
			}]]
		}
	}]]
}
```

<br>
### 1.1.3 整体流程
#### 1.1.3.1 机制
**两阶段提交协议的演变：**
- 一阶段：业务数据和回滚日志记录在同一个本地事务中提交，释放本地锁和连接资源。
- 二阶段：
提交异步化，非常快速地完成。
回滚通过一阶段的回滚日志进行反向补偿。

**详细执行步骤：**
- 一阶段
1. 先解析sql语句,得到表名,条件,sql类型,等信息；
2. 得到前镜像：根据解析得到的条件信息，生成查询语句，定位数据；
3. 执行业务 SQL；
4. 查询后镜像：根据前镜像的结果，通过 主键 定位数据；
5. 插入回滚日志：把前后镜像数据以及业务 SQL 相关的信息组成一条回滚日志，插入到 UNDO_LOG 表中；
6. **提交前，RM 向 TC 注册分支：申请一个主键等于目标数据主键值的全局锁**；
7. 本地事务提交：业务数据的更新和前面步骤中生成的 UNDO LOG 一并提交；
8. 将本地事务提交的结果上报给 TC。TM清除内存中XID，RM清除内存中的XID、branchId。

![image.png](分布式事务框架Seata1-2-实现AT.assets\45279bbb74134809803fccbe07b55749.png)

- 二阶段-提交
9. 收到 TC 的分支提交请求，把请求放入一个异步任务的队列中，马上返回提交成功的结果给 TC。
10. 异步任务阶段的分支提交请求将异步和批量地删除相应 UNDO LOG 记录。（提交全局事务时，RM将删除undo log。先将删除操作封装为任务放入AsyncWorker中的阻塞队列中，并返回TC成功消息。AsyncWorker中的定时器每隔1s执行删除任务。）

- 二阶段-回滚
9. 当 TC 接收到全局事务回滚的指令时，会向每个 RM 发送分支事务回滚的请求。收到 TC 的分支回滚请求，开启一个本地事务，执行如下操作；
10. 通过 XID 和 Branch ID 查找到相应的 UNDO LOG 记录。
11. 数据校验：拿 UNDO LOG 中的后镜与当前数据进行比较，如果有不同，说明数据被当前全局事务之外的动作做了修改。这种情况，需要根据配置策略来做处理。
12. 根据 UNDO LOG 中的前镜像和业务 SQL 的相关信息生成并执行回滚的语句。
13. 提交本地事务。并把本地事务的执行结果（即分支事务回滚的结果）上报给 TC。

![image.png](分布式事务框架Seata1-2-实现AT.assets\11141fbaf60041b19cb7dd396c81c6a5.png)

全局事务提交或者回滚操作处理完成之后（异常会封装异常信息），会把处理结果发送给 TC(服务端) `sender.sendResponse(msgId, serverAddress, resultMessage)`。服务端那边会有超时检测和重试机制，来保证分布式事务运行结果的正确性。

#### 1.1.3.2 写隔离
**即避免脏写。**
>**脏写：**当两个事务同时尝试去更新某一条数据记录时，就肯定会存在一个先一个后。而当事务A更新时，事务A还没提交，事务B就也过来进行更新，覆盖了事务A提交的更新数据，这就是脏写。
在4种隔离级别下，都不存在脏写情况，因为写时会添加排它锁。
脏写会带来什么问题呢？当多个事务并发写同一数据时，先执行的事务所写的数据会被后写的覆盖，这也就是更新丢失。Seata中会导致回滚时afterImage与实际记录对不上，发生异常。
##### 1.1.3.2.1 要点
- 一阶段本地事务提交前，需要确保先拿到 **全局锁** 。
- 拿不到 **全局锁** ，不能提交本地事务。
- 拿 **全局锁** 的尝试被限制在一定范围内，超出范围将放弃，并回滚本地事务，释放本地锁。

##### 1.1.3.2.2 示例说明
两个全局事务 tx1 和 tx2，分别对 a 表的 m 字段进行更新操作，m 的初始值 1000。

#####①正常情况
**tx1执行流程如下：**
- 1. tx1获取本地锁；
- 2. tx1执行`UPDATE a SET m = m - 100 WHERE  id = 1;` 但是还未commit；
- 3. tx1获取全局锁；
- 4. tx1提交本地事务；
- 5. tx1释放本地锁；
- 6. tx1提交全局事务；
- 7. tx1释放全局锁；

**tx2执行流程如下：**
- 1. tx1释放本地锁后，tx2获取本地锁
- 2. tx2执行`UPDATE a SET m = m - 100 WHERE  id = 1;` 但是还未commit；
- 3. tx2自旋尝试获取全局锁，直到tx1释放全局锁；
- 4. tx2获取全局锁并提交本地事务；
- 5. tx2释放本地锁；
- 6. tx2提交全局事务；
- 7. tx2释放全局锁；

**如下图：**
![image](分布式事务框架Seata1-2-实现AT.assets04127c6dbd14b078c48d24a708f43f5.png)
tx1 二阶段全局提交，释放 全局锁 。tx2 拿到 全局锁 提交本地事务。

<br>
#####②异常情况
**tx1执行流程如下：**
- 1. tx1获取本地锁；
- 2. tx1执行`UPDATE a SET m = m - 100 WHERE  id = 1;` 但是还未commit；
- 3. tx1获取全局锁；
- 4. tx1提交本地事务；
- 5. tx1释放本地锁；
此时全局事务中的其他事务异常发生了全局回滚。
- 7. tx1自旋尝试获取本地锁；

**tx2执行流程如下：**
- 1. tx1释放本地锁后，tx2获取本地锁
- 2. tx2执行`UPDATE a SET m = m - 100 WHERE  id = 1;` 但是还未commit；
- 3. tx2自旋尝试获取全局锁，直到tx1释放全局锁；
因为tx1一直在等待tx2释放本地锁，而tx2一直在等待tx1释放全局锁，导致了死锁的产生。

**如下图：**
![image](分布式事务框架Seata1-2-实现AT.assets