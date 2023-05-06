---
title: RabbitMQ消息确认机制(转载)
categories:
- 中间件
---
#### 1\. 配置RabbitMQ

```
# 发送确认
spring.rabbitmq.publisher-confirms=true
# 发送回调
spring.rabbitmq.publisher-returns=true
# 消费手动确认
spring.rabbitmq.listener.simple.acknowledge-mode=manual
```

#### 2\. 生产者发送消息确认机制

*   其实这个也不能叫确认机制，只是起到一个监听的作用，监听生产者是否发送消息到exchange和queue。
*   生产者和消费者代码不改变。
*   新建配置类 MQProducerAckConfig.java 实现ConfirmCallback和ReturnCallback接口，@Component注册成组件。
*   ConfirmCallback只确认消息是否到达exchange，已实现方法confirm中ack属性为标准，true到达，反之进入黑洞。
*   ReturnCallback消息没有正确到达队列时触发回调，如果正确到达队列不执行。

```
package com.fzb.rabbitmq.config;

import org.apache.commons.lang3.SerializationUtils;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.connection.CorrelationData;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;

/**
 * @Description 消息发送确认
 * <p>
 * ConfirmCallback  只确认消息是否正确到达 Exchange 中
 * ReturnCallback   消息没有正确到达队列时触发回调，如果正确到达队列不执行
 * <p>
 * 1\. 如果消息没有到exchange,则confirm回调,ack=false
 * 2\. 如果消息到达exchange,则confirm回调,ack=true
 * 3\. exchange到queue成功,则不回调return
 * 4\. exchange到queue失败,则回调return
 * @Author jxb
 * @Date 2019-04-04 16:57:04
 */
@Component
public class MQProducerAckConfig implements RabbitTemplate.ConfirmCallback, RabbitTemplate.ReturnCallback {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @PostConstruct
    public void init() {
        rabbitTemplate.setConfirmCallback(this);            //指定 ConfirmCallback
        rabbitTemplate.setReturnCallback(this);             //指定 ReturnCallback

    }

    @Override
    public void confirm(CorrelationData correlationData, boolean ack, String cause) {
        if (ack) {
            System.out.println("消息发送成功" + correlationData);
        } else {
            System.out.println("消息发送失败:" + cause);
        }
    }

    @Override
    public void returnedMessage(Message message, int replyCode, String replyText, String exchange, String routingKey) {
        // 反序列化对象输出
        System.out.println("消息主体: " + SerializationUtils.deserialize(message.getBody()));
        System.out.println("应答码: " + replyCode);
        System.out.println("描述：" + replyText);
        System.out.println("消息使用的交换器 exchange : " + exchange);
        System.out.println("消息使用的路由键 routing : " + routingKey);
    }
}

```

#### 3\. 消费者消息手动确认

*   SpringBoot集成RabbitMQ确认机制分为三种：none、auto(默认)、manual

**Auto：**
1\. 如果消息成功被消费（成功的意思是在消费的过程中没有抛出异常），则自动确认
2\. 当抛出 AmqpRejectAndDontRequeueException 异常的时候，则消息会被拒绝，且 requeue = false（不重新入队列）
3\. 当抛出 ImmediateAcknowledgeAmqpException 异常，则消费者会被确认
4\. 其他的异常，则消息会被拒绝，且 requeue = true，此时会发生死循环，可以通过 setDefaultRequeueRejected（默认是true）去设置抛弃消息

*   如设置成manual手动确认，一定要对消息做出应答，否则rabbit认为当前队列没有消费完成，将不再继续向该队列发送消息。

*   channel.basicAck(long,boolean); 确认收到消息，消息将被队列移除，false只确认当前consumer一个消息收到，true确认所有consumer获得的消息。

*   channel.basicNack(long,boolean,boolean); 确认否定消息，第一个boolean表示一个consumer还是所有，第二个boolean表示requeue是否重新回到队列，true重新入队。

*   channel.basicReject(long,boolean); 拒绝消息，requeue=false 表示不再重新入队，如果配置了死信队列则进入死信队列。

*   当消息回滚到消息队列时，这条消息不会回到队列尾部，而是仍是在队列头部，这时消费者会又接收到这条消息，如果想消息进入队尾，须确认消息后再次发送消息。

