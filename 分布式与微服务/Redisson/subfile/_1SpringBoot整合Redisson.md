# SpringBoot整合Redisson

> 本文转载至：https://www.cnblogs.com/keeya/p/13846807.html 作者：上帝爱吃苹果

点进来看整合的小伙伴肯定都了解Redisson的概念和背景了，这里就直接开始；

SpringBoot整合Redisson有个比较好用的starter包就是redisson-spring-boot-starter，这也是官方比较推荐的配置方式，本文就使用redisson-spring-boot-starter来配置一个RedissonClient。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>3.3.0</version>
</dependency>
<dependency>
	<groupId>org.redisson</groupId>
	<artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.11.4</version>
</dependency>
```

在application.yml中配置Redis相关信息：

```shell
spring.redis:
  enable: true
  # Connection URL, will override host, port and password (user will be ignored), e.g. redis://user:password@example.com:6379
  url: 配置你的地址
  timeout: 2000 # 连接或读取超时时长（毫秒）
  database: 7
  redisson:
    file: classpath:redisson.yml
  jedis:
    pool:
      max-active: 8  # 连接池最大连接数（使用负值表示没有限制）
      max-wait: 800 # 连接池最大阻塞等待时间（使用负值表示没有限制）
      max-idle: 8 # 连接池中的最大空闲连接
      min-idle: 2 # 连接池中的最小空闲连接
```

在resources目录下创建`redission.yml`文件，内部用于配置redisson的相关信息：

```yml
# 单节点配置
singleServerConfig:
  # 连接空闲超时，单位：毫秒
  idleConnectionTimeout: 10000
  # 连接超时，单位：毫秒
  connectTimeout: 10000
  # 命令等待超时，单位：毫秒
  timeout: 3000
  # 命令失败重试次数,如果尝试达到 retryAttempts（命令失败重试次数） 仍然不能将命令发送至某个指定的节点时，将抛出错误。
  # 如果尝试在此限制之内发送成功，则开始启用 timeout（命令等待超时） 计时。
  retryAttempts: 3
  # 命令重试发送时间间隔，单位：毫秒
  retryInterval: 1500
  # 密码
  password: redis.shbeta
  # 单个连接最大订阅数量
  subscriptionsPerConnection: 5
  # 客户端名称
  clientName: axin
  # 发布和订阅连接的最小空闲连接数
  subscriptionConnectionMinimumIdleSize: 1
  # 发布和订阅连接池大小
  subscriptionConnectionPoolSize: 50
  # 最小空闲连接数
  connectionMinimumIdleSize: 32
  # 连接池大小
  connectionPoolSize: 64
  # 数据库编号
  database: 6
  # DNS监测时间间隔，单位：毫秒
  dnsMonitoringInterval: 5000
# 线程池数量,默认值: 当前处理核数量 * 2
#threads: 0
# Netty线程池数量,默认值: 当前处理核数量 * 2
#nettyThreads: 0
# 编码
codec: !<org.redisson.codec.JsonJacksonCodec> {}
# 传输模式
transportMode : "NIO"
```

可以看到我再这里边配置 database: 6 ，当你使用 RedissonClient 时，会操作 redis 的 第6个分区。使用 RedisTemplate 则会操作第7个分区，在生产中最好配置一致。

配置的时候是参照 Config.java 这个类配置的，这个类在 package org.redisson.config 下；如果你想配置集群模式的Redisson，就点 Config 的成员变量 ClusterServersConfig 去看下里边有哪些可配置项;