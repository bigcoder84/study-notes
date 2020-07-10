# Kafka集群的安装

Kafka需要依赖于Zookeeper协调服务器工作，所以在安装Kafka之前需要安装好Zookeeper，此处不详述Zookeeper的安装过程。

#### **第一步：解压安装包**

```shell
tar -zxvf kafka_2.11-0.11.0.0.tgz -C /usr/local/kafka_home
```

#### **第二步：创建logs文件夹**

```shell
mkdir /usr/local/kafka_home/logs
```

#### **第三步：修改配置文件**

主要修改下面几项：

- broker.id：broker的全局唯一编号，不同节点的id不能相同
- delete.topic.enable：开启删除topic功能
- log.dirs：日志文件地址
- zookeeper.connect：Zookeeper集群地址

```properties
#broker的全局唯一编号，不能重复
broker.id=0
#删除topic功能使能
delete.topic.enable=true
#处理网络请求的线程数量
num.network.threads=3
#用来处理磁盘IO的现成数量
num.io.threads=8
#发送套接字的缓冲区大小
socket.send.buffer.bytes=102400
#接收套接字的缓冲区大小
socket.receive.buffer.bytes=102400
#请求套接字的缓冲区大小
socket.request.max.bytes=104857600
#kafka运行日志存放的路径	
log.dirs=/opt/module/kafka/logs
#topic在当前broker上的分区个数
num.partitions=1
#用来恢复和清理data下数据的线程数量
num.recovery.threads.per.data.dir=1
#segment文件保留的最长时间，超时将被删除
log.retention.hours=168
#配置连接Zookeeper集群地址
zookeeper.connect=hadoop102:2181,hadoop103:2181,hadoop104:2181
```

#### **第四步：启动节点**

```shell
./bin/kafka-server-start.sh -daemon config/server.properties
```

关闭节点：

```shell
./bin/kafka-server-stop.sh stop
```

