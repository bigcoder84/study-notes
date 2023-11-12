# 	RocketMQ主从同步原理

## 一. 主从同步概述

主从同步这个概念相信大家在平时的工作中，多少都会听到。其目的主要是用于做一备份类操作，以及一些读写分离场景。比如我们常用的关系型数据库mysql，就有主从同步功能在。

主从同步，就是将主服务器上的数据同步到从服务器上，也就是相当于新增了一个副本。

而具体的主从同步的实现也各有千秋，如mysql中通过binlog实现主从同步，es中通过translog实现主从同步，redis中通过aof实现主从同步。那么，rocketmq又是如何实现的主从同步呢？

另外，主从同步需要考虑的问题是哪些呢？

1. 数据同步的及时性？（延迟与一致性）
2. 对主服务器的影响性？（可用性）
3. 是否可替代主服务器？（可用性或者分区容忍性）

前面两个点是必须要考虑的，但对于第3个点，则可能不会被考虑。因为通过系统可能无法很好的做到这一点，所以很多系统就直接忽略这一点了，简单嘛。即很多时候只把从服务器当作是一个备份存在，不会接受写请求。如果要进行主从切换，必须要人工介入，做预知的有损切换。但随着技术的发展，现在已有非常多的自动切换主从的服务存在，这是在分布式系统满天下的当今的必然趋势。

## 二. RocketMQ如何配置主从同步

在 RocketMQ 中，最核心的组件是 broker, 它负责几乎所有的存储读取业务。所以，要谈主从同步，那必然是针对broker进行的。我们再来回看 RocketMQ 的部署架构图，以便全局观察：

![](../images/59.png)

非常清晰的架构，无需多言。因为我们讲的是主从同步，所以只看broker这个组件，那么整个架构就可以简化为: BrokerMaster -> BrokerSlave 了。同样，再简化，主从同步就是如何将Master的数据同步到Slave这么个过程。

那么如何配置主从同步呢？

### 2.1 BrokerMaster配置

创建配置文件 `conf/broker-a.properties`

```properties
#所属集群名字
brokerClusterName=DefaultCluster
#broker名字，名字可重复。相同名字的broker构成一组主从节点（每个master起一个名字，它的slave同他，eg:Amaster叫broker-a，他的slave也叫broker-a）
brokerName=broker-a
#节点ID，0 表示 Master 节点，大于 0 表示 Slave 节点
brokerId=0
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=ASYNC_MASTER
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#nameServer地址，分号分割
namesrvAddr=172.0.1.5:9876;172.0.1.6:9876
```

### 2.2 BrokerSlave配置

创建配置文件 `conf/broker-a-s.properties`

```properties
#所属集群名字
brokerClusterName=DefaultCluster
#broker名字，和Master节点保持一致
brokerName=broker-a
#节点ID，大于1表示这是Slave节点
brokerId=1
#Broker 的角色
#- ASYNC_MASTER 异步复制Master
#- SYNC_MASTER 同步双写Master
#- SLAVE
brokerRole=SLAVE
#刷盘方式
#- ASYNC_FLUSH 异步刷盘
#- SYNC_FLUSH 同步刷盘
flushDiskType=ASYNC_FLUSH
#nameServer地址，分号分割
namesrvAddr=172.0.1.5:9876;172.0.1.6:9876
```

配置项看起来有点多，但核心实际上只有两个：

1. 在保持 `brokderName` 相同的前提下配置 `brokerRole=ASYNC_MASTER|SLAVE|SYNC_MASTER`，通过这个节点就能知道主从同步复制模式。
2. 在保持 `brokderName` 相同的前提下配置 Master节点的 brokerId 配置为0，Slave节点配置为大于0，通过这个值就可以确定是主是从。

具体配置文件叫什么名字不重要，重要的是要在启动时指定指定对应的配置文件位置即可。启动master/slave命令如下:

```shell
# 启动Master节点
nohup sh /usr/local/rocketmq/bin/mqbroker -c conf/broker-a.properties > logs/broker-a.log 2>&1 &

# 启动Slave节点
nohup sh /usr/local/rocketmq/bin/mqbroker -c conf/broker-a-s.properties > logs/broker-a-s.log 2>&1 &
```

## 三. 源码分析

主从同步的实现逻辑主要在`HAService`中，在`DefaultMessageStore`的构造函数中，对`HAService`进行了实例化，并在start方法中，启动了`HAService`：

```java
public class DefaultMessageStore implements MessageStore {
    public DefaultMessageStore(final MessageStoreConfig messageStoreConfig, final BrokerStatsManager brokerStatsManager,
        final MessageArrivingListener messageArrivingListener, final BrokerConfig brokerConfig) throws IOException {
        // ...
        if (!messageStoreConfig.isEnableDLegerCommitLog()) {
            // 初始化HAService
            this.haService = new HAService(this);
        } else {
            this.haService = null;
        }
        // ...
    }

    public void start() throws Exception {
        // ...
        if (!messageStoreConfig.isEnableDLegerCommitLog()) {
            // 启动HAService
            this.haService.start();
            // 主节点启动延迟消息实现，从节点关闭Slave消息实现，主节点将延迟消息从延迟队列转移到真实的topic队列时，也会由主从同步同步至从节点，
            // 所以不需要从节点开启延迟队列
            this.handleScheduleMessageService(messageStoreConfig.getBrokerRole());
        }
        // ...
    }
}
```

