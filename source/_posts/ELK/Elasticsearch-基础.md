---
title: Elasticsearch-基础
categories:
- ELK
---
# 一、ES基本概念
## 1.1 索引（Index）
一个索引就是一个拥有几分相似特征的文档的集合。一个索引由一个名字来标识（必
须全部是小写字母），并且当我们要对这个索引中的文档进行索引、搜索、更新和删除的时候，都要使用到这个名字。在一个集群中，可以定义任意多的索引。

**索引结构主要包含mapping与setting两部分**

### 1.1.1 映射（Mapping）
mapping 是处理数据的方式和规则方面做一些限制，如：某个字段的数据类型、默认值、分析器、是否被索引等等。这些都是映射里面可以设置的，其它就是处理 ES 里面数据的一些使用规则设置也叫做映射，按着最优规则处理数据对性能提高很大，因此才需要建立映射，并且需要思考如何建立映射才能对性能更好。

**主要包含以下内容：**
1、定义索引中字段的名称
2、定义字段的数据类型，如：字符串、数字、boolean等
3、可对字段设置倒排索引的相关配置，如是否需要分词，使用什么分词器


**Elasticsearch 支持如下简单域类型**
字符串(string);整数(byte, short, integer, long);浮点数(float, double);布尔型(boolean);日期(date,format默认是strict_date_optional_time||epoch_millis，表示yyyy-HH-mmTHH:mm:ssZ或时间戳格式);地理位置(geo_point);

**通过PUT请求可以新增或修改类型(type)的映射，修改映射只能新增域，但是不能修改域。**
```
PUT /gb/_mapping/tweet
{ "properties" : { "tag" : { "type" : "string", "index": "not_analyzed" } }}
```

**mappings 中field定义有以下选择**
```
"field": {  
	"type":  "text", //文本类型  ，指定类型
	"index": "analyzed", //该属性共有三个有效值：analyzed、no和not_analyzed，默认是analyzed；analyzed：表示该字段被分析，编入索引，产生的token能被搜索到；not_analyzed：表示该字段不会被分析，使用原始值编入索引，在索引中作为单个词；no：不编入索引，无法搜索该字段；
	"analyzer":"ik"//指定分词器  
	"boost":1.23//字段级别的分数加权  
	"doc_values":false//对not_analyzed字段，默认都是开启，analyzed字段不能使用，对排序和聚合能提升较大性能，节约内存,如果您确定不需要对字段进行排序或聚合，或者从script访问字段值，则可以禁用doc值以节省磁盘空间
	"fielddata":{"loading" : "eager" }//Elasticsearch 加载内存 fielddata 的默认行为是 延迟 加载 。 当 Elasticsearch 第一次查询某个字段时，它将会完整加载这个字段所有 Segment 中的倒排索引到内存中，以便于以后的查询能够获取更好的性能。
	"fields":{"keyword": {"type": "keyword","ignore_above": 256}} //可以对一个字段提供多种索引模式，同一个字段的值，一个分词，一个不分词  
	"ignore_above":100 //超过100个字符的文本，将会被忽略，不被索引
	"include_in_all":ture//设置是否此字段包含在_all字段中，默认是true，除非index设置成no选项  
	"index_options":"docs"//4个可选参数docs（索引文档号） ,freqs（文档号+词频），positions（文档号+词频+位置，通常用来距离查询），offsets（文档号+词频+位置+偏移量，通常被使用在高亮字段）分词字段默认是position，其他的默认是docs  
	"norms":{"enable":true,"loading":"lazy"}//分词字段默认配置，不分词字段：默认{"enable":false}，存储长度因子和索引时boost，建议对需要参与评分字段使用 ，会额外增加内存消耗量  
	"null_value":"NULL"//设置一些缺失字段的初始化值，只有string可以使用，分词字段的null值也会被分词 	"position_increament_gap":0//影响距离查询或近似查询，可以设置在多值字段的数据上火分词字段上，查询时可指定slop间隔，默认值是100  
	"store":false//是否单独设置此字段的是否存储而从_source字段中分离，默认是false，只能搜索，不能获取值  
	"search_analyzer":"ik"//设置搜索时的分词器，默认跟ananlyzer是一致的，比如index时用standard+ngram，搜索时用standard用来完成自动提示功能  
	"similarity":"BM25"//默认是TF/IDF算法，指定一个字段评分策略，仅仅对字符串型和分词类型有效  
	"term_vector":"no"//默认不存储向量信息，支持参数yes（term存储），with_positions（term+位置）,with_offsets（term+偏移量），with_positions_offsets(term+位置+偏移量) 对快速高亮fast vector highlighter能提升性能，但开启又会加大索引体积，不适合大数据量用  
}  
```

### 1.1.2 Setting
**setting为ES索引的配置属性。**

索引的配置项按是否可以更改分为静态(static)属性与动态配置，所谓的静态配置即索引创建后不能修改，静态配置只能在创建索引时或者在状态为 closed index的索引（闭合的索引）上设置：

- **索引静态配置**
```
index.number_of_shards ：主分片数，不能修改。创建索引库的分片数默认 1 片，在 7.0.0 之前的 Elasticsearch 版本中，默认 5 片。

index.shard.check_on_startup ：是否在索引打开前检查分片是否损坏，当检查到分片损坏将禁止分片被打开
可选值：false：不检测；checksum：只检查物理结构；true：检查物理和逻辑损坏，相对比较耗CPU；fix：类同与false，7.0版本后将废弃。默认值：false。

index.codec：数据存储的压缩算法，默认算法为LZ4，也可以设置成best_compression，best_compression压缩比较好，但存储性能比LZ4差

index.routing_partition_size ：路由分区数，默认为 1，只能在索引创建时设置。此值必须小于index.number_of_shards，如果设置了该参数，其路由算法为： (hash(_routing) + hash(_id) % index.routing_parttion_size ) % number_of_shards。如果该值不设置，则路由算法为 hash(_routing) % number_of_shardings，_routing默认值为_id。
```

- **索引动态配置**

```
index.number_of_replicas ：每个主分片的副本数，默认为 1，该值必须大于等于0

index.auto_expand_replicas ：基于可用节点的数量自动分配副本数量,默认为 false（即禁用此功能）

index.refresh_interval ：执行刷新操作的频率，这使得索引的最近更改可以被搜索。默认为 1s。可以设置为 -1 以禁用刷新。
 
index.max_result_window ：用于索引搜索的 from+size 的最大值。默认为 10000
 
index.max_rescore_window ： 在搜索此索引中 rescore 的 window_size 的最大值
 
index.blocks.read_only ：设置为 true 使索引和索引元数据为只读，false 为允许写入和元数据更改。

index.blocks.read_only_allow_delete：与index.blocks.read_only基本类似，唯一的区别是允许删除动作。
 
index.blocks.read ：设置为 true 可禁用对索引的读取操作
 
index.blocks.write ：设置为 true 可禁用对索引的写入操作。
 
index.blocks.metadata ：设置为 true 可禁用索引元数据的读取和写入。
 
index.max_refresh_listeners ：索引的每个分片上可用的最大刷新侦听器数

index.max_docvalue_fields_search：一次查询最多包含开启doc_values字段的个数，默认为100。
```

<br>
## 1.2 类型（Type）
在一个索引中，你可以定义一种或多种类型。
一个类型是你的索引的一个逻辑上的分类/分区，其语义完全由你来定。通常，会为具
有一组共同字段的文档定义一个类型。不同的版本，类型发生了不同的变化。
|    版本       |      Type       |
|---------------|------------------|
|     5.x      |     支持多种 type        |
|     6.x      |     只能有一种 type        |
|     7.x      |     默认不再支持自定义索引类型（默认类型为：_doc）     |

>弃用原因：一个index中的多个type，实际上是放在一起存储的，一条数据会拥有所有type的field，导致field导致存在大量空值，造成资源浪费。所以，不同类型数据，要放到不同的索引中。

<br>
## 1.3 文档（Document）
一个文档是一个可被索引的基础信息单元，也就是一条数据
比如：你可以拥有某一个客户的文档，某一个产品的一个文档，当然，也可以拥有某个
订单的一个文档。文档以 JSON（Javascript Object Notation）格式来表示，而 JSON 是一个
到处存在的互联网数据交互格式。
在一个 index/type 里面，你可以存储任意多的文档。

<br>
## 1.4 字段（Field）
相当于是数据表的字段，对文档数据根据不同属性进行的分类标识。

<br>
## 1.5 分片（Shards）
一个索引可以存储超出单个节点硬件限制的大量数据。为了解决这个问题，Elasticsearch 提供了将索引划分成多份的能力，每一份就称之为分片。当你创建一个索引的时候，你可以指定你想要的分片的数量。每个分片本身也是一个功能完善并且独立的“索引”，这个“索引”可以被放置到集群中的任何节点上。

分片很重要，主要有两方面的原因：
1）允许你水平分割 / 扩展你的内容容量。
2）允许你在分片之上进行分布式的、并行的操作，进而提高性能/吞吐量。

至于一个分片怎样分布，它的文档怎样聚合和搜索请求，是完全由 Elasticsearch 管理的，对于作为用户的你来说，这些都是透明的，无需过分关心。
`被混淆的概念是，一个 Lucene 索引 我们在 Elasticsearch 称作 分片 。 一个Elasticsearch 索引 是分片的集合。 当 Elasticsearch 在索引中搜索的时候， 他发送查询到每一个属于索引的分片(Lucene 索引)，然后合并每个分片的结果到一个全局的结果集。`

