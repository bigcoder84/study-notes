# RabbitMQ高级特性

## 一. 消息可靠性

支付平台必须保证数据正确性，保证数据并发安全性，保证数据最终一致性。

支付平台通过如下几种方式保证数据一致性：

1. 分布式锁

这个比较容易理解，就是在操作某条数据时先锁定，可以用Redis或Zookeeper等常用框架来实现。 比如我们在修改账单时，先锁定该账单，如果该账单有并发操作，后面的操作只能等待上一个操作的锁释放后再依次执行。

优点：能够保证数据强一致性。缺点：高并发场景下可能有性能问题。

2. 消息队列 

消息队列是为了保证最终一致性，我们需要确保消息队列有ack机制，客户端收到消息并消费处理完成后，客户端发送ack消息给消息中间件 如果消息中间件超过指定时间还没收到ack消息，则定时去重发消息。

比如我们在用户充值完成后，会发送充值消息给账户系统，账户系统再去更改账户余额。

优点：异步、高并发 缺点：有一定延时、数据弱一致性（最终一致性），并且必须能够确保该业务操作肯定能够成功完成，不可能失败。

![](../images/9.png)

### 1.1 异常捕获机制

先执行业务操作，业务操作成功后执行行消息发送，消息发送过程通过try catch 方式捕获异常，在异常处理理的代码块中执行行回滚业务操作或者执行行重发操作等。这是一种最大努力确保的方式，并无法保证100%绝对可靠，因为这里没有异常并不代表消息就一定投递成功。

![](../images/10.png)

另外，可以通过`spring.rabbitmq.template.retry.enabled=true`配置开启发送端的重试。

### 1.2 AMQP/RabbitMQ事务机制

