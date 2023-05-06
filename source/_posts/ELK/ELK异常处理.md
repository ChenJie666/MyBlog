---
title: ELK异常处理
categories:
- ELK
---
**es集群状态**
- green状态：每个索引的primary shard和replica shard都是active状态
- yellow ： 每个索引的primary shard都是active状态，但是部分replica shard不是active状态，处于不可用状态
- red: 不是所有的索引的primary shard都是active状态，部分索引有数据丢失了

**查看集群状态**
- http://192.168.32.128:9200/_cat/health?v
```
epoch      timestamp cluster       status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1593775754 11:29:14  elasticsearch yellow          1         1     10  10    0    0        5             0                  -                 66.7%
```

<br>

- http://192.168.32.128:9200/_cluster/health?pretty=true
```
{
  "cluster_name" : "elasticsearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 10,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 5,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 66.66666666666666
}
```

>**参数说明**
cluster：集群名称
status：集群状态 green代表健康；yellow代表分配了所有主分片，但至少缺少一个副本，此时集群数据仍旧完整；red代表部分主分片不可用，可能已经丢失数据。
node.total：代表在线的节点总数量
node.data：代表在线的数据节点的数量
shards / active_shards：存活的分片数量
pri / ctive_primary_shards：存活的主分片数量 正常情况下 shards的数量是pri的两倍。
relo / relocating_shards：迁移中的分片数量，正常情况为 0
init / initializing_shards：初始化中的分片数量 正常情况为 0
unassign / unassigned_shards：未分配的分片 正常情况为 0
>pending_tasks：准备中的任务，任务指迁移分片等 正常情况为 0
max_task_wait_time：任务最长等待时间
active_shards_percent：正常分片百分比 正常情况为 100%

<br>

**修改es的副本数**
可以指定索引修改副本数，也可以全局修改副本数
```
curl -H "Content-Type: application/json" -XPUT 'http://192.168.32.128:9200/_settings' -d '
{
    "index" : {
        "number_of_replicas" : 0
    }
}'
```