<br>
## 1.6 副本（Replicas）
在一个网络 / 云的环境里，失败随时都可能发生，在某个分片/节点不知怎么的就处于离线状态，或者由于任何原因消失了，这种情况下，有一个故障转移机制是非常有用并且是强烈推荐的。为此目的，lasticsearch 允许你创建分片的一份或多份拷贝，这些拷贝叫做复制分片(副本)。

复制分片之所以重要，有两个主要原因：
1） 在分片/节点失败的情况下，提供了高可用性。因为这个原因，注意到复制分片从不与原/主要（original/primary）分片置于同一节点上是非常重要的。
2） 扩展你的搜索量/吞吐量，因为**搜索可以在所有的副本上并行运行。**

分片和复制的数量可以在索引创建的时候指定。在索引创建之后，你可
以在**任何时候动态地改变复制的数量**，但是你事后不能改变分片的数量。默认情况下，Elasticsearch 中的每个索引被分片 1 个主分片和 1 个复制。

<br>
## 1.7 分配（Allocation）
将分片分配给某个节点的过程，包括分配主分片或者副本。如果是副本，还包含从主分片复制数据的过程。这个过程是由 master 节点完成的。

<br>
# 二、系统架构

![image.png](Elasticsearch-基础.assets\8a52b74d9bf34479b190b1ec89115f72.png)

## 2.1 集群
一个运行中的 Elasticsearch 实例称为一个节点，而集群是由一个或者多个拥有相同cluster.name 配置的节点组成， 它们共同承担数据和负载的压力。当有节点加入集群中或者从集群中移除节点时，**集群将会重新平均分布所有的数据**。

**主节点责任：**
- 负责管理集群范围内的所有变更，例如增加、删除索引，或者增加、删除节点等。 
- 不负责到文档级别的变更和搜索等操作，所以当集群只拥有一个主节点的情况下，即使流量的增加它也不会成为瓶颈。 

作为用户，我们可以将请求发送到集群中的任何节点 ，包括主节点。 每个节点都知道任意文档所处的位置，并且能够将我们的请求直接转发到存储我们所需文档的节点。 无论我们将请求发送到哪个节点，它都能负责从各个包含我们所需文档的节点收集回数据，并将最终结果返回给客户端。 

**主节点和主分片是不相干的概念：**
- 主节点：负责管理集群范围内的所有变更，例如增加、删除索引，或者增加、删除节点等。 
- 主分片：负责到文档级别的变更。

## 2.2 故障转移（replicas）
为了防止节点故障导致数据丢失，我们需要将数据在另一台节点上进行备份，主节点的备份就是副本分片，备份分片数量可以在创建mapping进行指定，也可以在集群工作中动态修改。

**集群监控状况**
- green：所有主副分片都已分配。
- yellow ：至少有一个副本分片未分配
- red：至少有一个朱分片未分配


## 2.3 水平扩容
每个节点上可以存储的数据量有限，且单台节点上数据量过大对数据处理的压力会增大。我们可以通过扩展集群节点来进行水平扩容，好处如下：
- 1.虽然分片数量在创建mapping时指定后不能修改（分片数决定了索引能存储的最大数据量），但是可以通过增加节点来减小每台主机上的分片分布。因为启动了新的节点，集群将会为了分散负载而对分片进行重新分配；
- 2.节点数增多，可以配置更多的副本。读操作（搜索和返回数据）可以同时被主分片 或 副本分片所处理，所以当你拥有越多的副本分片时，也将拥有越高的吞吐量。


## 2.4 应对故障
如果一个节点宕机，那么这个节点上的主分片就会失效，如果其他节点上有副本分片，集群会将其他节点上的副本分片提升为主分片，这个过程是瞬间发生的。如果没有副本分片，那么集群健康状态就会变red，表示有主节点未分配。

## 2.5 路由计算
当索引一个文档的时候，文档会被存储到一个主分片中。 当我们创建文档时，它如何决定这个文档应当被存储在哪个分片中呢？这个是根据下面这个公式决定的：
```
shard = hash(routing) % number_of_primary_shards
```
>routing 是一个可变值，默认是文档的 _id ，也可以设置成一个自定义的值。

因此集群分片数在创建时指定后就不能修改，是因为修改之后，之前的路由值都会失效，文档再也找不到了。

所有的文档 API（ get 、 index 、 delete 、 bulk 、 update 以及 mget ）都接受一个叫做 routing 的路由参数 ，通过这个参数我们可以自定义文档到分片的映射。一个自定义的路由参数可以用来确保所有相关的文档——例如所有属于同一个用户的文档——都被存储到同一个分片中。

## 2.6 分片控制
我们可以发送请求到集群中的任一节点。 每个节点都有能力处理任意请求。 每个节点都知道集群中任一文档位置，所以可以直接将请求转发到需要的节点上。 在下面的例子中，将所有的请求发送到 Node 1，我们将其称为 协调节点(coordinating node)。
>当发送请求的时候， 为了扩展负载，更好的做法是轮询集群中所有的节点。

### 2.6.1 写流程
新建、索引和删除 请求都是 写 操作， 必须在主分片上面完成之后才能被复制到相关的副本分片。

![image.png](Elasticsearch-基础.assets\8d7149809c584d8e961bbf0a94db5b24.png)

**新建，索引和删除文档所需要的步骤顺序：**
1. 客户端向 Node 1 发送新建、索引或者删除请求。
2. 节点使用文档的 _id 确定文档属于分片 0 。请求会被转发到 Node 3，因为分片 0 的主分片目前被分配在 Node 3 上。
3. Node 3 在主分片上面执行请求。如果成功了，它将请求并行转发到 Node 1 和 Node 2 的副本分片上。一旦所有的副本分片都报告成功, Node 3 将向协调节点报告成功，协调节点向客户端报告成功。

在客户端收到成功响应时，文档变更已经在主分片和所有副本分片执行完成，变更是安全的。有一些可选的请求参数允许您影响这个过程，可能以数据安全为代价提升性能。这些选项很少使用，因为 Elasticsearch 已经很快，但是为了完整起见，请参考下面表格：

|                    参数              |                   含义                     |
|-----------------------------------|---------------------------------------|
| consistency | consistency，即一致性。在默认设置下，即使仅仅是在试图执行一个_写_操作之前，主分片都会要求 必须要有 规定数量(quorum)（或者换种说法，也即必须要有大多数）的分片副本处于活跃可用状态，才会去执行_写_操作(其中分片副本可以是主分片或者副本分片)。这是为了避免在发生网络分区故障（network partition）的时候进行_写_操作，进而导致数据不一致。_规定数量_即：<br>int( (primary + number_of_replicas) / 2 ) + 1 <br>consistency 参数的值可以设为**one**（只要主分片状态 ok 就允许执行_写_操作）,**all**（必须要主分片和所有副本分片的状态没问题才允许执行_写_操作）, 或**quorum** 。默认值为 quorum , 即大多数的分片副本状态没问题就允许执行_写_操作。<br>注意，规定数量 的计算公式中 number_of_replicas 指的是在索引设置中的设定副本分片数，而不是指当前处理活动状态的副本分片数。如果你的索引设置中指定了当前索引拥有三个副本分片，那规定数量的计算结果即：<br>int( (primary + 3 replicas) / 2 ) + 1 = 3<br>如果此时你只启动两个节点，那么处于活跃状态的分片副本数量就达不到规定数量，也因此您将无法索引和删除任何文档。 |
| timeout | 如果没有足够的副本分片会发生什么？ Elasticsearch 会等待，希望更多的分片出现。默认情况下，它最多等待 1 分钟。 如果你需要，你可以使用 timeout 参数使它更早终止： 100 100 毫秒，30s 是 30 秒。 |
>NOTE：新索引默认有 1 个副本分片，这意味着为满足规定数量应该需要两个活动的分片副本。 但是，这些默认的设置会阻止我们在单一节点上做任何事情。为了避免这个问题，要求只有当number_of_replicas 大 于 1 的时候，规定数量才会执行。

### 2.6.2 读流程
![image.png](Elasticsearch-基础.assets\d58450b0e9e54fb7a620146de2fbe61f.png)

**从主分片或者副本分片检索文档的步骤顺序：**
1. 客户端向 Node 1 发送获取请求；
2. 节点使用文档的 _id 来确定文档属于分片 0 。分片 0 的副本分片存在于所有的三个节点上。 在这种情况下，它将请求转发到 Node 2 ；
3. Node 2 将文档返回给 Node 1 ，然后将文档返回给客户端。

在处理读取请求时，协调结点在每次请求的时候都会通过**轮询所有的副本分片**来达到负载均衡。在文档被检索时，已经被索引的文档可能已经存在于主分片上但是还没有复制到副本分片。 在这种情况下，副本分片可能会报告文档不存在，但是主分片可能成功返回文档。 一旦索引请求成功返回给用户，文档在主分片和副本分片都是可用的。


### 2.6.3 更新流程

![image.png](Elasticsearch-基础.assets0b15cf6e0c14aacaec81151365b72e7.png)

