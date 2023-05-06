---
title: Compass-2-1-数仓梳理
categories:
- 大数据火星人业务
---
# 一、梳理

## 1.1 表梳理

事务型事实表(增量分区)：订单明细事实表，退单表
周期型快照事实表(全量分区)：
累积型事实表(增量变化分区)：订单事实表

维度表：时间表，地区表，产品表，渠道表

全量表：产品维度表，渠道维度表
增量表：订单明细事实表
增量变化表：订单维度表
特殊表：时间维度表，地区维度表
拉链表：用户维度表

<br>
## 1.2 业务总线矩阵

|                | 时间 | 用户 | 门店 | 渠道 | 地址 | 度量值                          |
| -------------- | ---- | ---- | ---- | ---- | ---- | ------------------------------- |
| 电商订单       | √    | √    | √    | √    | √    | 运费/优惠金额/原始金额/最终金额 |
| 电商订单详情   | √    | √    | √    | √    | √    | 件数/优惠金额/原始金额/最终金额 |
| 支付           | √    | √    | √    | √    | √    | 支付金额                        |
| 发货           | √    | √    | √    | √    | √    | 件数                            |
| 退单           | √    | √    | √    | √    | √    | 退单件数/金额                   |
| 非电商订单     | √    | √    | √    | √    | √    | 运费/优惠金额/原始金额/最终金额 |
| 非电商订单详情 | √    | √    | √    | √    | √    | 件数/优惠金额/原始金额/最终金额 |


<br>

## 2.2 分层表
ODS（operation data store）：存放原始数据。保持数据原貌不变；创建分区表，防止后续的全表扫描；时间分区，采用LZO压缩，需要建索引，指定输入输出格式；创建外部表；
DWD（data warehouse detail）：结构粒度与ODS层保持一致，对ODS层数据进行清洗（去除无效数据、脏数据，数据脱敏，维度退化，数据转换等）。ETL数据清洗，用hive sql、MR、Python、Kettle、SparkSQL；时间分区，采用LZO压缩(parquet支持切片)，不需要建索引，采用parquet格式存储；创建外部表；
DWS（data warehouse service）：在DWD基础上，按天进行轻度汇总。时间分区，采用parquet格式存储；创建外部表；
DWT（data warehouse topic）：在DWS基础上，按主题进行汇总。采用parquet格式存储；创建外部表，时间分区；
ADS（Application Data Store）：为统计报表提供数据。明确字段分割符，与sqoop对应；创建外部表，时间分区。


### 2.2.1 ods层
edb，adh，wms和u8的原始表。
- ods_edb
问题：
①不管根据订单时间、获取时间或者更新时间去取edb的数据，都有丢数据的风险。比如昨日支付的订单在今天凌晨00:01时更新了，导致拉取不到这条订单。这样就会导致如根据更新时间计算销量的数据有误差。
②存在edb去平台取数据和我们取edb取数据的双重延迟，如23:59支付的订单，edb获取的时间为第二天，导致没有获取到该数据。但是电商在早上十点获取了该数据。
解决：
①该条订单在以后最终会被获取到，但是正常我们认为该订单已经计算过销量了。所以可以比对该订单是否已经存在支付明细表中，如果存在表示该订单已经计算；不存在则需要插入到支付时间对应的分区中并重新计算该分区的销量数据，包括周月年统计数据。
②第三方平台的问题，无法解决，造成丢数据。

### 2.2.2 dim层
产品维度表，门店维度表，时间维度表，地区维度表

### 2.2.3 dwd层
该层需要对脏数据进行过滤，如`订单数据进行去重，edb_order订单的渠道需要能匹配上dim_channel表，订单的产品需要能匹配上dim_product表`，`发货数据能匹配上对应的订单，发货产品能匹配上产品表`。避免在dws层时统计的多张宽表数据矛盾，这时进行多表关联去除匹配不上的数据就会产生每张宽表都需要这个操作从而造成代码冗余的情况发生。