在`HAService`的构造函数中，创建了`AcceptSocketService`、`GroupTransferService`和`HAClient`，在start方法中主要做了如下几件事：

1. 调用 `AcceptSocketService` 的 `beginAccept` 方法，这一步**主要是进行端口绑定，在端口上监听从节点的连接请求**（可以看做是运行在master节点的）;
2. 调用 `AcceptSocketService` 的 `start` 方法启动服务，这一步**主要为了处理从节点的连接请求，与从节点建立连接**（可以看做是运行在master节点的）;
3. 调用 `GroupTransferService` 的 `start` 方法，**主要用于在主从同步的时候，等待数据传输完毕**（可以看做是运行在master节点的）;
4. 调用 `HAClient` 的 `start` 方法启动，**里面与master节点建立连接，向master汇报主从同步进度并存储master发送过来的同步数据**（可以看做是运行在从节点的）;

```java
public class HAService {
     public HAService(final DefaultMessageStore defaultMessageStore) throws IOException {
        this.defaultMessageStore = defaultMessageStore;
        // 创建AcceptSocketService
        this.acceptSocketService =
            new AcceptSocketService(defaultMessageStore.getMessageStoreConfig().getHaListenPort());
        this.groupTransferService = new GroupTransferService();
        // 创建HAClient
        this.haClient = new HAClient();
    }

    public void start() throws Exception {
        // 开始监听从服务器的连接
        this.acceptSocketService.beginAccept();
        // 启动服务
        this.acceptSocketService.start();
        // 启动GroupTransferService
        this.groupTransferService.start();
        // 启动
        this.haClient.start();
    }
}
```

![](../images/60.png)

### 3.1 监听从节点连接请求

`AcceptSocketService` 的 `beginAccept` 方法里面首先获取了 `ServerSocketChannel`，然后进行端口绑定，并在selector上面注册了OP_ACCEPT事件的监听，监听从节点的连接请求：

```java
public class HAService {
    class AcceptSocketService extends ServiceThread {
        /**
         * 监听从节点的连接
         *
         * @throws Exception If fails.
         */
        public void beginAccept() throws Exception {
            // 创建ServerSocketChannel
            this.serverSocketChannel = ServerSocketChannel.open();
            // 获取selector
            this.selector = RemotingUtil.openSelector();
            this.serverSocketChannel.socket().setReuseAddress(true);
            // 绑定端口
            this.serverSocketChannel.socket().bind(this.socketAddressListen);
            // 设置非阻塞
            this.serverSocketChannel.configureBlocking(false);
            // 注册OP_ACCEPT连接事件的监听
            this.serverSocketChannel.register(this.selector, SelectionKey.OP_ACCEPT);
        }
    }
}
```

### 3.2 处理从节点连接请求

`AcceptSocketService`的run方法中，对监听到的连接请求进行了处理，处理逻辑大致如下：

1. 从selector中获取到监听到的事件；
2. 如果是`OP_ACCEPT`连接事件，创建与从节点的连接对象`HAConnection`，与从节点建立连接，然后调用`HAConnection`的start方法进行启动，并创建的`HAConnection`对象加入到连接集合中，**HAConnection中封装了Master节点和从节点的数据同步逻辑**；

```java
public class HAService {
    class AcceptSocketService extends ServiceThread {
        @Override
        public void run() {
            log.info(this.getServiceName() + " service started");
            // 如果服务未停止
            while (!this.isStopped()) {
                try {
                    this.selector.select(1000);
                    // 获取监听到的事件
                    Set<SelectionKey> selected = this.selector.selectedKeys();
                    // 处理事件
                    if (selected != null) {
                        for (SelectionKey k : selected) {
                            // 如果是连接事件
                            if ((k.readyOps() & SelectionKey.OP_ACCEPT) != 0) {
                                SocketChannel sc = ((ServerSocketChannel) k.channel()).accept();
                                if (sc != null) {
                                    HAService.log.info("HAService receive new connection, "
                                        + sc.socket().getRemoteSocketAddress());
                                    try {
                                        // 创建HAConnection，建立连接
                                        HAConnection conn = new HAConnection(HAService.this, sc);
                                        // 启动
                                        conn.start();
                                        // 添加连接
                                        HAService.this.addConnection(conn);
                                    } catch (Exception e) {
                                        log.error("new HAConnection exception", e);
                                        sc.close();
                                    }
                                }
                            } else {
                                log.warn("Unexpected ops in select " + k.readyOps());
                            }
                        }
                        selected.clear();
                    }
                } catch (Exception e) {
                    log.error(this.getServiceName() + " service has exception.", e);
                }
            }
            log.info(this.getServiceName() + " service end");
        }
    }
}
```

### 3.3 等待主从复制传输结束

`GroupTransferService`的run方法主要是为了在进行主从数据同步的时候，等待从节点数据同步完毕。