**部分更新一个文档的步骤如下：**
1. 客户端向 Node 1 发送更新请求。
2. 它将请求转发到主分片所在的 Node 3 。
3. Node 3 从主分片检索文档，修改 _source 字段中的 JSON ，并且尝试重新索引主分片的文档。如果文档已经被另一个进程修改，它会重试步骤 3 ，超过 retry_on_conflict 次后放弃。(使用乐观锁控制并发，每次修改数据_version都会加一)
4. 如果 Node 3 成功地更新文档，它将新版本的文档并行转发到 Node 1 和 Node 2 上的副本分片，重新建立索引。一旦所有副本分片都返回成功， Node 3 向协调节点也返回成功，协调节点向客户端返回成功。
>当主分片把更改转发到副本分片时， 它不会转发更新请求。 相反，它转发完整文档的新版本(只取最新的_version版本，保证同步的是最新版本)。请记住，这些更改将会异步转发到副本分片，并且不能保证它们以发送它们相同的顺序到达。 如果 Elasticsearch 仅转发更改请求，则可能以错误的顺序应用更改，导致得到损坏的文档。

### 2.6.4 多文档操作流程
mget 和 bulk API 的模式类似于单文档模式。区别在于协调节点知道每个文档存在于哪个分片中。它将整个多文档请求分解成 每个分片 的多文档请求，并且将这些请求并行转发到每个参与节点。
协调节点一旦收到来自每个节点的应答，就将每个节点的响应收集整理成单个响应，返回给客户端；



**用单个 mget 请求取回多个文档所需的步骤顺序:**
![image.png](Elasticsearch-基础.assets1ab2545329e49f485addbcdc9ca639f.png)
1. 客户端向 Node 1 发送 mget 请求；
2. Node 1 为每个分片构建多文档获取请求，然后并行转发这些请求到托管在每个所需的主分片或者副本分片的节点上。一旦收到所有答复， Node 1 构建响应并将其返回给客户端。
可以对 docs 数组中每个文档设置 routing 参数。

<br>
**bulk API， 允许在单个批量请求中执行多个创建、索引、删除和更新请求：**
![image.png](Elasticsearch-基础.assets\767437485ff24ef7a32b64cf0f0836d3.png)
1. 客户端向 Node 1 发送 bulk 请求。
2. Node 1 为每个节点创建一个批量请求，并将这些请求并行转发到每个包含主分片的节点主机。
3. 主分片一个接一个按顺序执行每个操作。当每个操作成功时，主分片并行转发新文档（或删除）到副本分片，然后执行下一个操作。 一旦所有的副本分片报告所有操作成功，该节点将向协调节点报告成功，协调节点将这些响应收集整理并返回给客户端。

<br>
## 2.7 shard内部原理
分片是 Elasticsearch 最小的工作单元。传统的数据库每个字段存储单个值，但这对全文检索并不够。文本字段中的每个单词需要被搜索，对数据库意味着需单个字段有索引多值的能力。最好的支持是一个字段多个值需求的数据结构是**倒排索引**。
### 2.7.1 倒排索引
Elasticsearch 使用一种称为倒排索引的结构，它适用于快速的全文搜索。一个倒排索引由文档中所有不重复词的列表构成，对于其中每个词，有一个包含它的文档列表。

**倒排索引包含以下几个部分：**
- 某个关键词的doc list
- 某个关键词的所有doc的数量IDF(逆向文档频率：总文档数除以含改词文档数再取对数)
- 某个关键词在每个doc中出现的次数：TF(词频：词在本文档中出现频率)
- 某个关键词在这个doc中的次序
- 每个doc的长度：length norm
- 某个关键词的所有doc的平均长度
>记录这些信息，就是为了方便搜索的效率和_score分值的计算。

### 2.7.2 分词和标准化（分析）
你只能搜索在索引中出现的词条，所以索引文本和查询字符串必须标准化为相
同的格式。

**analyzer即分析器，分析器包括**
- 字符过滤器CharacterFilters（0个或1个以上）：首先，字符串按顺序通过每个 字符过滤器 。他们的任务是在分词前整理字符串。一个字符过滤器可以用来去掉HTML，或者将 & 转化成 and。
- 分词器Tokenizer（1个）：其次，字符串被 分词器 分为单个的词条。一个简单的分词器遇到空格和标点的时候，可能会将文本拆分成词条。如whitespace分词器，会通过空格符划分词条。
- 后过滤器TokenFilter（0个或1个以上）：最后，词条按顺序通过每个 token 过滤器 。这个过程可能会改变词条（例如，小写化 Quick ），删除词条（例如， 像 a， and， the 等无用词），或者增加词条（例如，像 jump 和 leap 这种同义词）。

![image.png](Elasticsearch-基础.assets321642c51ae45f49e1bac2f556bfa44.png)

### 2.7.3 动态更新索引
早期的全文检索会为整个文档集合建立一个很大的倒排索引并将其写入到磁盘。 一旦新的索引就绪，旧的就会被其替换，这样最近的变化便可以被检索到。

**不变性的好处如下：**
- 线程安全：线程安全，无需靠考虑多线程问题。
- 倒排索引不可改变，那么内存中的数据就不会改变。只要文件系统缓存中还有足够的空间，那么大部分读请求会直接请求内存，而不会命中磁盘。这提供了很大的性能提升。
- 其它缓存(像 filter 缓存)，在索引的生命周期内始终有效。它们不需要在每次数据改变时被重建，因为数据不会变化。
- 写入单个大的倒排索引允许数据被压缩，减少磁盘 I/O 和 需要被缓存到内存的索引的使用量。

**如何在保留不变性的前提下实现倒排索引的更新？**
通过补充新的索引来反映最新的修改，而不是直接重写整个倒排索引。这就引入了**按段搜索**的概念，每个段(segment)都是一个倒排索引，每一个倒排索引都会被轮流查询到，从最早的开始查询完后再对结果进行合并。还增加了提交点的概念(commit point)。

- **段(segment file)**：存储倒排索引的文件，每个segment本质上就是一个倒排索引，每秒都会生成一个segment文件，当文件过多时es会自动进行segment merge（合并文件），合并时会同时将已经标注删除的文档物理删除；
- **提交点(commit point)**：记录当前所有可用的segment，每个commit point都会维护一个.del文件（es删除数据本质是不属于物理删除），当es做删改操作时首先会在.del文件中声明某个document已经被删除，文件内记录了在某个segment内某个文档已经被删除，当查询请求过来时在segment中被删除的文件是能够查出来的，但是当返回结果时会根据commit point维护的那个.del文件把已经删除的文档过滤掉；
- **translog日志文件**: 为了防止elasticsearch宕机造成数据丢失保证可靠存储，es会将每次写入数据的同时写到translog日志中。

<br>
### 2.7.4 近实时搜索
随着按段（per-segment）搜索的发展，一个新的文档从索引到可被搜索的延迟显著降低了。新文档在几分钟之内即可被检索，但这样还是不够快。磁盘在这里成为了瓶颈。提交（Commiting）一个的段到磁盘需要一个 fsync 来确保段被物理性地写入磁盘，这样在断电的时候就不会丢失数据。 但是 fsync 操作代价很大; 如果每次索引一个文档都去执行一次的话会造成很大的性能问题。
这就意味着fsync不能被经常触发，但是只有段真正落盘后，才真正生效，所以fsync时间越长，新文档插入后可以被检索的延迟就越长。为了实现近实时搜索，同时为了防止数据丢失，新段会被先写入到文件系统缓存中(refresh)，这一步代价会比较低，稍后再被刷新到磁盘(flush)，这一步代价比较高。而fsync仅作为translog日志文件同步到磁盘中的操作。

- **refresh**：es接收数据请求时先存入内存中，默认每隔一秒会从内存buffer中将数据写入filesystem cache，这个过程叫做refresh；
- **flush**：es默认每隔30分钟会将filesystem cache中的数据刷入磁盘同时清空translog日志文件，这个过程叫做flush。
- **fsync**：translog会每隔5秒或者在一个变更请求完成之后执行一次fsync操作，将translog从缓存刷入磁盘，这个操作比较耗时，如果对数据一致性要求不是跟高时建议将索引改为异步，如果节点宕机时会有5秒数据丢失;

<br>
**段合并过程**
由于自动刷新流程每秒会创建一个新的段 ，这样会导致短时间内的段数量暴增。而段数目太多会带来较大的麻烦。 每一个段都会消耗文件句柄、内存和 cpu 运行周期。更重要的是，每个搜索请求都必须轮流检查每个段；所以段越多，搜索也就越慢。
段合并的时候会将那些旧的已删除文档从文件系统中清除。被删除的文档（或被更新文档的旧版本）不会被拷贝到新的大段中。

启动段合并不需要你做任何事。进行索引和搜索时会自动进行：
1. 当索引的时候，刷新（refresh）操作会创建新的段并将段打开以供搜索使用。
2. 合并进程选择一小部分大小相似的段，并且在后台将它们合并到更大的段中。这并不会中断索引和搜索。
3. 一旦合并结束，老的段被删除。

合并大的段需要消耗大量的 I/O 和 CPU 资源，如果任其发展会影响搜索性能。Elasticsearch在默认情况下会对合并流程进行资源限制，所以搜索仍然 有足够的资源很好地执行。

