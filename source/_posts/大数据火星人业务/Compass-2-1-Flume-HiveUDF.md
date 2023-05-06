---
title: Compass-2-1-Flume-HiveUDF
categories:
- 大数据火星人业务
---
# Flume采集数据
**edb_order 订单数据**
```
# agent
a1.sources = r1
a1.channels = c1
a1.sinks = k1

# source
a1.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a1.sources.r1.batchSize = 5000
a1.sources.r1.batchDurationMillis = 2000
a1.sources.r1.kafka.bootstrap.servers = cos-bigdata-test-hadoop-01:9092,cos-bigdata-test-hadoop-02:9092,cos-bigdata-test-hadoop-03:9092
a1.sources.r1.kafka.topics = compass-edb-sales-test
a1.sources.r1.kafka.consumer.group.id = edb_order_consumer

# interceptor
a1.sources.r1.interceptors =  i1 i2
a1.sources.r1.interceptors.i1.type = com.iotmars.interceptor.ETLInterceptor$Builder
a1.sources.r1.interceptors.i2.type = com.iotmars.interceptor.TimeStampInterceptor$Builder

# channels
#a1.channels.c1.type = memory
#a1.channels.c1.capacity = 10000
#a1.channels.c1.transactionCapacity = 10000
#a1.channels.c1.byteCapacityBufferPercentage = 20
#a1.channels.c1.byteCapacity = 800000
a1.channels.c1.type = file 
a1.channels.c1.checkpointDir = /opt/module/flume-1.7.0/checkpoint/edb_order_file_channel2
a1.channels.c1.dataDirs = /opt/module/flume-1.7.0/data/edb_order_file_channel2

# sinks
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /origin_data/compass/edb/edb_order/%Y-%m-%d
a1.sinks.k1.hdfs.filePrefix = edb
a1.sinks.k1.hdfs.batchSize = 100
a1.sinks.k1.hdfs.rollInterval = 1200
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.useLocalTimeStamp = false

# kerberos
a1.sinks.k1.hdfs.kerberosPrincipal = hive@IOTMARS.COM
a1.sinks.k1.hdfs.kerberosKeytab = /etc/security/keytab/hive.keytab

# compress
a1.sinks.k1.hdfs.codeC = lzop
a1.sinks.k1.hdfs.fileType = CompressedStream

# combine
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```




**edb_salesReturn  退单数据**
```
# agent 
a1.sources = r1
a1.channels = c1
a1.sinks = k1

# source
a1.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a1.sources.r1.batchSize = 5000
a1.sources.r1.batchDurationMillis = 2000
a1.sources.r1.kafka.bootstrap.servers = cos-bigdata-test-hadoop-01:9092,cos-bigdata-test-hadoop-02:9092,cos-bigdata-test-hadoop-03:9092
a1.sources.r1.kafka.topics = compass-edb-returnSales-test
a1.sources.r1.kafka.consumer.group.id = edb_returnSales_consumer1

# interceptor
a1.sources.r1.interceptors =  i1 i2
a1.sources.r1.interceptors.i1.type = com.iotmars.interceptor.ETLInterceptor$Builder
a1.sources.r1.interceptors.i2.type = com.iotmars.interceptor.TimeStampInterceptor$Builder

# channels
#a1.channels.c1.type = memory
#a1.channels.c1.capacity = 10000
#a1.channels.c1.transactionCapacity = 10000
#a1.channels.c1.byteCapacityBufferPercentage = 20
#a1.channels.c1.byteCapacity = 800000
a1.channels.c1.type = file 
a1.channels.c1.checkpointDir = /opt/module/flume-1.7.0/checkpoint/edb_returnSales_file_channel1
a1.channels.c1.dataDirs = /opt/module/flume-1.7.0/data/edb_returnSales_file_channel1

# sinks
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /origin_data/compass/edb/edb_returnSales/%Y-%m-%d
a1.sinks.k1.hdfs.filePrefix = edb
a1.sinks.k1.hdfs.batchSize = 100
a1.sinks.k1.hdfs.rollInterval = 1200
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.useLocalTimeStamp = false

# kerberos
a1.sinks.k1.hdfs.kerberosPrincipal = hive@IOTMARS.COM
a1.sinks.k1.hdfs.kerberosKeytab = /etc/security/keytab/hive.keytab

# compress
a1.sinks.k1.hdfs.codeC = lzop
a1.sinks.k1.hdfs.fileType = CompressedStream

# combine
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

<br>
# 二、Interceptor
**依赖**
```
        <dependency>
            <groupId>org.apache.flume</groupId>
            <artifactId>flume-ng-core</artifactId>
            <version>1.7.0</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.76</version>
        </dependency>