在运行时首先进会调用`waitForRunning`进行等待，因为此时可能还有没有开始主从同步，所以先进行等待，之后如果有同步请求，会唤醒该线程，然后调用`doWaitTransfer`方法等待数据同步完成：

```java
public class HAService {
    class GroupTransferService extends ServiceThread {

         public void run() {
            log.info(this.getServiceName() + " service started");
            // 如果服务未停止
            while (!this.isStopped()) {
                try {
                    // 等待运行
                    this.waitForRunning(10);
                    // 如果被唤醒，调用doWaitTransfer等待主从同步完成
                    this.doWaitTransfer();
                } catch (Exception e) {
                    log.warn(this.getServiceName() + " service has exception. ", e);
                }
            }

            log.info(this.getServiceName() + " service end");
        }
    }
}

```

在看`doWaitTransfer`方法之前，首先看下是如何判断有数据需要同步的。

Master节点中，当消息被写入到 `CommitLog` 以后，会调用 `handleHA` 方法处主从同步，首先判断当前Broker的角色是否是SYNC_MASTER，如果是则会构建消息提交请求`GroupCommitRequest`，然后调用`HAService`的`putRequest`添加到请求集合中，并唤醒`GroupTransferService`中在等待的线程：

```java
public class CommitLog {
    public void handleHA(AppendMessageResult result, PutMessageResult putMessageResult, MessageExt messageExt) {
        // 判断是否是同步复制到从节点
        if (BrokerRole.SYNC_MASTER == this.defaultMessageStore.getMessageStoreConfig().getBrokerRole()) {
            HAService service = this.defaultMessageStore.getHaService();
            // 如果是同步复制，也可以在发送消息时手动设置不等待同步成功就返回，这样增加了同步复制场景下的灵活性。在小部分不需要的同步复制，
            // 但是RocketMQ又配置为主从同步复制的场景下，也使得消息异步复制
            if (messageExt.isWaitStoreMsgOK()) {
                // Determine whether to wait
                if (service.isSlaveOK(result.getWroteOffset() + result.getWroteBytes())) {
                    // 提交主从同步任务
                    GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes());
                    // 添加请求
                    service.putRequest(request);
                    // 唤醒GroupTransferService中在等待的线程
                    service.getWaitNotifyObject().wakeupAll();
                    // 等待同步复制任务完成，异步同步线程复制完毕后会唤醒当前线程，超时时间默认为5s，如果超时则返回刷盘错误，刷盘成功后正常返回给调用方。
                    boolean flushOK =
                        request.waitForFlush(this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout());
                    if (!flushOK) {
                        log.error("do sync transfer other node, wait return, but failed, topic: " + messageExt.getTopic() + " tags: "
                            + messageExt.getTags() + " client address: " + messageExt.getBornHostNameString());
                        putMessageResult.setPutMessageStatus(PutMessageStatus.FLUSH_SLAVE_TIMEOUT);
                    }
                }
                // Slave problem
                else {
                    // Tell the producer, slave not available
                    putMessageResult.setPutMessageStatus(PutMessageStatus.SLAVE_NOT_AVAILABLE);
                }
            }
        }

    }
}

```

在`HAService.GroupCommitRequest.doWaitTransfer`方法中，会判断 `CommitLog` 提交请求集合 `requestsRead` 是否为空，如果不为空，表示有消息写入了 `CommitLog`，Master节点需要等待将数据传输给从节点：

1. `push2SlaveMaxOffset` 记录了从节点已经同步的消息偏移量，判断 `push2SlaveMaxOffset` 是否大于本次 `CommitLog` 提交的偏移量，也就是请求中设置的偏移量；
2. 获取请求中设置的等待截止时间；
3. 开启循环，判断数据是否还未传输完毕，并且未超过截止时间，如果是则等待1s，然后继续判断传输是否完毕，不断进行，直到超过截止时间或者数据已经传输完毕；
   （向从节点发送的消息最大偏移量 `push2SlaveMaxOffset` 超过了请求中设置的偏移量表示本次同步数据传输完毕）；
4. 唤醒在等待数据同步完毕的线程；

```java
public class HAService {
    // CommitLog提交请求集合
    private volatile LinkedList<CommitLog.GroupCommitRequest> requestsRead = new LinkedList<>();

    class GroupTransferService extends ServiceThread {

        private void doWaitTransfer() {
            synchronized (this.requestsRead) {
                if (!this.requestsRead.isEmpty()) {
                    for (CommitLog.GroupCommitRequest req : this.requestsRead) {
                        // 判断主从同步是否完成，判断传输到从节点最大偏移量是否超过了请求中设置的偏移量
                        boolean transferOK = HAService.this.push2SlaveMaxOffset.get() >= req.getNextOffset();
                        // 默认同步有5s的超时时间
                        long waitUntilWhen = HAService.this.defaultMessageStore.getSystemClock().now()
                            + HAService.this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout();
                        // 如果从节点还未同步完毕并且未超过截止时间
                        while (!transferOK && HAService.this.defaultMessageStore.getSystemClock().now() < waitUntilWhen) {
                            // 等待
                            this.notifyTransferObject.waitForRunning(1000);
                            // 判断从节点同步的最大偏移量是否超过了请求中设置的偏移量
                            transferOK = HAService.this.push2SlaveMaxOffset.get() >= req.getNextOffset();
                        }

                        if (!transferOK) {
                            log.warn("transfer messsage to slave timeout, " + req.getNextOffset());
                        }
                        // 同步完成，唤醒消息发送处理线程
                        req.wakeupCustomer(transferOK);
                    }

                    this.requestsRead.clear();
                }
            }
        }
    }
}
```

