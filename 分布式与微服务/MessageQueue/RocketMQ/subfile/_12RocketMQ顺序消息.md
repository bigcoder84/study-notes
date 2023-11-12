# RocketMQ顺序消息源码分析

## 一. 前言

本文来带大家了解一下`RocketMQ`的**顺序消息**，虽然这玩意在实际开发中的**使用频率**不如`普通消息`，但是在某些场景下还必须用它~

例如前些日子的`618`，相信大家下了不少订单，银行卡疯狂的给你发`余额短信`，此时我们就要**注意了**！

举例: 当前你的银行卡余额为**100元**

1. 你先下了个单，购物金额为**20元**，此时银行卡余额为**80元**
2. 然后你又下了个单，购物金额为**50元**，此时银行卡余额为**30元**

这时候就要注意了，余额为**80元**的短信肯定要在余额为**30元**的短信之前，否则的话余额先是`30元`然后又变成`80元`，这就很奇怪了~

生产环境中，我们并不要求支付成功后，实时的发送余额短信，这时候我们是完全可以利用`MQ`进行`异步解耦`的，但是必须要使用**顺序消息**，否则的话就可能出现我上面所诉的情况，出现**线上事故！**

## 二. RocketMQ顺序消息类型

### 2.1 全局顺序消息

对于指定的一个`Topic`，所有消息按照严格的先入先出（FIFO）的顺序来发布和消费（单生产者单线程，单消费者单线程）

- 适用场景

  适用于性能要求不高，所有的消息严格按照FIFO原则来发布和消费的场景。

### 2.1 分区顺序消息

对于指定的一个`Topic`，所有消息根据`Sharding Key`进行划分到不同队列中，同一个队列内的消息按照严格的先进先出（FIFO）原则进行发布和消费。同一队列内同一`Sharding Key`的消息保证顺序，不同队列之间的消息顺序不做要求。

- 适用场景

  适用于性能要求高，以`Sharding Key`作为划分字段，在同一个区块中严格地按照先进先出（FIFO）原则进行消息发布和消费的场景。

以`RocketMQ`中提供的`顺序消息案例`来看

`Producer`发送消息的时候自定义了`MessageQueueSelector`，同时传入的`orderId`，在选择队列的时候，根据`orderId % mqs.size()`来选择，这样一来就保证了同一个`orderId`的消息肯定被发送到同一个`msgQueue`中，从而保证**分区顺序**。

而且`Consumer`方，需要指定`MessageListenerOrderly`来消费顺序消息

```java
package org.apache.rocketmq.example.ordermessage;

// Producer
public class Producer {
  public static void main(String[] args) throws UnsupportedEncodingException {
    try {
      DefaultMQProducer producer = new DefaultMQProducer("please_rename_unique_group_name");
      producer.start();

      String[] tags = new String[] {"TagA", "TagB", "TagC", "TagD", "TagE"};
      for (int i = 0; i < 100; i++) {
        int orderId = i % 10;
        Message msg =
          new Message("TopicTestjjj", tags[i % tags.length], "KEY" + i,
                      ("Hello RocketMQ " + i).getBytes(RemotingHelper.DEFAULT_CHARSET));

        // 自定义MessageQueueSelector来根据arg来选择消息队列
        SendResult sendResult = producer.send(msg, new MessageQueueSelector() {
          @Override
          public MessageQueue select(List<MessageQueue> mqs, Message msg, Object arg) {
            Integer id = (Integer) arg;
            // 订单号与mqSize取模
            int index = id % mqs.size();
            return mqs.get(index);
          }
        }, orderId);

        System.out.printf("%s%n", sendResult);
      }

      producer.shutdown();
    } catch (MQClientException | RemotingException | MQBrokerException | InterruptedException e) {
      e.printStackTrace();
    }
  }
}

// Consumer
public class Consumer {

  public static void main(String[] args) throws MQClientException {
    DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("please_rename_unique_group_name_3");

    consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);

    consumer.subscribe("TopicTest", "TagA || TagC || TagD");

    // 消费者方要使用MessageListenerOrderly来消费顺序消息
    consumer.registerMessageListener(new MessageListenerOrderly() {
      AtomicLong consumeTimes = new AtomicLong(0);

      @Override
      public ConsumeOrderlyStatus consumeMessage(List<MessageExt> msgs, ConsumeOrderlyContext context) {
        context.setAutoCommit(true);
        System.out.printf("%s Receive New Messages: %s %n", Thread.currentThread().getName(), msgs);
        this.consumeTimes.incrementAndGet();
        if ((this.consumeTimes.get() % 2) == 0) {
          return ConsumeOrderlyStatus.SUCCESS;
        } else if ((this.consumeTimes.get() % 5) == 0) {
          context.setSuspendCurrentQueueTimeMillis(3000);
          return ConsumeOrderlyStatus.SUSPEND_CURRENT_QUEUE_A_MOMENT;
        }

        return ConsumeOrderlyStatus.SUCCESS;
      }
    });

    consumer.start();
    System.out.printf("Consumer Started.%n");
  }

}
```

