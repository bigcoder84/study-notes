# Redis持久化

Redis支持RDB和AOF两种持久化机制，持久化功能有效地避免因进程退出造成的数据丢失问题，当下次重启时利用之前持久化的文件即可实现数据恢复。

## 一. RDB

RDB持久化是将当前进程数据生成快照保存在硬盘中的过程，触发RDB持久化过程分为手动粗发和自动触发。

### 1.1 触发时机

#### 1.1.1 手动触发

手动触发分别对应`save`和`bgsave`命令：

- `save`命令：阻塞当前Redis服务器，直到RDB过程完成为止，对于内存比较大的实例会造成长时间的阻塞，线上环境不建议使用。运行save命令对应的Redis日志如下：

  ```shell
  * DB saved on disk
  ```

- `bgsave`命令：Redis进程执行fork操作创建子进程，RDB持久化过程由子进程负责，完成后自动结束。阻塞只发生在fork阶段，一般时间比较短。执行`bgsave`命令对应的Redis日志如下：

  ```shell
  * Backgroud saving started by pid 2131
  * DB saved on disk
  * RDB: 0 MB of memory used by copy-on-write
  * Backgroud saving terminated with success
  ```

显然`bgsave`是对`save`阻塞问题做的优化。因此Redis内部所有的涉及RDB操作都采用`bgsave`的方式，而`save`命令已经废弃。

#### 1.1.2 自动触发

除了手动触发以外，Redis内部还存在自动触发RDB持久化的机制：

自动触发最常见的情况是在配置文件中通过`save m n`，指定当 m 秒内发生 n 次变化时，会自动触发`bgsave`。

![](../images/48.png)

#### 1.1.3 其他触发时机

除了`save m n`以外，还有一些其他情况会自动触发`bgsave`：

1. 如果从节点执行全量复制操作，主节点自动执行`bgsave`生成RDB文件并发送给从节点。
2. 执行debug reload命令重新加载Redis时，也会自动触发save操作。
3. 默认情况下执行shutdown命令时，如果没有开启AOF持久化功能则自动执行`bgsave`

### 1.2 RDB流程说明

bgsave是主流的触发RDB持久化方式，下图是运作流程：

![](../images/49.png)

1) 执行`bgsave`命令，Redis父进程判断当前是否存在正在执行的子进程，如RDB/AOF子进程，如果存在`bgsave`命令直接返回。

2) 父进程执行fork操作创建子进程，fork操作过程中父进程会阻塞，通过`info stats`命令查看`latest_fork_usec`选项，可以获取最近一个fork以操作的耗时，单位为微秒。

3) 父进程仍fork完成后，bgsave命令返回“Background saving started”信息并不再阻塞父进程，可以继续响应其他命令。

4) 子进程创建RDB文件，根据父进程内存生成临时快照文件，完成后对原有文件进行原子替换。执行`lastsave`命令可以获取最后一次生成尺RDB的时间，对应info统计的`rdb_last_save_time`选项。

5) 进程发送信号给父进程衣示完成，父进程更新统计信息，具体见info Persistence下的rdb_*相关选项。

### 1.3 RDB文件处理

#### 1.3.1 保存

RDB文件保存在`dir`配置指定的目录下，文件名通过`dbfilename`配置指定。可以通过执行`config set dir {newDir}`和`config set dbfilename {newFileName}`运行期动态执行，当下次运行时RDB文件会保存到新目录。

#### 1.3.2 压缩

Redis默认采用LZF算法对生成的RDB文件做压缩处理，压缩后的文件远远小于内存大小，默认开启，可以通过参数`config set rdbcompression {yes|no}`动态修改。

> 虽然压缩RDB会消耗额外的CPU资源，但是可以大幅降低文件体积，方便保存在磁盘上或通过网络发送给从节点，因此线上建议开启。

#### 1.3.3 校验

如果Redis加载到损坏的RDB文件时会拒绝启动，并打印日志：

```shell
# Short read or OOM loading DB. Unrecoverable error, aborting now.
```

这时可以使用Redis提供的`redis-check-dump`工具检测RDB文件并获取对应的错误报告。

### 1.4 RDB的优缺点

RDB的优点:

- RDB是一个紧凑压缩的二进制文件，代表Redis在某一个时间点上的数据快照。非常适合用于备份，全量复制等场景。比如每6小时执行bgsave备份，并把RDB文件拷贝到远程机器或者文件系统中（如hdfs），用于灾难恢复。
- Redis加载RDB恢复数据远远快于AOF方式。

RDB的缺点

- RDB方式数据没办法做到实时持久化/秒级持久化。因为bgsave每次运行都要执行fork操作创建子进程，属于重量级操作，频繁执行成本过高。
- RDB文件使用特定二进制格式保存，**Redis版本演进过程中有多个格式的RDB版本，存在老版本Redis服务无法兼容新版RDB格式的问题**。

