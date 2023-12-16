# RocketMQ消息过滤机制源码详解

RocketMQ提供了2种消息过滤的方式：

- TAG 过滤

- SQL92 过滤

> SQL过滤默认是没有打开的，如果想要支持，必须在broker的配置文件中设置：**enablePropertyFilter = true**

## 一. 示例代码

### 1.1 producer 代码

```java
public class Producer {

    public static void main(String[] args) throws Exception {

        // 实例化消息生产者Producer
        DefaultMQProducer producer = new DefaultMQProducer("tag_p_g");
        // 设置NameServer的地址
        producer.setNamesrvAddr("127.0.0.1:9876");

        producer.start();

        String[] tags = {"TAG_A", "TAG_B", "TAG_C"};

        for (int i = 0; i < 10 ; i++) {

            byte[] body = ("Hi filter message," + i).getBytes();
            String tag = tags[i % tags.length];

            //同一个topic下，会发送多种tag消息
            Message msg = new Message("MY_topic", tag, body);
            
            //设置一些属性,消费者SQL过滤时可以使用
            msg.putUserProperty("age", String.valueOf(i));
            msg.putUserProperty("name", "name" + (i + 1));
            msg.putUserProperty("isGender", String.valueOf(new Random().nextBoolean()));

            SendResult sendResult = producer.send(msg);

            System.out.println("sendResult = " + sendResult);
        }


        producer.shutdown();
    }
}
```

### 1.2 consumer 代码

#### 1.2.1 TAG过滤

```java
public class Consumer {

    public static void main(String[] args) throws Exception {

        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("c_tag_group");

        consumer.setNamesrvAddr("127.0.0.1:9876");

        /**
         * 订阅消息过滤
         * 只订阅 topic = MY_topic 下
         * tag = TAG_A 或者 tag = TAG_C 的消息,不要 tag = TAG_B 的消息
         * 订阅多个tag使用 || 分开
         */
        consumer.subscribe("MY_topic", "TAG_A || TAG_C");

        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext context) {

                for (MessageExt msg : msgs) {
                    System.out.println(msg);
                }

                //消费成功时返回
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });

        consumer.start();

        System.out.println("Filter Tag Consumer Started");
    }
}
```

#### 1.2.2 SQL92过滤

```java
public class Consumer {

    public static void main(String[] args) throws Exception {

        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("cg");

        consumer.setNamesrvAddr(MQConstant.NAME_SERVER_ADDR);

        /**
         * 订阅消息过滤: 根据消息生产者指定的用户属性进行过滤
         * 支持的常量类型：
         *   数值：比如：123，3.1415
         *   字符：必须用单引号包裹起来，比如：'abc'
         *   布尔：TRUE 或 FALSE
         *   NULL：特殊的常量，表示空
         *
         * 支持的运算符有：
         *   数值比较：>，>=，<，<=，BETWEEN，=
         *   字符比较：=，<>，IN
         *   逻辑运算 ：AND，OR，NOT
         *   NULL判断：IS NULL 或者 IS NOT NULL
         *
         *   // (age between 6 and 9) AND (name IS NOT NULL) AND (isGender = TRUE)
         */
        consumer.subscribe(MQConstant.FILTER_SQL_TOPIC, MessageSelector.bySql("(age between 6 and 9) AND (name IS NOT NULL) AND (isGender = TRUE)"));

        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext context) {

                for (MessageExt msg : msgs) {
                    System.out.println(msg);
                }

                //消费成功时返回
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });

        consumer.start();

        System.out.println("Filter SQL Consumer Started");
    }
}
```

## 二. 说明

消费者去broker拉取消息时,先经过broker过滤一次，在经过消费者过滤一次

1. 如果是 TAG 过滤。broker要先根据ConsumeQueue 中 Tag HashCode过滤一次，消费者在根据 Tag 值过滤一次。因为 ConsumeQueue 为了便于检索，文件中每一个条目都是定长20字节，所以条目在最后八个字节存储的是消息 Tag 的 HashCode，而不是 Tag 值。这样broker在拉取磁盘中的消息时，只需要对比 ConsumeQueue中 的Tag HashCode，而不需要解析 CommitLog 中的 Tag 值，如果发生Hash冲突，则交给消费者客户端过滤消息中的Tag值。
2. 如果是 SQL92 过滤。则全部由 broker 过滤。因为 SQL 过滤的是消息中的属性值，所以必须反序列化 CommitLog 中的属性值，既然在broker已经进行了精确匹配，那么客户端自然可以省去这个步骤了。