## 三. RocketMQ顺序消息原理

### 3.1 Producer保证顺序

在上面的官方案例中，我们提到过：`Producer`发送消息的时候自定义了`MessageQueueSelector`，同时传入的`orderId`，在选择队列的时候，根据`orderId % mqs.size()`来选择，这样一来就保证了同一个`orderId`的消息肯定被发送到同一个`msgQueue`中，从而保证**分区顺序**

参考源码，`Producer`在发送消息时，确实**回调**了自定义的`MessageQueueSelector`来选择消息队列

```java
//org.apache.rocketmq.client.impl.producer.DefaultMQProducerImpl#sendSelectImpl
private SendResult sendSelectImpl(
  Message msg,
  MessageQueueSelector selector,
  Object arg,
  final CommunicationMode communicationMode,
  final SendCallback sendCallback, final long timeout
) throws MQClientException, RemotingException, MQBrokerException, InterruptedException {
   // ......

  // 获取topic发布信息
  TopicPublishInfo topicPublishInfo = this.tryToFindTopicPublishInfo(msg.getTopic());
  if (topicPublishInfo != null && topicPublishInfo.ok()) {
    MessageQueue mq = null;
    try {
      // 解析出topic对应的队列集合
      List<MessageQueue> messageQueueList =
        mQClientFactory.getMQAdminImpl().parsePublishMessageQueues(topicPublishInfo.getMessageQueueList());
      Message userMessage = MessageAccessor.cloneMessage(msg);
      String userTopic = NamespaceUtil.withoutNamespace(userMessage.getTopic(), mQClientFactory.getClientConfig().getNamespace());
      userMessage.setTopic(userTopic);

      // 回调select，选择具体的messageQueue
      mq = mQClientFactory.getClientConfig().queueWithNamespace(selector.select(messageQueueList, userMessage, arg));
    } catch (Throwable e) {
      throw new MQClientException("select message queue threw exception.", e);
    }

    // ......

    if (mq != null) {
      // 向broker消息
      return this.sendKernelImpl(msg, mq, communicationMode, sendCallback, null, timeout - costTime);
    } else {
      throw new MQClientException("select message queue return null.", null);
    }
  }
  // ......
}
```

### 3.2 Consumer保证顺序

仅仅在Producer端保证将顺序消息投送至同一个消费队列还不够，因为假如多个实例下的消费者同时消费同一个队列仍然会出现消息的乱序消费。Consumer端主要要解决同一个队列在整个消费组中只有一个线程去消费。

`Consumer`启动后，会判断`消费者Listener`类型

- 如果类型是`MessageListenerOrderly`表示要进行**顺序消费**，此时使用`ConsumeMessageOrderlyService`对`ConsumeMessageService`进行实例化
- 如果类型是`MessageListenerConcurrently`表示要进行**并发消费**，此时使用`ConsumeMessageConcurrentlyService`对`ConsumeMessageService`进行实例化

```java
// org.apache.rocketmq.client.impl.consumer.DefaultMQPushConsumerImpl#start
public synchronized void start() throws MQClientException {
  switch (this.serviceState) {
    case CREATE_JUST:
      // ......
      
      // 判断消费者Listener类型
      if (this.getMessageListenerInner() instanceof MessageListenerOrderly) {
        this.consumeOrderly = true;
        // 说明是顺序消费，使用ConsumeMessageOrderlyService
        this.consumeMessageService =
          new ConsumeMessageOrderlyService(this, (MessageListenerOrderly) this.getMessageListenerInner());
      } else if (this.getMessageListenerInner() instanceof MessageListenerConcurrently) {
        this.consumeOrderly = false;
        // 并发消费，使用ConsumeMessageConcurrentlyService
        this.consumeMessageService =
          new ConsumeMessageConcurrentlyService(this, (MessageListenerConcurrently) this.getMessageListenerInner());
      }

      // 启动
      this.consumeMessageService.start();

      // ......
  }

  // ......
}
```