### 3.4 启动HAClient

HAClient可以看做是在从节点上运行的，主要进行的处理如下：

1. 调用`connectMaster`方法连接Master节点，Master节点上也会运行，但是它本身就是Master没有可连的Master节点，所以可以忽略；
2. 调用`isTimeToReportOffset`方法判断是否需要向Master节点汇报同步偏移量，如果需要则调用`reportSlaveMaxOffset`方法将当前的消息同步偏移量发送给Master节点；
3. 调用`processReadEvent`处理网络请求中的可读事件，**也就是处理Master发送过来的消息，将消息存入CommitLog**；

```java
public class HAService {
    class HAClient extends ServiceThread {
   
        @Override
        public void run() {
            log.info(this.getServiceName() + " service started");
            while (!this.isStopped()) {
                try {
                    // 连接Master节点
                    if (this.connectMaster()) {
                        // 是否需要报告消息同步偏移量
                        if (this.isTimeToReportOffset()) {
                            // 向Master节点发送同步偏移量
                            boolean result = this.reportSlaveMaxOffset(this.currentReportedOffset);
                            if (!result) {
                                this.closeMaster();
                            }
                        }
                        // 等待事件产生
                        this.selector.select(1000);
                        // 处理读事件，也就是Master节点发送的数据
                        boolean ok = this.processReadEvent();
                        if (!ok) {
                            this.closeMaster();
                        }
                        // ...
                    } else {
                        this.waitForRunning(1000 * 5);
                    }
                } catch (Exception e) {
                    log.warn(this.getServiceName() + " service has exception. ", e);
                    this.waitForRunning(1000 * 5);
                }
            }

            log.info(this.getServiceName() + " service end");
        }
    }
}
```

#### 3.4.1 连接主节点

`connectMaster` 方法中会获取Master节点的地址，并转换为 `SocketAddress` 对象，然后向Master节点请求建立连接，并在selector注册OP_READ可读事件监听：

```java
public class HAService {
    class HAClient extends ServiceThread {
    // 当前的主从复制进度
    private long currentReportedOffset = 0;

    private boolean connectMaster() throws ClosedChannelException {
        // 如果socketChannel为空，则尝试连接主服务器
        if (null == socketChannel) {
            String addr = this.masterAddress.get();
            if (addr != null) {
                // 将地址转为SocketAddress
                SocketAddress socketAddress = RemotingUtil.string2SocketAddress(addr);
                if (socketAddress != null) {
                    // 建立与Master的连接
                    this.socketChannel = RemotingUtil.connect(socketAddress);
                    if (this.socketChannel != null) {
                        // 注册OP_READ（网络读事件）
                        this.socketChannel.register(this.selector, SelectionKey.OP_READ);
                    }
                }
            }

            // 获取从节点本地的CommitLog最大偏移量
            this.currentReportedOffset = HAService.this.defaultMessageStore.getMaxPhyOffset();
            // 更新上次心跳发送时间
            this.lastWriteTimestamp = System.currentTimeMillis();
        }

        // 如果主服务器地址为空，返回false
        return this.socketChannel != null;
    }
}

```

#### 3.4.2 发送主从同步消息拉取偏移量

在`isTimeToReportOffset`方法中，首先获取当前时间与上一次进行主从同步的时间间隔interval，如果时间间隔interval大于配置的发送心跳时间间隔，表示需要向Master节点发送从节点消息同步的偏移量，接下来会调用`reportSlaveMaxOffset`方法发送同步偏移量，**也就是说从节点会定时向Master节点发送请求，反馈CommitLog中同步消息的偏移量**：

```java
public class HAService {
    class HAClient extends ServiceThread {
       // 当前从节点已经同步消息的偏移量大小
       private long currentReportedOffset = 0;

       private boolean isTimeToReportOffset() {
            // 获取距离上一次主从同步的间隔时间
            long interval =
                HAService.this.defaultMessageStore.getSystemClock().now() - this.lastWriteTimestamp;
            // 判断是否超过了配置的发送心跳包时间间隔
            boolean needHeart = interval > HAService.this.defaultMessageStore.getMessageStoreConfig()
                .getHaSendHeartbeatInterval();

            return needHeart;
        }

        // 发送同步偏移量,传入的参数是当前的主从复制偏移量currentReportedOffset
        private boolean reportSlaveMaxOffset(final long maxOffset) {
            this.reportOffset.position(0);
            this.reportOffset.limit(8); // 设置数据传输大小为8个字节
            this.reportOffset.putLong(maxOffset);// 设置同步偏移量
            this.reportOffset.position(0);
            this.reportOffset.limit(8);

            for (int i = 0; i < 3 && this.reportOffset.hasRemaining(); i++) {
                try {
                    // 向Master节点发送拉取偏移量
                    this.socketChannel.write(this.reportOffset);
                } catch (IOException e) {
                    log.error(this.getServiceName()
                        + "reportSlaveMaxOffset this.socketChannel.write exception", e);
                    return false;
                }
            }
            // 更新上次心跳发送时间
            lastWriteTimestamp = HAService.this.defaultMessageStore.getSystemClock().now();
            return !this.reportOffset.hasRemaining();
        }
    }
}
```