## 三. 消费者启动注册订阅信息到broker

consumer订阅信息会保存到`SubscriptionData`中，当consumer启动后，会通过心跳先将订阅信息发送到broker。broker主要是构建2部分：

1. 保存consumer发送的订阅信息`SubscriptionData`对象。
2. 构建SQL过滤的`ConsumerFilterData`对象。

那么我们看下consumer构建订阅数据以及发送到broker的过程：

```java
// org.apache.rocketmq.client.impl.consumer.DefaultMQPushConsumerImpl#subscribe(java.lang.String, org.apache.rocketmq.client.consumer.MessageSelector)
public void subscribe(final String topic, final MessageSelector messageSelector) throws MQClientException {
    try {
        if (messageSelector == null) {
            subscribe(topic, SubscriptionData.SUB_ALL);
            return;
        }
        
        //核心就是创建SubscriptionData
        SubscriptionData subscriptionData = FilterAPI.build(topic,
            messageSelector.getExpression(), messageSelector.getExpressionType());

        this.rebalanceImpl.getSubscriptionInner().put(topic, subscriptionData);
        if (this.mQClientFactory != null) {
            this.mQClientFactory.sendHeartbeatToAllBrokerWithLock();
        }
    } catch (Exception e) {
        throw new MQClientException("subscription exception", e);
    }
}
```

继续看`FilterAPI.build(...)`方法：

```java
// org.apache.rocketmq.common.filter.FilterAPI#build
public static SubscriptionData build(final String topic, final String subString,
        final String type) throws Exception {
        // 如果是TAG过滤，则执行这里
        if (ExpressionType.TAG.equals(type) || type == null) {
            return buildSubscriptionData(topic, subString);
        }

        if (subString == null || subString.length() < 1) {
            throw new IllegalArgumentException("Expression can't be null! " + type);
        }

        // 如果是SQL过滤，则执行这里，相对简单，直接原样发送给broker
        SubscriptionData subscriptionData = new SubscriptionData();
        subscriptionData.setTopic(topic);
        subscriptionData.setSubString(subString);
        subscriptionData.setExpressionType(type);

        return subscriptionData;
    }
}
```

如果是TAG过滤，consumer会做些额外的处理：

```java
// org.apache.rocketmq.common.filter.FilterAPI#buildSubscriptionData 
public static SubscriptionData buildSubscriptionData(final String consumerGroup, String topic,
        String subString) throws Exception {
        SubscriptionData subscriptionData = new SubscriptionData();
        subscriptionData.setTopic(topic);
        subscriptionData.setSubString(subString);

        if (null == subString || subString.equals(SubscriptionData.SUB_ALL) || subString.length() == 0) {
            // 订阅所有消息
            subscriptionData.setSubString(SubscriptionData.SUB_ALL);
        } else {
            // 如果订阅的不是*,则通过 || 分割
            String[] tags = subString.split("\\|\\|");
            if (tags.length > 0) {
                for (String tag : tags) {
                    if (tag.length() > 0) {
                        String trimString = tag.trim();
                        if (trimString.length() > 0) {
                            // 保存分割后的TAG值
                            subscriptionData.getTagsSet().add(trimString);
                            // 保存分割后的TAG HashCode
                            subscriptionData.getCodeSet().add(trimString.hashCode());
                        }
                    }
                }
            } else {
                throw new Exception("subString split error");
            }
        }

        return subscriptionData;
    }
```

这样consumer的订阅信息就准备好了，然后consumer启动，发送心跳数据：

```java
//org.apache.rocketmq.client.impl.consumer.DefaultMQPushConsumerImpl#start

public synchronized void start() throws MQClientException {
    //......代码省略.......
    
    // 发送心跳
    this.mQClientFactory.sendHeartbeatToAllBrokerWithLock();
    
    //......代码省略.......
}
```

