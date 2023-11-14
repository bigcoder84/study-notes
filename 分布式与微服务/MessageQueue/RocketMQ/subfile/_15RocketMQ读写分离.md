# RocketMQ读写分离机制

## 一. 主从复制

RocketMQ为了提高消费的高可用性，避免Broker发生单点故障引起Broker上的消息无法及时消费，同时避免单个机器上硬盘坏损出现消费数据丢失。

RocketMQ采用Broker数据主从复制机制，当消息发送到Master服务器后会将消息同步到Slave服务器，如果Master服务器宕机，消息消费者还可以继续从Slave拉取消息。

消息从Master服务器复制到Slave服务器上，有两种复制方式：同步复制`SYNC_MASTER`和异步复制`ASYNC_MASTER`。

**通过配置文件conf/broker.conf文件配置：**

```java
brokerClusterName = DefaultCluster
brokerName = broker-a
brokerId = 0
deleteWhen = 04
fileReservedTime = 48
brokerRole = ASYNC_MASTER
flushDiskType = ASYNC_FLUSH
```

对brokerRole参数进行设置：

**同步复制：** Master和Slave都写成功后才返回客户端写成功的状态。

- **优点：** Master服务器出现故障，Slave服务器上有全部数据的备份，很容易恢复到Master服务器。
- **缺点：** 由于多了一个同步等待的步骤，增加数据写入延迟，降低系统吞吐量。

**异步复制：** 仅Master服务器写成功即可返回给客户端写成功的状态。

- **优点：** 没有同步等待的步骤，低延迟，高吞吐。
- **缺点：** 如果Master服务器出现故障，有些数据可能未写入Slave服务器，未同步的数据可能丢失

实际应用中，需要结合业务场景，合理设置刷盘方式和主从复制方式。不建议使用同步刷盘方式，因为它频繁触发写磁盘操作，性能下降很明显。**通常把`Master`和`Slave`设置为异步刷盘，同步复制，保证数据不丢失**。这样即使一台服务器出故障，仍然可以保证数据不丢失。

## 二. 读写分离

读写分离机制是高性能、高可用架构中常见的设计，例如MySQL实现读写分离机制，Client只能从Master服务器写数据，可以从Master服务器和Slave服务器都读数据。

RocketMQ的 `Consumer` 在拉取消息时，Broker 会判断 Master 服务器的消息堆积量来决定 Consumer 是否从 Slave 服务器拉取消息消费。默认一开始从 Master 服务器拉群消息，如果 Master 服务器的消息堆积超过物理内存40%，则会返回给 Consumer 的消息结果并告知Consumer，下次从其他 Slave 服务器上拉取消息。

RocketMQ 有属于自己的一套读写分离逻辑，会判断主服务器的消息堆积量来决定消费者是否向从服务器拉取消息消费。

`Consumer` 在向 Broker 发送消息拉取请求时，会根据筛选出来的消息队列，判定是从 Master，还是从 Slave 拉取消息，默认是 Master。

Broker 接收到消息消费者拉取请求，在获取本地堆积的消息量后，会计算服务器的消息堆积量是否大于物理内存的一定值，如果是，则标记下次从 Slave服务器拉取，计算 Slave服务器的 Broker Id，并响应给消费者。

Consumer在接收到 Broker的响应后，会把消息队列与建议下一次拉取节点的 Broker Id 关联起来，并缓存在内存中，以便下次拉取消息时，确定从哪个节点发送请求。