```
channel.basicPublish(message.getMessageProperties().getReceivedExchange(),
                    message.getMessageProperties().getReceivedRoutingKey(), 
                    MessageProperties.PERSISTENT_TEXT_PLAIN,
                    message.getBody());

```

*   延续上一章direct类型队列为例，当消息出现异常，判断是否回滚过消息，如否则消息从新入队，反之抛弃消息。其中一个消费者模拟一个异常。

```
    @RabbitListener(bindings = {@QueueBinding(value = @Queue(value = "direct.queue"), exchange = @Exchange(value = "direct.exchange"), key = "HelloWorld")})
    public void getDirectMessage(User user, Channel channel, Message message) throws IOException {
        try {
            // 模拟执行任务
            Thread.sleep(1000);
            // 模拟异常
            String is = null;
            is.toString();
            // 确认收到消息，false只确认当前consumer一个消息收到，true确认所有consumer获得的消息
            channel.basicAck(message.getMessageProperties().getDeliveryTag(), false);
        } catch (Exception e) {
            if (message.getMessageProperties().getRedelivered()) {
                System.out.println("消息已重复处理失败,拒绝再次接收" + user.getName());
                // 拒绝消息，requeue=false 表示不再重新入队，如果配置了死信队列则进入死信队列
                channel.basicReject(message.getMessageProperties().getDeliveryTag(), false);
            } else {
                System.out.println("消息即将再次返回队列处理" + user.getName());
                // requeue为是否重新回到队列，true重新入队
                channel.basicNack(message.getMessageProperties().getDeliveryTag(), false, true);
            }
            //e.printStackTrace();
        }
    }

@RabbitListener(queues = "direct.queue")
    public void getDirectMessageCopy(User user, Channel channel, Message message) throws IOException {
        try {
            // 模拟执行任务
            Thread.sleep(1000);
            System.out.println("--jxb--MQConsumer--getDirectMessageCopy：" + user.toString());
            // 确认收到消息，false只确认当前consumer一个消息收到，true确认所有consumer获得的消息
            channel.basicAck(message.getMessageProperties().getDeliveryTag(), false);
        } catch (Exception e) {
            if (message.getMessageProperties().getRedelivered()) {
                System.out.println("消息已重复处理失败,拒绝再次接收！");
                // 拒绝消息，requeue=false 表示不再重新入队，如果配置了死信队列则进入死信队列
                channel.basicReject(message.getMessageProperties().getDeliveryTag(), false);
            } else {
                System.out.println("消息即将再次返回队列处理！");
                // requeue为是否重新回到队列，true重新入队
                channel.basicNack(message.getMessageProperties().getDeliveryTag(), false, true);
            }
            e.printStackTrace();
        }
    }

```

从执行结果来看，三条消息都调用了confirm方法，说明消息发送到了exchange，且没有调用return方法，说明消息成功到达相应队列。

getDirectMessageCopy方法成功消费掉“张三”这条消息，由于getDirectMessage方法模拟异常，所以第一次把“李四”从新入队，此时getDirectMessageCopy继续消费“王五”成功，getDirectMessage方法因李四已经从新入队过，再次发生异常则抛弃消息。

![image](//upload-images.jianshu.io/upload_images/7185724-ac97d04a08b05b78.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700/format/webp)

进一步挖掘你会发现，开始一共3条消息，有一条回滚消息总数变成了4条，每个消费者消费2条，所以两个消费者是轮询分配的。

*   工作队列有两种工作方式：轮询分发(默认)、公平分发即当某个消费者没有消费完成之前不用再分发消息。
*   修改配置文件

```
# 消费者每次从队列获取的消息数量。此属性当不设置时为：轮询分发，设置为1为：公平分发
spring.rabbitmq.listener.simple.prefetch=1

```

将第一个消费者模拟执行5秒，然后向数据库增加一条数据，执行结果为：

![image](//upload-images.jianshu.io/upload_images/7185724-0d6db7659b7f00df.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/700/format/webp)

可以看到，getDirectMessageCopy执行了4次，getDirectMessage执行了1次，根据他们的消费能力来公平分发消息。