#### 3.2.1 定时任务对消息队列加锁续期

`ConsumeMessageOrderlyService#start`中，如果是处于`集群模式`下，则会开启一个`定时任务`，**周期性对消息队列加锁**

```java
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageOrderlyService#start
public void start() {
  // 如果是集群模式才加锁
  if (MessageModel.CLUSTERING.equals(ConsumeMessageOrderlyService.this.defaultMQPushConsumerImpl.messageModel())) {
      // Broker 消息队列锁会过期，默认配置 30s。因此，Consumer 需要不断向 Broker 刷新该锁过期时间，默认配置 20s 刷新一次。
    this.scheduledExecutorService.scheduleAtFixedRate(new Runnable() {
      @Override
      public void run() {
        try {
          ConsumeMessageOrderlyService.this.lockMQPeriodically();
        } catch (Throwable e) {
          log.error("scheduleAtFixedRate lockMQPeriodically exception", e);
        }
      }
    }, 1000 * 1, ProcessQueue.REBALANCE_LOCK_INTERVAL, TimeUnit.MILLISECONDS);
  }
}

```

最终走到`RebalanceImpl#lockAll`

1. 从`processQueueTable`中，映射出`broker -> Set<MsgQueue>`的关系（`map`）
2. 以`broker`维度进行遍历，根据`brokerName`获取`broker`信息
3. 对该`broker`下的所有**消息队列**（即上面`map`对应的消息队列集合），**批量发送加锁请求**
4. 处理加锁成功、未成功的消息队列

```java
// org.apache.rocketmq.client.impl.consumer.RebalanceImpl#lockAll
public void lockAll() {
  // 映射broker -> Set<MsgQueue>的关系
  HashMap<String, Set<MessageQueue>> brokerMqs = this.buildProcessQueueTableByBrokerName();

  // 遍历
  Iterator<Entry<String, Set<MessageQueue>>> it = brokerMqs.entrySet().iterator();
  while (it.hasNext()) {
    Entry<String, Set<MessageQueue>> entry = it.next();
    final String brokerName = entry.getKey();
    final Set<MessageQueue> mqs = entry.getValue();

    if (mqs.isEmpty())
      continue;

    // 根据brokerName获取broker信息
    FindBrokerResult findBrokerResult = this.mQClientFactory.findBrokerAddressInSubscribe(brokerName, MixAll.MASTER_ID, true);
    if (findBrokerResult != null) {

      // 构建加锁请求
      LockBatchRequestBody requestBody = new LockBatchRequestBody();
      requestBody.setConsumerGroup(this.consumerGroup);
      requestBody.setClientId(this.mQClientFactory.getClientId());
      requestBody.setMqSet(mqs);

      try {
        // 批量加锁，会返回加锁成功的消息队列
        Set<MessageQueue> lockOKMQSet =
          this.mQClientFactory.getMQClientAPIImpl().lockBatchMQ(findBrokerResult.getBrokerAddr(), requestBody, 1000);

        // 遍历加锁成功的队列
        for (MessageQueue mq : lockOKMQSet) {
          ProcessQueue processQueue = this.processQueueTable.get(mq);
          if (processQueue != null) {
            if (!processQueue.isLocked()) {
              log.info("the message queue locked OK, Group: {} {}", this.consumerGroup, mq);
            }

            // 标记为加锁成功
            processQueue.setLocked(true);
            processQueue.setLastLockTimestamp(System.currentTimeMillis());
          }
        }

        // 遍历所有队列，如果不存在于lockOKMQSet中，则表明加速失败
        for (MessageQueue mq : mqs) {
          if (!lockOKMQSet.contains(mq)) {
            ProcessQueue processQueue = this.processQueueTable.get(mq);
            if (processQueue != null) {
              // 标记为加锁失败
              processQueue.setLocked(false);
              log.warn("the message queue locked Failed, Group: {} {}", this.consumerGroup, mq);
            }
          }
        }
      } catch (Exception e) {
        log.error("lockBatchMQ exception, " + mqs, e);
      }
    }
  }
}

```