<br>
**完整elasticsearch的写入数据流程如下：**
![](Elasticsearch-基础.assets\506b2ee0a01b4685bc2fd985c21a7bb0.png)

## 2.8 文档处理
### 2.8.1 文档冲突
当多个客户端并发更新文档时，最新的更新数据会被作为最终的结果进行保存，并重新索引整个文档，在一般场景下是没有问题的。
但是在某些场景下需要进行并发控制，如库存问题，需要先查询库存余额然后再减掉卖掉的物品数量。这就会产生超卖问题。

**解决这种并发问题一般有两种方式：**
- 悲观并发控制：在访问数据时添加排他锁，解锁之后才能被其他进程访问。
- 乐观并发控制：在访问数据时获取其版本号，修改数据时，只有版本号大于或等于数据的版本号，才允许修改，修改成功后数据的版本号加一。

**在es中默认使用乐观锁：**
当添加文档成功时，会返回当前文档的_version、_seq_no和_primary_term信息。这些都是版本号相关的属性。
```
{
    "_index": "smartcook",
    "_type": "_doc",
    "_id": "4",
    "_version": 1,
    "result": "created",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 2,
    "_primary_term": 8
}
```
修改该文档时，可以携带版本号信息，如果版本号信息有误，就会修改失败。
```
http://chenjie.asia:9200/smartcook/_doc/4?if_seq_no=3&if_primary_term=8

# 返回
{
    "_index": "smartcook",
    "_type": "_doc",
    "_id": "4",
    "_version": 3,
    "result": "updated",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 4,
    "_primary_term": 8
}
```

### 2.8.2 乐观并发控制
Elasticsearch 是分布式的。当文档创建、更新或删除时， 新版本的文档必须复制到集群中的其他节点。Elasticsearch 也是异步和并发的，这意味着这些复制请求被并行发送，并且到达目的地时也许 顺序是乱的 。Elasticsearch 需要一种方法确保文档的旧版本不会覆盖新的版本。
当我们之前讨论 index ，GET 和 delete 请求时，我们指出每个文档都有一个 _version （版本）号，当文档被修改时版本号递增。 Elasticsearch 使用这个 version 号来确保变更以正确顺序得到执行。如果旧版本的文档在新版本之后到达，它可以被简单的忽略。
我们可以利用 version 号来确保 应用中相互冲突的变更不会导致数据丢失。我们通过指定想要修改文档的 version 号来达到这个目的。 如果该版本不是当前版本号，我们的请求将会失败。
老的版本 es 使用 version，但是新版本不支持了，会报下面的错误，提示我们用 if_seq_no和 if_primary_term。
```
{
 "error": {
 "root_cause": [
 {
 "type": "action_request_validation_exception",
 "reason": "Validation Failed: 1: internal versioning can not be used 
for optimistic concurrency control. Please use `if_seq_no` and `if_primary_term` 
instead;"
 }
 ],
 "type": "action_request_validation_exception",
 "reason": "Validation Failed: 1: internal versioning can not be used for 
optimistic concurrency control. Please use `if_seq_no` and `if_primary_term` 
instead;"
 },
 "status": 400
}
```

### 2.8.3 外部系统版本控制
一个常见的设置是使用其它数据库作为主要的数据存储，使用 Elasticsearch 做数据检索， 这意味着主数据库的所有更改发生时都需要被复制到 Elasticsearch ，如果多个进程负责这一数据同步，你可能遇到类似于之前描述的并发问题。
如果你的主数据库已经有了版本号 — 或一个能作为版本号的字段值比如 timestamp —那么你就可以在 Elasticsearch 中通过增加 version_type=external 到查询字符串的方式重用这些相同的版本号， 版本号必须是大于零的整数， 且小于 9.2E+18 — 一个 Java 中 long 类型的正值。
外部版本号的处理方式和我们之前讨论的内部版本号的处理方式有些不同，Elasticsearch 不是检查当前 _version 和请求中指定的版本号是否相同， 而是检查当前_version 是否 小于 指定的版本号。 如果请求成功，外部的版本号作为文档的新 _version 进行存储。
```
http://chenjie.asia:9200/smartcook/_doc/4?version=4&version_type=external

# 返回
{
    "_index": "smartcook",
    "_type": "_doc",
    "_id": "4",
    "_version": 4,
    "result": "updated",
    "_shards": {
        "total": 2,
        "successful": 1,
        "failed": 0
    },
    "_seq_no": 5,
    "_primary_term": 8
}
```
外部版本号不仅在索引和删除请求是可以指定，而且在 创建 新文档时也可以指定。


<br>
# 三、操作命令

![21580557-355e7ba2dc10b507.png](Elasticsearch-基础.assets\18ed6e8ac214442fb8e9f4fe16e8ab2c.png)

## 3.1 基础命令

**查看es的分片副本情况：**

```
http://chenjie.asia:9200/_cat/shards
http://chenjie.asia:9200/_cat/shards/{index}
```

**查看es的健康状况：**

```
GET http://chenjie.asia:9200/_cat/health?v
GET http://chenjie.asia:9200/_cluster/health?pretty=true
```

**查看节点**

```
GET http://chenjie.asia:9200/_cat/nodes
```

**查看主节点**

```
GET http://chenjie.asia:9200/_cat/master
```

**查看所有索引**

```
http://chenjie.asia:9200/_cat/indices
http://chenjie.asia:9200/_cat/allocation 
http://chenjie.asia:9200/_cat/thread_pool
http://chenjie.asia:9200/_cat/segments 
http://chenjie.asia:9200/_cat/segments/{index}
```



## 3.2 索引

#### 创建索引
```
PUT http://chenjie.asia:9200/smartcook
```

#### 查询索引
```
GET http://chenjie.asia:9200/smartcook
```

#### 删除索引
```
PUT http://chenjie.asia:9200/smartcook
```


#### 创建带setting和mapping的索引
```
PUT http://chenjie.asia:9200/smartcook
{
	"setting":{
		"analysis": {
			// 自定义分词器
		},
		"index": {
			"number_of_shards": 3,
			"number_of_replicas": 1
		}
	},
    "mappings": {
            // 字段名称和类型的定义
            "properties": {   
                // 字段名
                "menu": {  
                    // 字段类型
                    "type": "text",   // text表示可分词
                    "index": true   // 可以被索引的，即可查的
                },
                "author": {
					"type": "keyword",  // keyword表示不分词
                    "index": true
                },
                "food": {
					"type": "keyword",
                    "index": false   // 不能被查询
                },
                "degree": {
					"type": "integer",
                    "index": true
                }
            }
    }
}
```



**注：如果没有指定fields，那么插入数据时会动态进行动态创建。
创建mapping的时候可以指定dynamic属性（可以设置在type下，也可以设置在字段中）
> a.  true：允许传入新field，且自动映射一个新的field（默认的配置）
> b.  false：允许传入新field，但不会映射为一个新的field，且无法对字段进行查询操作
> c.  strict：传入新field会报错
**可以设置如下**
```
PUT http://chenjie.asia:9200/smartcook/_mapping/
{
	"dynamic":"strict"
}
```

> 创建mapping的时候可以指定dynamic属性（可以设置在type下，也可以设置在字段中）
> a.  true：允许传入新field，且自动映射一个新的field（默认的配置）
> b.  false：允许传入新field，但不会映射为一个新的field，且无法对字段进行查询操作
> c.  strict：传入新field会报错




## 3.3 数据操作

#### 插入数据

如果没有定义该field，则自动设置为keyword类型。如果不指定_id，会自动生成随机_id

```
PUT http://chenjie.asia:9200/smartcook/_doc/1
{
	"menu":"西红柿鸡蛋",
	"author":"CJ",
	"food":"西红柿,鸡蛋",
	"degree": 3
}

PUT http://chenjie.asia:9200/smartcook/_doc/2
{
	"menu":"韭菜鸡蛋",
	"author":"ZS",
	"food":"韭菜,鸡蛋",
	"degree": 2
}
```

#### 查询数据

```
# 根据id查询数据
GET http://chenjie.asia:9200/smartcook/_doc/1  
# 查询索引下所有数据
GET http://chenjie.asia:9200/smartcook/_search
```



#### 修改已插入的数据

方式一：直接PUT一条相同id的数据，进行覆盖。

```
PUT http://chenjie.asia:9200/smartcook/_doc/1
{
	"degree": 5
}
```

方式二：使用POST请求对指定的field进行update

```
POST http://chenjie.asia:9200/smartcook/_doc/1
{
	"degree": 5
}
```

#### 删除数据

```
http://chenjie.asia:9200/smartcook/_doc/1
```



## 3.4 分析器

### 3.4.1 概念

**analyzer即分析器，分析器包括**

- 字符过滤器CharacterFilters（0个或1个以上）：首先，字符串按顺序通过每个 字符过滤器 。他们的任务是在分词前整理字符串。一个字符过滤器可以用来去掉HTML，或者将 & 转化成 and。
- 分词器Tokenizer（1个）：其次，字符串被 分词器 分为单个的词条。一个简单的分词器遇到空格和标点的时候，可能会将文本拆分成词条。如whitespace分词器，会通过空格符划分词条。
- 后过滤器TokenFilter（0个或1个以上）：最后，词条按顺序通过每个 token 过滤器 。这个过程可能会改变词条（例如，小写化 Quick ），删除词条（例如， 像 a， and， the 等无用词），或者增加词条（例如，像 jump 和 leap 这种同义词）。

