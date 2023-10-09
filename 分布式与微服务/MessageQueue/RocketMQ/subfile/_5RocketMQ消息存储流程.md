# RocketMQ消息存储流程

> 本文转载至：[RocketMQ 消息存储流程 | 赵坤的个人网站 (kunzhao.org)](https://kunzhao.org/docs/rocketmq/rocketmq-message-store-flow/)

> 本文基于RocketMQ 4.8.0进行源码分析

## 一. 存储概要设计

RocketMQ存储的文件主要包括CommitLog文件、ConsumeQueue文件、Index文件。RocketMQ将所有topic的消息存储在同一个文件中，确保消息发送时按顺序写文件，尽最大的能力确保消息发送的高性能与高吞吐量。因为消息中间件一般是基于消息主题的订阅机制，所以给按照消息主题检索消息带来了极大的不便。为了提高消息消费的效率，RocketMQ引入了ConsumeQueue消息消费队列文件，每个topic包含多个消息消费队列，每一个消息队列有一个消息文件。Index索引文件的设计理念是为了加速消息的检索性能，根据消息的属性从CommitLog文件中快速检索消息。

![](../images/55.png)

- CommitLog ：消息存储文件，所有topic的消息都存储在CommitLog 文件中。

- ConsumeQueue ：消息消费队列，消息到达CommitLog 文件后，将异步转发到消息消费队列，供消息消费者消费。

- IndexFile ：消息索引文件，主要存储消息Key 与Offset 的对应关系。

### 1.1 CommitLog

RocketMQ 在消息写入过程中追求极致的磁盘顺序写，所有topic的消息全部写入一个文件，即 CommitLog 文件。所有消息按抵达顺序依次

追加到 CommitLog 文件中，消息一旦写入，不支持修改。CommitLog 文件默认创建的大小为 1GB。

![](../images/29.png)

一个文件为 1GB 大小，也即 `1024 * 1024 * 1024 = 1073741824` 字节，CommitLog 每个文件的命名是按照总的字节偏移量来命名的。例如第一个文件偏移量为 0，那么它的名字为 `00000000000000000000`；当前这 1G 文件被存储满了之后，就会创建下一个文件，下一个文件的偏移量则为 1GB，那么它的名字为 `00000000001073741824`，以此类推。

![](../images/30.png)

默认情况下这些消息文件位于 `$HOME/store/commitlog` 目录下，如下图所示:

![](../images/32.png)



基于文件编程与基于内存编程一个很大的不同是基于内存编程时我们有现成的数据结构，例如List、HashMap，对数据的读写非常方便，那么一条一条消息存入CommitLog文件后，该如何查找呢？

正如关系型数据库会为每条数据引入一个ID字段，基于文件编程也会为每条消息引入一个身份标志：消息物理偏移量，即消息存储在文件的起始位置。

正是有了物理偏移量的概念，CommitLog文件的命名方式也是极具技巧性，使用存储在该文件的第一条消息在整个CommitLog文件组中的偏移量来命名，例如第一个CommitLog文件为0000000000000000000，第二个CommitLog文件为00000000001073741824，依次类推。

这样做的好处是给出任意一个消息的物理偏移量，可以通过二分法进行查找，快速定位这个文件的位置，然后用消息物理偏移量减去所在文件的名称，得到的差值就是在该文件中的绝对地址。

### 1.2 ConsumeQueue

CommitlLog文件的设计理念是追求极致的消息写，但我们知道消息消费模型是基于主题订阅机制的，即一个消费组是消费特定主题的消息。根据主题从CommitlLog文件中检索消息，这绝不是一个好主意，这样只能从文件的第一条消息逐条检索，其性能可想而知，为了解决基于topic的消息检索问题，RocketMQ引入了ConsumeQueue文件。ConsumeQueue文件结构入下图：

![](../images/2.webp)

ConsumeQueue文件是消息消费队列文件，是 CommitLog 文件基于topic的索引文件，主要用于消费者根据 topic 消费消息，其组织方式为 `/topic/queue`，同一个队列中存在多个消息文件。ConsumeQueue 的设计极具技巧，每个条目长度固定（8字节CommitLog物理偏移量、4字节消息长度、8字节tag哈希码）。这里不是存储tag的原始字符串，而是存储哈希码，目的是确保每个条目的长度固定，可以使用访问类似数组下标的方式快速定位条目，极大地提高了ConsumeQueue文件的读取性能。消息消费者根据topic、消息消费进度（ConsumeQueue逻辑偏移量），即第几个ConsumeQueue条目，这样的消费进度去访问消息，通过逻辑偏移量logicOffset×20，即可找到该条目的起始偏移量（ConsumeQueue文件中的偏移量），然后读取该偏移量后20个字节即可得到一个条目，无须遍历ConsumeQueue文件。

ConsumeQueue文件可以看作基于topic的CommitLog索引文件，故ConsumeQueue文件夹的组织方式为topic/queue/file三层组织结构，文件存储在 `$HOME/store/consumequeue/{topic}/{queueId}/{fileName}`，单个文件由30万个条目组成，每个文件大小约5.72MB。

### 1.3 Index

RocketMQ与Kafka相比具有一个强大的优势，就是支持按消息属性检索消息，引入ConsumeQueue文件解决了基于topic查找消息的问题，但如果想基于消息的某一个属性进行查找，ConsumeQueue文件就无能为力了。故RocketMQ又引入了Index索引文件，实现基于文件的哈希索引。Index文件的存储结构如下图所示。

![](../images/3.webp)

Index文件基于物理磁盘文件实现哈希索引。Index文件由40字节的文件头、500万个哈希槽、2000万个Index条目组成，每个哈希槽4字节、每个Index条目含有20个字节，分别为4字节索引key的哈希码、8字节消息物理偏移量、4字节时间戳、4字节的前一个Index条目（哈希冲突的链表结构）。

### 1.4 内存映射

虽然基于磁盘的顺序写消息可以极大提高I/O的写效率，但如果基于文件的存储采用常规的Java文件操作API，例如FileOutputStream等，将性能提升会很有限，故RocketMQ又引入了内存映射，将磁盘文件映射到内存中，以操作内存的方式操作磁盘，将性能又提升了一个档次。
在Java中可通过FileChannel的map方法创建内存映射文件。在Linux服务器中由该方法创建的文件使用的就是操作系统的页缓存（pagecache）。Linux操作系统中内存使用策略时会尽可能地利用机器的物理内存，并常驻内存中，即页缓存。在操作系统的内存不够的情况下，采用缓存置换算法，例如LRU将不常用的页缓存回收，即操作系统会自动管理这部分内存。

如果RocketMQ Broker进程异常退出，存储在页缓存中的数据并不会丢失，操作系统会定时将页缓存中的数据持久化到磁盘，实现数据安全可靠。不过如果是机器断电等异常情况，存储在页缓存中的数据也有可能丢失。

### 1.5 刷盘策略

有了顺序写和内存映射的加持，RocketMQ的写入性能得到了极大的保证，但凡事都有利弊，引入了内存映射和页缓存机制，消息会先写入页缓存，此时消息并没有真正持久化到磁盘。那么Broker收到客户端的消息后，是存储到页缓存中就直接返回成功，还是要持久化到磁盘中才返回成功呢？

这是一个“艰难”的选择，是在性能与消息可靠性方面进行权衡。为此，RocketMQ提供了三种策略：同步刷盘、异步刷盘、异步刷盘+缓冲区。

| 类型                                         | 描述            |
| -------------------------------------------- | --------------- |
| SYNC_FLUSH                                   | 同步刷盘        |
| ASYNC_FLUSH                                  | 异步刷盘        |
| ASYNC_FLUSH && transientStorePoolEnable=true | 异步刷盘+缓冲区 |

- 同步刷盘时，只有消息被真正持久化到磁盘才会响应ACK，可靠性非常高，但是性能会受到较大影响，适用于金融业务。
- 异步刷盘时，消息写入PageCache就会响应ACK，然后由后台线程异步将PageCache里的内容持久化到磁盘，降低了读写延迟，提高了性能和吞吐量。服务宕机消息不丢失，机器断电少量消息丢失。
- 异步刷盘+缓冲区，消息先写入直接内存缓冲区，然后由后台线程异步将缓冲区里的内容持久化到磁盘，性能最好。但是最不可靠，服务宕机和机器断电都会丢失消息。

### 1.6 文件恢复机制

我们知道，RocketMQ主要的数据存储文件包括CommitLog、ConsumeQueue和Index，而ConsumeQueue、Index文件是根据CommitLog文件异步构建的。既然是异步操作，这两者之间的数据就不可能始终保持一致，那么，重启broker时需要如何恢复数据呢？我们考虑如下异常场景。

1. 消息采用同步刷盘方式写入CommitLog文件，准备转发给ConsumeQueue文件时由于断电等异常，导致存储失败。

2. 在刷盘的时候，突然记录了100MB消息，准备将这100MB消息写入磁盘，由于机器突然断电，只写入50MB消息到CommitLog文件。

3. 在RocketMQ存储目录下有一个检查点（Checkpoint）文件，用于记录CommitLog等文件的刷盘点。但将数据写入CommitLog文件后才会将刷盘点记录到检查点文件中，有可能在从刷盘点写入检查点文件前数据就丢失了。

在RocketMQ中有broker异常停止恢复和正常停止恢复两种场景。这两种场景的区别是定位从哪个文件开始恢复的逻辑不一样，大致思路如下。

1. 尝试恢复ConsumeQueue文件，根据文件的存储格式（8字节物理偏移量、4字节长度、8字节tag哈希码），找到最后一条完整的消息格式所对应的物理偏移量，用maxPhysical OfConsumequeue表示。
2. 尝试恢复CommitLog文件，先通过文件的魔数判断该文件是否为ComitLog文件，然后按照消息的存储格式寻找最后一条合格的消息，拿到其物理偏移量，如果CommitLog文件的有效偏移量小于ConsumeQueue文件存储的最大物理偏移量，将会删除ConsumeQueue中多余的内容，如果大于，说明ConsuemQueue文件存储的内容少于CommitLog文件，则会重推数据。

那么如何定位要恢复的文件呢？

正常停止刷盘的情况下，先从倒数第三个文件开始进行恢复，然后按照消息的存储格式进行查找，如果该文件中所有的消息都符合消息存储格式，则继续查找下一个文件，直到找到最后一条消息所在的位置。

异常停止刷盘的情况下，RocketMQ会借助检查点文件，即存储的刷盘点，定位恢复的文件。刷盘点记录的是CommitLog、ConsuemQueue、Index文件最后的刷盘时间戳，但并不是只认为该时间戳之前的消息是有效的，超过这个时间戳之后的消息就是不可靠的。

异常停止刷盘时，从最后一个文件开始寻找，在寻找时读取该文件第一条消息的存储时间，如果这个存储时间小于检查点文件中的刷盘时间，就可以从这个文件开始恢复，如果这个文件中第一条消息的存储时间大于刷盘点，说明不能从这个文件开始恢复，需要寻找上一个文件，因为检查点文件中的刷盘点代表的是100%可靠的消息。

## 二. 文件创建

当有新的消息到来的时候，其会默认选择列表中的最后一个文件来进行消息的保存:

![](../images/33.png)

当有新的消息到来的时候，其会默认选择列表中的最后一个文件来进行消息的保存:

![](../images/31.png)

`org.apache.rocketmq.store.MappedFileQueue`：

```java
public class MappedFileQueue {
    public MappedFile getLastMappedFile() {
        MappedFile mappedFileLast = null;

        while (!this.mappedFiles.isEmpty()) {
            try {
                mappedFileLast = this.mappedFiles.get(this.mappedFiles.size() - 1);
                break;
            } catch (IndexOutOfBoundsException e) {
                //continue;
            } catch (Exception e) {
                log.error("getLastMappedFile has exception.", e);
                break;
            }
        }

        return mappedFileLast;
    }
}
```

当然如果这个 Broker 之前从未接受过消息的话，那么这个列表肯定是空的。这样一旦有新的消息需要存储的时候，其就得需要立即创建一个 `MappedFile` 文件来存储消息。

RocketMQ 提供了一个专门用来实例化 `MappedFile` 文件的服务类 `AllocateMappedFileService`。在内存中，也同时维护了一张请求表 `requestTable` 和一个优先级请求队列 `requestQueue` 。当需要创建文件的时候，Broker 会创建一个 `AllocateRequest` 对象，其包含了文件的路径、大小等信息。然后先将其放入 `requestTable` 表中，再将其放入优先级请求队列 `requestQueue` 中:

`org.apache.rocketmq.store.AllocateMappedFileService#putRequestAndReturnMappedFile`

```java
public class AllocateMappedFileService extends ServiceThread {

    public MappedFile putRequestAndReturnMappedFile(String nextFilePath,
                                                    String nextNextFilePath,
                                                    int fileSize) {

        // ...

        AllocateRequest nextReq = new AllocateRequest(nextFilePath, fileSize);
        boolean nextPutOK = this.requestTable.putIfAbsent(nextFilePath, nextReq) == null;
        if (nextPutOK) {
            // ...
            boolean offerOK = this.requestQueue.offer(nextReq);
        }
        
    }
    
}
```

服务类会**一直**等待优先级队列是否有新的请求到来，如果有，便会从队列中取出请求，然后创建对应的 `MappedFile`，并将请求表 requestTable 中 `AllocateRequest` 对象的字段 `mappedFile` 设置上值。最后将 `AllocateRequest` 对象上的 `CountDownLatch` 的计数器减 1 ，以标明此分配申请的 `MappedFile` 已经创建完毕了:

`org.apache.rocketmq.store.AllocateMappedFileService#mmapOperation`

```java
public class AllocateMappedFileService extends ServiceThread {
        public void run() {
        log.info(this.getServiceName() + " service started");
		//会一直尝试从队列中获取请求，从而执行创建文件的任务
        while (!this.isStopped() && this.mmapOperation()) {

        }
        log.info(this.getServiceName() + " service end");
    }

    /**
     * Only interrupted by the external thread, will return false
     */
    private boolean mmapOperation() {
        boolean isSuccess = false;
        AllocateRequest req = null;
        try {
            // 获取优先队列中的请求
            req = this.requestQueue.take();
            AllocateRequest expectedRequest = this.requestTable.get(req.getFilePath());

            // ...
            
            if (req.getMappedFile() == null) {
                long beginTime = System.currentTimeMillis();

                MappedFile mappedFile;
                if (messageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
                    try {
                        //创建MappedFile
                        mappedFile = ServiceLoader.load(MappedFile.class).iterator().next();
                        mappedFile.init(req.getFilePath(), req.getFileSize(), messageStore.getTransientStorePool());
                    } catch (RuntimeException e) {
                        log.warn("Use default implementation.");
                        mappedFile = new MappedFile(req.getFilePath(), req.getFileSize(), messageStore.getTransientStorePool());
                    }
                } else {
                    mappedFile = new MappedFile(req.getFilePath(), req.getFileSize());
                }

                // pre write mappedFile
                if (mappedFile.getFileSize() >= this.messageStore.getMessageStoreConfig()
                   //...
                }

                req.setMappedFile(mappedFile);
                this.hasException = false;
                isSuccess = true;
            }
        } catch (InterruptedException e) {
            log.warn(this.getServiceName() + " interrupted, possibly by shutdown.");
            this.hasException = true;
            return false;
        } catch (IOException e) {
            log.warn(this.getServiceName() + " service has exception. ", e);
            this.hasException = true;
            if (null != req) {
                requestQueue.offer(req);
                try {
                    Thread.sleep(1);
                } catch (InterruptedException ignored) {
                }
            }
        } finally {
            if (req != null && isSuccess)
                // 文件创建成功，计数减一。因为创建文件的动作是在独立的线程中完成的，业务线程需要等待文件创建完毕
                req.getCountDownLatch().countDown();
        }
        return true;
    }
}
```

等待 `MappedFile` 创建完毕之后，其便会从请求表 `requestTable` 中取出并删除表中记录:

`org.apache.rocketmq.store.AllocateMappedFileService#putRequestAndReturnMappedFile`

```java
public class AllocateMappedFileService extends ServiceThread {

    public MappedFile putRequestAndReturnMappedFile(String nextFilePath,
                                                    String nextNextFilePath,
                                                    int fileSize) {
        // ...........
        //获取请求
        AllocateRequest result = this.requestTable.get(nextFilePath);
        try {
            if (result != null) {
                // 等待 MappedFile 的创建完成
                boolean waitOK = result.getCountDownLatch().await(waitTimeOut, TimeUnit.MILLISECONDS);
                if (!waitOK) {
                    // 创建超时
                    log.warn("create mmap timeout " + result.getFilePath() + " " + result.getFileSize());
                    return null;
                } else {
                    //创建成功，则将requestTable中将请求移除
                    this.requestTable.remove(nextFilePath);
                    // 返回创建的MappedFiles
                    return result.getMappedFile();
                }
            } else {
                log.error("find preallocate mmap failed, this never happen");
            }
        } catch (InterruptedException e) {
            log.warn(this.getServiceName() + " service has exception. ", e);
        }

        return null;
    }
    
}
```

创建完成后将其加入列表中：

`org.apache.rocketmq.store.MappedFileQueue#getLastMappedFile(long, boolean)`

```java
public class MappedFileQueue {
    public MappedFile getLastMappedFile(final long startOffset, boolean needCreate) {
        long createOffset = -1;
        // 尝试获取最后一个MappedFile
        MappedFile mappedFileLast = getLastMappedFile();

        if (mappedFileLast == null) {
            createOffset = startOffset - (startOffset % this.mappedFileSize);
        }

        if (mappedFileLast != null && mappedFileLast.isFull()) {
            createOffset = mappedFileLast.getFileFromOffset() + this.mappedFileSize;
        }

        // 第一次启动未创建MappedFile
        if (createOffset != -1 && needCreate) {
            // 文件名
            String nextFilePath = this.storePath + File.separator + UtilAll.offset2FileName(createOffset);
            String nextNextFilePath = this.storePath + File.separator
                + UtilAll.offset2FileName(createOffset + this.mappedFileSize);
            MappedFile mappedFile = null;

            if (this.allocateMappedFileService != null) {
                // 提交一个创建MappedFile的请求
                mappedFile = this.allocateMappedFileService.putRequestAndReturnMappedFile(nextFilePath,
                    nextNextFilePath, this.mappedFileSize);
            } else {
                try {
                    mappedFile = new MappedFile(nextFilePath, this.mappedFileSize);
                } catch (IOException e) {
                    log.error("create mappedFile exception", e);
                }
            }

            if (mappedFile != null) {
                //创建成功
                if (this.mappedFiles.isEmpty()) {
                    mappedFile.setFirstCreateInQueue(true);
                }
                //加入列表
                this.mappedFiles.add(mappedFile);
            }

            return mappedFile;
        }

        return mappedFileLast;
    }    
}
```

![](../images/34.png)

至此，`MappedFile` 已经创建完毕，也即可以进行下一步的操作了。

## 三. 文件初始化

在 `MappedFile` 的构造函数中，其使用了 `FileChannel` 类提供的 map 函数来将磁盘上的这个文件映射到进程地址空间中。然后当通过 `MappedByteBuffer` 来读入或者写入文件的时候，磁盘上也会有相应的改动。采用这种方式，通常比传统的基于文件 IO 流的方式读取效率高。

```java
public class MappedFile extends ReferenceResource {
    
    public MappedFile(final String fileName, final int fileSize)
        throws IOException {
        init(fileName, fileSize);
    }

    private void init(final String fileName, final int fileSize)
        throws IOException {
        // ...
        this.fileChannel = new RandomAccessFile(this.file, "rw").getChannel();
        this.mappedByteBuffer = this.fileChannel.map(MapMode.READ_WRITE, 0, fileSize);
        // ...
    }
    
}
```

## 四. 消息文件加载

前面提到过，Broker 在启动的时候，会加载磁盘上的文件到一个 `mappedFiles` 列表中。但是加载完毕后，其还会对这份列表中的消息文件进行**验证 (恢复)**，确保没有错误。

验证的基本想法是通过一一读取列表中的每一个文件，然后再一一读取每个文件中的每个消息，在读取的过程中，其会更新整体的消息写入的偏移量，如下图中的红色箭头 (我们假设最终读取的消息的总偏移量为 905):

![](../images/35.png)

当确定消息整体的偏移量之后，Broker 便会确定每一个单独的 `MappedFile` 文件的**各自的偏移量**，每一个文件的偏移量是通过**取余**算法确定的:

`org.apache.rocketmq.store.MappedFileQueue#truncateDirtyFiles`:

```java
public class MappedFileQueue {

    public void truncateDirtyFiles(long offset) {

        for (MappedFile file : this.mappedFiles) {
            long fileTailOffset = file.getFileFromOffset() + this.mappedFileSize;
            if (fileTailOffset > offset) {
                if (offset >= file.getFileFromOffset()) {
                    // 确定每个文件的各自偏移量
                    file.setWrotePosition((int) (offset % this.mappedFileSize));
                    file.setCommittedPosition((int) (offset % this.mappedFileSize));
                    file.setFlushedPosition((int) (offset % this.mappedFileSize));
                } else {
                    // ...
                }
            }
        }

        // ...
    }
    
}
```

![](../images/36.png)

在确定每个消息文件各自的写入位置的同时，其还会删除**起始偏移量**大于当前总偏移量的消息文件，这些文件可以视作脏文件，或者也可以说这些文件里面一条消息也没有。这也是上述文件 `1073741824` 被打上红叉的原因:

```java
public void truncateDirtyFiles(long offset) {
    List<MappedFile> willRemoveFiles = new ArrayList<MappedFile>();

    for (MappedFile file : this.mappedFiles) {
        long fileTailOffset = file.getFileFromOffset() + this.mappedFileSize;
        if (fileTailOffset > offset) {
            if (offset >= file.getFileFromOffset()) {
                // ...
            } else {
                // 总偏移量 < 文件起始偏移量
                // 加入到待删除列表中
                file.destroy(1000);
                willRemoveFiles.add(file);
            }
        }
    }

    this.deleteExpiredFile(willRemoveFiles);
}
```

## 五. 写入消息

> 消息写入口：org.apache.rocketmq.store.CommitLog#putMessage

一旦我们获取到 `MappedFile` 文件之后，我们便可以往这个文件里面写入消息了。写入消息可能会遇见如下两种情况，一种是这条消息可以完全追加到这个文件中，另外一种是这条消息完全不能或者只有一小部分能存放到这个文件中，其余的需要放到新的文件中。我们对于这两种情况分别讨论:

### 5.1 文件可以完全存储消息

`MappedFile` 类维护了一个用以标识当前写位置的指针 `wrotePosition`，以及一个用来映射文件到进程地址空间的 `mappedByteBuffer`:

```java
public class MappedFile extends ReferenceResource {

    protected final AtomicInteger wrotePosition = new AtomicInteger(0);
    private MappedByteBuffer mappedByteBuffer;
    
}
```

由这两个数据结构我们可以看出来，单个文件的消息写入过程其实是非常简单的。首先获取到这个文件的写入位置，然后将消息内容追加到 `byteBuffer` 中，然后再更新写入位置。

```java
public class MappedFile extends ReferenceResource {

    public AppendMessageResult appendMessagesInner(final MessageExt messageExt, final AppendMessageCallback cb) {
        // ...
    
        int currentPos = this.wrotePosition.get();

        if (currentPos < this.fileSize) {
            ByteBuffer byteBuffer =
                writeBuffer != null ?
                writeBuffer.slice() :
                this.mappedByteBuffer.slice();

            // 更新 byteBuffer 位置
            byteBuffer.position(currentPos);

            // 写入消息内容
            // ...

            // 获取当前需要写入的消息长度，更新 wrotePosition 指针的位置
            this.wrotePosition.addAndGet(result.getWroteBytes());

            return result;
        }

    }
    
}
```

示例流程如下所示:

![](../images/37.png)

### 5.2 文件不可以完全存储消息

在写入消息之前，如果判断出文件已经满了的情况下，其会直接尝试创建一个新的 `MappedFile`:

```java
public class CommitLog {

    public PutMessageResult putMessage(final MessageExtBrokerInner msg) {

        // 文件为空 || 文件已经满了
        if (null == mappedFile || mappedFile.isFull()) {
            mappedFile = this.mappedFileQueue.getLastMappedFile(0);
        }

        // ...
        
        result = mappedFile.appendMessage(msg, this.appendMessageCallback);
        
    }
    
}
```

如果文件未满，那么在写入之前会先计算出消息体长度 `msgLen`，然后判断这个文件剩下的空间是否有能力容纳这条消息。在这个地方我们还需要介绍下每条消息的存储方式。

每条消息的存储是按照一个 4 字节的长度来做界限的，这个长度本身就是整个消息体的长度，当读完这整条消息体的长度之后，下一次再取出来的一个 4 字节的数字，便又是下一条消息的长度:

![](../images/38.png)

围绕着一条消息，还会存储许多其它内容，我们在这里只需要了解前两位是 4 字节的总长度和 4 字节的 MAGICCODE 即可:

![](../images/39.png)

`MAGICCODE` 的可选值有:

- `CommitLog.MESSAGE_MAGIC_CODE`
- `CommitLog.BLANK_MAGIC_CODE`

当这个文件有能力容纳这条消息体的情况下，其便会存储 `MESSAGE_MAGIC_CODE` 值；当这个文件没有能力容纳这条消息体的情况下，其便会存储 `BLANK_MAGIC_CODE` 值。所以这个 `MAGICCODE` 是用来界定这是空消息还是一条正常的消息。

当判定这个文件不足以容纳整个消息的时候，其将消息体长度设置为这个文件剩余的最大空间长度，将 `MAGICCODE` 设定为这是一个空消息文件 (需要去下一个文件去读)。由此我们可以看出消息体长度 和 `MAGICCODE` 是判别一条消息格式的最基本要求，这也是 `END_FILE_MIN_BLANK_LENGTH` 的值为 8 的原因:

`org.apache.rocketmq.store.CommitLog.DefaultAppendMessageCallback#doAppend(long, java.nio.ByteBuffer, int, org.apache.rocketmq.store.MessageExtBrokerInner)`

```java
public class CommitLog {

    
    class DefaultAppendMessageCallback implements AppendMessageCallback {

        // File at the end of the minimum fixed length empty
        private static final int END_FILE_MIN_BLANK_LENGTH = 4 + 4;

        public AppendMessageResult doAppend(final long fileFromOffset,
                                            final ByteBuffer byteBuffer,
                                            final int maxBlank,
                                            final MessageExtBrokerInner msgInner) {

            // ...

            if ((msgLen + END_FILE_MIN_BLANK_LENGTH) > maxBlank) {
                // ...

                // 1 TOTALSIZE
                this.msgStoreItemMemory.putInt(maxBlank);
                // 2 MAGICCODE
                this.msgStoreItemMemory.putInt(CommitLog.BLANK_MAGIC_CODE);
                // 3 The remaining space may be any value
                byteBuffer.put(this.msgStoreItemMemory.array(), 0, maxBlank);

                return new AppendMessageResult(AppendMessageStatus.END_OF_FILE,
                                               /** other params **/ );
            }

        }

    }
}
```

由上述方法我们看出在这种情况下返回的结果是 `END_OF_FILE`。当检测到这种返回结果的时候，`CommitLog` 接着又会申请创建新的 `MappedFile` 并尝试写入消息。追加方法同 (1) 相同，不再赘述:

![](../images/40.png)

> 注: 在消息文件加载的过程中，其也是通过判断 `MAGICCODE` 的类型，来判断是否继续读取下一个 `MappedFile` 来计算整体消息偏移量的。

## 六. 消息刷盘策略

### 6.2 异步刷盘

当配置为异步刷盘策略的时候，Broker 会运行一个服务 `FlushRealTimeService` 用来刷新缓冲区的消息内容到磁盘，这个服务使用一个独立的线程来做刷盘这件事情，默认情况下每隔 500ms 来检查一次是否需要刷盘:

```java
class FlushRealTimeService extends FlushCommitLogService {

    public void run() {

        // 不停运行
        while (!this.isStopped()) {

            // interval 默认值是 500ms
            if (flushCommitLogTimed) {
                Thread.sleep(interval);
            } else {
                this.waitForRunning(interval);
            }

            // 刷盘
            CommitLog.this.mappedFileQueue.flush(flushPhysicQueueLeastPages);

        }
        
    }
    
}
```