#### 3.2.2 拉取消息时加锁保证消息只被一个消费者实例拉取

RocketMQ消息消费是用过 `PullMessageService` 线程不断拉取broker上的消息缓存在本地，供给消费者线程池消费。而要保证消息消费的有序性，就必须要保证同一时间只能有一个消费者进程拉取同一队列的消息，RocketMQ中通过分布式锁保证的这一点。

`Consumer` 构造拉取消息请求逻辑处于 `RebalanceImpl#updateProcessQueueTableInRebalance`

但由于**重平衡**的机制存在，**当前消息者所属的消息队列**可能存在一定的变动，会被**分配到新的消息队列**，但此时定时任务加锁可能会不够及时，所以消费者在**构建拉取消息请求前**，会对顺序消息队列**再次检查并加锁**

1. 遍历分配的消息队列（重平衡机制存在，`mqSet`为新分配的`Consumer`所属的消息队列）,处理新加入的`msgQueue`
2. 如果是顺序消息，且当前`msgQueue`加锁失败，则直接跳过不处理
3. 普通消息 或者 加锁成功的顺序消息，如果不存在于`processQueueTable`，则为该`msgQueue`构建新的`PullRequest`
4. 添加消息拉取请求`dispatchPullRequest`

```java
// org.apache.rocketmq.client.impl.consumer.RebalanceImpl#updateProcessQueueTableInRebalance
private boolean updateProcessQueueTableInRebalance(final String topic, final Set<MessageQueue> mqSet,
                                                   final boolean isOrder) {
  boolean changed = false;

  // ......

  // 遍历分配的消息队列
  List<PullRequest> pullRequestList = new ArrayList<PullRequest>();
  for (MessageQueue mq : mqSet) {
    // processQueueTable不包含当前mqQueue，说明是新分配的mqQueue
    if (!this.processQueueTable.containsKey(mq)) {

      // 如果 mqSet 不存在于本地缓存中，则证明是新增加的消息队列
      // 如果是顺序消费，则需要对queue进行加分布式锁，只有加锁成功才会创建 PullRequest 从broker上拉取消息
      if (isOrder && !this.lock(mq)) {
        log.warn("doRebalance, {}, add a new mq failed, {}, because lock failed", consumerGroup, mq);
        continue;
      }

      // 删除当前消息队列的offSet
      this.removeDirtyOffset(mq);
      // 标记ProcessQueue为加锁成功
      ProcessQueue pq = new ProcessQueue();
      pq.setLocked(true);

      long nextOffset = -1L;
      try {
        // 计算新的offSet
        nextOffset = this.computePullFromWhereWithException(mq);
      } catch (Exception e) {
        log.info("doRebalance, {}, compute offset failed, {}", consumerGroup, mq);
        continue;
      }

      if (nextOffset >= 0) {
        ProcessQueue pre = this.processQueueTable.putIfAbsent(mq, pq);
        if (pre != null) {
          log.info("doRebalance, {}, mq already exists, {}", consumerGroup, mq);
        } else {
          // 说明之前该消息队列不属于该Consumer，则需要构建新的PullRequest
          log.info("doRebalance, {}, add a new mq, {}", consumerGroup, mq);
          PullRequest pullRequest = new PullRequest();
          pullRequest.setConsumerGroup(consumerGroup);
          pullRequest.setNextOffset(nextOffset);
          pullRequest.setMessageQueue(mq);
          pullRequest.setProcessQueue(pq);
          pullRequestList.add(pullRequest);
          changed = true;
        }
      } else {
        log.warn("doRebalance, {}, add new mq failed, {}", consumerGroup, mq);
      }
    }
  }

  // 添加消息拉取请求
  this.dispatchPullRequest(pullRequestList);

  return changed;
}
```

上一步构建好拉取消息请求后，会将请求添加到 `PullMessageService` 的 `pullRequestQueue` 中，同时会启动线程，从 `pullRequestQueue` 获取 `pullRequest` 执行拉取请求