![image.png](Elasticsearch-基础.assets\5b4e31a0b6f04e04ad8a84a5ebd87bab.png)
一个 analyzer 有且只有一个 tokenizer，有0个或一个以上的 char filter 及 token filter。

Elasticsearch 已经提供了比较丰富的开箱即用 analyzer。我们可以自己创建自己的 token analyzer，甚至可以利用已经有的 char filter，tokenizer 及 token filter 来重新组合成一个新的 analyzer，并可以对文档中的每一个字段分别定义自己的 analyzer。

![不同分析器分词效果](Elasticsearch-基础.assets84834408bec459c80040ad864cc1020.png)



### 3.4.2 分词器效果测试
默认的Character Filters：HTML Strip(去除html标签和转换html实体)、Mapping(字符串替换操作)、Pattern Replace(正则匹配替换)。

如下实例通过CharacterFilters过滤掉html的标签：
```
POST _analyze
{
"tokenizer":  "keyword",
"char_filter" : [ "html_strip" ],
"text" : "<div><h1>B<sup>+</sup>Trees</h1></div>"
}
```
#### 3.4.2.1 测试常用分词器效果

##### ①测试keyword分词

```
GET http://chenjie.asia:9200/smartcook/_analyze
{
  "analyzer": "keyword",  //keyword分词器将不会对文本进行分词
  "text": "老干妈炒饭"    
}
```

##### ②测试standard分词
在默认的情况下，standard analyzer 是 Elasticsearch 的缺省分析器：
- 没有 Char Filter
- 使用 standard tokonizer
- 把字符串变为小写，同时有选择地删除一些 stop words 等。默认的情况下 stop words 为 _none_，也即不过滤任何 stop words。
```
GET http://chenjie.asia:9200/smartcook/_analyze
{
  "analyzer": "standard",  //standard分词器会将中文的每个字分词
  "text": "老干妈炒饭"
}
```

##### ③测试english分词器

```
http://chenjie.asia:9200/smartcook/_analyze
{
	"analyzer": "english",
	"text":"running apps in a phone"
}

# 得到 [run]  [app]  [phone]
```
在上面Running的词源是run，Apps 的词源是 app。english  analyzer 调用将使用 stemmer 后过滤器返回这些词的词源。

##### ④测试ik分词器

```
http://chenjie.asia:9200/smartcook/_analyze
{
  "analyzer": "ik_smart",  //ik_smart分词器会对文本进行智能分词
  "text": "老干妈炒饭"    
}
或
{
  "analyzer": "ik_max_word",  //ik_max_word分词器会对文本进行最细粒度的拆分
  "text": "老干妈炒饭"    
}
```

##### ⑤测试pinyin分词器

```
http://chenjie.asia:9200/smartcook/_analyze
{
  "analyzer": "pinyin",  //pinyin分词器会存储每个字的拼音和字符串的拼音首字母
  "text": "老干妈炒饭"    
}
```

#### 3.4.2.2 测试指定索引中字段的分词效果

```
GET http://chenjie.asia:9200/smartcook/_analyze
{
	"field":"name",
	"text":"老干妈炒饭"
}
```



## 3.5 查询命令

### 3.5.1 简单查询

查询索引下author为CJ的行

```
http://chenjie.asia:9200/smartcook/_search?q=author:CJ
```

### 3.5.2 复杂查询

1) term：查询某个域里含有指定关键词的文档，不会对关键词进行分析。
2) terms：查询某个域里含有多个关键词的文档，不会对关键词进行分析，并且域需要包含所有指定的关键词。
3) match：会对关键词进行分析，如果关键词的分词和被搜索字段的分词有匹配上的就匹配成功并返回结果。
4) match_all：不设条件，查询所有文档
5) multi_match：匹配多个字段
6) match_phrase：短语匹配查询。字符串被分析时，分析器不仅只返回一个词条列表，它同时也返回原始字符串的每个词条的位置、或者顺序信息。匹配含有正确单词出现顺序的文档，且在这些单词之间没有插入别的单词。slop参数告诉match_phrase查询词条能够相隔多远时仍然将文档视为匹配。相隔多远的意思是，你需要移动一个词条多少次来让查询和文档匹配。如下所示，quick fox能够匹配quick brown fox；当slop为3时，fox quick能够匹配quick brown fox



注：term不会对查询条件进行分词，keyword不会对字段进行分词。text类型会被分词器解析，keyword不会被分词器解析。



**字段过滤，排序和分页**

```
"_source": ["menu","author"],  // 结果过滤，只显示menu和author两个字段
"sort": [
        {
                "degree": {
                        "order": "desc"
                }
        },  // 查询结果根据degree进行倒排
        {
                 "_score":{
                        "order": "desc"
         }
}],
"from": 0, // 从第几个数据开始
"size": 2  // 返回数据个数
"profile": true,       //显示具体的执行过程
"explain": true,       //显示分数计算
```

**高亮查询**

```
// 高亮显示
"highlight": {
	"pre_tags": ["<p class='key' style='color:red'>"],  //可以自定义的html前缀标签
	"post_tags": ["</p>"],  //可以自定义的html后缀标签
	"fields": {
		"menu": {}  //会自动将搜索结果添加html高亮标签<em>
	}
}
```



#### 精确查询(term不分词)

term为精确查询，不再将搜索关键字分词。

```
GET http://chenjie.asia:9200/smartcook/_search
{
 	"query": {
		"term": {
			"name": "CJ"
		}
	}
}
```

查询term（不分词查询）

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "term":{
      "menu":{
         "value":"鸡 蛋"
      }
    }
  }
}
```

查询terms（不分词 OR）

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "terms":{
      "menu":["鸡","蛋"]  // 多关键词不分词查询，关键词之间是OR的关系
    }
  }
}
```




#### 全量查询

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"query":{
		"match_all":{
		}
	},
	"_source": ["menu","author"],  // 结果过滤，只显示menu和author两个字段
    "sort": [
	    {"degree": {"order": "desc"}}  // 查询结果根据degree进行倒排
	],
    "from": 0, // 从第几个数据开始
    "size": 2  // 返回数据个数
}
```



#### 单条件分词查询（match）

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"query": {
		"match": {
			"menu": "西红柿鸡蛋"
		}
	},
	"profile": true,       //显示具体的执行过程
	"explain": true,       //显示分数计算
	// 高亮显示
	"highlight": {
	"pre_tags": ["<p class='key' style='color:red'>"],  //可以自定义的html前缀标签
	"post_tags": ["</p>"],  //可以自定义的html后缀标签
	"fields": {
	"menu": {}  //会自动将搜索结果添加html高亮标签<em>
	}
}
```



#### 多条件分词查询

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"query":{
		"bool": {
			"must": [
				{
					"match": {
						"menu": "西红柿"
					}
				},
				{
					"match": {
						"author": "CJ"
					}
				}
			],
			"should": [],
			"must_not":[], // 不影响相关性算分
			"filter":{  // 不影响相关性算分
				"range":{
					"degree":{
						"gt": 1,   // gte、lte、gt、lt
						"lt": 5
					}
				}
			}
		}
	}
}
```





#### 查询match（分词查询）

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "match":{
      "menu":{
        "query":"西红柿 蛋",
        "operator":"and"    // 【西红柿】 和 【蛋】 需要同时满足
      }
    }
  }
}
```





#### 查询match_phrase（短语查询）

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "match_phrase":{
      "menu":{
        "query":"西 蛋",
        "slop": 3    //表示短语中的单词相对位置允许有3个位置的偏差
      }
    }
  }
}
```


#### multi_query
```
{
	"query": {
		"multi_match": {
			"query": "CJ",
			"fields": ["menu","author"]
		}
	} 
}
```

#### 查询query_string（单或多字段查询）

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "query_string":{
      "fields":["menu","author"],      //匹配的field为menu和author
      "query":"ZS OR (西红柿 AND 鸡蛋)"    //指定关键词，有"ZS"或同时有"西红柿"和"鸡蛋"
    }
  }
}
```



#### 范围查询range

```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query":{
    "range":{
      "degree":{
        "gte":3,
        "lte" :4
      }
    }
  }
}
```



#### match_phrase_prefix查询

（推荐搜索，最后一个单词会匹配大量的文档，效率不高）

```
POST /my_index/my_type/_search
{
	"query": {
		"match_phrase_prefix": {
			"title": {
				"query": "this is r",
				"analyzer": "standard",
				"max_expansions": 10,
				"slop": 2,
				"boost": 100
			}
		}
	}
}
```
> 参数说明：
> analyzer 指定何种分析器来对该短语进行分词处理
> max_expansions 控制最大的返回结果
> boost 用于设置该查询的权重
> slop 允许短语间的词项(term)间隔
> 注：match_phrase_prefix与match_phrase相同,但是它多了一个特性,就是它允许在文本的最后一个词项(term)上的前缀匹配,如果是一个单词,比如a,它会匹配文档字段所有以a开头的文档,如果是一个短语,比如 "this is ma" ,则它会先进行match_phrase查询,找出所有包含短语"this is"的的文档,然后在这些匹配的文档中找出所有以"ma"为前缀的文档.