> [消息队列之事务消息，RocketMQ 和 Kafka 是如何做的？ - InfoQ 写作平台](https://xie.infoq.cn/article/53240651a2ef7c173f50a3194)
>
> [一个基于RabbitMQ的可复用的事务消息方案 - throwable - 博客园 (cnblogs.com)](https://www.cnblogs.com/throwable/p/12266806.html)

RabbitMQ支持事务(transaction)。事务模式也不是默认开启的，需要调用tx.select方法开启事务模式。**当开启了事务模式后，只有当一个事务被所有的mirrors接受之后，tx.commit-ok才会返回给客户端**。confirm模式和开启事务模式都可以保证"被所有的mirrors接受"，那么，开启confirm模式和开启事务模式有什么区别吗？**不同点在于confirm是针对一条消息的，而事务是可以针对多条消息的（当然是针对同一个queue的多条消息）**。另外就是，confirm模式只是针对publisher的设置，而事务模式即可以针对publisher，也可以针对consumer。如果针对publisher设置事务模式，则我们可以将多个basic.publish方法放在一个事务中，当所有的publish的消息被所有的mirrors接受后，publisher client会收到tx.commit-ok的方法。如果针对consumer设置事务模式，则我们可以将多个basic.ack方法放在一个事务中，收到tx.commit-ok时表示这些消息都被确认了。

![](../images/11.png)

### 1.3 发送端确认机制

RabbitMQ后来引入了一种轻量量级的方式，叫发送方确认(publisher confirm)机制。生产者将信道设置成confirm(确认)模式，一旦信道进入confirm 模式，所有在该信道上⾯面发布的消息都会被指派一个唯一的ID(从1 开始)，一旦消息被投递到所有匹配的队列之后（如果消息和队列是持久化的，那么确认消息会在消息持久化后发出），RabbitMQ 就会发送一个确认(Basic.Ack)给生产者(包含消息的唯一ID)，这样生产者就知道消息已经正确送达了。

> RabbitMQ是采用的AMQP协议，AMQP协议定义了"确认"（acknowledgement）,它是从consumer到RabbitMQ的确认，表示一条消息已经被客户端正确处理。RabbitMQ扩展了AMQP协议，定义了从broker到publisher的"确认"，但将其称之为confirm。所以RabbitMQ的确认有2种，叫不同的名字，一个consumer acknowledgement，一个叫publisher confirm。
>
> 根据AMQP协议规定，consumer acknowledgemenet是通过basic.ack方法实现的，consumer在收到一条消息后，可以向broker发送basic.ack方法，确认一条消息已经收到。在默认的情况下，consumer acknowledgement模式是开启的，如果不想发送basic.ack，可以在发送basic.consume方法时指定no-ack参数，关闭consumer acknowledgement模式。
>
> Publisher confirm并没有在AMQ协议的基础上添加新的确认方法，而是复用了basic.ack方法。但是publisher confirm模式并不是默认打开的，需要调用confirm.select方法将channel设置成confirm模式。**当开启了confirm模式之后，只有当一条消息被所有的mirrors接受之后，publisher才会收到这条消息的confirm，也就是一个basic.ack方法**。

![](../images/12.png)

RabbitMQ回传给生产者的确认消息中的deliveryTag字段包含了确认消息的序号，另外，通过设置channel.basicAck方法中的multiple参数，表示到这个序号之前的所有消息是否都已经得到了处理了。生产者投递消息后并不需要一直阻塞着，可以继续投递下一条消息并通过回调方式处理理ACK响应。如果 RabbitMQ 因为自身内部错误导致消息丢失等异常情况发生，就会响应一条nack(Basic.Nack)命令，生产者应用程序同样可以在回调方法中处理理该`nack`命令。

```java
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

public class PublisherConfirmsProducer {
    public static void main(String[] args) throws Exception{
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");
        final Connection connection = factory.newConnection();
        final Channel channel = connection.createChannel();

        // 向RabbitMQ服务器发送AMQP命令，将当前通道标记为发送方确认通道
        final AMQP.Confirm.SelectOk selectOk = channel.confirmSelect();

        channel.queueDeclare("queue.pc", true, false, false, null);
        channel.exchangeDeclare("ex.pc", "direct", true, false, null);
        channel.queueBind("queue.pc", "ex.pc", "key.pc");

        // 发送消息
        channel.basicPublish("ex.pc", "key.pc", null, "hello world".getBytes());

        try {
            // 同步的方式等待RabbitMQ的确认消息
            channel.waitForConfirmsOrDie(5_000);
            System.out.println("发送的消息已经得到确认");
        } catch (IOException ex) {
            System.out.println("消息被拒收");
        } catch (IllegalStateException ex) {
            System.out.println("发送消息的通道不是PublisherConfirms通道");
        } catch (TimeoutException ex) {
            System.out.println("等待消息确认超时");
        }

        channel.close();
        connection.close();
    }
}
```

waitForConfirm方法有个重载的，可以自定义timeout超时时间，超时后会抛TimeoutException。类似的有几个waitForConfirmsOrDie方法，Broker端在返回nack(Basic.Nack)之后该方法会抛出java.io.IOException。需要根据异常类型来做区别处理理，TimeoutException超时是属于第三状态（无法确定成功还是失败），而返回Basic.Nack抛出IOException这种是明确的失败。上面的代码主要只是演示confirm机制，实际上还是同步阻塞模式的，性能并不不是太好。

实际上，我们也可以通过“批处理理”的方式来改善整体的性能（即批量量发送消息后仅调用一次waitForConfirms方法）。正常情况下这种批量处理的方式效率会高很多，但是如果发生了超时或者nack（失败）后那就需要批量量重发消息或者通知上游业务批量回滚（因为我们只知道这个批次中有消息没投递成功，而并不知道具体是那条消息投递失败了，所以很难针对性处理），如此看来，批量重发消息肯定会造成部分消息重复。另外，我们可以通过异步回调的方式来处理Broker的响应。addConfirmListener 方法可以添加ConfirmListener 这个回调接口，这个 ConfirmListener 接口包含两个方法:handleAck 和handleNack，分别用来处理 RabbitMQ 回传的 Basic.Ack 和 Basic.Nack。

**批量确认:**

```java
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

public class PublisherConfirmsProducer2 {
    public static void main(String[] args) throws Exception {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");
        final Connection connection = factory.newConnection();
        final Channel channel = connection.createChannel();

        // 向RabbitMQ服务器发送AMQP命令，将当前通道标记为发送方确认通道
        final AMQP.Confirm.SelectOk selectOk = channel.confirmSelect();

        channel.queueDeclare("queue.pc", true, false, false, null);
        channel.exchangeDeclare("ex.pc", "direct", true, false, null);
        channel.queueBind("queue.pc", "ex.pc", "key.pc");

        String message = "hello-";
        // 批处理的大小
        int batchSize = 10;
        // 用于对需要等待确认消息的计数
        int outstrandingConfirms = 0;
        for (int i = 0; i < 103; i++) {
            channel.basicPublish("ex.pc", "key.pc", null, (message + i).getBytes());

            outstrandingConfirms++;
            if (outstrandingConfirms == batchSize) {
                // 此时已经有一个批次的消息需要同步等待broker的确认消息
                // 同步等待
                channel.waitForConfirmsOrDie(5_000);
                System.out.println("消息已经被确认了");
                outstrandingConfirms = 0;
            }
        }

        if (outstrandingConfirms > 0) {
            channel.waitForConfirmsOrDie(5_000);
            System.out.println("剩余消息已经被确认了");
        }

        channel.close();
        connection.close();
    }
}
```

回调方式进行确认：

```java
import com.rabbitmq.client.*;

import javax.management.loading.MLet;
import java.io.IOException;
import java.util.concurrent.ConcurrentNavigableMap;
import java.util.concurrent.ConcurrentSkipListMap;

public class PublisherConfirmsProducer3 {
    public static void main(String[] args) throws Exception {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");
        final Connection connection = factory.newConnection();
        final Channel channel = connection.createChannel();

        // 向RabbitMQ服务器发送AMQP命令，将当前通道标记为发送方确认通道
        final AMQP.Confirm.SelectOk selectOk = channel.confirmSelect();

        channel.queueDeclare("queue.pc", true, false, false, null);
        channel.exchangeDeclare("ex.pc", "direct", true, false, null);
        channel.queueBind("queue.pc", "ex.pc", "key.pc");


        ConcurrentNavigableMap<Long, String> outstandingConfirms = new ConcurrentSkipListMap<>();

        ConfirmCallback clearOutstandingConfirms = (deliveryTag, multiple) -> {
            if (multiple) {
                System.out.println("编号小于等于 " + deliveryTag + " 的消息都已经被确认了");
                final ConcurrentNavigableMap<Long, String> headMap
                        = outstandingConfirms.headMap(deliveryTag, true);
                // 清空outstandingConfirms中已经被确认的消息信息
                headMap.clear();

            } else {
                // 移除已经被确认的消息
                outstandingConfirms.remove(deliveryTag);
                System.out.println("编号为：" + deliveryTag + " 的消息被确认");
            }
        };

        // 设置channel的监听器，处理确认的消息和不确认的消息
        channel.addConfirmListener(clearOutstandingConfirms, (deliveryTag, multiple) -> {
            if (multiple) {
                // 将没有确认的消息记录到一个集合中
                // 此处省略实现
                System.out.println("消息编号小于等于：" +  deliveryTag + " 的消息 不确认");
            } else {
                System.out.println("编号为：" + deliveryTag + " 的消息不确认");
            }
        });

        String message = "hello-";
        for (int i = 0; i < 1000; i++) {
            // 获取下一条即将发送的消息的消息ID
            final long nextPublishSeqNo = channel.getNextPublishSeqNo();
            channel.basicPublish("ex.pc", "key.pc", null, (message + i).getBytes());
            System.out.println("编号为：" + nextPublishSeqNo + " 的消息已经发送成功，尚未确认");
            outstandingConfirms.put(nextPublishSeqNo, (message + i));
        }

        // 等待消息被确认
        Thread.sleep(10000);

        channel.close();
        connection.close();
    }
}
```

### 1.4 持久化存储机制

持久化是提高RabbitMQ可靠性的基础，否则当RabbitMQ遇到异常时（如：重启、断电、停机等）数据将会丢失。主要从以下几个方面来保障消息的持久性：

1. Exchange的持久化。通过定义时设置durable参数为true来保证Exchange相关的元数据不不丢失。
2. Queue的持久化。也是通过定义时设置durable参数为true来保证Queue相关的元数据不不丢失。
3. 消息的持久化。通过将消息的投递模式 (BasicProperties中的deliveryMode属性)设置为2即可实现消息的持久化，保证消息自身不丢失。

根据 [官方博文](http://www.rabbitmq.com/blog/2011/01/20/rabbitmq-backing-stores-databases-and-disks/) 的介绍，RabbitMQ在两种情况下会将消息写入磁盘：

> Firstly we need to discuss what properties RabbitMQ itself expects of any backing store. RabbitMQ writes messages to disk in two cases: either the message has been published in such a way that it must be written to disk (e.g. published with `delivery_mode = 2`) or memory pressure is causing RabbitMQ to start running out of RAM and so it is pushing messages to disk in order to free up RAM. In the first case, just because we’ve written the message to disk, does not mean that we’re going to forget about it from RAM: if memory is abundant then there’s no reason to incur the cost of a subsequent disk read.
>
> 首先，我们需要讨论 RabbitMQ 本身对任何后备存储有哪些期望。RabbitMQ 在两种情况下将消息写入磁盘: 要么消息已经以必须写入磁盘的方式发布(例如以 delivery mode = 2发布) ，要么内存压力导致 RabbitMQ 开始耗尽 RAM，因此它将消息推送到磁盘以释放 RAM。在第一种情况下，仅仅因为我们已经将消息写到了磁盘上，并不意味着我们将会忘记从 RAM 中读取的消息: 如果内存很充裕，那么就没有理由产生后续磁盘读取的成本。

1. 消息本身在publish的时候就要求消息写入磁盘；
2. 内存紧张，需要将部分内存中的消息转移到磁盘；

```java
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

public class Producer {
    public static void main(String[] args) throws Exception {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");
        final Connection connection = factory.newConnection();
        final Channel channel = connection.createChannel();
        // durable:true表示是持久化消息队列
        channel.queueDeclare("queue.persistent", true, false, false, null);
        // 持久化的交换器
        channel.exchangeDeclare("ex.persistent", "direct", true, false, null);

        channel.queueBind("queue.persistent", "ex.persistent", "key.persistent");

        final AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
                .deliveryMode(2) // 表示是持久化消息
                .build();

        channel.basicPublish("ex.persistent",
                "key.persistent",
                properties,  // 设置消息的属性，此时消息是持久化消息
                "hello world".getBytes());


        channel.close();
        connection.close();
    }
}
```

### 1.5 消费端确认

前面我们讲了生产者发送确认机制和消息的持久化存储机制，然而这依然无法完全保证整个过程的可靠性，因为如果消息被消费过程中业务处理失败了但是消息却已经出列了（被标记为已消费了），我们又没有任何重试，那结果跟消息丢失没什么分别。

RabbitMQ在消费端会有Ack机制，即消费端消费消息后需要发送Ack确认报文给Broker端，告知自己是否已消费完成，否则可能会一直重发消息直到消息过期（AUTO模式）。

这也是我们之前一直在讲的“最终一致性”、“可恢复性” 的基础。

一般而言，我们有如下处理手段：

1. 采用NONE模式，消费的过程中自行捕获异常，引发异常后直接记录日志并落到异常恢复表，再通过后台定时任务扫描异常恢复表尝试做重试动作。如果业务不自行处理则有丢失数据的风险。
2. 采用AUTO（自动Ack）模式，不主动捕获异常，当消费过程中出现异常时会将消息放回Queue中，然后消息会被重新分配到其他消费者节点（如果没有则还是选择当前节点）重新被消费，默认会一直重发消息并直到消费完成返回Ack或者一直到过期
3. 采用MANUAL（手动Ack）模式，消费者自行控制流程并手动调用channel相关的方法返回ACK

```java
package com.lagou.rabbitmq.demo;

import com.rabbitmq.client.*;

import java.io.IOException;

public class MyConsumer {
    public static void main(String[] args) throws Exception {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");

        final Connection connection = factory.newConnection();
        final Channel channel = connection.createChannel();

        channel.queueDeclare("queue.ca", false, false, false, null);

        // 拉消息的模式
//        final GetResponse getResponse = channel.basicGet("queue.ca", false);
//        channel.basicReject(getResponse.getEnvelope().getDeliveryTag(), true);

        // 推消息模式
        // autoAck:false表示手动确认消息
        channel.basicConsume("queue.ca", false, "myConsumer", new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag,
                                       Envelope envelope,
                                       AMQP.BasicProperties properties,
                                       byte[] body) throws IOException {

                System.out.println(new String(body));

                // 确认消息
                // channel.basicAck(envelope.getDeliveryTag(), false);

                // 第一个参数是消息的标签，第二个参数表示不确认多个消息还是一个消息
                // 第三个参数表示不确认的消息是否需要重新入列，然后重发
                // 可以用于拒收多条消息
                // channel.basicNack(envelope.getDeliveryTag(), false, true);
                // 用于拒收一条消息
                // 对于不确认的消息，是否重新入列，然后重发
//                channel.basicReject(envelope.getDeliveryTag(), true);
                channel.basicReject(envelope.getDeliveryTag(), false);
            }
        });

//
//        channel.close();
//        connection.close();
    }
}
```

上面是通过在消费端直接配置指定ackMode，在一些比较老的spring项目中一般是通过xml方式去定义、声明和配置的，不管是XML还是注解，相关配置、属性这些其实都是大同小异，触类旁通。然后需要注意的是channel.basicAck这几个手工Ack确认的方法。

### 1.6 消费端限流

在电商的秒杀活动中，活动一开始会有大量并发写请求到达服务端，需要对消息进行削峰处理，如何削峰？

当消息投递速度远快于消费速度时，随着时间积累就会出现“消息积压”。消息中间件本身是具备一定的缓冲能力的，但这个能力是有容量限制的，如果长期运行并没有任何处理，最终会导致*Broker*崩溃，而分布式系统的故障往往会发生上下游传递，连锁反应那就会很悲剧...

下面我将从多个角度介绍QoS与限流，防止上面的悲剧发生。

1. RabbitMQ可以对**内存和磁盘使用量**设置阈值，当达到阈值后，生产者将被阻塞(block)，直到对应项指标恢复正常。全局上可以防止超大流量、消息积压等导致的Broker被压垮。当内存受限或磁盘可用空间受限的时候，服务器都会暂时阻止连接，服务器将暂停从发布消息的已连接客户端的套接字读取数据。连接心跳监视也将被禁用。所有网络连接将在rabbitmqctl和管理插件中显示为“已阻止”，这意味着它们尚未尝试发布，因此可以继续或被阻止，这意味着它们已发布，现在已暂停。兼容的客户端被阻止时将收到通知。

在/etc/rabbitmq/rabbitmq.conf中配置磁盘可用空间大小：

![](../images/13.png)

2. RabbitMQ还默认提供了一种基于**credit flow**的**流控**机制，面向每一个连接进行流控。当单个队列达到最大流速时，或者多个队列达到总流速时，都会触发流控。触发单个链接的流控可能是因为connection、channel、queue的某一个过程处于flow状态，这些状态都可以从监控平台看到。

![](../images/14.png)

![](../images/15.png)

![](../images/16.png)

3. RabbitMQ中有一种QoS保证机制，可以**限制Channel上接收到的未被Ack的消息数量**，如果超过这个数量限制RabbitMQ将不会再往消费端推送消息。这是一种流控手段，可以防止大量消息瞬时从Broker送达消费端造成消费端巨大压力（甚至压垮消费端）。比较值得注意的是**QoS机制仅对于消费端推模式有效，对拉模式无效**。而且不支持NONE Ack模式。执行channel.basicConsume 方法之前通过 channel.basicQoS方法可以设置该数量。消息的发送是异步的，消息的确认也是异步的。在消费者消费慢的时候，可以设置Qos的prefetchCount，它表示broker在向消费者发送消息的时候，一旦发送了prefetchCount个消息而没有一个消息确认的时候，就停止发送。消费者确认一个，broker就发送一个，确认两个就发送两个。换句话说，消费者确认多少，broker就发送多少，消费者等待处理的个数永远限制在prefetchCount个。

   如果对于每个消息都发送确认，增加了网络流量，此时可以批量确认消息。如果设置了multiple为true，消费者在确认的时候，比如说id是8的消息确认了，则在8之前的所有消息都确认了。

   ```java
    ConnectionFactory factory = new ConnectionFactory();
    factory.setUri("amqp://root:123456@node1:5672/%2f");
    final Connection connection = factory.newConnection();
    final Channel channel = connection.createChannel();
   
    channel.queueDeclare("queue.qos", false, false, false, null);
   
    // 使用basic做限流，仅对消息推送模式生效。
    // 表示Qos是10个消息，最多有10个消息等待确认
    channel.basicQos(10);
   
    // 表示最多10个消息等待确认。如果global设置为true，则表示只要是使用当前的channel的Consumer，该设置都生效
    // false表示仅限于当前Consumer
    //channel.basicQos(10, false);
   
    // 第一个参数表示未确认消息的大小，Rabbit没有实现，不用管。
    //channel.basicQos(1000, 10, true);
   
    channel.basicConsume("queue.qos", false, new DefaultConsumer(channel) {
        @Override
        public void handleDelivery(String consumerTag,
                                   Envelope envelope,
                                   AMQP.BasicProperties properties,
                                   byte[] body) throws IOException {
            // some code going on
            // 可以批量确认消息，减少每个消息都发送确认带来的网络流量负载。
            channel.basicAck(envelope.getDeliveryTag(), true);
        }
    });
   
   
    channel.close();
    connection.close();
   ```


生产者往往是希望自己产生的消息能快速投递出去，而当消息投递太快且超过了下游的消费速度时就容易出现消息积压/堆积，所以，从上游来讲我们应该在生产端应用程序中也可以加入限流、应急开关等控制手段，避免超过Broker端的极限承载能力或者压垮下游消费者

再看看下游，我们期望下游消费端能尽快消费完消息，而且还要防止瞬时大量消息压垮消费端（推模式），我们期望消费端处理速度是最快、最稳定而且还相对均匀（比较理想化）。

**提升下游应用的吞吐量**和**缩短消费过程的耗时**，优化主要以下几种方式：

1. 优化应用程序的性能，缩短响应时间（需要时间）

2. 增加消费者节点实例（成本增加，而且底层数据库操作这些也可能是瓶颈）

3. 调整并发消费的线程数（线程数并非越大越好，需要大量压测调优至合理值）

```java
    @Bean
    public RabbitListenerContainerFactory rabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        // SimpleRabbitListenerContainerFactory发现消息中有content_type有text 就会默认将其
        // 转换为String类型的，没有content_type都按byte[]类型 
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        // 设置并发线程数 
        factory.setConcurrentConsumers(10);
        // 设置最大并发线程数
        factory.setMaxConcurrentConsumers(20);
        return factory;
    }
```

### 1.7 消息可靠性保障

在讲高级特性的时候几乎已经都涉及到了，这里简单回顾总结下：

1. 消息传输保障

2. 各种限流、应急手段

3. 业务层面的一些容错、补偿、异常重试等手段

**消息可靠传输**一般是业务系统接入消息中间件时**首要考虑的问题**，一般消息中间件的消息传输保障分为三个层级：

1. At most once：最多一次。消息可能会丢失，但绝**不会重复**传输

2. At least once：最少一次。消息绝不会丢失，但**可能会重复**传输

3. Exactly once：恰好一次。每条消息肯定会被**传输一次且仅传输一次**

RabbitMQ支持其中的“**最多一次**”和“**最少一次**”。

其中“**最少一次**”投递实现需要考虑以下这个几个方面的内容：

1. 消息生产者需要开启事务机制或者publisher confirm 机制，以确保消息可以可靠地传输到RabbitMQ 中。

2. 消息生产者需要配合使用 mandatory 参数或者备份交换器来确保消息能够从交换器路由到队列中，进而能够保存下来而不会被丢弃。

3. 消息和队列都需要进行持久化处理，以确保RabbitMQ 服务器在遇到异常情况时不会造成消息丢失。

4. 消费者在消费消息的同时需要将autoAck 设置为false，然后通过手动确认的方式去确认已经正确消费的消息，以避免在消费端引起不必要的消息丢失。

“**最多一次**”的方式就无须考虑以上那些方面，生产者随意发送，消费者随意消费，不过这样很难确保消息不会丢失。（估计有不少公司的业务系统都是这样的，想想都觉得可怕）

“**恰好一次**”是**RabbitMQ** 目前无法保障的。

考虑这样一种情况，消费者在消费完一条消息之后向RabbitMQ 发送确认Basic.Ack 命令，此时由于网络断开或者其他原因造成RabbitMQ 并没有收到这个确认命令，那么RabbitMQ不会将此条消息标记删除。在重新建立连接之后，消费者还是会消费到这一条消息，这就造成了重复消费。

再考虑一种情况，生产者在使用publisher confirm机制的时候，发送完一条消息等待RabbitMQ返回确认通知，此时网络断开，生产者捕获到异常情况，为了确保消息可靠性选择重新发送，这样RabbitMQ 中就有两条同样的消息，在消费的时候消费者就会重复消费。

## 二. 可靠性分析

### 2.1 Firehose

在使用任何消息中间件的过程中，难免会出现消息丢失等异常情况，这个时候就需要有一个良好的机制来跟踪记录消息的过程（轨迹溯源），帮助我们**排查问题**。 

在RabbitMQ 中可以使用Firehose 功能来实现消息追踪，Firehose 可以记录每一次发送或者消费消息的记录，方便RabbitMQ 的使用者进行调试、排错等。

Firehose的原理是将生产者投递给RabbitMQ的消息，或者RabbitMQ投递给消费者的消息按照指定的格式**发送到一个默认的交换器上**。这个默认的交换器的名称为`amq.rabbitmq.trace`，它是一个topic类型的交换器。当开启Firehose功能后，所有生产者发送给交换机的消息，会被复制转发到这个交换机上，routingKey是`publish.{exchangename}` ；所有消费者消费的消息，会被复制转发到这个交换机上，routingKey是`deliver.{queuename}`。

所以我们只需要新建一个队列，然后通过`publish.{exchangename}`或`deliver.{queuename}`routingKey绑定到`amq.rabbitmq.trace`交换机上即可获取到指定交换机、队列消息的发送和消费情况。

![](../images/17.png)

开启Firehose命令：

```shell
$ rabbitmqctl trace_on [-p vhost]
```

其中[-p vhost]是可选参数，用来指定虚拟主机vhost。

对应的关闭命令为：

```shell
$ rabbitmqctl trace_off [-p vhost]
```

**Firehose** 默认情况下处于**关闭状态**，并且Firehose 的**状态是非持久化的**，会在RabbitMQ服务重启的时候还原成默认的状态。Firehose 开启之后多少会**影响RabbitMQ整体服务性能**，因为它会引起额外的消息生成、路由和存储。

### 2.2 rabbitmq_tracing插件

同时基于Firehose机制，RabbitMQ还提供了**rabbitmq_tracing插件**相当于Firehose的GUI版本，它同样能跟踪RabbitMQ中消息的流入流出情况。rabbitmq_tracing插件同样会对流入流出的消息进行封装，然后将封装后的**消息日志存入相应的trace文件中**，这样就不用我们去手动消费Firehose中的代码。

可以使用下列命令开启插件：

```shell
$ rabbitmq-plugins enable rabbitmq_tracing
```

![](../images/18.png)

然后使用下列命令关闭插件：

```shell
$ rabbitmq-plugins disable rabbitmq_tracing
```

开启rabbitmq_tracing插件后，我们就可以在控制台进行配置了：

![](../images/19.png)

配置好后发送消息，就可以看到跟踪的结果了：

![](../images/20.png)

## 三. TTL机制

TTL，Time to Live的简称，即过期时间。

RabbitMQ可以对消息和队列两个维度类设置TTL。

任何消息中间件的容量和堆积能力都是有限的，如果有一些消息总是不被消费掉，那么需要有一种过期的机制来做兜底。

目前有两种方法可以设置消息的TTL：

1. 通过Queue属性设置，队列中所有消息都有相同的过期时间。
2. 对消息自身进行单独设置，每条消息的TTL可以不同。

如果两种方法一起使用，则消息的TTL以两者之间**较小数值为准**。通常来讲，消息在队列中的生存时间一旦超过设置的66.值时，就会变成Ŗ死信TTL值时，消费者默认就无法再收到该消息。当然，“死信”也是可以被取出来消费的，下一小节我们会讲解。

```java
ConnectionFactory factory = new ConnectionFactory();
factory.setUri("amqp://root:123456@node1:5672/%2f");

try (final Connection connection = factory.newConnection();
     final Channel channel = connection.createChannel()) {

    Map<String, Object> arguments = new HashMap<>();
    //消息队列中消息过期时间，10s
    arguments.put("x-message-ttl", 10 * 1000);
    //如果消息队列没有消费者，则60s后消息过期，消息队列也删除
    arguments.put("x-expires", 60 * 1000);

    channel.queueDeclare("queue.ttl.waiting",
            true,
            false,
            false,
            arguments);

    channel.exchangeDeclare("ex.ttl.waiting",
            "direct",
            true,
            false,
            null);

    channel.queueBind("queue.ttl.waiting", "ex.ttl.waiting", "key.ttl.waiting");

    final AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
            .contentEncoding("utf-8")
            .deliveryMode(2)   // 持久化的消息
            .expiration("5000") //此条消息的过期时间
            .build();

    channel.basicPublish("ex.ttl.waiting",
            "key.ttl.waiting",
            properties,
            "等待的订单号".getBytes("utf-8"));


} catch (Exception ex) {
    ex.printStackTrace();
}
```

## 四. 死信队列

在定义业务队列时可以考虑指定一个 死信交换机，并绑定一个死信队列。当消息变成死信时，该消息就会被发送到该死信队列上，这样方便我们查看消息失败的原因。

DLX，全称为Dead-Letter-Exchange，死信交换器。消息在一个队列中变成死信（Dead Letter）之后，被重新发送到一个特殊的交换器（DLX）中，同时，绑定DLX的队列就称为“**死信队列**”。

**以下几种情况导致消息变为死信**：

1. 消息被拒绝（Basic.Reject/Basic.Nack），并且设置requeue参数为false； 

2. 消息过期；

3. 队列达到最大长度

对于RabbitMQ 来说，DLX 是一个非常有用的特性。它可以处理异常情况下，消息不能够被消费者正确消费(消费者调用了Basic.Nack 或Basic.Reject)而被置入死信队列中的情况，后续分析程序可以通过消费这个死信队列中的内容来分析当时所遇到的异常情况，进而可以改善和优化系统。

```java
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

import java.util.HashMap;
import java.util.Map;

public class Producer {
    public static void main(String[] args) throws Exception {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri("amqp://root:123456@node1:5672/%2f");

        try (final Connection connection = factory.newConnection();
             final Channel channel = connection.createChannel()) {

//            正常业务的交换器
            channel.exchangeDeclare("ex.biz", "direct", true);
//            声明死信交换器 DLX
            channel.exchangeDeclare("ex.dlx", "direct", true);
//            声明队列做死信队列
            channel.queueDeclare("queue.dlx", true, false, false, null);
//            绑定死信交换器和死信队列
            channel.queueBind("queue.dlx", "ex.dlx", "key.dlx");

            Map<String, Object> arguments = new HashMap<>();
//            指定消息队列中的消息过期时间
            arguments.put("x-message-ttl", 10000);

//            指定过期消息通过死信交换器发送到死信队列，死信交换器的名称，DLX
            arguments.put("x-dead-letter-exchange", "ex.dlx");
//            指定死信交换器的路由键
            arguments.put("x-dead-letter-routing-key", "key.dlx");

            channel.queueDeclare("queue.biz", true, false, false, arguments);
//            绑定业务的交换器和消息队列
            channel.queueBind("queue.biz", "ex.biz", "key.biz");

            channel.basicPublish("ex.biz", "key.biz", null, "orderid.45789987678".getBytes());

        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
}
```