```java
public class GetMessageResult {

    private final List<SelectMappedBufferResult> messageMapedList =
        new ArrayList<SelectMappedBufferResult>(100);
    private final List<ByteBuffer> messageBufferList = new ArrayList<ByteBuffer>(100);
    private GetMessageStatus status;
    private long nextBeginOffset;
    private long minOffset;
    private long maxOffset;
    private int bufferTotalSize = 0;
    // 标识是否通过Slave拉拉取消息
    private boolean suggestPullingFromSlave = false;
    private int msgCount4Commercial = 0;
}

// 针对消息堆积量过大会切换到Slave进行查询。
// maxOffsetPy 为当前最大物理偏移量，maxPhyOffsetPulling 为本次消息拉取最大物理偏移量，他们的差即可表示消息堆积量。
// TOTAL_PHYSICAL_MEMORY_SIZE 表示当前系统物理内存，accessMessageInMemoryMaxRatio 的默认值为 40，
// 以上逻辑即可算出当前消息堆积量是否大于物理内存的 40%，如果大于则将 suggestPullingFromSlave 设置为 true。
// org.apache.rocketmq.store.DefaultMessageStore#getMessage
public GetMessageResult getMessage(final String group, final String topic, final int queueId, final long offset,
        final int maxMsgNums,
        final MessageFilter messageFilter) {
    // ..........
    
    // diff：是 maxOffsetPy 和 maxPhyOffsetPulling 两者的差值，表示还有多少消息没有拉取
    long diff = maxOffsetPy - maxPhyOffsetPulling;
    // StoreUtil.TOTAL_PHYSICAL_MEMORY_SIZE：表示当前 Master Broker 全部的物理内存大小。
    long memory = (long) (StoreUtil.TOTAL_PHYSICAL_MEMORY_SIZE
        * (this.messageStoreConfig.getAccessMessageInMemoryMaxRatio() / 100.0));
    // 如果消息堆积大于内存 40% 则建议从Slave Broker拉取消息（实现读写分离）
    getResult.setSuggestPullingFromSlave(diff > memory);
    
    
    // ..........
}
```

- 决定消费者是否向从服务器拉取消息消费的值存在 `GetMessageResult `类中。
- `suggestPullingFromSlave`的默认值为 false，即默认消费者不会消费从服务器，但它会在消费者发送消息拉取请求时，动态改变该值，Broker 接收、处理消费者拉取消息请求。
- 针对本MessageQueue消息堆积量过大会切换到Slave进行查询，maxOffsetPy 为当前最大物理偏移量，`maxPhyOffsetPulling `为本次消息拉取最大物理偏移量，他们的差即可表示消息堆积量，当前消息堆积量是否大于物理内存的 40% 就会切换到Slave进行查询。

```java
public class PullMessageResponseHeader implements CommandCustomHeader {
    // suggestWhichBrokerId标识从哪个broker进行查询
    private Long suggestWhichBrokerId;
    private Long nextBeginOffset;
    private Long minOffset;
    private Long maxOffset;
}


public class PullMessageProcessor implements NettyRequestProcessor {

    private RemotingCommand processRequest(final Channel channel, RemotingCommand request, boolean brokerAllowSuspend)
        throws RemotingCommandException {
        RemotingCommand response = RemotingCommand.createResponseCommand(PullMessageResponseHeader.class);
        final PullMessageResponseHeader responseHeader = (PullMessageResponseHeader) response.readCustomHeader();
        final PullMessageRequestHeader requestHeader =
            (PullMessageRequestHeader) request.decodeCommandCustomHeader(PullMessageRequestHeader.class);

        response.setOpaque(request.getOpaque());

        final GetMessageResult getMessageResult =
            this.brokerController.getMessageStore().getMessage(requestHeader.getConsumerGroup(), requestHeader.getTopic(),
                requestHeader.getQueueId(), requestHeader.getQueueOffset(), requestHeader.getMaxMsgNums(), messageFilter);

        if (getMessageResult != null) {
            response.setRemark(getMessageResult.getStatus().name());
            responseHeader.setNextBeginOffset(getMessageResult.getNextBeginOffset());
            responseHeader.setMinOffset(getMessageResult.getMinOffset());
            responseHeader.setMaxOffset(getMessageResult.getMaxOffset());

            // 建议从slave消费消息
            if (getMessageResult.isSuggestPullingFromSlave()) {
                // 从slave查询
                responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getWhichBrokerWhenConsumeSlowly());
            } else {
                // 从master查询
                responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
            }

            switch (this.brokerController.getMessageStoreConfig().getBrokerRole()) {
                case ASYNC_MASTER:
                case SYNC_MASTER:
                    break;
                case SLAVE:
                    // 针对SLAVE需要判断是否可读，不可读的情况下读MASTER
                    if (!this.brokerController.getBrokerConfig().isSlaveReadEnable()) {
                        response.setCode(ResponseCode.PULL_RETRY_IMMEDIATELY);
                        responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
                    }
                    break;
            }

            if (this.brokerController.getBrokerConfig().isSlaveReadEnable()) {
                // consume too slow ,redirect to another machine
                if (getMessageResult.isSuggestPullingFromSlave()) {
                    responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getWhichBrokerWhenConsumeSlowly());
                }
                // consume ok
                else {
                    responseHeader.setSuggestWhichBrokerId(subscriptionGroupConfig.getBrokerId());
                }
            } else {
                responseHeader.setSuggestWhichBrokerId(MixAll.MASTER_ID);
            }
        }

        return response;
    }
}
```