#### 聚合查询

对degree字段进行聚合，得到每个degree值的**统计次数**。如果不想显示原数据，可以加上size=0

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs": {   // 聚合操作
		"degree_count": {	// 名称，随意其名
			"terms": {  // 分组统计
				"field": "degree"  // 分组字段
			}
		}
	},
	"size": 0
}
```

得到聚合字段的**平均值**。

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs": {   // 聚合操作
		"degree_avg": {	// 名称，随意其名
			"avg": {  // 平均值
				"field": "degree"  // 分组字段
			}
		}
	},
	"size": 0
}
```

得到聚合字段的**最大值**。
```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs":{
		"degree_max":{
			"max":{
 				"field":"degree"
			}
		}
	},
	"size":0
}
```

得到聚合字段的**最小值**。
```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs":{
		"degree_min":{
			"min":{
 				"field":"degree"
			}
		}
	},
	"size":0
}
```

得到聚合字段的**求和**。
```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs":{
		"degree_sum":{
			"sum":{
 				"field":"degree"
			}
		}
	},
	"size":0
}
```

对某个字段的值进行去重之后再取总数
```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs":{
		"degree_distinct":{
			"cardinality":{
 				"field":"degree"
			}
		}
	},
	"size":0
}
```

State 聚合，对某个字段一次性返回 count，max，min，avg 和 sum 五个指标
```
GET http://chenjie.asia:9200/smartcook/_search
{
	"aggs":{
		"degree_stats":{
			"stats":{
 				"field":"degree"
			}
		}
	},
	"size":0
}
```

#### 桶聚合查询
桶聚和相当于 sql 中的 group by 语句
```
{
	"aggs":{
		"age_groupby":{
			"terms":{
				"field":"age"
			}
		}
	},
	"size":0
}
```

#### fuzzy实现模糊查询
返回包含与搜索字词相似的字词的文档。
编辑距离是将一个术语转换为另一个术语所需的一个字符更改的次数。这些更改可以包括：
- 更改字符（box → fox） 
- 删除字符（black → lack）
- 插入字符（sic → sick） 
- 转置两个相邻字符（act → cat）
为了找到相似的术语，fuzzy 查询会在指定的编辑距离内创建一组搜索词的所有可能的变体或扩展。然后查询返回每个扩展的完全匹配。
通过 fuzziness 修改编辑距离。一般使用默认值 AUTO，根据术语的长度生成编辑距离。
```
GET http://chenjie.asia:9200/smartcook/_search
{
  "query": {
    "fuzzy": {
      "author": {
        "value": "CJJ",
        "fuzziness": 2
      }
    }
  } 
}
```
>value：查询的关键字
boost：查询的权值，默认值是1.0
min_similarity：设置匹配的最小相似度，默认值0.5，对于字符串，取值0-1(包括0和1)；对于数值，取值可能大于1；对于日期取值为1d,1m等，1d等于1天
prefix_length：指明区分词项的共同前缀长度，默认是0


<br>


# 四、集群部署
## 4.1 es 5.6.3
**在一个节点上部署安装了ik和拼音分词器的es集群，步骤如下：**

#### ①编辑Dockerfile

vim elasticsearch.dockerfile

```
FROM elasticsearch:5.6.3-alpine
ENV VERSION=5.6.3
ADD https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v$VERSION/elasticsearch-analysis-ik-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch file:///tmp/elasticsearch-analysis-ik-$VERSION.zip
ADD https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v$VERSION/elasticsearch-analysis-pinyin-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch file:///tmp/elasticsearch-analysis-pinyin-$VERSION.zip
RUN rm -rf /tmp/*
```

#### ②创建镜像es_ik_py

```
docker build -t es_ik_py . -f elasticsearch.dockerfile
```

#### ③创建启动容器

**节点1：**

```
docker run -d -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name es1-p 9200:9200 -p 9300:9300 -v /root/docker/es-cluster/es1.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/docker/es-cluster/data/esdata:/usr/share/elasticsearch/data  es_ik_py
```
/var/lib/elasticsearch/data

**节点2：**

```
docker run -d -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name es2 -p 9201:9200 -p 9301:9300 -v /root/docker/es-cluster/es2.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/docker/es-cluster/data:/usr/share/elasticsearch/data es_ik_py
```

**映射的配置文件**
es1.yml为：

```xml
cluster.name: elasticsearch-cluster
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["116.62.148.11:9300","116.62.148.11:9301"]
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"
```

es2.yml为：

```xml
cluster.name: elasticsearch-cluster
node.name: node-2
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["116.62.148.11:9300","116.62.148.11:9301"]
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"
```

<br>
## 4.2 es 7.8.0
**vim elasticsearch.dockerfile**
```
FROM elasticsearch:7.8.0
ENV VERSION=7.8.0
RUN sh -c '/bin/echo -e "y" | /usr/share/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v${VERSION}/elasticsearch-analysis-ik-$VERSION.zip'
RUN sh -c '/bin/echo -e "y" | /usr/share/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v$VERSION/elasticsearch-analysis-pinyin-$VERSION.zip'
```
**配置文件**
es1.yml
```properties
#节点 1 的配置信息：
#集群名称，节点之间要保持一致
cluster.name: my-elasticsearch
#节点名称，集群内要唯一
node.name: node-1
node.master: true
node.data: true
#允许访问的ip地址
network.host: 0.0.0.0
#http 端口
http.port: 9200
#tcp 监听端口
transport.tcp.port: 9300
#discovery.seed_hosts: ["chenjie.asia:9300", "chenjie.asia:9301"]
#discovery.zen.fd.ping_timeout: 1m
#discovery.zen.fd.ping_retries: 5
#集群内的可以被选为主节点的节点列表
cluster.initial_master_nodes: ["node-1", "node-2"]
#跨域配置
#action.destructive_requires_name: true
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"

# 控制fielddata允许内存大小，达到HEAP 20% 自动清理旧cache。不配置就不回收。
indices.fielddata.cache.size: 20%
indices.breaker.total.use_real_memory: false
# fielddata 断路器限制fileddata的堆大小上限，默认设置堆的 60%
indices.breaker.fielddata.limit: 40%
# request 断路器估算需要完成其他请求部分的结构大小，例如创建一个聚合桶，默认限制是堆内存的 40%。
indices.breaker.request.limit: 40%
# total 揉合 request 和 fielddata 断路器保证两者组合起来不会使用超过堆内存的 70%(默认值)。
indices.breaker.total.limit: 95%
```
es1.yml
```properties
#节点 1 的配置信息：
#集群名称，节点之间要保持一致
cluster.name: my-elasticsearch
#节点名称，集群内要唯一
node.name: node-2
node.master: true
node.data: true
#允许访问的ip地址
network.host: 0.0.0.0
#http 端口
http.port: 9200
#tcp 监听端口
transport.tcp.port: 9300
discovery.seed_hosts: ["chenjie.asia:9300", "chenjie.asia:9301"]
discovery.zen.fd.ping_timeout: 1m
discovery.zen.fd.ping_retries: 5
#集群内的可以被选为主节点的节点列表
cluster.initial_master_nodes: ["node-1", "node-2"]
#跨域配置
#action.destructive_requires_name: true
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"

# 控制fielddata允许内存大小，达到HEAP 20% 自动清理旧cache。不配置就不回收。
indices.fielddata.cache.size: 20%
indices.breaker.total.use_real_memory: false
# fielddata 断路器限制fileddata的堆大小上限，默认设置堆的 60%
indices.breaker.fielddata.limit: 40%
# request 断路器估算需要完成其他请求部分的结构大小，例如创建一个聚合桶，默认限制是堆内存的 40%。
indices.breaker.request.limit: 40%
# total 揉合 request 和 fielddata 断路器保证两者组合起来不会使用超过堆内存的 70%(默认值)。
indices.breaker.total.limit: 95%
```
**启动es容器**
```
docker run -d --privileged -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name es1 -p 9200:9200 -p 9300:9300 -v /root/docker/es/conf/es1.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/docker/es/data/es1data:/usr/share/elasticsearch/data -v  /root/docker/es/logs:/usr/share/elasticsearch/logs -v /root/docker/es/analysis-ik:/usr/share/elasticsearch/config/analysis-ik es_ik_py:7.8.0
```
```
docker run -d --privileged -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name es2 -p 9201:9200 -p 9301:9300 -v /root/docker/es/conf/es2.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/docker/es/data/es2data:/usr/share/elasticsearch/data -v  /root/docker/es/logs:/usr/share/elasticsearch/logs -v /root/docker/es/analysis-ik:/usr/share/elasticsearch/config/analysis-ik es_ik_py:7.8.0
```
>如果启动异常，可能是挂载文件没有写权限，执行`chmod -R 777 /root/docker/es/data/es1data /root/docker/es/logs`

<br>

#### 备注：

1. **如果容器启动报错为bootstrap checks failed，则需要修改宿主机系统文件的内存配置如下**
   **①vi /etc/security/limits.conf** ，修改如下内容：

   ```
   * soft nofile 65536
   * hard nofile 131072
   * soft nproc 4096
   * hard nproc 4096
   ```

   **②vi /etc/security/limits.d/XX-nproc.conf**，修改为：

   ```
   * soft nproc 4096
   ```

   **③vi /etc/sysctl.conf**，添加如下内容：

   ```
   vm.max_map_count=655360
   ```

   **④使系统文件生效**

   ```
   sysctl -p
   ```