```

**代码**
```
package com.iotmars.flume;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.interceptor.Interceptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.List;

public class ETLInterceptor implements Interceptor {
    private Logger logger;

    @Override
    public void initialize() {
        logger = LoggerFactory.getLogger("ETLInterceptor");
    }

    @Override
    public Event intercept(Event event) {
        byte[] body = event.getBody();
        String log = new String(body, StandardCharsets.UTF_8);

        JSONObject jsonObject;

        try {
            jsonObject = JSON.parseObject(log);
        } catch (Exception execption) {
            logger.warn("Parse failed: " + log);
            return null;
        }

        String ts = jsonObject.getString("ts");
        if (ts == null) {
            logger.warn("Get ts failed: " + log);

            return null;
        }else{
            return event;
        }

    }

    @Override
    public List<Event> intercept(List<Event> list) {
        Iterator<Event> iterator = list.iterator();

        while (iterator.hasNext()) {
            Event event = iterator.next();

            if (intercept(event) == null) {
                iterator.remove();
            }
        }

        return list;
    }

    @Override
    public void close() {

    }


    public static class Builder implements Interceptor.Builder{

        @Override
        public Interceptor build() {
            return new ETLInterceptor();
        }

        @Override
        public void configure(Context context) {

        }
    }

}
```
```
package com.iotmars.flume;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.interceptor.Interceptor;