**edb**
- 订单信息表(累积型事实表)
问题：
①作为累积型事实表，edb的数据没有明确的订单关闭字段(finish_time或platform_status不是很准确)。
②正常ods层订单表中一个分区保存的是增量或修改的数据，但是数据源只支持一个分区存储最近n个月的数据
③执行历史某一天的数据，因为该天数据中finish_time为null的数据插入到9999-99-99分区总，但是该数据可能在之后的某天已经结束并插入到finish_time日期的分区中。导致9999-99-99分区和finish_time分区中同时存在该数据。
解决思路：
①只能将没有结束字段的记录一直放到9999-99-99分区；或规定4个月后默认关闭，插入到month_add(tid_time, 4)分区(如果后续有该订单的记录，可能会导致数据重复)；
②既然一个分区存储n个月的数据，那么只能拿这n个月的数据去和9999-99-99分区数据full out join。需要注意过滤条件为 finish_time is null 或 finish_time = $do_date，因为finish_time 不为当日的数据必然已经导入到了之前的分区，finish_time is null 的数据可以更新9999-99-99数据的状态。(注意：因为只拿了tid_time内n个月的数据，所以可能有部分订单的结束数据的tid_time在n个月之前就读取不到了，导致这部分订单一直结束不了)
③历史某一天的数据重新运行后，后面的日期都要按日期顺序重新运行一遍。

>目前取数逻辑是根据最近30天的get_time进行取值(get_time目前的理解就是edb去各平台取数的时间，如果数据不存在或变化，将数据插入或更新，get_time为取数时间，如果数据没变化，则不变)。所以取get_time为当天的数据就是当天新增或修改的数据。

- 订单详情表(事务型事实表)：直接根据下单时间将子订单插入到对应分区中即可。
问题：
①因为是从第三方拿的数据，数据存在延迟。如27日的订单28日才到，但是28日只处理28日创建的订单，导致迟到数据丢失。
②与正常的从业务的订单详情表中获取增量子订单的情况不同，因为这里子订单是从订单中拆出来的，所以存在重复，需要去重。
解决思路：
①和②解决：取当日tmp表的distinct tid_time，从订单详情表中取出这些分区的数据 full outer join 当日tmp的数据然后动态插入到订单详情表中。

- 订单支付表(事务型事实表)：正常是要创建累积型事实表(有创建时间/确认回调时间等)，因为订单表中有全部时间，所以这里直接使用事务型事实表。
问题：
①京东自营订单没有pay_time，只有pay_status；
②部分订单只有在付尾款时才有记录，可能是10天前的订单，进行付了尾款才拿到这条记录；
解决思路：
①判断当日的所有已支付订单是否是历史支付订单，如果不是历史已支付订单(需要看电商判断逻辑)，则插入到当日的支付表分区；
②看电商的统计逻辑，如果是付尾款时才统计金额，那么就按常规的来做即可。

- 订单退单表(事务型事实表)：正常是要创建累积型事实表(有创建时间/同意退单时间等)，因为订单表中有全部时间，且结构类似订单数据，所以这里直接使用事务型事实表。

- 订单修正表：因为订单延迟拆分和套餐拆分等问题，订单的返利金额和订单实际金额会发生变化(多次变化)，所以需要存一张表用于记录这些变化数据，然后进行统计，最后在ads层进行汇总，对历史数据进行修正。

### 2.2.4 dws层
**dws层从 原子指标 统计出 派生指标：**
**原子指标**基于某一业务过程的度量值，是业务定义中不可再拆解的指标，原子指标的核心功能就是对指标的聚合逻辑进行了定义。我们可以得出结论，原子指标包含三要素，分别是**业务过程、度量值和聚合逻辑**。
公式为：原子指标=业务过程+度量值+聚合逻辑
例：订单总数=下单+"1"+count()

**派生指标**基于原子指标，可以通过原子指标直接计算得到。
公式为：派生指标=原子指标+统计周期+业务限定+统计粒度
例：最近一天各渠道各产品订单总额=订单总额+最近一天(where限定统计时间范围)+指定的品类(where限定统计范围)+渠道(group by 定义统计粒度)

`dws层轻度聚合宽表构建思路：将星座模型聚合成一张宽表，然后对所有的维度进行grouping sets聚合，统计出各个维度下的度量值的日统计值。`

- edb支付订单数据[商品][渠道]维度按日聚合统计宽表：主要就是对集群进行调优，合理增大内存和cpu值。使用Grouping Sets进行多维度聚合，需要带GROUPING__ID字段(注意初始化脚本中会多聚合一个ddate字段，会造成GROUPING__ID不同)。需要注意的是，对没有匹配上维度表的脏数据进行过滤，如匹配渠道表时没匹配上或有字段为null，那么group by多个渠道层级的结果是一样的，所以出现了数据重复。