2. **启动容器报错WARNING: IPv4 forwarding is disabled. Networking will not work. 或者 网络不通**
   需要修改 /etc/sysctl.conf 

   ```
   net.ipv4.ip_forward=1
   ```

   然后重启network服务

   ```
   systemctl restart network
   ```

   查看

   ```
   sysctl net.ipv4.ip_forward
   ```


<br>
# 五、Elasticsearch 优化
## 5.1 硬件选择
Elasticsearch 的基础是 Lucene，所有的索引和文档数据是存储在本地的磁盘中，具体的路径可在 ES 的配置文件 ../config/elasticsearch.yml 中配置，如下：
```
#----------------------------------- Paths
------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
#path.data: /path/to/data
#
# Path to log files:
#
#path.logs: /path/to/logs
#
```
磁盘在现代服务器上通常都是瓶颈。Elasticsearch 重度使用磁盘，你的磁盘能处理的吞吐量
越大，你的节点就越稳定。这里有一些优化磁盘 I/O 的技巧：
- 使用 SSD。就像其他地方提过的， 他们比机械磁盘优秀多了。
- 使用 RAID 0。条带化 RAID 会提高磁盘 I/O，代价显然就是当一块硬盘故障时整个就故障了。不要使用镜像或者奇偶校验 RAID 因为副本已经提供了这个功能。
- 另外，使用多块硬盘，并允许 Elasticsearch 通过多个 path.data 目录配置把数据条带化分配到它们上面。
- 不要使用远程挂载的存储，比如 NFS 或者 SMB/CIFS。这个引入的延迟对性能来说完全是背道而驰的。

## 5.2 分片策略
### 5.2.1 合理设置分片数
分片和副本的设计为 ES 提供了支持分布式和故障转移的特性，但并不意味着分片和副本是可以无限分配的。而且索引的分片完成分配后由于索引的路由机制，我们是不能重新修改分片数的。
分片数过大过小都会影响es工作的效率
- 一个分片的底层即为一个 Lucene 索引，会消耗一定文件句柄、内存、以及 CPU 运转。
- 每一个搜索请求都需要命中索引中的每一个分片，如果每一个分片都处于不同的节点还好， 但如果多个分片都需要在同一个节点上竞争使用相同的资源就有些糟糕了。
- 用于计算相关度的词项统计信息是基于分片的。如果有许多分片，每一个都只有很少的数据会导致很低的相关度。

一个业务索引具体需要分配多少分片可能需要架构师和技术人员对业务的增长有个预先的判断，横向扩展应当分阶段进行。为下一阶段准备好足够的资源。 只有当你进入到下一个阶段，你才有时间思考需要作出哪些改变来达到这个阶段。一般来说，我们遵循一些原则：
- 控制每个分片占用的硬盘容量不超过 ES 的最大 JVM 的堆空间设置（一般设置不超过 32G，参考下文的 JVM 设置原则），因此，如果索引的总容量在 500G 左右，那分片大小在 16 个左右即可；当然，最好同时考虑原则 2。
- 考虑一下 node 数量，一般一个节点有时候就是一台物理机，如果分片数过多，大大超过了节点数，很可能会导致一个节点上存在多个分片，一旦该节点故障，即使保持了 1 个以上的副本，同样有可能会导致数据丢失，集群无法恢复。所以， 一般都设置分片数不超过节点数的 3 倍。
- 主分片，副本和节点最大数之间数量，我们分配的时候可以参考以下关系：`节点数<=主分片数*（副本数+1）`

### 5.2.2 推迟分片分配
对于节点瞬时中断的问题，默认情况，集群会等待一分钟来查看节点是否会重新加入，如果这个节点在此期间重新加入，重新加入的节点会保持其现有的分片数据，不会触发新的分片分配。这样就可以减少 ES 在自动再平衡可用分片时所带来的极大开销。
通过修改参数 `delayed_timeout` ，可以延长再均衡的时间，可以全局设置也可以在索引级别进行修改：
```
PUT /_all/_settings 
{
 "settings": {
 "index.unassigned.node_left.delayed_timeout": "5m" 
 } 
}
```

## 5.3 路由选择
当我们查询文档的时候，Elasticsearch 如何知道一个文档应该存放到哪个分片中呢？它其实是通过下面这个公式来计算出来：
`shard = hash(routing) % number_of_primary_shards`
routing 默认值是文档的 id，也可以采用自定义值，比如用户 id。

**不带 routing 查询：**在查询的时候因为不知道要查询的数据具体在哪个分片上，所以整个过程分为 2 个步骤：
- 分发：请求到达协调节点后，协调节点将查询请求分发到每个分片上。
- 聚合: 协调节点搜集到每个分片上查询结果，在将查询的结果进行排序，之后给用户返回结果。

**带 routing 查询：**查询的时候，可以直接根据 routing 信息定位到某个分配查询，不需要查询所有的分配，经过协调节点排序。

对于上面自定义的用户查询，如果 routing 设置为 userid 的话，就可以直接查询出数据来，效率提升很多。


## 5.4 写入速度优化
ES 的默认配置，是综合了数据可靠性、写入速度、搜索实时性等因素。实际使用时，我们需要根据公司要求，进行偏向性的优化。
针对于搜索性能要求不高，但是对写入要求较高的场景，我们需要尽可能的选择恰当写优化策略。综合来说，可以考虑以下几个方面来提升写索引的性能：
- 加大 Translog Flush ，目的是降低 Iops、Writeblock。
- 增加 Index Refresh 间隔，目的是减少 Segment Merge 的次数。
- 调整 Bulk 线程池和队列。
- 优化节点间的任务分布。
- 优化 Lucene 层的索引建立，目的是降低 CPU 及 IO。

### 5.4.1 批量数据提交
ES 提供了 Bulk API 支持批量操作，当我们有大量的写任务时，可以使用 Bulk 来进行批量写入。
通用的策略如下：Bulk 默认设置批量提交的数据量不能超过 100M。数据条数一般是根据文档的大小和服务器性能而定的，但是单次批处理的数据大小应从 5MB～15MB 逐渐增加，当性能没有提升时，把这个数据量作为最大值。

### 5.4.2 优化存储设备
ES 是一种密集使用磁盘的应用，在段合并的时候会频繁操作磁盘，所以对磁盘要求较高，当磁盘速度提升之后，集群的整体性能会大幅度提高。

### 5.4.3 合理使用合并
Lucene 以段的形式存储数据。当有新的数据写入索引时，Lucene 就会自动创建一个新的段。
随着数据量的变化，段的数量会越来越多，消耗的多文件句柄数及 CPU 就越多，查询效率就会下降。
由于 Lucene 段合并的计算量庞大，会消耗大量的 I/O，所以 ES 默认采用较保守的策略，让后台定期进行段合并。

### 5.4.4 减少 Refresh 的次数
Lucene 在新增数据时，采用了延迟写入的策略，默认情况下索引的 refresh_interval 为1 秒。
Lucene 将待写入的数据先写到内存中，超过 1 秒（默认）时就会触发一次 Refresh，然后 Refresh 会把内存中的的数据刷新到操作系统的文件缓存系统中。
如果我们对搜索的实效性要求不高，可以将 Refresh 周期延长，例如 30 秒。
这样还可以有效地减少段刷新次数，但这同时意味着需要消耗更多的 Heap 内存。

### 5.5.5 加大 Flush 设置
Flush 的主要目的是把文件缓存系统中的段持久化到硬盘，当 Translog 的数据量达到512MB 或者 30 分钟时，会触发一次 Flush。
index.translog.flush_threshold_size 参数的默认值是 512MB，我们进行修改。
增加参数值意味着文件缓存系统中可能需要存储更多的数据，所以我们需要为操作系统的文件缓存系统留下足够的空间。

### 5.5.6 减少副本的数量
ES 为了保证集群的可用性，提供了 Replicas（副本）支持，然而每个副本也会执行分析、索引及可能的合并过程，所以 Replicas 的数量会严重影响写索引的效率。
当写索引时，需要把写入的数据都同步到副本节点，副本节点越多，写索引的效率就越慢。
如 果 我 们 需 要 大 批 量 进 行 写 入 操 作 ， 可 以 先 禁 止 Replica 复 制 ， 设 置index.number_of_replicas: 0 关闭副本。在写入完成后，Replica 修改回正常的状态。


## 5.5 内存设置
ES 默认安装后设置的内存是 1GB，对于任何一个现实业务来说，这个设置都太小了。
如果是通过解压安装的 ES，则在 ES 安装文件中包含一个 jvm.option 文件，添加如下命令来设置 ES 的堆大小，Xms 表示堆的初始大小，Xmx 表示可分配的最大内存，都是 1GB。
确保 Xmx 和 Xms 的大小是相同的，其目的是为了能够在 Java 垃圾回收机制清理完堆区后不需要重新分隔计算堆区的大小而浪费资源，可以减轻伸缩堆大小带来的压力。
假设你有一个 64G 内存的机器，按照正常思维思考，你可能会认为把 64G 内存都给ES 比较好，但现实是这样吗， 越大越好？虽然内存对 ES 来说是非常重要的，但是答案是否定的！