#### 3.4.3 处理网络读事件

`processReadEvent`方法中处理了可读事件，也就是处理Master节点发送的同步数据，首先从 `socketChannel` 中读取数据到`byteBufferRead` 中，`byteBufferRead` 是读缓冲区，读取数据的方法会返回读取到的字节数，对字节数大小进行判断：

- 如果可读字节数大于0表示有数据需要处理，调用`dispatchReadRequest`方法进行处理;
- 如果可读字节数为0表示没有可读数据，此时记录读取到空数据的次数，如果连续读到空数据的次数大于3次，将终止本次处理;

```java
  class HAClient extends ServiceThread {
        // 读缓冲区，会将从socketChannel读入缓冲区
        private ByteBuffer byteBufferRead = ByteBuffer.allocate(READ_MAX_BUFFER_SIZE);

        private boolean processReadEvent() {
            int readSizeZeroTimes = 0;
            // 循环判断readByteBuffer是否还有剩余空间，如果存在剩余空间，则调用
            // SocketChannel#read（ByteBuffer readByteBuffer）方法，将通道中
            // 的数据读入读缓存区。
            while (this.byteBufferRead.hasRemaining()) {
                try {
                    // 从socketChannel中读取数据到byteBufferRead中，返回读取到的字节数
                    int readSize = this.socketChannel.read(this.byteBufferRead);
                    if (readSize > 0) {
                        // 重置readSizeZeroTimes
                        readSizeZeroTimes = 0;
                          // 然后调用dispatchReadRequest方法将读取到的所有消息全部追加到消息内存映射文件中，再次反馈拉取进度给主服务器。
                        boolean result = this.dispatchReadRequest();
                        if (!result) {
                            log.error("HAClient, dispatchReadRequest error");
                            return false;
                        }
                    } else if (readSize == 0) {
                        // 记录读取到空数据的次数
                        if (++readSizeZeroTimes >= 3) {
                            break;
                        }
                    } else {
                        log.info("HAClient, processReadEvent read socket < 0");
                        return false;
                    }
                } catch (IOException e) {
                    log.info("HAClient, processReadEvent read socket exception", e);
                    return false;
                }
            }

            return true;
        }
  }
```

`dispatchReadRequest`方法中会将从节点读取到的数据写入 `CommitLog`，`dispatchPosition`记录了已经处理的数据在读缓冲区中的位置，从读缓冲区`byteBufferRead`获取剩余可读取的字节数，如果可读数据的字节数大于一个消息头的字节数（12个字节），表示有数据还未处理完毕，反之表示消息已经处理完毕结束处理。对数据的处理逻辑如下：

1. 从缓冲区中读取数据，首先获取到的是消息在master节点的物理偏移量masterPhyOffset；
2. 向后读取8个字节，得到消息体内容的字节数bodySize；
3. 获取从节点当前 `CommitLog` 的最大物理偏移量 `slavePhyOffset`，如果不为0并且不等于 `masterPhyOffset`，**表示与Master节点的传输偏移量不一致，也就是数据不一致，此时终止处理**；
4. 如果可读取的字节数大于一个消息头的字节数 + 消息体大小，表示有消息可处理，继续进行下一步；
5. 计算消息体在读缓冲区中的起始位置，**从读缓冲区中根据起始位置，读取消息内容，将消息追加到从节点的CommitLog中**；
6. 更新dispatchPosition的值为消息头大小 + 消息体大小，dispatchPosition之前的数据表示已经处理完毕；

![](../images/61.png)

```java
    class HAClient extends ServiceThread {
        // 已经处理的数据在读缓冲区中的位置,初始化为0
        private int dispatchPosition = 0;
        // 读缓冲区
        private ByteBuffer byteBufferRead = ByteBuffer.allocate(READ_MAX_BUFFER_SIZE);

        private boolean dispatchReadRequest() {
            // 消息头大小
            final int msgHeaderSize = 8 + 4; // phyoffset + size
            // 开启循环不断读取数据
            while (true) {
                // 获可读取的字节数
                int diff = this.byteBufferRead.position() - this.dispatchPosition;
                // 如果字节数大于一个消息头的字节数
                if (diff >= msgHeaderSize) {
                    // 获取消息在master节点的物理偏移量
                    long masterPhyOffset = this.byteBufferRead.getLong(this.dispatchPosition);
                    // 获取消息体大小
                    int bodySize = this.byteBufferRead.getInt(this.dispatchPosition + 8);
                    // 获取从节点当前CommitLog的最大物理偏移量
                    long slavePhyOffset = HAService.this.defaultMessageStore.getMaxPhyOffset();
                    if (slavePhyOffset != 0) {
                        // 如果不一致结束处理
                        if (slavePhyOffset != masterPhyOffset) {
                            log.error("master pushed offset not equal the max phy offset in slave, SLAVE: "
                                + slavePhyOffset + " MASTER: " + masterPhyOffset);
                            return false;
                        }
                    }
                    // 如果可读取的字节数大于一个消息头的字节数 + 消息体大小
                    if (diff >= (msgHeaderSize + bodySize)) {
                        // 将度缓冲区的数据转为字节数组
                        byte[] bodyData = byteBufferRead.array();
                        // 计算消息体在读缓冲区中的起始位置
                        int dataStart = this.dispatchPosition + msgHeaderSize;
                        // 从读缓冲区中根据消息的位置，读取消息内容，将消息追加到从节点的CommitLog中
                        HAService.this.defaultMessageStore.appendToCommitLog(
                                masterPhyOffset, bodyData, dataStart, bodySize);
                        // 更新dispatchPosition的值为消息头大小+消息体大小
                        this.dispatchPosition += msgHeaderSize + bodySize;
                        if (!reportSlaveMaxOffsetPlus()) {
                            return false;
                        }
                        continue;
                    }
                }
                if (!this.byteBufferRead.hasRemaining()) {
                    this.reallocateByteBuffer();
                }

                break;
            }

            return true;
        }
    }
```

