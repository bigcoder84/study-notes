# Kafka命令行操作

## 一. 主题

### 1.1 创建主题

```shell
./kafka-topics.sh --zookeeper 192.168.2.113:2181 --create --topic tjd --partitions 2 --replication-factor 1
```

- --zookeeper：指定kafka所连接的Zookeeper地址
- --topic：指定所要创建主题的名称
- --partitions：指定分区个数
- --replication-factor：指定副本因子
- --create：创建主题的动作命令

### 1.2 查看所有主题

```java
./kafka-topics.sh --zookeeper 192.168.2.113:2181 --list
```

### 1.3 查看指定topic明细

```shell
./kafka-topics.sh --zookeeper 192.168.2.113:2181 --describe --topic tjd
```

```shell
Topic: tjd	PartitionCount: 2	ReplicationFactor: 1	Configs: 
	Topic: tjd	Partition: 0	Leader: 1	Replicas: 1	Isr: 1
	Topic: tjd	Partition: 1	Leader: 2	Replicas: 2	Isr: 2
```

从第一排可以看到topic的名称，partition数量，副本数量。使用1份副本，就是保证数据的可用性，即使有两台broker服务器挂了，也能保证kafka的正常运行。从第二排开始，表格包含了五列，显示partition的情况，分别表示：topic名称、partition编号，此partions的leader broker编号，副本存放的broker编号，同步broker编号。

### 1.4 修改主题

```shell
./kafka-topics.sh --zookeeper localhost:2181 --alter --topic tjd --partitions 20
```

### 1.5 删除主题

删除之前，需要先将server.properties文件中的配置`delete.topic.enable=true`更改一下，否则执行删除命令不会生效。

```shell
./kafka-topics.sh --zookeeper localhost:2181 --delete --topic tjd
```



## 二. 消费者

### 2.1 启动消费者消费消息

```shell
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic tjd
```

## 三. 生成者

### 3.1 启动生产者生产消息

```shell
./kafka-console-producer.sh --broker-list localhost:9092 --topic tjd
```

- --broker-list：用于指定Kafka集群地址