**因为 ES 堆内存的分配需要满足以下两个原则：**
- 不要超过物理内存的 50%：Lucene 的设计目的是把底层 OS 里的数据缓存到内存中。
Lucene 的段是分别存储到单个文件中的，这些文件都是不会变化的，所以很利于缓存，同时操作系统也会把这些段文件缓存起来，以便更快的访问。
如果我们设置的堆内存过大，Lucene 可用的内存将会减少，就会严重影响降低 Lucene 的全文本查询性能。

- 堆内存的大小最好不要超过 32GB：在 Java 中，所有对象都分配在堆上，然后有一个 Klass Pointer 指针指向它的类元数据。
这个指针在 64 位的操作系统上为 64 位，64 位的操作系统可以使用更多的内存（2^64）。在 32 位的系统上为 32 位，32 位的操作系统的最大寻址空间为 4GB（2^32）。
但是 64 位的指针意味着更大的浪费，因为你的指针本身大了。浪费内存不算，更糟糕的是，更大的指针在主内存和缓存器（例如 LLC, L1 等）之间移动数据的时候，会占用更多的带宽。
最终我们都会采用 31 G 设置
-Xms 31g
-Xmx 31g
假设你有个机器有 128 GB 的内存，你可以创建两个节点，每个节点内存分配不超过 32 GB。 也就是说不超过 64 GB 内存给 ES 的堆内存，剩下的超过 64 GB 的内存给 Lucene。

## 5.6 重要配置
| 参数名                             | 参数值        | 说明                                                         |
| ---------------------------------- | ------------- | ------------------------------------------------------------ |
| cluster.name                       | elasticsearch | 配置 ES 的集群名称，默认值是 ES，建议改成与所存数据相关的名称，ES 会自动发现在同一网段下的 集群名称相同的节点。 |
| node.name                          | node-1        | 集群中的节点名，在同一个集群中不能重复。节点的名称一旦设置，就不能再改变了。当然，也可以设 置 成 服 务 器 的 主 机 名 称 ， 例 如node.name:${HOSTNAME}。 |
| node.master                        | true          | 指定该节点是否有资格被选举成为 Master 节点，默认是 True，如果被设置为 True，则只是有资格成为Master 节点，具体能否成为 Master 节点，需要通过选举产生。 |
| node.data                          | true          | 指定该节点是否存储索引数据，默认为 True。数据的增、删、改、查都是在 Data 节点完成的。 |
| index.number_of_shards             | 1             | 设置都索引分片个数，默认是 1 片。也可以在创建索引时设置该值，具体设置为多大都值要根据数据量的大小来定。如果数据量不大，则设置成 1 时效率最高 |
| index.number_of_replicas           | 1             | 设置默认的索引副本个数，默认为 1 个。副本数越多，集群的可用性越好，但是写索引时需要同步的数据越多。 |
| transport.tcp.compress             | true          | 设置在节点间传输数据时是否压缩，默认为 False，不压缩         |
| discovery.zen.minimum_master_nodes | 1             | 设置在选举 Master 节点时需要参与的最少的候选主节点数，默认为 1。如果使用默认值，则当网络不稳定时有可能会出现脑裂。<br />合理的数值为 (master_eligible_nodes/2)+1 ，其中master_eligible_nodes 表示集群中的候选主节点数 |
| discovery.zen.ping.timeout         | 3s            | 设置在集群中自动发现其他节点时 Ping 连接的超时时间，默认为 3 秒。<br />在较差的网络环境下需要设置得大一点，防止因误判该节点的存活状态而导致分片的转移。 |



<br>
# 六、ES异常记录
## 5.1 circuit_breaking_exception异常
**①查询时报异常**
```{
    "error": {
        "root_cause": [
            {
                "type": "circuit_breaking_exception",
                "reason": "[parent] Data too large, data for [<http_request>] would be [257665614/245.7mb], which is larger than the limit of [255013683/243.1mb], real usage: [257665384/245.7mb], new bytes reserved: [230/230b], usages [request=0/0b, fielddata=0/0b, in_flight_requests=230/230b, accounting=3516/3.4kb]",
                "bytes_wanted": 257665614,
                "bytes_limit": 255013683,
                "durability": "PERMANENT"
            }
        ],
        "type": "circuit_breaking_exception",
        "reason": "[parent] Data too large, data for [<http_request>] would be [257665614/245.7mb], which is larger than the limit of [255013683/243.1mb], real usage: [257665384/245.7mb], new bytes reserved: [230/230b], usages [request=0/0b, fielddata=0/0b, in_flight_requests=230/230b, accounting=3516/3.4kb]",
        "bytes_wanted": 257665614,
        "bytes_limit": 255013683,
        "durability": "PERMANENT"
    },
    "status": 429
}
```

**原因：**
ES为了防止缓存使用的内存容量超过限制进行的保护措施。ES默认的缓存设置让缓存区只进不出引起的；

>ES在查询时，会将索引数据缓存在内存（JVM）中： 
驱逐线 和 断路器。当缓存数据到达驱逐线时，会自动驱逐掉部分数据，把缓存保持在安全的范围内。当用户准备执行某个查询操作时，断路器就起作用了，缓存数据+当前查询需要缓存的数据量到达断路器限制时，会返回Data too large错误，阻止用户进行这个查询操作。ES把缓存数据分成两类，FieldData和其他数据，我们接下来详细看FieldData，它是造成我们这次异常的“元凶”。
ES配置中提到的FieldData指的是字段数据。当排序（sort），统计（aggs）时，ES把涉及到的字段数据全部读取到内存（JVM Heap）中进行操作。相当于进行了数据缓存，提升查询效率。


**解决：**
```
# 控制fielddata允许内存大小，达到HEAP 20% 自动清理旧cache。不配置就不回收。
indices.fielddata.cache.size: 20%
indices.breaker.total.use_real_memory: false
# fielddata 断路器限制fileddata的堆大小上限，默认设置堆的 60%
indices.breaker.fielddata.limit: 40%
# request 断路器估算需要完成其他请求部分的结构大小，例如创建一个聚合桶，默认限制是堆内存的 40%。
indices.breaker.request.limit: 40%
# total 揉合 request 和 fielddata 断路器保证两者组合起来不会使用超过堆内存的 70%(默认值)。
indices.breaker.total.limit: 95%
```

<br>
# 七、面试题
## 7.1 为什么要使用 Elasticsearch?
系统中的数据，随着业务的发展，时间的推移，将会非常多，而业务中往往采用模糊查询进行数据的搜索，而模糊查询会导致查询引擎放弃索引，导致系统查询数据时都是全表扫描，在百万级别的数据库中，查询效率是非常低下的，而我们使用 ES 做一个全文索引，将经常查询的系统功能的某些字段，比如说电商系统的商品表中商品名，描述、价格还有 id 这些字段我们放入 ES 索引库里，可以提高查询速度。

## 7.2 Elasticsearch 的 master 选举流程？
- Elasticsearch 的选主是 ZenDiscovery 模块负责的，主要包含 Ping（节点之间通过这个 RPC 来发现彼此）和 Unicast（单播模块包含一个主机列表以控制哪些节点需要 ping 通）这两部分。
- 对所有可以成为 master 的节点（node.master: true）根据 nodeId 字典排序，每次选举每个节点都把自己所知道节点排一次序，然后选出第一个（第 0 位）节点，暂且认为它是 master 节点。
- 如果对某个节点的投票数达到一定的值（可以成为 master 节点数 n/2+1）并且该节点自己也选举自己，那这个节点就是 master。否则重新选举一直到满足上述条件。
- master 节点的职责主要包括集群、节点和索引的管理，不负责文档级别的管理；data 节点可以关闭 http功能。

## 7.3 Elasticsearch 集群脑裂问题？
**“脑裂”问题可能的成因:**
- 网络问题：集群间的网络延迟导致一些节点访问不到 master，认为 master 挂掉了从而选举出新的master，并对 master 上的分片和副本标红，分配新的主分片。
- 节点负载：主节点的角色既为 master 又为 data，访问量较大时可能会导致 ES 停止响应造成大面积延迟，此时其他节点得不到主节点的响应认为主节点挂掉了，会重新选取主节点。
- 内存回收：data 节点上的 ES 进程占用的内存较大，引发 JVM 的大规模内存回收，造成 ES 进程失去响应。

**脑裂问题解决方案：**
- 减少误判：discovery.zen.ping_timeout 节点状态的响应时间，默认为 3s，可以适当调大，如果 master在该响应时间的范围内没有做出响应应答，判断该节点已经挂掉了。调大参数（如 6s，discovery.zen.ping_timeout:6），可适当减少误判。
- 选举触发: discovery.zen.minimum_master_nodes:1 
该参数是用于控制选举行为发生的最小集群主节点数量。当备选主节点的个数大于等于该参数的值，且备选主节点中有该参数个节点认为主节点挂了，进行选举。官方建议为（n/2）+1，n 为主节点个数（即有资格成为主节点的节点个数）
- 角色分离：即 master 节点与 data 节点分离，限制角色
主节点配置为：node.master: true node.data: false
从节点配置为：node.master: false node.data: true


## 7.4 Elasticsearch 索引文档的流程？
![image.png](Elasticsearch-基础.assets