```java
    // org.apache.rocketmq.client.impl.consumer.PullMessageService#run
	@Override
    public void run() {
        log.info(this.getServiceName() + " service started");

        //  while (!this.isStopped()) 是一种通用的设计技巧，Stopped
        // 声明为volatile，每执行一次业务逻辑，检测一下其运行状态，可以
        // 通过其他线程将Stopped设置为true，从而停止该线程
        while (!this.isStopped()) {
            try {
                // 从pullRequestQueue中获取一个PullRequest消息拉取任务，
                // 如果pullRequestQueue为空，则线程将阻塞，直到有拉取任务被放入
                PullRequest pullRequest = this.pullRequestQueue.take();
                this.pullMessage(pullRequest);
            } catch (InterruptedException ignored) {
            } catch (Exception e) {
                log.error("Pull Message Service Run Method exception", e);
            }
        }

        log.info(this.getServiceName() + " service end");
    }
```

消息拉取成功后会存在 `PullCallback` 的回调，在 `onSuccess` 中，则代表拉取成功：

- 如果未拉取到消息，则将拉取请求放入队列再重试
- 如果拉取到消息，则将消息添加到`processQueue`，并提交消费请求(`submitConsumeRequest`)，这样消费者线程池就能真正消费到这些消息了。

```java
// org.apache.rocketmq.client.impl.consumer.DefaultMQPushConsumerImpl#pullMessage
public void pullMessage(final PullRequest pullRequest) {
  // ......

  // 拉取消息回调
  PullCallback pullCallback = new PullCallback() {
    @Override
    public void onSuccess(PullResult pullResult) {
      if (pullResult != null) {
        // ......
        
        // 判断拉取结果
        switch (pullResult.getPullStatus()) {
          case FOUND:
            // ......
            long firstMsgOffset = Long.MAX_VALUE;
            
            // 未拉取到消息
            if (pullResult.getMsgFoundList() == null || pullResult.getMsgFoundList().isEmpty()) {
              // 将拉取请求放入队列再重试
              DefaultMQPushConsumerImpl.this.executePullRequestImmediately(pullRequest);
            } else {
              // ......

              // 向processQueue添加消息，并提交消费请求
              boolean dispatchToConsume = processQueue.putMessage(pullResult.getMsgFoundList());
              DefaultMQPushConsumerImpl.this.consumeMessageService.submitConsumeRequest(
                pullResult.getMsgFoundList(),
                processQueue,
                pullRequest.getMessageQueue(),
                dispatchToConsume);

              // ......
            }
            // ......
        }
      }
    }
  };

  // .....
}
```

#### 3.2.3 消费顺序消息

顺序消息实现类为`ConsumeMessageOrderlyService`，通过下面源码可见，即使是顺序消息也是利用`线程池`进行异步消费，既然这样，那顺序消息如何保证同一进程下多个消费线程有序被消费呢？下面接着看~

```java
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageOrderlyService#submitConsumeRequest
public void submitConsumeRequest(
  final List<MessageExt> msgs,
  final ProcessQueue processQueue,
  final MessageQueue messageQueue,
  final boolean dispathToConsume) {
  if (dispathToConsume) {
    ConsumeRequest consumeRequest = new ConsumeRequest(processQueue, messageQueue);
    this.consumeExecutor.submit(consumeRequest);
  }
}
```

`ConsumeMessageOrderlyService.ConsumeRequestConsumeRequest`实现了`Runnable`接口，实现了`run`方法

1. `processQueue`被删除，直接`return`，不处理
2. **消息消费队列加锁**，调用`fetchLockObject`获取对象并使用`synchronized`加对象锁，保证即使**顺序消息即使是线程池多线程消费**，但是对于**同一个消息队列，只会有一个消费者消费**
3. 如果是`广播模式`，或者当前的消息队列已经加锁成功（`lock`字段为`true`）并且加锁时间**未过期**，才开始对拉取的消息进行消费
4. 执行校验逻辑
   1. 集群模式下`processQueue`未加锁 或者 集群模式下`processQueue`锁过期，则延时重试加锁，并延时重新消费该`processQueue`
   2. 如果**当前时间距离开始处理的时间超过了最大消费时间**，也延时重新消费该`processQueue`
5. 批量从`processQueue`取出消息，**加消息消费锁**，回调`Consumer`自定义的`MessageListenerOrderly`进行消费（也就是执行消费的业务代码）