import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class TimeStampInterceptor implements Interceptor {
    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {
        byte[] body = event.getBody();
        String log = new String(body, StandardCharsets.UTF_8);

        JSONObject jsonObject = JSON.parseObject(log);
        String ts = jsonObject.getString("ts");

        Map<String, String> headers = event.getHeaders();
        headers.put("timestamp", ts);

        return event;
    }

    @Override
    public List<Event> intercept(List<Event> list) {
        Iterator<Event> iterator = list.iterator();

        while (iterator.hasNext()) {
            Event event = iterator.next();
            intercept(event);
        }

        return list;
    }

    @Override
    public void close() {

    }

    public static class Builder implements Interceptor.Builder{
        @Override
        public Interceptor build() {
            return new TimeStampInterceptor();
        }

        @Override
        public void configure(Context context) {

        }
    }

}
```

<br>
# 三、解析edb的json数据
### 数据格式
```
ods_edb_order 的line字段如下
{
	"order_totalfee": "6449.0000",
	"is_except": "False",
	"flag_color": "黄色",
	"express_no": "20210723996529",
	"type": "他方代发",
	"net_weight_freight": "0.00",
	"out_tid": "1970674814254351010",
	"province": "安徽省",
	"express_coding": "ZT",
	"is_print": "1",
	"sku": "1",
	"transaction_id": "2021072322001101461444582431",
	"buyer_message": "自提",
	"printer": "edb_b393220                                       ",
	"product_num": "1",
	"pro_totalfee": "6449.0000",
	"is_pre_delivery_notice": "0",
	"promotion_info": "满减200:省200.00元;722优惠券:省100.00元;天猫活力价:省600.00元;",
	"alipay_id": "176****2888",
	"status": "已财务审核",
	"review_orders_operator": "edb_b400016                                       ",
	"tid_item": [{
			"original_price": "6899.0000",
			"item_discountfee": "450.0000",
			"sell_price": "6449.0000",
			"discount_amount": "450.0000",
			"timeinventory": [],
			"tid": "S2107230000173",
			"send_num": "1",
			"ferght": "0.0000",
			"second_barcode": "100009569207",
			"out_tid": "1970674814254351010",
			"inspection_num": [],
			"barcode": "020603001",
			"stock_situation": [],
			"proexplain": [],
			"book_inventory": "346.000",
			"credit_amount": "0.0000",
			"weight": "0.000",
			"seller_remark": [],
			"brand_name": "火星人",
			"plat_discount": "0.0000",
			"sncode": [],
			"out_proid": [],
			"refund_num": [],
			"promotion_info": "满减200:省200.00元;722优惠券:省100.00元;天猫活力价:省600.00元;",
			"shopid": [],
			"product_specification": "IDW-G2U1-S",
			"distributer": [],
			"iscombination": "0",
			"pro_name": "【天猫活力价】火星人E4B/X烟灶消集成灶集成水槽洗碗机套装组合整体厨房",
			"sys_price": "0.0000",
			"pro_detail_code": "1184",
			"distribut_time": [],
			"refund_renum": [],
			"isgifts": [],
			"out_prosku": [],
			"gift_num": [],
			"brand_number": "1",
			"storage_id": "1",
			"combine_barcode": [],
			"buyer_memo": [],
			"store_location": "默认库位",
			"isbook_pro": [],
			"cost_price": "0.0000",
			"inspection_time": [],
			"MD5_encryption": "92EC7282-4968-4212-835B-88E1EA43DBA2",
			"iscancel": [],
			"average_price": [],
			"specification": "IDW-G2U1-S",
			"pro_type": "原始产品",
			"product_no": "020603001",
			"isscheduled": [],
			"book_storage": [],
			"pro_num": "1"
		},
		{
			"original_price": "10899.0000",
			"item_discountfee": "1900.0000",
			"sell_price": "8999.0000",
			"discount_amount": "1900.0000",
			"timeinventory": [],
			"tid": "S2107230000174",
			"send_num": "1",
			"ferght": "0.0000",
			"second_barcode": "6952736503451",
			"out_tid": "1970673230505430336",
			"inspection_num": [],
			"barcode": "02021304001",
			"stock_situation": [],
			"proexplain": [],
			"book_inventory": "459.000",
			"credit_amount": "0.0000",
			"weight": "0.000",
			"seller_remark": [],
			"brand_name": "火星人",
			"plat_discount": "0.0000",
			"sncode": [],
			"out_proid": [],
			"refund_num": [],
			"promotion_info": "天猫活力价:省1200.00元;",
			"shopid": [],
			"product_specification": "JJZT-E2B/Z 12T 黑色",
			"distributer": [],
			"iscombination": "0",
			"pro_name": "【天猫活力价】MARSSENGER/火星人 E2B/Z集成灶 蒸箱下排式侧吸油烟机燃气灶一体",
			"sys_price": "0.0000",
			"pro_detail_code": "845",
			"distribut_time": [],
			"refund_renum": [],
			"isgifts": [],
			"out_prosku": [],
			"gift_num": [],
			"brand_number": "1",
			"storage_id": "1",
			"combine_barcode": [],
			"buyer_memo": [],
			"store_location": "默认库位",
			"isbook_pro": [],
			"cost_price": "0.0000",
			"inspection_time": [],
			"MD5_encryption": "1951C0A106E85BC54CE002552634287F",
			"iscancel": [],
			"average_price": [],
			"specification": "燃料种类:天然气;颜色分类:黑色",
			"pro_type": "原始产品",
			"product_no": "02021304001",
			"isscheduled": [],
			"book_storage": [],
			"pro_num": "1"
		}
	],
	"city": "宿州市",
	"city_code": "341300",
	"inspect_time": "2021-07-24 09:10:02",
	"is_cod": "0",
	"discount_fee": "450.0000",
	"receiver_name": "韩刘■",
	"print_time": "2021-07-23 12:53:20",
	"taobao_delivery_order_status": "交易成功",
	"order_channel": "直营网店",
	"tid_net_weight": "0.00",
	"invoice_situation": "0",
	"address": "安徽省 宿州市 埇桥区三八街道光彩城C区29栋5～6号（火星人集成灶专卖店）",
	"receiver_mobile": "17682762888",
	"item_num": "1",
	"service_remarks": "自提【小俞 07-23 00:08】",
	"express_col_fee": "0.00",
	"single_num": "1",
	"customer_id": "CU2004170000215",
	"platform_status": "交易成功",
	"is_inspection": "1",
	"delivery_status": "已发货",
	"plat_send_status": "1",
	"ts": 1635761346017,
	"provinc_code": "340000",
	"other_remarks": "火星人-安徽省-宿州店（韩刘）",
	"enable_inte_delivery_time": "2021-07-23 00:11:20",
	"cod_service_fee": "0.00",
	"delivery_operator": "奇门",
	"express": "自提",
	"delivery_time": "2021-07-24 09:10:11",
	"buyer_id": "韩刘15555930098",
	"tid": "S2107230000173",
	"dt": "2021-11-01",
	"express_code": "19",
	"post": "234000",
	"finance_review_operator": "edb_b393216",
	"order_creater": "edb_a89526",
	"total_num": "713",
	"cost_point": "0.00",
	"gross_weight": "0.000",
	"commission_fee": "0.0000",
	"resultNum": "18",
	"taobao_delivery_method": "express",
	"area_code": "341302",
	"shop_name": "天猫",
	"import_mark": "已处理",
	"finish_time": "2021-07-29 08:08:13",
	"is_stock": "0",
	"order_disfee": "0.0000",
	"pay_time": "2021-07-23 00:07:41",
	"review_orders_time": "2021-07-23 08:35:31",
	"platform_preferential": "0.00",
	"district": "埇桥区",
	"shopid": "1",
	"plat_type": "天猫",
	"get_time": "2021-07-23 00:11:13",
	"pay_status": "已付款",
	"is_break": "0",
	"real_income_freight": "0.00",
	"storage_id": "1",
	"invoice_fee": "6449.0000",
	"finance_review_time": "2021-07-23 10:38:11",
	"reference_price_paid": "6449.0000",
	"is_bill": "0",
	"tid_time": "2021-07-23 00:07:33",
	"is_adv_sale": "0",
	"merge_status": "手动拆分",
	"is_promotion": "0"
}
```
其中tid_item是一个数组，需要使用爆炸函数将数组拆成多条记录。

[官网](https://cwiki.apache.org/confluence/display/Hive/DeveloperGuide+UDTF)

### 创建UDTF逻辑代码
依赖
```
        <dependency>
            <groupId>org.apache.hive</groupId>
            <artifactId>hive-exec</artifactId>
            <version>3.1.2</version>
            <scope>provided</scope>
        </dependency>