### 3.5 HAConnection

HAConnection中封装了Master节点与从节点的网络通信处理，分别在`ReadSocketService`和`WriteSocketService`中。

#### 3.5.1 ReadSocketService

`ReadSocketService`启动后处理监听到的可读事件，前面知道HAClient中从节点会定时向Master节点汇报从节点的消息同步偏移量，Master节点对汇报请求的处理就在这里，如果从网络中监听到了可读事件，会调用`processReadEvent`处理读事件：

```java
public class HAConnection {
     class ReadSocketService extends ServiceThread {
        @Override
        public void run() {
            HAConnection.log.info(this.getServiceName() + " service started");
            while (!this.isStopped()) {
                try {
                    this.selector.select(1000);
                    // 处理可读事件
                    boolean ok = this.processReadEvent();
                    if (!ok) {
                        HAConnection.log.error("processReadEvent error");
                        break;
                    }
                    // ...
                } catch (Exception e) {
                    HAConnection.log.error(this.getServiceName() + " service has exception.", e);
                    break;
                }
            }
            // ...
            HAConnection.log.info(this.getServiceName() + " service end");
        }
     }
}

```

`processReadEvent`中从网络中处理读事件的方式与上面`HAClient`的`dispatchReadRequest`类似，都是将网络中的数据读取到读缓冲区中，并用一个变量记录已读取数据的位置，`processReadEvent`方法的处理逻辑如下：

1. 从socketChannel读取数据到读缓冲区byteBufferRead中，返回读取到的字节数；
2. 如果读取到的字节数大于0，进入下一步，如果读取到的字节数为0，记录连续读取到空字节数的次数是否超过三次，如果超过终止处理；
3. 判断剩余可读取的字节数是否大于等于8，前面知道，从节点发送同步消息拉取偏移量的时候设置的字节大小为8，所以字节数大于等于8的时候表示需要读取从节点发送的偏移量；
4. 计算数据在缓冲区中的位置，从缓冲区读取从节点发送的同步偏移量readOffset；
5. 更新processPosition的值，processPosition表示读缓冲区中已经处理数据的位置；
6. 更新slaveAckOffset为从节点发送的同步偏移量readOffset的值；
7. 如果当前Master节点记录的从节点的同步偏移量slaveRequestOffset小于0，表示还未进行同步，此时将slaveRequestOffset更新为从节点发送的同步偏移量；
8. 如果从节点发送的同步偏移量比当前Master节点的最大物理偏移量还要大，终止本次处理；
9. 调用notifyTransferSome，更新Master节点记录的向从节点同步消息的偏移量；