- u8发货数据[地域][快递公司]维度按日聚合统计宽表：


### 2.2.5 dwt层
**dwt层从派生指标 统计出 衍生指标：**
衍生指标是在一个或多个派生指标的基础上，通过各种逻辑运算复合而成的。例如比率、比例等类型的指标。衍生指标也会对应实际的统计需求。
公式为：衍生指标=原子指标+统计周期+业务限定+统计粒度
例：最近30日各渠道退单率 = (最近30日各渠道退单次数=退单总次数+最近30日+ +渠道) / (最近30日各渠道下单次数=下单总次数+最近30日+ +渠道)

`dwt层主题聚合宽表构建思路：在dws层轻度聚合宽表的基础上，对派生指标进行计算并维护到主题宽表中，包括周月年统计、同比环比统计等。`

- edb支付订单数据渠道维度主题宽表：将日、周、月、年等度量值都维护到这张宽表中，同时计算衍生数据，如同比环比。
问题：
①需要求日月年的同比环比，如何简化逻辑。
②历史数据初始化脚本如何求日月年的同比环比。
③表中的日周月年数据是每条分开的，如何将这些数据汇总为一条记录。
解决思路：
①取到今天的数据，然后将日月年同比的分区数据 group by 产品,渠道 后拼接为与今天的数据结构一样的数据，然后通过开窗函数 partitioned by 产品,渠道 后取上一条数据与本条数据计算同比。环比计算方式相同。
②先计算历史数据的日月年统计，为每条记录添加日、周、月、年的字段，然后通过grouping sets聚合字段 产品,渠道,日,周,月,年 得到日周月年的统计值。然后添加一个字段用于存储该条记录的同比日期，然后通过 [表left join自己 on 分区=同比日期] 获取同比日期的度量值，然后计算同比。环比计算方式同理。
③通过 group by 维度字段，通过collect_list将所有记录汇总，然后通过str_to_map将每条记录转换为map(key为数据的时间类型,value为当日相同维度和时间下的不同度量值的汇总)，然后通过key将value拆到对应的字段中。示例如下:
```
select split(data['year_month_day'], ',')[0] as sale_num_mom_day,
       split(data['year_month_day'], ',')[1] as sale_amount_mom_day,
       split(data['year_month_day'], ',')[2] as send_num_mom_day,
       split(data['year_week'], ',')[0]      as sale_num_mom_week,
       split(data['year_week'], ',')[1]      as sale_amount_mom_week,
       split(data['year_week'], ',')[2]      as send_num_mom_week,
       split(data['year_month'], ',')[0]     as sale_num_mom_month,
       split(data['year_month'], ',')[1]     as sale_amount_mom_month,
       split(data['year_month'], ',')[2]     as send_num_mom_month,
       split(data['year'], ',')[0]           as sale_num_mom_year,
       split(data['year'], ',')[1]           as sale_amount_mom_year,
       split(data['year'], ',')[2]           as send_num_mom_year
from (
         select str_to_map(concat_ws('-', collect_list(
                 concat(case
                            when year_month_day is not null
                                then 'year_month_day'
                            when year_week is not null
                                then 'year_week'
                            when year_month is not null
                                then 'year_month'
                            when year is not null then 'year'
                            end, '=', sale_num_mom, ',', sale_amount_mom, ',', send_num_mom
                     )
             )
                               ), '-', '=') as data
         from (select null      as year_month_day,
                      '2021-12' as year_week,
                      null      as year_month,
                      null      as year,
                      1.1          sale_num_mom,
                      2.2          sale_amount_mom,
                      3.3          send_num_mom
               UNION ALL
               select null      as year_month_day,
                      null      as year_week,
                      '2021-12' as year_month,
                      null      as year,
                      0.11         sale_num_mom,
                      0.22         sale_amount_mom,
                      0.33         send_num_mom
              ) tmp
     ) tmp;
```
>需要注意的是，concat中有一个为null，则结果为null，所以可以通过nvl将null值替换为空串，当空串插入到decimal(20,4)格式的字段中时又会转换为null。

### 2.2.6 ads层