`PullMessageResponseHeader`的`suggestWhichBrokerId`标识某个`MessageQueue`的消息从具体的brokerId进行查询。
针对Slave不可读的情况会设置为从MASTER_ID进行查询。

```java
public class PullAPIWrapper {
    private final InternalLogger log = ClientLogger.getLog();
    private final MQClientInstance mQClientFactory;
    private final String consumerGroup;
    private final boolean unitMode;
    private ConcurrentMap<MessageQueue, AtomicLong/* brokerId */> pullFromWhichNodeTable =
        new ConcurrentHashMap<MessageQueue, AtomicLong>(32);
    private volatile boolean connectBrokerByUser = false;
    private volatile long defaultBrokerId = MixAll.MASTER_ID;
    private Random random = new Random(System.currentTimeMillis());
    private ArrayList<FilterMessageHook> filterMessageHookList = new ArrayList<FilterMessageHook>();

    public PullResult processPullResult(final MessageQueue mq, final PullResult pullResult,
        final SubscriptionData subscriptionData) {
        PullResultExt pullResultExt = (PullResultExt) pullResult;

        // 处理MessageQueue对应拉取的brokerId
        this.updatePullFromWhichNode(mq, pullResultExt.getSuggestWhichBrokerId());

        // 省略相关代码

        pullResultExt.setMessageBinary(null);

        return pullResult;
    }

    public void updatePullFromWhichNode(final MessageQueue mq, final long brokerId) {
        // 保存在pullFromWhichNodeTable对象中
        AtomicLong suggest = this.pullFromWhichNodeTable.get(mq);
        if (null == suggest) {
            this.pullFromWhichNodeTable.put(mq, new AtomicLong(brokerId));
        } else {
            suggest.set(brokerId);
        }
    }
}
```

`Consumer`收到拉取响应回来的数据后，会将下次建议拉取的 `brokerId`缓存起来。

