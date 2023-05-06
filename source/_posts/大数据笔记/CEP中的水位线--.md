---
title: CEP中的水位线--
categories:
- 大数据笔记
---
问题：
1. 为什么无论迟到时间为多久，都可以得到正确结果？？？
2. 从文本中读取，水位线时间间隔为200ms，理应来不及更新水位线，但是结果还是正确的


1. 经过实测，无论迟到时间为多久，都可以得到正确结果
```scala
package com.hxr

import java.util
import java.util.Properties

import com.alibaba.fastjson.serializer.SerializerFeature
import com.alibaba.fastjson.{JSON, JSONObject}
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.cep.{PatternSelectFunction, PatternTimeoutFunction}
import org.apache.flink.cep.scala.CEP
import org.apache.flink.cep.scala.pattern.Pattern
import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer
import org.apache.flink.streaming.api.windowing.time.Time
import scala.util.control.Breaks._

import scala.collection.JavaConversions._
import scala.collection.mutable

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/13 14:04
 */
case class ModelLogQ6(iotId: String, productKey: String, timestamp: Long, data: String)

object LogBehaviorEtl {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(3)

    val properties = new Properties()
    properties.setProperty("bootstrap.servers", "192.168.32.242:9092")
    properties.setProperty("group.id", "consumer-group")
    properties.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
    properties.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
    properties.setProperty("auto.offset.reset", "latest")

    //        val inputStream = env.addSource(new FlinkKafkaConsumer[String]("ModelLog_Q6", new SimpleStringSchema(), properties))
    //    val inputStream = env.socketTextStream("192.168.32.242", 7777)
    val resource = getClass.getResource("/DeviceModelLog")
    val inputStream = env.readTextFile(resource.getPath)

    val dataStream = inputStream
      .map(log => {
        val jsonObject = JSON.parseObject(log)
        val iotId = jsonObject.getString("iotId")
        val productKey = jsonObject.getString("productKey")
        val timestamp = jsonObject.getLong("gmtCreate")
        //        val data = jsonObject.getString("items")
        ModelLogQ6(iotId, productKey, timestamp, log)
      })
      //    .assignAscendingTimestamps(_.timestamp)
      .assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[ModelLogQ6](Time.seconds(5)) {
        override def extractTimestamp(element: ModelLogQ6): Long = element.timestamp
      })

    val pattern = Pattern
      .begin[ModelLogQ6]("start").where(_.productKey.equals("a17JZbZVctc"))
      .next("next").where(_.productKey.equals("a17JZbZVctc"))

    val outputTag = new OutputTag[ModelLogQ6]("order-timeout")

    val resultStream = CEP
      .pattern(dataStream.keyBy(_.iotId), pattern)
      .select(outputTag, new LogTimeoutResult, new LogCompleteResult)

    resultStream.getSideOutput(outputTag).print("warn")
    resultStream.filter(_ != null).print("success")

    env.execute("Q6 Log ETL")
  }
}

class LogTimeoutResult extends PatternTimeoutFunction[ModelLogQ6, ModelLogQ6] {
  override def timeout(map: util.Map[String, util.List[ModelLogQ6]], l: Long): ModelLogQ6 = {
    map.get("start").get(0)
  }
}

class LogCompleteResult extends PatternSelectFunction[ModelLogQ6, String] {
  override def select(map: util.Map[String, util.List[ModelLogQ6]]): String = {
    val start: ModelLogQ6 = map.get("start").get(0)
    val next: ModelLogQ6 = map.get("next").get(0)
    val oldData: String = start.data
    val newData: String = next.data

    // 解析新数据的事件
    val jsonObject: JSONObject = JSON.parseObject(newData)
    val newItems = jsonObject.getJSONObject("items")
    val keySet: util.Set[String] = newItems.keySet()

    // 解析旧数据的事件
    val oldItems = JSON.parseObject(oldData).getJSONObject("items")

    val changePros = new util.HashMap[String, JSONObject]()

    for (key <- keySet) {
      breakable {
        // 过滤掉目前无用且一直打印的字段
        if ("LFirewallTemp".equals(key) || "StOvRealTemp".equals(key) || "RFirewallTemp".equals(key)) {
          break()
        }

        val oldValue: JSONObject = oldItems.getJSONObject(key)
        val oldValueVa: String = oldValue.getString("value")

        val newValue: JSONObject = newItems.getJSONObject(key)
        val newValueVa: String = newValue.getString("value")

        // 剩余时间取最大值
        if ("StOvSetTimerLeft".equals(key) || "HoodOffLeftTime".equals(key)) {
          if (newValueVa.compareTo(oldValueVa) > 0) {
            changePros.put(key, newValue)
          }
        }

        // 累计运行时间取最大值
        if ("HoodRunningTime".equals(key)) {
          if (newValueVa.compareTo(oldValueVa) < 0) {
            changePros.put(key, newValue)
          }
        }

        if (!oldValueVa.equals(newValueVa)) {
          changePros.put(key, newValue)
        }
      }
    }

    if (changePros.nonEmpty) {
      jsonObject.put("items", changePros)
      jsonObject.toString()
    } else {
      null
    }
  }
}
```