- edb的BI展示表
问题：
①因为日周月年在一条记录上，而ads层BI表日周月年分别为一条记录，如何只读一次dwt层记录获取4条ads层需要的日周月年记录。
②ads层不分区，如何保证重跑某一天的数据不会与历史数据产生重复。
解决思路：
①将日周月年相关字段分别放入4个map中，然后创建array(map(),map(),map(),map())，通过lateral view explode(array) 炸裂为4行，最后提取每个map中的数据到对应的字段中即可。
②原来使用 原始数据full outer join新数据 来覆盖掉过期数据，但是还是有脏数据存在的可能性(如匹配不上的过期数据就会一直存在)；现在的方法是，从ads表中读取数据时过滤掉该天的数据，然后UNION ALL新计算的该天的数据，最后OVERWRITE 到 ads表中。

### 2.2.7 datax到mysql（业务数据通过datax导入hdfs同理）
**问题一：因为azkaban无法对每个flow指定执行的节点，解决方案如下：**
- 方法一就将datax的任务单独拆出来，缺点是不好关联两个项目的任务，增加了复杂性。
- 方法二在脚本中远程执行datax任务，可以选择一个datax节点发送，复杂点可以设置多个datax节点随机选择并设置故障转移。

**问题二：合并test分支到prod分支时，需要注意如下：**
1. 同步的mysql地址不能被test分支的环境修改；
2. Azkaban的脚本拉取分支需要区分test和prod分支。
为了解决第一个痛点，可以在shell脚本中将mysql相关参数设置为占位符，在Azkaban任务脚本中进行传参。

<br>
#### 需求1：sku层级交易统计
| 统计周期 | 统计粒度 | 指标 | 说明 |
| --- | --- | --- | --- |
| 本周/本月/本年 | sku/渠道 | 订单数 | 略 |
| 本周/本月/本年 | sku/渠道 | 订单金额 | 略 |
| 本周/本月/本年 | sku/渠道 | 退单数 | 略 |
| 本周/本月/本年 | sku/渠道 | 退单金额 | 略 |

#### 需求2：型号层级交易统计
| 统计周期 | 统计粒度 | 指标 | 说明 |
| --- | --- | --- | --- |
| 本周/本月/本年 | 型号/渠道 | 订单数 | 略 |
| 本周/本月/本年 | 型号/渠道 | 订单金额 | 略 |
| 本周/本月/本年 | 型号/渠道 | 退单数 | 略 |
| 本周/本月/本年 | 型号/渠道 | 退单金额 | 略 |

#### 需求3：系列层级交易统计
| 统计周期 | 统计粒度 | 指标 | 说明 |
| --- | --- | --- | --- |
| 本周/本月/本年 | 系列/渠道 | 订单数 | 略 |
| 本周/本月/本年 | 系列/渠道 | 订单金额 | 略 |
| 本周/本月/本年 | 系列/渠道 | 退单数 | 略 |
| 本周/本月/本年 | 系列/渠道 | 退单金额 | 略 |

#### 需求4：大类层级交易统计
| 统计周期 | 统计粒度 | 指标 | 说明 |
| --- | --- | --- | --- |
| 本周/本月/本年 | 大类/渠道 | 订单数 | 略 |
| 本周/本月/本年 | 大类/渠道 | 订单金额 | 略 |
| 本周/本月/本年 | 大类/渠道 | 退单数 | 略 |
| 本周/本月/本年 | 大类/渠道 | 退单金额 | 略 |