我们再看下broker是如何处理心跳数据的：

```java
public class ClientManageProcessor implements NettyRequestProcessor {

    @Override
    public RemotingCommand processRequest(ChannelHandlerContext ctx, RemotingCommand request)
        throws RemotingCommandException {
        switch (request.getCode()) {
			// 接收客户端心跳指令,保存客户端信息
            case RequestCode.HEART_BEAT:
                return this.heartBeat(ctx, request);
            case RequestCode.UNREGISTER_CLIENT:
                return this.unregisterClient(ctx, request);
            case RequestCode.CHECK_CLIENT_CONFIG:
                return this.checkClientConfig(ctx, request);
            default:
                break;
        }
        return null;
    }
}
```

heartBeat方法：

```java
// org.apache.rocketmq.broker.processor.ClientManageProcessor#heartBeat 
public RemotingCommand heartBeat(ChannelHandlerContext ctx, RemotingCommand request) {

        // 处理消费者心跳
        for (ConsumerData data : heartbeatData.getConsumerDataSet()) {
            SubscriptionGroupConfig subscriptionGroupConfig =
                this.brokerController.getSubscriptionGroupManager().findSubscriptionGroupConfig(
                    data.getGroupName());
            //...

            // 注册消费者信息
            boolean changed = this.brokerController.getConsumerManager().registerConsumer(
                data.getGroupName(),
                clientChannelInfo,
                data.getConsumeType(),
                data.getMessageModel(),
                data.getConsumeFromWhere(),
                data.getSubscriptionDataSet(),
                isNotifyConsumerIdsChangedEnable
            );

            // ...
        }

     	// ...
       
        return response;
    }
```

继续往下走：

```java
// org.apache.rocketmq.broker.client.ConsumerManager#registerConsumer
public boolean registerConsumer(final String group, final ClientChannelInfo clientChannelInfo,
    ConsumeType consumeType, MessageModel messageModel, ConsumeFromWhere consumeFromWhere,
    final Set<SubscriptionData> subList, boolean isNotifyConsumerIdsChangedEnable) {

    //...
    
    // 更新topic下消费组信息
    boolean r2 = consumerGroupInfo.updateSubscription(subList);

    //...
    
    
    this.consumerIdsChangeListener.handle(ConsumerGroupEvent.REGISTER, group, subList);

    //...
}
```

继续往里走：

```java
// org.apache.rocketmq.broker.filter.ConsumerFilterManager#register(java.lang.String, java.lang.String, java.lang.String, java.lang.String, long)
public boolean register(final String topic, final String consumerGroup, final String expression,
    final String type, final long clientVersion) {
    // 如果是TAG 过滤，则退出
    if (ExpressionType.isTagType(type)) {
        return false;
    }

    // 如果是SQL过滤，但没有指定过滤规则，则退出
    if (expression == null || expression.length() == 0) {
        return false;
    }

    FilterDataMapByTopic filterDataMapByTopic = this.filterDataByTopic.get(topic);

    if (filterDataMapByTopic == null) {
        FilterDataMapByTopic temp = new FilterDataMapByTopic(topic);
        FilterDataMapByTopic prev = this.filterDataByTopic.putIfAbsent(topic, temp);
        filterDataMapByTopic = prev != null ? prev : temp;
    }

    BloomFilterData bloomFilterData = bloomFilter.generate(consumerGroup + "#" + topic);

    // 构建SQL过滤的ConsumerFilterData
    return filterDataMapByTopic.register(consumerGroup, expression, type, bloomFilterData, clientVersion);
}

```

注册方法内部主要就是构建`ConsumerFilterData`对象：