```
代码
```
public class ExplodeJSONArray extends GenericUDTF {

    @Override
    public StructObjectInspector initialize(ObjectInspector[] argOIs) throws UDFArgumentException {
        // 1.检查参数合法性
        if (argOIs.length != 1) {
            throw new UDFArgumentException("只需要一个参数");
        }

        // 2. 第一个参数必须为string
        // 判断参数是否为基础数据类型
        if (argOIs[0].getCategory() != ObjectInspector.Category.PRIMITIVE) {
            throw new UDFArgumentException("只接受基础类型参数");
        }

        // 将参数对象检查器强制转为基础类型对象检查其
        PrimitiveObjectInspector argument = (PrimitiveObjectInspector) argOIs[0];

        // 判断参数是否为String类型
        if (argument.getPrimitiveCategory() != PrimitiveObjectInspector.PrimitiveCategory.STRING) {
            throw new UDFArgumentException("只接受string类型参数");
        }

        // 定义返回值名称和类型
        ArrayList<String> fieldNames = new ArrayList<String>();
        ArrayList<ObjectInspector> fieldOIs = new ArrayList<ObjectInspector>();

        fieldNames.add("items");
        fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);

        return ObjectInspectorFactory.getStandardStructObjectInspector(fieldNames,fieldOIs);
    }

    @Override
    public void process(Object[] objects) throws HiveException {
        Object arg = objects[0];
        String jsonArrayStr = PrimitiveObjectInspectorUtils.getString(arg, PrimitiveObjectInspectorFactory.javaStringObjectInspector);

        JSONArray jsonArray = new JSONArray(jsonArrayStr);

        for (int i = 0; i < jsonArray.length(); i++) {
            String json = jsonArray.getString(i);
            String[] result = {json};
            forward(result);
        }
    }

    @Override
    public void close() throws HiveException {

    }
}
```
- initialize方法：该方法对ObjectInspector(对象检查器)进行处理，参数类型，数量和名称是通过对象检查器进行传输的，在initialize方法中会先对接收到的对象检查器进行检查，并创建对象检查器传递给下一个函数。
- process方法：该方法对数据进行处理。

### 创建函数
打包后将jar包放置到hdfs上
```
hadoop fs -mkdir /user/hive/jars
hadoop fs -put /opt/module/packages/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar /user/hive/jars/
```
创建永久函数
```
create function device_udf as 'com.cj.hive.TimeCountUDF ' using jar 'hdfs://bigdata1:9000/user/hive/jars/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar';
create function addr_udtf as 'com.cj.hive.ModelJsonUDTF ' using jar 'hdfs://bigdata1:9000/user/hive/jars/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar';
show functions like "*udtf*";  # 模糊匹配搜索函数
```
删除函数
```
drop [temporary] function [if exists] [dbname.]function_name;
```