读取的文本内容
```
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"144","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610537090852,"deviceName":"Q6-aoxinwen2","items":{"StOvDoorState":{"value":1,"time":1610537090847},"HoodLight":{"value":0,"time":1610537090847},"StOvState":{"value":0,"time":1610537090847},"StOvOrderTimerLeft":{"value":0,"time":1610537090847},"HoodSpeed":{"value":0,"time":1610537090847},"StOvMode":{"value":0,"time":1610537090847},"StOvSetTimerLeft":{"value":0,"time":1610537090847},"HoodOffLeftTime":{"value":0,"time":1610537090847},"HoodRunningTime":{"value":0,"time":1610537090847},"OilBoxState":{"value":0,"time":1610537090847},"RSwitchState":{"value":0,"time":1610537090847},"HoodOffTimerStove":{"value":0,"time":1610537090847},"TimingSet":{"value":0,"time":1610537090847},"RStoveTimingState":{"value":0,"time":1610537090847},"ErrorCodeShow":{"value":0,"time":1610537090847},"MultiMode":{"value":0,"time":1610537090847},"StOvSetTimer":{"value":0,"time":1610537090847},"MultiStageName":{"value":"","time":1610537090847},"TimingState":{"value":0,"time":1610537090847},"LFirewallTemp":{"value":20,"time":1610537090847},"LStoveStatus":{"value":0,"time":1610537090847},"TimingLeft":{"value":0,"time":1610537090847},"RStoveStatus":{"value":0,"time":1610537090847},"HoodOffTimerStOv":{"value":10,"time":1610537090847},"StOvSetTemp":{"value":0,"time":1610537090847},"RStoveTimingSet":{"value":0,"time":1610537090847},"StOvOrderTimer":{"value":0,"time":1610537090847},"SysPower":{"value":0,"time":1610537090847},"LSwitchState":{"value":0,"time":1610537090847},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537090847},"RStoveTimingLeft":{"value":0,"time":1610537090847},"ErrorCode":{"value":0,"time":1610537090847},"ElcHWVersion":{"value":"01-01","time":1610537090847},"RFirewallTemp":{"value":20,"time":1610537090847},"StOvLightState":{"value":0,"time":1610537090847},"StOvRealTemp":{"value":21,"time":1610537090847},"ElcSWVersion":{"value":"17-01","time":1610537090847}}}
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb0000000","requestId":"144","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610637090852,"deviceName":"Q6-aoxinwen1","items":{"StOvDoorState":{"value":1,"time":1610537090847},"HoodLight":{"value":0,"time":1610537090847},"StOvState":{"value":0,"time":1610537090847},"StOvOrderTimerLeft":{"value":0,"time":1610537090847},"HoodSpeed":{"value":0,"time":1610537090847},"StOvMode":{"value":0,"time":1610537090847},"StOvSetTimerLeft":{"value":0,"time":1610537090847},"HoodOffLeftTime":{"value":0,"time":1610537090847},"HoodRunningTime":{"value":0,"time":1610537090847},"OilBoxState":{"value":0,"time":1610537090847},"RSwitchState":{"value":0,"time":1610537090847},"HoodOffTimerStove":{"value":0,"time":1610537090847},"TimingSet":{"value":0,"time":1610537090847},"RStoveTimingState":{"value":0,"time":1610537090847},"ErrorCodeShow":{"value":0,"time":1610537090847},"MultiMode":{"value":0,"time":1610537090847},"StOvSetTimer":{"value":0,"time":1610537090847},"MultiStageName":{"value":"","time":1610537090847},"TimingState":{"value":0,"time":1610537090847},"LFirewallTemp":{"value":20,"time":1610537090847},"LStoveStatus":{"value":0,"time":1610537090847},"TimingLeft":{"value":0,"time":1610537090847},"RStoveStatus":{"value":0,"time":1610537090847},"HoodOffTimerStOv":{"value":10,"time":1610537090847},"StOvSetTemp":{"value":0,"time":1610537090847},"RStoveTimingSet":{"value":0,"time":1610537090847},"StOvOrderTimer":{"value":0,"time":1610537090847},"SysPower":{"value":0,"time":1610537090847},"LSwitchState":{"value":0,"time":1610537090847},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537090847},"RStoveTimingLeft":{"value":0,"time":1610537090847},"ErrorCode":{"value":0,"time":1610537090847},"ElcHWVersion":{"value":"01-01","time":1610537090847},"RFirewallTemp":{"value":20,"time":1610537090847},"StOvLightState":{"value":0,"time":1610537090847},"StOvRealTemp":{"value":21,"time":1610537090847},"ElcSWVersion":{"value":"17-01","time":1610537090847}}}
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"147","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610637093907,"deviceName":"Q6-aoxinwen2","items":{"StOvDoorState":{"value":1,"time":1610537093903},"HoodLight":{"value":0,"time":1610537093903},"StOvState":{"value":0,"time":1610537093903},"StOvOrderTimerLeft":{"value":0,"time":1610537093903},"HoodSpeed":{"value":0,"time":1610537093903},"StOvMode":{"value":0,"time":1610537093903},"StOvSetTimerLeft":{"value":0,"time":1610537093903},"HoodOffLeftTime":{"value":0,"time":1610537093903},"HoodRunningTime":{"value":0,"time":1610537093903},"OilBoxState":{"value":0,"time":1610537093903},"RSwitchState":{"value":0,"time":1610537093903},"HoodOffTimerStove":{"value":0,"time":1610537093903},"TimingSet":{"value":0,"time":1610537093903},"RStoveTimingState":{"value":0,"time":1610537093903},"ErrorCodeShow":{"value":0,"time":1610537093903},"MultiMode":{"value":0,"time":1610537093903},"StOvSetTimer":{"value":0,"time":1610537093903},"MultiStageName":{"value":"","time":1610537093903},"TimingState":{"value":0,"time":1610537093903},"LFirewallTemp":{"value":20,"time":1610537093903},"LStoveStatus":{"value":0,"time":1610537093903},"TimingLeft":{"value":0,"time":1610537093903},"RStoveStatus":{"value":0,"time":1610537093903},"HoodOffTimerStOv":{"value":10,"time":1610537093903},"StOvSetTemp":{"value":0,"time":1610537093903},"RStoveTimingSet":{"value":0,"time":1610537093903},"StOvOrderTimer":{"value":0,"time":1610537093903},"SysPower":{"value":0,"time":1610537093903},"LSwitchState":{"value":0,"time":1610537093903},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537093903},"RStoveTimingLeft":{"value":0,"time":1610537093903},"ErrorCode":{"value":0,"time":1610537093903},"ElcHWVersion":{"value":"01-01","time":1610537093903},"RFirewallTemp":{"value":20,"time":1610537093903},"StOvLightState":{"value":0,"time":1610537093903},"StOvRealTemp":{"value":20,"time":1610537093903},"ElcSWVersion":{"value":"17-01","time":1610537093903}}}
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"146","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610537092881,"deviceName":"Q6-aoxinwen2","items":{"StOvDoorState":{"value":1,"time":1610537092875},"HoodLight":{"value":0,"time":1610537092875},"StOvState":{"value":0,"time":1610537092875},"StOvOrderTimerLeft":{"value":0,"time":1610537092875},"HoodSpeed":{"value":0,"time":1610537092875},"StOvMode":{"value":0,"time":1610537092875},"StOvSetTimerLeft":{"value":0,"time":1610537092875},"HoodOffLeftTime":{"value":0,"time":1610537092875},"HoodRunningTime":{"value":0,"time":1610537092875},"OilBoxState":{"value":0,"time":1610537092875},"RSwitchState":{"value":0,"time":1610537092875},"HoodOffTimerStove":{"value":3,"time":1610537092875},"TimingSet":{"value":0,"time":1610537092875},"RStoveTimingState":{"value":0,"time":1610537092875},"ErrorCodeShow":{"value":0,"time":1610537092875},"MultiMode":{"value":0,"time":1610537092875},"StOvSetTimer":{"value":0,"time":1610537092875},"MultiStageName":{"value":"","time":1610537092875},"TimingState":{"value":0,"time":1610537092875},"LFirewallTemp":{"value":20,"time":1610537092875},"LStoveStatus":{"value":0,"time":1610537092875},"TimingLeft":{"value":0,"time":1610537092875},"RStoveStatus":{"value":0,"time":1610537092875},"HoodOffTimerStOv":{"value":10,"time":1610537092875},"StOvSetTemp":{"value":0,"time":1610537092875},"RStoveTimingSet":{"value":0,"time":1610537092875},"StOvOrderTimer":{"value":0,"time":1610537092875},"SysPower":{"value":0,"time":1610537092875},"LSwitchState":{"value":0,"time":1610537092875},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537092875},"RStoveTimingLeft":{"value":0,"time":1610537092875},"ErrorCode":{"value":0,"time":1610537092875},"ElcHWVersion":{"value":"01-01","time":1610537092875},"RFirewallTemp":{"value":20,"time":1610537092875},"StOvLightState":{"value":0,"time":1610537092875},"StOvRealTemp":{"value":21,"time":1610537092875},"ElcSWVersion":{"value":"17-01","time":1610537092875}}}
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"134","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610537100000,"deviceName":"Q6-aoxinwen2","items":{"StOvDoorState":{"value":1,"time":1610537018871},"HoodLight":{"value":0,"time":1610537018871},"StOvState":{"value":0,"time":1610537018871},"StOvOrderTimerLeft":{"value":0,"time":1610537018871},"HoodSpeed":{"value":0,"time":1610537018871},"StOvMode":{"value":0,"time":1610537018871},"StOvSetTimerLeft":{"value":0,"time":1610537018871},"HoodOffLeftTime":{"value":0,"time":1610537018871},"HoodRunningTime":{"value":0,"time":1610537018871},"OilBoxState":{"value":0,"time":1610537018871},"RSwitchState":{"value":0,"time":1610537018871},"HoodOffTimerStove":{"value":1,"time":1610537018871},"TimingSet":{"value":0,"time":1610537018871},"RStoveTimingState":{"value":0,"time":1610537018871},"ErrorCodeShow":{"value":0,"time":1610537018871},"MultiMode":{"value":0,"time":1610537018871},"StOvSetTimer":{"value":0,"time":1610537018871},"MultiStageName":{"value":"","time":1610537018871},"TimingState":{"value":0,"time":1610537018871},"LFirewallTemp":{"value":20,"time":1610537018871},"LStoveStatus":{"value":0,"time":1610537018871},"TimingLeft":{"value":0,"time":1610537018871},"RStoveStatus":{"value":0,"time":1610537018871},"HoodOffTimerStOv":{"value":10,"time":1610537018871},"StOvSetTemp":{"value":0,"time":1610537018871},"RStoveTimingSet":{"value":0,"time":1610537018871},"StOvOrderTimer":{"value":0,"time":1610537018871},"SysPower":{"value":0,"time":1610537018871},"LSwitchState":{"value":0,"time":1610537018871},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537018871},"RStoveTimingLeft":{"value":0,"time":1610537018871},"ErrorCode":{"value":0,"time":1610537018871},"ElcHWVersion":{"value":"01-01","time":1610537018871},"RFirewallTemp":{"value":20,"time":1610537018871},"StOvLightState":{"value":0,"time":1610537018871},"StOvRealTemp":{"value":21,"time":1610537018871},"ElcSWVersion":{"value":"17-01","time":1610537018871}}}
{"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb0000000","requestId":"134","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610637100000,"deviceName":"Q6-aoxinwen1","items":{"StOvDoorState":{"value":1,"time":1610537018871},"HoodLight":{"value":0,"time":1610537018871},"StOvState":{"value":0,"time":1610537018871},"StOvOrderTimerLeft":{"value":0,"time":1610537018871},"HoodSpeed":{"value":0,"time":1610537018871},"StOvMode":{"value":0,"time":1610537018871},"StOvSetTimerLeft":{"value":0,"time":1610537018871},"HoodOffLeftTime":{"value":0,"time":1610537018871},"HoodRunningTime":{"value":0,"time":1610537018871},"OilBoxState":{"value":0,"time":1610537018871},"RSwitchState":{"value":0,"time":1610537018871},"HoodOffTimerStove":{"value":1,"time":1610537018871},"TimingSet":{"value":0,"time":1610537018871},"RStoveTimingState":{"value":0,"time":1610537018871},"ErrorCodeShow":{"value":0,"time":1610537018871},"MultiMode":{"value":0,"time":1610537018871},"StOvSetTimer":{"value":0,"time":1610537018871},"MultiStageName":{"value":"","time":1610537018871},"TimingState":{"value":0,"time":1610537018871},"LFirewallTemp":{"value":20,"time":1610537018871},"LStoveStatus":{"value":0,"time":1610537018871},"TimingLeft":{"value":0,"time":1610537018871},"RStoveStatus":{"value":0,"time":1610537018871},"HoodOffTimerStOv":{"value":10,"time":1610537018871},"StOvSetTemp":{"value":0,"time":1610537018871},"RStoveTimingSet":{"value":0,"time":1610537018871},"StOvOrderTimer":{"value":0,"time":1610537018871},"SysPower":{"value":0,"time":1610537018871},"LSwitchState":{"value":0,"time":1610537018871},"MultiStageState":{"value":{"RemindText":"","current":0,"cnt":0,"remind":0},"time":1610537018871},"RStoveTimingLeft":{"value":0,"time":1610537018871},"ErrorCode":{"value":0,"time":1610537018871},"ElcHWVersion":{"value":"01-01","time":1610537018871},"RFirewallTemp":{"value":20,"time":1610537018871},"StOvLightState":{"value":0,"time":1610537018871},"StOvRealTemp":{"value":21,"time":1610537018871},"ElcSWVersion":{"value":"17-01","time":1610537018871}}}
```

得到的结果
```
success:1> {"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"146","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610537092881,"deviceName":"Q6-aoxinwen2","items":{"HoodOffTimerStove":{"time":1610537092875,"value":3}}}
success:3> {"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb0000000","requestId":"134","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610637100000,"deviceName":"Q6-aoxinwen1","items":{"HoodOffTimerStove":{"time":1610537018871,"value":1}}}
success:1> {"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"134","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610537100000,"deviceName":"Q6-aoxinwen2","items":{"HoodOffTimerStove":{"time":1610537018871,"value":1}}}
success:1> {"deviceType":"IntegratedStove","iotId":"FcTR7mfqsuCBiIejsFb6000000","requestId":"147","checkFailedData":{},"productKey":"a17JZbZVctc","gmtCreate":1610637093907,"deviceName":"Q6-aoxinwen2","items":{"HoodOffTimerStove":{"time":1610537093903,"value":0}}}
```