```java
public class HAConnection {

     class ReadSocketService extends ServiceThread {
     // 读缓冲区    
     private final ByteBuffer byteBufferRead = ByteBuffer.allocate(READ_MAX_BUFFER_SIZE);
     // 读缓冲区中已经处理的数据位置
     private int processPosition = 0;

     private boolean processReadEvent() {
            int readSizeZeroTimes = 0;
            // 如果没有可读数据
            if (!this.byteBufferRead.hasRemaining()) {
                this.byteBufferRead.flip();
                // 处理位置置为0
                this.processPosition = 0;
            }
            // 如果数据未读取完毕
            while (this.byteBufferRead.hasRemaining()) {
                try {
                    // 从socketChannel读取数据到byteBufferRead中，返回读取到的字节数
                    int readSize = this.socketChannel.read(this.byteBufferRead);
                    // 如果读取数据字节数大于0
                    if (readSize > 0) {
                        // 重置readSizeZeroTimes
                        readSizeZeroTimes = 0;
                        // 获取上次处理读事件的时间戳
                        this.lastReadTimestamp = HAConnection.this.haService.getDefaultMessageStore().getSystemClock().now();
                        // 判断剩余可读取的字节数是否大于等于8
                        if ((this.byteBufferRead.position() - this.processPosition) >= 8) {
                            // 获取偏移量内容的结束位置
                            int pos = this.byteBufferRead.position() - (this.byteBufferRead.position() % 8);
                            // 从结束位置向前读取8个字节得到从点发送的同步偏移量
                            long readOffset = this.byteBufferRead.getLong(pos - 8);
                            // 更新处理位置
                            this.processPosition = pos;
                            // 更新slaveAckOffset为从节点发送的同步进度
                            HAConnection.this.slaveAckOffset = readOffset;
                            // 如果记录的从节点的同步进度小于0，表示还未进行同步
                            if (HAConnection.this.slaveRequestOffset < 0) {
                                // 更新为从节点发送的同步进度
                                HAConnection.this.slaveRequestOffset = readOffset;
                                log.info("slave[" + HAConnection.this.clientAddr + "] request offset " + readOffset);
                            } else if (HAConnection.this.slaveAckOffset > HAConnection.this.haService.getDefaultMessageStore().getMaxPhyOffset()) {
                                // 如果从节点发送的拉取偏移量比当前Master节点的最大物理偏移量还要大
                                log.warn("slave[{}] request offset={} greater than local commitLog offset={}. ",
                                        HAConnection.this.clientAddr,
                                        HAConnection.this.slaveAckOffset,
                                        HAConnection.this.haService.getDefaultMessageStore().getMaxPhyOffset());
                                return false;
                            }
                            // 更新Master节点记录的向从节点同步消息的偏移量
                            HAConnection.this.haService.notifyTransferSome(HAConnection.this.slaveAckOffset);
                        }
                    } else if (readSize == 0) 
                        // 判断连续读取到空数据的次数是否超过三次
                        if (++readSizeZeroTimes >= 3) {
                            break;
                        }
                    } else {
                        log.error("read socket[" + HAConnection.this.clientAddr + "] < 0");
                        return false;
                    }
                } catch (IOException e) {
                    log.error("processReadEvent exception", e);
                    return false;
                }
            }

            return true;
        }
    }
}

```

前面在 `GroupTransferService` 中可以看到是通过 `push2SlaveMaxOffset` 的值判断本次同步是否完成的，在 `notifyTransferSome` 方法中可以看到当Master节点收到从节点反馈的消息拉取偏移量时，对 `push2SlaveMaxOffset` 的值进行了更新：

```java
public class HAService {
    // 向从节点推送的消息最大偏移量
    private final GroupTransferService groupTransferService;

    public void notifyTransferSome(final long offset) {
        // 如果传入的偏移大于push2SlaveMaxOffset记录的值，进行更新
        for (long value = this.push2SlaveMaxOffset.get(); offset > value; ) {
            // 更新向从节点推送的消息最大偏移量
            boolean ok = this.push2SlaveMaxOffset.compareAndSet(value, offset);
            if (ok) {
                this.groupTransferService.notifyTransferSome();
                break;
            } else {
                value = this.push2SlaveMaxOffset.get();
            }
        }
    }
}
```

#### 3.5.2 WriteSocketService

`WriteSocketService`用于Master节点向从节点发送同步消息，处理逻辑如下：

1. 根据从节点发送的主从同步消息拉取偏移量`slaveRequestOffset`进行判断：
   - 如果`slaveRequestOffset`值为-1，表示还未收到从节点报告的同步偏移量，此时睡眠一段时间等待从节点发送消息拉取偏移量；
   - 如果`slaveRequestOffset`值不为-1，表示已经开始进行主从同步进行下一步；
2. 判断`nextTransferFromWhere`值是否为-1，**nextTransferFromWhere记录了下次需要传输的消息在CommitLog中的偏移量**，如果值为-1表示初次进行数据同步，此时有两种情况：
   - 如果从节点发送的拉取偏移量slaveRequestOffset为0，就从当前CommitLog文件最大偏移量开始同步；
   - 如果slaveRequestOffset不为0，则从slaveRequestOffset位置处进行数据同步；
3. 判断上次写事件是否已经将数据都写入到从节点
   - 如果已经写入完毕，判断距离上次写入数据的时间间隔是否超过了设置的心跳时间，如果超过，为了避免连接空闲被关闭，需要发送一个心跳包，此时构建心跳包的请求数据，调用transferData方法传输数据；
   - 如果上次的数据还未传输完毕，调用transferData方法继续传输，如果还是未完成，则结束此处处理；
4. 根据nextTransferFromWhere从CommitLog中获取消息，如果未获取到消息，等待100ms，如果获取到消息，从CommitLog中获取消息进行传输：
   （1）如果获取到消息的字节数大于最大传输的大小，设置最最大传输数量，分批进行传输；
   （2）更新下次传输的偏移量地址也就是nextTransferFromWhere的值；
   （3）从CommitLog中获取的消息内容设置到将读取到的消息数据设置到selectMappedBufferResult中；
   （4）设置消息头信息，包括消息头字节数、拉取消息的偏移量等；
   （5）调用transferData发送数据；