```java
public class PullAPIWrapper {
    private final InternalLogger log = ClientLogger.getLog();
    private final MQClientInstance mQClientFactory;
    private final String consumerGroup;
    private final boolean unitMode;
    private ConcurrentMap<MessageQueue, AtomicLong/* brokerId */> pullFromWhichNodeTable =
        new ConcurrentHashMap<MessageQueue, AtomicLong>(32);
    private volatile boolean connectBrokerByUser = false;
    private volatile long defaultBrokerId = MixAll.MASTER_ID;
    private Random random = new Random(System.currentTimeMillis());
    private ArrayList<FilterMessageHook> filterMessageHookList = new ArrayList<FilterMessageHook>();

    public PullResult pullKernelImpl(
        final MessageQueue mq,
        final String subExpression,
        final String expressionType,
        final long subVersion,
        final long offset,
        final int maxNums,
        final int sysFlag,
        final long commitOffset,
        final long brokerSuspendMaxTimeMillis,
        final long timeoutMillis,
        final CommunicationMode communicationMode,
        final PullCallback pullCallback
    ) throws MQClientException, RemotingException, MQBrokerException, InterruptedException {

        // 查找MessageQueue应该从brokerName的哪个节点查询
        FindBrokerResult findBrokerResult =
            this.mQClientFactory.findBrokerAddressInSubscribe(mq.getBrokerName(),
                this.recalculatePullFromWhichNode(mq), false);

        if (null == findBrokerResult) {
            this.mQClientFactory.updateTopicRouteInfoFromNameServer(mq.getTopic());
            findBrokerResult =
                this.mQClientFactory.findBrokerAddressInSubscribe(mq.getBrokerName(),
                    this.recalculatePullFromWhichNode(mq), false);
        }

        if (findBrokerResult != null) {
            {
                // check version
                if (!ExpressionType.isTagType(expressionType)
                    && findBrokerResult.getBrokerVersion() < MQVersion.Version.V4_1_0_SNAPSHOT.ordinal()) {
                    throw new MQClientException("The broker[" + mq.getBrokerName() + ", "
                        + findBrokerResult.getBrokerVersion() + "] does not upgrade to support for filter message by " + expressionType, null);
                }
            }
            int sysFlagInner = sysFlag;

            if (findBrokerResult.isSlave()) {
                sysFlagInner = PullSysFlag.clearCommitOffsetFlag(sysFlagInner);
            }

            PullMessageRequestHeader requestHeader = new PullMessageRequestHeader();
            requestHeader.setConsumerGroup(this.consumerGroup);
            requestHeader.setTopic(mq.getTopic());
            requestHeader.setQueueId(mq.getQueueId());
            requestHeader.setQueueOffset(offset);
            requestHeader.setMaxMsgNums(maxNums);
            requestHeader.setSysFlag(sysFlagInner);
            requestHeader.setCommitOffset(commitOffset);
            requestHeader.setSuspendTimeoutMillis(brokerSuspendMaxTimeMillis);
            requestHeader.setSubscription(subExpression);
            requestHeader.setSubVersion(subVersion);
            requestHeader.setExpressionType(expressionType);

            String brokerAddr = findBrokerResult.getBrokerAddr();
            if (PullSysFlag.hasClassFilterFlag(sysFlagInner)) {
                brokerAddr = computPullFromWhichFilterServer(mq.getTopic(), brokerAddr);
            }

            PullResult pullResult = this.mQClientFactory.getMQClientAPIImpl().pullMessage(
                brokerAddr,
                requestHeader,
                timeoutMillis,
                communicationMode,
                pullCallback);

            return pullResult;
        }

        throw new MQClientException("The broker[" + mq.getBrokerName() + "] not exist", null);
    }


    public long recalculatePullFromWhichNode(final MessageQueue mq) {
        if (this.isConnectBrokerByUser()) {
            return this.defaultBrokerId;
        }

        AtomicLong suggest = this.pullFromWhichNodeTable.get(mq);
        if (suggest != null) {
            return suggest.get();
        }

        return MixAll.MASTER_ID;
    }
}
```

`Consumer`拉取消息的时候会从 `pullFromWhichNodeTable `中取出拉取 brokerId确定去具体的broker进行查询。

## 三. 总结

RocketMQ的 `Consumer` 在拉取消息时，Broker 会判断 Master 服务器的消息堆积量来决定 Consumer 是否从 Slave 服务器拉取消息消费。默认一开始从 Master 服务器拉群消息，如果 Master 服务器的消息堆积超过物理内存40%，则会返回给 Consumer 的消息结果并告知Consumer，下次从其他 Slave 服务器上拉取消息。



> 本文参考至：[RocketMQ设计之主从复制和读写分离 - 掘金 (juejin.cn)](https://juejin.cn/post/7136559143942357006)