```java
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageOrderlyService.ConsumeRequest#run
public void run() {
  // processQueue被删除，直接return
  if (this.processQueue.isDropped()) {
    log.warn("run, the message queue not be able to consume, because it's dropped. {}", this.messageQueue);
    return;
  }

  // todo: 消息消费队列锁
  final Object objLock = messageQueueLock.fetchLockObject(this.messageQueue);
  synchronized (objLock) {
    
    // 如果是广播模式，或者当前的消息队列已经加锁成功且加锁时间未过期
    if (MessageModel.BROADCASTING.equals(ConsumeMessageOrderlyService.this.defaultMQPushConsumerImpl.messageModel())
        || (this.processQueue.isLocked() && !this.processQueue.isLockExpired())) {
      final long beginTime = System.currentTimeMillis();
      
      // 开始消费消息
      for (boolean continueConsume = true; continueConsume; ) {
        
        // processQueue被删除，直接跳出循环
        if (this.processQueue.isDropped()) {
          log.warn("the message queue not be able to consume, because it's dropped. {}", this.messageQueue);
          break;
        }

        // 校验: 集群模式下processQueue未加锁
        if (MessageModel.CLUSTERING.equals(ConsumeMessageOrderlyService.this.defaultMQPushConsumerImpl.messageModel())
            && !this.processQueue.isLocked()) {
          // 延时加锁重试，并延时重试消费
          ConsumeMessageOrderlyService.this.tryLockLaterAndReconsume(this.messageQueue, this.processQueue, 10);
          break;
        }

        // 校验: 集群模式下processQueue锁过期
        if (MessageModel.CLUSTERING.equals(ConsumeMessageOrderlyService.this.defaultMQPushConsumerImpl.messageModel())
            && this.processQueue.isLockExpired()) {
          // 延时加锁重试，并延时重试消费
          ConsumeMessageOrderlyService.this.tryLockLaterAndReconsume(this.messageQueue, this.processQueue, 10);
          break;
        }

        // 如果当前时间距离开始处理的时间超过了最大消费时间,则延时重新消费该processQueue
        long interval = System.currentTimeMillis() - beginTime;
        if (interval > MAX_TIME_CONSUME_CONTINUOUSLY) {
          ConsumeMessageOrderlyService.this.submitConsumeRequestLater(processQueue, messageQueue, 10);
          break;
        }

        // 批量消费消息个数
        final int consumeBatchSize =
          ConsumeMessageOrderlyService.this.defaultMQPushConsumer.getConsumeMessageBatchMaxSize();

        // 从processQueue获取消息
        List<MessageExt> msgs = this.processQueue.takeMessages(consumeBatchSize);
        defaultMQPushConsumerImpl.resetRetryAndNamespace(msgs, defaultMQPushConsumer.getConsumerGroup());
        if (!msgs.isEmpty()) {
          // ......

          long beginTimestamp = System.currentTimeMillis();
          ConsumeReturnType returnType = ConsumeReturnType.SUCCESS;
          boolean hasException = false;
          try {
            // todo: 消息消费锁
            this.processQueue.getConsumeLock().lock();
            if (this.processQueue.isDropped()) {
              log.warn("consumeMessage, the message queue not be able to consume, because it's dropped. {}",
                       this.messageQueue);
              break;
            }

            // todo: messageListener回调
            status = messageListener.consumeMessage(Collections.unmodifiableList(msgs), context);
          } catch (Throwable e) {
            log.warn(String.format("consumeMessage exception: %s Group: %s Msgs: %s MQ: %s",
                                   RemotingHelper.exceptionSimpleDesc(e),
                                   ConsumeMessageOrderlyService.this.consumerGroup,
                                   msgs,
                                   messageQueue), e);
            hasException = true;
          } finally {
            // 解锁
            this.processQueue.getConsumeLock().unlock();
          }

          // ......
        } else {
          continueConsume = false;
        }
      }
    } else {
      if (this.processQueue.isDropped()) {
        log.warn("the message queue not be able to consume, because it's dropped. {}", this.messageQueue);
        return;
      }

      ConsumeMessageOrderlyService.this.tryLockLaterAndReconsume(this.messageQueue, this.processQueue, 100);
    }
  }
}
```