<br>
```
INSERT OVERWRITE TABLE compass_dwd.dwd_edb_order_tmp PARTITION (ds='$do_date')
SELECT get_json_object(line, '$.order_totalfee'),
       get_json_object(line, '$.exception'),
       get_json_object(line, '$.payment_received_time'),
       get_json_object(line, '$.is_except'),
       get_json_object(line, '$.Sorting_code'),
       get_json_object(line, '$.buyer_name'),
       get_json_object(line, '$.discount'),
       get_json_object(line, '$.flag_color'),
       get_json_object(line, '$.express_no'),
       get_json_object(line, '$.type'),
       get_json_object(line, '$.net_weight_freight'),
       get_json_object(line, '$.file_operator'),
       get_json_object(line, '$.out_tid'),
       get_json_object(line, '$.province'),
       get_json_object(line, '$.cod_settlement_vouchernumber'),
       get_json_object(line, '$.good_receive_time'),
       get_json_object(line, '$.weigh_operator'),
       get_json_object(line, '$.book_delivery_time'),
       get_json_object(line, '$.real_pay_freight'),
       get_json_object(line, '$.three_codes'),
       get_json_object(line, '$.express_coding'),
       get_json_object(line, '$.is_print'),
       get_json_object(line, '$.sku'),
       get_json_object(line, '$.cod_fee'),
       get_json_object(line, '$.transaction_id'),
       get_json_object(line, '$.cancel_time'),
       get_json_object(line, '$.buyer_message'),
       get_json_object(line, '$.destCode'),
       get_json_object(line, '$.printer'),
       get_json_object(line, '$.product_num'),
       get_json_object(line, '$.packager'),
       get_json_object(line, '$.pro_totalfee'),
       get_json_object(line, '$.is_pre_delivery_notice'),
       get_json_object(line, '$.sending_type'),
       get_json_object(line, '$.phone'),
       get_json_object(line, '$.distributor_id'),
       get_json_object(line, '$.promotion_info'),
       get_json_object(line, '$.alipay_id'),
       get_json_object(line, '$.distributer'),
       get_json_object(line, '$.file_time'),
       get_json_object(line, '$.point_pay'),
       get_json_object(line, '$.distributor_mark'),
       get_json_object(line, '$.status'),
       get_json_object(line, '$.gross_weight_freight'),
       get_json_object(line, '$.review_orders_operator'),
       get_json_object(line, '$.city'),
       get_json_object(line, '$.delivery_name'),
       get_json_object(line, '$.related_orders_type'),
       get_json_object(line, '$.city_code'),
       get_json_object(line, '$.inspect_time'),
       get_json_object(line, '$.order_process_time'),
       get_json_object(line, '$.distribut_time'),
       get_json_object(line, '$.is_cod'),
       get_json_object(line, '$.modity_time'),
       get_json_object(line, '$.discount_fee'),
       get_json_object(line, '$.message_time'),
       get_json_object(line, '$.invoice_content'),
       get_json_object(line, '$.receiver_name'),
       get_json_object(line, '$.print_time'),
       get_json_object(line, '$.taobao_delivery_order_status'),
       get_json_object(line, '$.currency'),
       get_json_object(line, '$.system_remarks'),
       get_json_object(line, '$.order_channel'),
       get_json_object(line, '$.tid_net_weight'),
       get_json_object(line, '$.superior_point'),
       get_json_object(line, '$.email'),
       get_json_object(line, '$.invoice_situation'),
       get_json_object(line, '$.pack_time'),
       get_json_object(line, '$.cancel_operator'),
       get_json_object(line, '$.address'),
       get_json_object(line, '$.deliver_centre'),
       get_json_object(line, '$.enable_inte_sto_time'),
       get_json_object(line, '$.taobao_delivery_status'),
       get_json_object(line, '$.abnormal_status'),
       get_json_object(line, '$.pay_mothed'),
       get_json_object(line, '$.receiver_mobile'),
       get_json_object(line, '$.item_num'),
       get_json_object(line, '$.service_remarks'),
       get_json_object(line, '$.express_col_fee'),
       get_json_object(line, '$.single_num'),
       get_json_object(line, '$.is_flag'),
       get_json_object(line, '$.customer_id'),
       get_json_object(line, '$.platform_status'),
       get_json_object(line, '$.updatetime'),
       get_json_object(line, '$.is_inspection'),
       get_json_object(line, '$.delivery_status'),
       get_json_object(line, '$.plat_send_status'),
       get_json_object(line, '$.ts'),
       get_json_object(line, '$.provinc_code'),
       get_json_object(line, '$.other_remarks'),
       get_json_object(line, '$.enable_inte_delivery_time'),
       get_json_object(line, '$.adv_distributer'),
       get_json_object(line, '$.breaker'),
       get_json_object(line, '$.cod_service_fee'),
       get_json_object(line, '$.delivery_operator'),
       get_json_object(line, '$.out_promotion_detail'),
       get_json_object(line, '$.express'),
       get_json_object(line, '$.delivery_time'),
       get_json_object(line, '$.buyer_id'),
       get_json_object(line, '$.tid'),
       get_json_object(line, '$.invoice_name'),
       get_json_object(line, '$.locker'),
       get_json_object(line, '$.last_refund_time'),
       get_json_object(line, '$.dt'),
       get_json_object(line, '$.express_code'),
       get_json_object(line, '$.post'),
       get_json_object(line, '$.finance_review_operator'),
       get_json_object(line, '$.order_creater'),
       get_json_object(line, '$.total_num'),
       get_json_object(line, '$.cost_point'),
       get_json_object(line, '$.originCode'),
       get_json_object(line, '$.adv_distribut_time'),
       get_json_object(line, '$.gross_weight'),
       get_json_object(line, '$.commission_fee'),
       get_json_object(line, '$.big_marker'),
       get_json_object(line, '$.resultNum'),
       get_json_object(line, '$.taobao_delivery_method'),
       get_json_object(line, '$.area_code'),
       get_json_object(line, '$.alipay_status'),
       get_json_object(line, '$.receive_time'),
       get_json_object(line, '$.deliver_station'),
       get_json_object(line, '$.shop_name'),
       get_json_object(line, '$.import_mark'),
       get_json_object(line, '$.revoke_cancel_er'),
       get_json_object(line, '$.is_stock'),
       get_json_object(line, '$.advance_printer'),
       get_json_object(line, '$.finish_time'),
       get_json_object(line, '$.order_disfee'),
       get_json_object(line, '$.pay_time'),
       get_json_object(line, '$.review_orders_time'),
       get_json_object(line, '$.platform_preferential'),
       get_json_object(line, '$.business_man'),
       get_json_object(line, '$.promotion_plan'),
       get_json_object(line, '$.external_point'),
       get_json_object(line, '$.payment_received_operator'),
       get_json_object(line, '$.district'),
       get_json_object(line, '$.merchant_disfee'),
       get_json_object(line, '$.weigh_time'),
       get_json_object(line, '$.shopid'),
       get_json_object(line, '$.last_returned_time'),
       get_json_object(line, '$.break_time'),
       get_json_object(line, '$.inner_lable'),
       get_json_object(line, '$.break_explain'),
       get_json_object(line, '$.plat_type'),
       get_json_object(line, '$.invoice_title'),
       get_json_object(line, '$.get_time'),
       get_json_object(line, '$.channel_disfee'),
       get_json_object(line, '$.revoke_cancel_time'),
       get_json_object(line, '$.online_express'),
       get_json_object(line, '$.point'),
       get_json_object(line, '$.total_weight'),
       get_json_object(line, '$.royalty_fee'),
       get_json_object(line, '$.maxrowver'),
       get_json_object(line, '$.pay_status'),
       get_json_object(line, '$.is_break'),
       get_json_object(line, '$.real_income_freight'),
       get_json_object(line, '$.rate'),
       get_json_object(line, '$.storage_id'),
       get_json_object(line, '$.distributor_level'),
       get_json_object(line, '$.invoice_fee'),
       get_json_object(line, '$.freight_explain'),
       get_json_object(line, '$.invoice_type'),
       get_json_object(line, '$.finance_review_time'),
       get_json_object(line, '$.inspecter'),
       get_json_object(line, '$.reference_price_paid'),
       get_json_object(line, '$.other_fee'),
       get_json_object(line, '$.related_orders'),
       get_json_object(line, '$.out_pay_tid'),
       get_json_object(line, '$.refund_totalfee'),
       get_json_object(line, '$.is_bill'),
       get_json_object(line, '$.is_new_customer'),
       get_json_object(line, '$.message'),
       get_json_object(line, '$.serial_num'),
       get_json_object(line, '$.jd_delivery_time'),
       get_json_object(line, '$.lock_time'),
       get_json_object(line, '$.tid_time'),
       get_json_object(line, '$.order_from'),
       get_json_object(line, '$.is_adv_sale'),
       get_json_object(line, '$.merge_status'),
       get_json_object(line, '$.is_promotion'),
       get_json_object(line, '$.voucher_id'),
       get_json_object(line, '$.book_file_time'),
       get_json_object(line, '$.distributing_centre_name'),
       get_json_object(line, '$.send_site_name'),
       get_json_object(line, '$.verificaty_time'),
       get_json_object(item, '$.original_price'),
       get_json_object(item, '$.item_discountfee'),
       get_json_object(item, '$.sell_price'),
       get_json_object(item, '$.discount_amount'),
       get_json_object(item, '$.timeinventory'),
       get_json_object(item, '$.tid'),
       get_json_object(item, '$.send_num'),
       get_json_object(item, '$.ferght'),
       get_json_object(item, '$.second_barcode'),
       get_json_object(item, '$.out_tid'),
       get_json_object(item, '$.inspection_num'),
       get_json_object(item, '$.barcode'),
       get_json_object(item, '$.stock_situation'),
       get_json_object(item, '$.proexplain'),
       get_json_object(item, '$.book_inventory'),
       get_json_object(item, '$.credit_amount'),
       get_json_object(item, '$.weight'),
       get_json_object(item, '$.seller_remark'),
       get_json_object(item, '$.brand_name'),
       get_json_object(item, '$.plat_discount'),
       get_json_object(item, '$.sncode'),
       get_json_object(item, '$.out_proid'),
       get_json_object(item, '$.refund_num'),
       get_json_object(item, '$.promotion_info'),
       get_json_object(item, '$.shopid'),
       get_json_object(item, '$.product_specification'),
       get_json_object(item, '$.distributer'),
       get_json_object(item, '$.iscombination'),
       get_json_object(item, '$.pro_name'),
       get_json_object(item, '$.sys_price'),
       get_json_object(item, '$.pro_detail_code'),
       get_json_object(item, '$.distribut_time'),
       get_json_object(item, '$.refund_renum'),
       get_json_object(item, '$.isgifts'),
       get_json_object(item, '$.out_prosku'),
       get_json_object(item, '$.gift_num'),
       get_json_object(item, '$.brand_number'),
       get_json_object(item, '$.storage_id'),
       get_json_object(item, '$.combine_barcode'),
       get_json_object(item, '$.buyer_memo'),
       get_json_object(item, '$.store_location'),
       get_json_object(item, '$.cost_price'),
       get_json_object(item, '$.isbook_pro'),
       get_json_object(item, '$.inspection_time'),
       get_json_object(item, '$.MD5_encryption'),
       get_json_object(item, '$.iscancel'),
       get_json_object(item, '$.average_price'),
       get_json_object(item, '$.pro_type'),
       get_json_object(item, '$.specification'),
       get_json_object(item, '$.product_no'),
       get_json_object(item, '$.isscheduled'),
       get_json_object(item, '$.book_storage'),
       get_json_object(item, '$.pro_num'),
       get_json_object(item, '$.sub_tid')
FROM (
         SELECT row_number() over (partition by get_json_object(line, '$.tid') ) row_num,
                line
         FROM hxr_edb.ods_edb_order
         where ds = '$edb_ds'
           and get_json_object(line, '$.tid_item') is not null
           and get_json_object(line, '$.tid') is not null
           and get_json_object(line, '$.tid') <> ''
           and get_json_object(line, '$.status') <> '已作废'
     ) tmp
         lateral view compass_dwd.explode_json_array(get_json_object(tmp.line, '$.tid_item')) table_tmp as item
where row_num = 1;
```

<br>
## 问题记录
### 问题一
- 描述：正式环境和测试环境中的channel_code对应的channel_name不同。
- 原因：因为使用`concat('20'+行号)`作为channel_code，但是取行号时没有进行排序，导致每次执行其行号是不同的，导致每次执行其channel_code和channel_name对应的是随机的
```
select *
from (
         SELECT c1.shop_id      --门店id
              , c1.shop_name    --门店名
              , c1.channel_name --渠道名
              , c2.code as channel_id
              , c1.class_name   --大分类
              , c1.class_id
              , c1.original_code
         FROM (
                  SELECT *
                  FROM compass_dim.dim_shop_channel
              ) c1
                  LEFT JOIN
              (
                  SELECT t1.channel_name, concat('20', row_number() over (partition by t1.code order by t1.channel_name)) code
                  FROM (
                           SELECT channel_name, '1' as code
                           FROM compass_dim.dim_shop_channel
                           group by channel_name
                       ) t1
              ) c2 on c1.channel_name = c2.channel_name
     )tmp
where class_id=2;
```
- 解决：添加排序，修改行号如下  `SELECT t1.channel_name, concat('20', row_number() over (partition by t1.code order by t1.channel_name)) code`