```java
// org.apache.rocketmq.broker.filter.ConsumerFilterManager#build
public static ConsumerFilterData build(final String topic, final String consumerGroup,
    final String expression, final String type,
    final long clientVersion) {
    if (ExpressionType.isTagType(type)) {
        return null;
    }

    ConsumerFilterData consumerFilterData = new ConsumerFilterData();
    consumerFilterData.setTopic(topic);
    consumerFilterData.setConsumerGroup(consumerGroup);
    consumerFilterData.setBornTime(System.currentTimeMillis());
    consumerFilterData.setDeadTime(0);
    consumerFilterData.setExpression(expression);
    consumerFilterData.setExpressionType(type);
    consumerFilterData.setClientVersion(clientVersion);
    try {
        consumerFilterData.setCompiledExpression(
            FilterFactory.INSTANCE.get(type).compile(expression)
        );
    } catch (Throwable e) {
        log.error("parse error: expr={}, topic={}, group={}, error={}", expression, topic, consumerGroup, e.getMessage());
        return null;
    }

    return consumerFilterData;
}
```

最终工作的就是：

```java
public class SqlFilter implements FilterSpi {

    @Override
    public Expression compile(final String expr) throws MQFilterException {
        return SelectorParser.parse(expr);
    }

    @Override
    public String ofType() {
        return ExpressionType.SQL92;
    }
}
```

好了，到这里就铺垫好了，接下来我们继续看消息过滤的过程，这个过程中，上面的2个对象将会工作。

## 四. 拉取消息

> broker处理拉取请求的处理器：PullMessageProcessor 方法内容比较多，还是关注和过滤相关的部分

```java
// org.apache.rocketmq.broker.processor.PullMessageProcessor#processRequest(io.netty.channel.Channel, org.apache.rocketmq.remoting.protocol.RemotingCommand, boolean)
private RemotingCommand processRequest(final Channel channel, RemotingCommand request, boolean brokerAllowSuspend)
    throws RemotingCommandException {
    RemotingCommand response = RemotingCommand.createResponseCommand(PullMessageResponseHeader.class);
    final PullMessageResponseHeader responseHeader = (PullMessageResponseHeader) response.readCustomHeader();
    final PullMessageRequestHeader requestHeader =
        (PullMessageRequestHeader) request.decodeCommandCustomHeader(PullMessageRequestHeader.class);

   
    // .......省略诸多代码........

    SubscriptionData subscriptionData = null;
    ConsumerFilterData consumerFilterData = null;
    // 这里是false, consumer启动时已经将订阅信息发送到了broker，拿来即用即可
    if (hasSubscriptionFlag) {
        try {
            subscriptionData = FilterAPI.build(
                requestHeader.getTopic(), requestHeader.getSubscription(), requestHeader.getExpressionType()
            );
            if (!ExpressionType.isTagType(subscriptionData.getExpressionType())) {
                consumerFilterData = ConsumerFilterManager.build(
                    requestHeader.getTopic(), requestHeader.getConsumerGroup(), requestHeader.getSubscription(),
                    requestHeader.getExpressionType(), requestHeader.getSubVersion()
                );
                assert consumerFilterData != null;
            }
        } catch (Exception e) {
            log.warn("Parse the consumer's subscription[{}] failed, group: {}", requestHeader.getSubscription(),
                requestHeader.getConsumerGroup());
            response.setCode(ResponseCode.SUBSCRIPTION_PARSE_FAILED);
            response.setRemark("parse the consumer's subscription failed");
            return response;
        }
    } else {
        ConsumerGroupInfo consumerGroupInfo =
            this.brokerController.getConsumerManager().getConsumerGroupInfo(requestHeader.getConsumerGroup());
        
        // ....省略判断.......

        // 获取订阅数据，这个就是consumer启动时发送给broker的
        subscriptionData = consumerGroupInfo.findSubscriptionData(requestHeader.getTopic());
         
        // .....省略判断.......
         
        // SQL过滤 
        if (!ExpressionType.isTagType(subscriptionData.getExpressionType())) {
            //TODO:前面分析consumer心跳时看到了它，SQL过滤时会创建
            consumerFilterData = this.brokerController.getConsumerFilterManager().get(requestHeader.getTopic(),
                requestHeader.getConsumerGroup());
            
            // ....省略判断......
        }
    }

    // .....省略判断.......

    MessageFilter messageFilter;
    if (this.brokerController.getBrokerConfig().isFilterSupportRetry()) {
        messageFilter = new ExpressionForRetryMessageFilter(subscriptionData, consumerFilterData,
            this.brokerController.getConsumerFilterManager());
    } else {
        // 创建MessageFilter
        messageFilter = new ExpressionMessageFilter(subscriptionData, consumerFilterData,
            this.brokerController.getConsumerFilterManager());
    }


    // 从broker 拉取消息
    final GetMessageResult getMessageResult =
        this.brokerController.getMessageStore().getMessage(requestHeader.getConsumerGroup(), requestHeader.getTopic(),
            requestHeader.getQueueId(), requestHeader.getQueueOffset(), requestHeader.getMaxMsgNums(), messageFilter);
            
            
   //....省略大量代码.....和过滤无关        
}      
```