在消费消息时，我们可以看到首先会对**消息队列加锁**:

```java
// todo: 消息消费队列锁
final Object objLock = messageQueueLock.fetchLockObject(this.messageQueue);
synchronized (objLock) {
  // ......
}
```

其本质上是是是利用的`ConcurrentMap + synchronized`来实现的，`map`中维护每个消息队列对应的`Object`对象，再使用`synchronized`对对象加锁，这样一来，在多线程环境下，也能保持**每个消息队列都是单线程消费**，保证了顺序。

走到这一步看似已经完美了，“broker分布式锁”保证了在多进程消费组下只有一个消费者进程能拉取消息，messageQueue锁保证了拉取到消息的进程中只有一个线程会消费消息。

但是这么做是不够的，因为生产环境中消费组会不定期增加或删除消费者实例，所以 RocketMQ 会每20秒拉取所有消费者信息，对topic下的队列进行重平衡。重平衡就可能会将原先A实例消费的一个队列分配到B实例上，这样A实例就会释放这个队列在broker上加的分布式锁，如果此时A实例内存中仍有消息正在被消费，B实例拿到分布式锁，开始消费消息，就会出现两个实例同时消费同一个队列消息的情况。

所以在真正消费消息之前，会对 `processQueue` 加 **消费锁**：

```java
try {
  // todo: 消息消费锁
  this.processQueue.getConsumeLock().lock();
  // 消费消息......
} catch (Throwable e) {
  // ......
  hasException = true;
} finally {
  // 解锁
  this.processQueue.getConsumeLock().unlock();
}
```

这样在重平衡下移除消息队列，尝试去释放broker分布式锁时会先获取“消费锁”，如果成功获取到消费锁，则证明当前进程已经没有线程在消费这个队列了，可以移除broker分布式锁，让别的进程去消费这个队列了：

```java
// org.apache.rocketmq.client.impl.consumer.RebalancePushImpl#removeUnnecessaryMessageQueue
public boolean removeUnnecessaryMessageQueue(MessageQueue mq, ProcessQueue pq) {
  this.defaultMQPushConsumerImpl.getOffsetStore().persist(mq);
  this.defaultMQPushConsumerImpl.getOffsetStore().removeOffset(mq);
  
  // 顺序消费，且是集群模式
  if (this.defaultMQPushConsumerImpl.isConsumeOrderly()
      && MessageModel.CLUSTERING.equals(this.defaultMQPushConsumerImpl.messageModel())) {
    try {
      // 尝试获取processQueue的消费锁
      if (pq.getConsumeLock().tryLock(1000, TimeUnit.MILLISECONDS)) {
        try {
          // 成功获取，则才会去延时解开消息队列的锁
          return this.unlockDelay(mq, pq);
        } finally {
          pq.getConsumeLock().unlock();
        }
      } else {
        log.warn("[WRONG]mq is consuming, so can not unlock it, {}. maybe hanged for a while, {}",
                 mq,
                 pq.getTryUnlockTimes());

        pq.incTryUnlockTimes();
      }
    } catch (Exception e) {
      log.error("removeUnnecessaryMessageQueue Exception", e);
    }

    return false;
  }
  return true;
}
```

## 四. 总结

`RocketMQ`为了保证消息的顺序性，分别从`Producer`和`Consumer`都有着相应的设计~

- `Producer`方面，为保证顺序消息，可自定义`MessageQueueSelector`来选择队列。例: `orderId % msgQueueSize`，从而可保证同一个`orderId`的相关消息，会被发送到同一个队列里。
- `Consumer`方面，在整体设计上用了三把锁，来保证消息的顺序消费。
  - broker分布式锁：保证只有一个消费者进程能够拉取到消息。
  - processQueue锁：保证在拉取到消息的进程中，只有一个线程能够消费这些消息。
  - 消费锁：保证消费线程在消费途中，重平衡导致队列被分配到别的实力上时，不会立即将broker分布式锁解锁，而是等待消费者消费完成或者等待下一次重平衡在解锁。这样就能保证在重平衡场景下不会出现两个进程内的线程消费同一个队列的情况。

> 本文参考至：[RocketMQ顺序消息机制源码分析~ - 掘金 (juejin.cn)](https://juejin.cn/post/7270509734926630971)