```java
public class HAConnection {
    class WriteSocketService extends ServiceThread {
        private final int headerSize = 8 + 4;// 消息头大小
        @Override
        public void run() {
            HAConnection.log.info(this.getServiceName() + " service started");
            while (!this.isStopped()) {
                try {
                    this.selector.select(1000);
                    // 如果slaveRequestOffset为-1，表示还未收到从节点报告的拉取进度
                    if (-1 == HAConnection.this.slaveRequestOffset) {
                        // 等待一段时间
                        Thread.sleep(10);
                        continue;
                    }
                    // 初次进行数据同步
                    if (-1 == this.nextTransferFromWhere) {
                        // 如果拉取进度为0
                        if (0 == HAConnection.this.slaveRequestOffset) {
                            // 从master节点最大偏移量从开始传输
                            long masterOffset = HAConnection.this.haService.getDefaultMessageStore().getCommitLog().getMaxOffset();
                            masterOffset =
                                masterOffset
                                    - (masterOffset % HAConnection.this.haService.getDefaultMessageStore().getMessageStoreConfig()
                                    .getMappedFileSizeCommitLog());

                            if (masterOffset < 0) {
                                masterOffset = 0;
                            }
                            // 更新nextTransferFromWhere
                            this.nextTransferFromWhere = masterOffset;
                        } else {
                            // 根据从节点发送的偏移量开始数据同步
                            this.nextTransferFromWhere = HAConnection.this.slaveRequestOffset;
                        }

                        log.info("master transfer data from " + this.nextTransferFromWhere + " to slave[" + HAConnection.this.clientAddr
                            + "], and slave request " + HAConnection.this.slaveRequestOffset);
                    }
                    // 判断上次传输是否完毕
                    if (this.lastWriteOver) {
                        // 获取当前时间距离上次写入数据的时间间隔
                        long interval =
                            HAConnection.this.haService.getDefaultMessageStore().getSystemClock().now() - this.lastWriteTimestamp;
                        // 如果距离上次写入数据的时间间隔超过了设置的心跳时间
                        if (interval > HAConnection.this.haService.getDefaultMessageStore().getMessageStoreConfig()
                            .getHaSendHeartbeatInterval()) {
                            // 构建header
                            this.byteBufferHeader.position(0);
                            this.byteBufferHeader.limit(headerSize);
                            this.byteBufferHeader.putLong(this.nextTransferFromWhere);
                            this.byteBufferHeader.putInt(0);
                            this.byteBufferHeader.flip();
                            // 发送心跳包
                            this.lastWriteOver = this.transferData();
                            if (!this.lastWriteOver)
                                continue;
                        }
                    } else {
                        // 未传输完毕，继续上次的传输
                        this.lastWriteOver = this.transferData();
                        // 如果依旧未完成，结束本次处理
                        if (!this.lastWriteOver)
                            continue;
                    }
                    // 根据偏移量获取消息数据
                    SelectMappedBufferResult selectResult =
                        HAConnection.this.haService.getDefaultMessageStore().getCommitLogData(this.nextTransferFromWhere);
                    if (selectResult != null) {// 获取消息不为空
                        // 获取消息内容大小
                        int size = selectResult.getSize();
                        // 如果消息的字节数大于最大传输的大小
                        if (size > HAConnection.this.haService.getDefaultMessageStore().getMessageStoreConfig().getHaTransferBatchSize()) {
                            // 设置为最大传输大小
                            size = HAConnection.this.haService.getDefaultMessageStore().getMessageStoreConfig().getHaTransferBatchSize();
                        }

                        long thisOffset = this.nextTransferFromWhere;
                        // 更新下次传输的偏移量地址
                        this.nextTransferFromWhere += size;

                        selectResult.getByteBuffer().limit(size);
                        // 将读取到的消息数据设置到selectMappedBufferResult
                        this.selectMappedBufferResult = selectResult;

                        // 设置消息头
                        this.byteBufferHeader.position(0);
                        // 设置消息头大小
                        this.byteBufferHeader.limit(headerSize);
                        // 设置偏移量地址
                        this.byteBufferHeader.putLong(thisOffset);
                        // 设置消息内容大小
                        this.byteBufferHeader.putInt(size);
                        this.byteBufferHeader.flip();
                        // 发送数据
                        this.lastWriteOver = this.transferData();
                    } else {
                        // 等待100ms
                        HAConnection.this.haService.getWaitNotifyObject().allWaitForRunning(100);
                    }
                } catch (Exception e) {

                    HAConnection.log.error(this.getServiceName() + " service has exception.", e);
                    break;
                }
            }

            HAConnection.this.haService.getWaitNotifyObject().removeFromWaitingThreadTable();

            // ...
            HAConnection.log.info(this.getServiceName() + " service end");
        }
    }
}
```

## 四. 总结

![](../images/62.png)

**有新消息写入之后的同步流程**

![](../images/1.jpg)

> 本文参考至：
>
> [【RocketMQ】【源码】主从同步实现原理 - shanml - 博客园 (cnblogs.com)](https://www.cnblogs.com/shanml/p/16950178.html) 
>
> [RocketMQ(九)：主从同步的实现 - 阿牛20 - 博客园 (cnblogs.com)](https://www.cnblogs.com/yougewe/p/14198675.html) 
>
> [【RocketMQ】主从同步实现原理 - shanml - 博客园 (cnblogs.com)](https://www.cnblogs.com/shanml/p/17301201.html)