接下来我们就看下从 CommitLog 读取消息并过滤的过程：

```java
// org.apache.rocketmq.store.DefaultMessageStore#getMessage
public GetMessageResult getMessage(final String group, final String topic, final int queueId, final long offset,
    final int maxMsgNums,
    final MessageFilter messageFilter) {
    
       // .....省略大篇幅代码.......
    
            // 在去commitlog读取消息之前，对ConsumeQueue条目进行 tag hashcode 过滤
            if (messageFilter != null
                && !messageFilter.isMatchedByConsumeQueue(isTagsCodeLegal ? tagsCode : null, extRet ? cqExtUnit : null)) {
                if (getResult.getBufferTotalSize() == 0) {
                    status = GetMessageStatus.NO_MATCHED_MESSAGE;
                }

                continue;
            }

            // 从CommitLog 读取消息
            SelectMappedBufferResult selectResult = this.commitLog.getMessage(offsetPy, sizePy);
            if (null == selectResult) {
                if (getResult.getBufferTotalSize() == 0) {
                    status = GetMessageStatus.MESSAGE_WAS_REMOVING;
                }

                nextPhyFileStartOffset = this.commitLog.rollNextFile(offsetPy);
                continue;
            }

            // 在从commitlog读取消息之后，进行 SQL 过滤
            if (messageFilter != null
                && !messageFilter.isMatchedByCommitLog(selectResult.getByteBuffer().slice(), null)) {
                if (getResult.getBufferTotalSize() == 0) {
                    status = GetMessageStatus.NO_MATCHED_MESSAGE;
                }
                // release...
                selectResult.release();
                continue;
            }

                        
}
```

主要就是做3件事：

1. 在去 CommitLog 读取消息之前，先根据 TAG hashcode 过滤一次 ConsumeQueue 中的条目，如果ConsumeQueue中保存Tag HashCode与消费组需要消费Tag HashCode不一致，则不会读取CommitLog中的消息了。

> broker先完成tag hashcode 过滤，consumer进一步完成tag 值过滤。

2. 去 CommitLog 读取消息
3. 从 CommitLog 读取出消息之后，如果是SQL过滤，则在broker完成过滤。

### 4.1 Broker完成 TAG HashCode 过滤

TAG 过滤就是`ExpressionMessageFilter#isMatchedByConsumeQueue(..)`方法：

```java
@Override
public boolean isMatchedByConsumeQueue(Long tagsCode, ConsumeQueueExt.CqExtUnit cqExtUnit) {
    if (null == subscriptionData) {
        return true;
    }

    if (subscriptionData.isClassFilterMode()) {
        return true;
    }

    // by tags code.
    if (ExpressionType.isTagType(subscriptionData.getExpressionType())) {

        if (tagsCode == null) {
            return true;
        }

        if (subscriptionData.getSubString().equals(SubscriptionData.SUB_ALL)) {
            return true;
        }

        // 根据tag hashcode 过滤
        return subscriptionData.getCodeSet().contains(tagsCode.intValue());
    } else {
    
       // ....省略else.....
    }

    return true;
}
```

这个方法内部会完成TAG 的hashcode 过滤，不过这里只是TAG的初步过滤，因为两个不同TAG也可能有相同的hashcode,所以这里过滤并不完善，真正的TAG过滤是交给消费者来完成的。

### 4.2 Broker完成 SQL 过滤

SQL的过滤是在`ExpressionMessageFilter#isMatchedByCommitLog(..)`方法中：

```java
@Override
public boolean isMatchedByCommitLog(ByteBuffer msgBuffer, Map<String, String> properties) {
    if (subscriptionData == null) {
        return true;
    }

    if (subscriptionData.isClassFilterMode()) {
        return true;
    }

    // 如果是TAG过滤，则直接退出
    if (ExpressionType.isTagType(subscriptionData.getExpressionType())) {
        return true;
    }

    // SQL过滤的数据（sql表达式等等)
    ConsumerFilterData realFilterData = this.consumerFilterData;
    Map<String, String> tempProperties = properties;

    // .....校验code.....

    Object ret = null;
    try {
        MessageEvaluationContext context = new MessageEvaluationContext(tempProperties);

        ret = realFilterData.getCompiledExpression().evaluate(context);
    } catch (Throwable e) {
        log.error("Message Filter error, " + realFilterData + ", " + tempProperties, e);
    }

    log.debug("Pull eval result: {}, {}, {}", ret, realFilterData, tempProperties);

    if (ret == null || !(ret instanceof Boolean)) {
        return false;
    }

    return (Boolean) ret;
}
```

这里会根据SQL进行过滤，如果该条消息是消费者想要的，则将其放入容器中，返回给消费者，如果不是消费者想要的，则直接丢弃，继续查询下一条消息。

> 这里的丢弃只是不返回给消费者，在清除 CommitLog 文件之前，这条消息都是在的。

## 五. 消费消息

前面说了，如果是TAG 过滤，则Broker会率先完成一次TAG Hashcode过滤，但是这样过滤并不完全，因为不同TAG可能有相同Hashcode,所以消费者要根据TAG 值完成最后的过滤。

> 如果是SQL过滤，只能由Broker完成，消费者不做其他任何操作。

那么我们还是看消费者消费消息时的过滤逻辑：

```java
// org.apache.rocketmq.client.impl.consumer.DefaultMQPushConsumerImpl#pullMessage
public void pullMessage(final PullRequest pullRequest) {
   
    //......

    PullCallback pullCallback = new PullCallback() {
        @Override
        public void onSuccess(PullResult pullResult) {
            if (pullResult != null) {
                // 处理拉取结果，这里将会完成TAG的值过滤
                pullResult = DefaultMQPushConsumerImpl.this.pullAPIWrapper.processPullResult(pullRequest.getMessageQueue(), pullResult,
                    subscriptionData);
            }
            
        //.......
    }
    
    //.......
}
```

那么我们继续看下它的内部实现：

```java
// org.apache.rocketmq.client.impl.consumer.PullAPIWrapper#processPullResult
public PullResult processPullResult(final MessageQueue mq, final PullResult pullResult,
    final SubscriptionData subscriptionData) {
    PullResultExt pullResultExt = (PullResultExt) pullResult;

    this.updatePullFromWhichNode(mq, pullResultExt.getSuggestWhichBrokerId());
    if (PullStatus.FOUND == pullResult.getPullStatus()) {
        ByteBuffer byteBuffer = ByteBuffer.wrap(pullResultExt.getMessageBinary());
        List<MessageExt> msgList = MessageDecoder.decodes(byteBuffer);

        List<MessageExt> msgListFilterAgain = msgList;
        // 根据TAG 值过滤
        if (!subscriptionData.getTagsSet().isEmpty() && !subscriptionData.isClassFilterMode()) {
            msgListFilterAgain = new ArrayList<MessageExt>(msgList.size());
            for (MessageExt msg : msgList) {
                if (msg.getTags() != null) {
                    if (subscriptionData.getTagsSet().contains(msg.getTags())) {
                        msgListFilterAgain.add(msg);
                    }
                }
            }
        }
        
        // 将过滤后的消息给消费者消费
        pullResultExt.setMsgFoundList(msgListFilterAgain);

        //........
    }

    return pullResult;
}
```

## 六. 总结

1. RocketMQ支持两种方式的消息过滤：TAG/SQL
2. 要想使用SQL过滤，必须要在broker中配置：`enablePropertyFilter = true`
3. TAG 过滤分两个阶段完成：

- 第一阶段：broker率先根据tag的hashcode完成过滤
- 第二阶段：consumer根据tag值完成最后的过滤

4. SQL过滤只能在Broker中完成