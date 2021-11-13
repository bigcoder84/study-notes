# SpringAMQP配置详解

## 一. 基础信息

```properties
spring.rabbitmq.host: 默认localhost
spring.rabbitmq.port: 默认5672
spring.rabbitmq.username: 用户名
spring.rabbitmq.password: 密码
spring.rabbitmq.virtual-host: 连接到代理时用的虚拟主机
spring.rabbitmq.addresses: 连接到server的地址列表（以逗号分隔），先addresses后host 
spring.rabbitmq.requested-heartbeat: 请求心跳超时时间，0为不指定，如果不指定时间单位默认为妙
spring.rabbitmq.publisher-confirms: 是否启用【发布确认】，默认false
spring.rabbitmq.publisher-returns: 是否启用【发布返回】，默认false
spring.rabbitmq.connection-timeout: 连接超时时间，单位毫秒，0表示永不超时 
```

## 二. SSL

```properties
spring.rabbitmq.ssl.enabled: 是否支持ssl，默认false
spring.rabbitmq.ssl.key-store: 持有SSL certificate的key store的路径
spring.rabbitmq.ssl.key-store-password: 访问key store的密码
spring.rabbitmq.ssl.trust-store: 持有SSL certificates的Trust store
spring.rabbitmq.ssl.trust-store-password: 访问trust store的密码
spring.rabbitmq.ssl.trust-store-type=JKS：Trust store 类型.
spring.rabbitmq.ssl.algorithm: ssl使用的算法，默认由rabiitClient配置
spring.rabbitmq.ssl.validate-server-certificate=true：是否启用服务端证书验证
spring.rabbitmq.ssl.verify-hostname=true 是否启用主机验证
```

## 三. 缓存Cache

```properties
spring.rabbitmq.cache.channel.size: 缓存中保持的channel数量
spring.rabbitmq.cache.channel.checkout-timeout: 当缓存数量被设置时，从缓存中获取一个channel的超时时间，单位毫秒；如果为0，则总是创建一个新channel
spring.rabbitmq.cache.connection.size: 缓存的channel数，只有是CONNECTION模式时生效
spring.rabbitmq.cache.connection.mode=channel: 连接工厂缓存模式：channel 和 connection
```

## 四. Listener

```properties
spring.rabbitmq.listener.type=simple: 容器类型.simple或direct
 
spring.rabbitmq.listener.simple.auto-startup=true: 是否启动时自动启动容器
spring.rabbitmq.listener.simple.acknowledge-mode: 表示消息确认方式，其有三种配置方式，分别是none、manual和auto；默认auto
spring.rabbitmq.listener.simple.concurrency: 最小的消费者数量
spring.rabbitmq.listener.simple.max-concurrency: 最大的消费者数量
spring.rabbitmq.listener.simple.prefetch: 一个消费者最多可处理的nack消息数量，如果有事务的话，必须大于等于transaction数量.
spring.rabbitmq.listener.simple.transaction-size: 当ack模式为auto时，一个事务（ack间）处理的消息数量，最好是小于等于prefetch的数量.若大于prefetch， 则prefetch将增加到这个值
spring.rabbitmq.listener.simple.default-requeue-rejected: 决定被拒绝的消息是否重新入队；默认是true（与参数acknowledge-mode有关系）
spring.rabbitmq.listener.simple.missing-queues-fatal=true 若容器声明的队列在代理上不可用，是否失败； 或者运行时一个多多个队列被删除，是否停止容器
spring.rabbitmq.listener.simple.idle-event-interval: 发布空闲容器的时间间隔，单位毫秒
spring.rabbitmq.listener.simple.retry.enabled=false: 监听重试是否可用
spring.rabbitmq.listener.simple.retry.max-attempts=3: 最大重试次数
spring.rabbitmq.listener.simple.retry.max-interval=10000ms: 最大重试时间间隔
spring.rabbitmq.listener.simple.retry.initial-interval=1000ms:第一次和第二次尝试传递消息的时间间隔
spring.rabbitmq.listener.simple.retry.multiplier=1: 应用于上一重试间隔的乘数
spring.rabbitmq.listener.simple.retry.stateless=true: 重试时有状态or无状态
 
spring.rabbitmq.listener.direct.acknowledge-mode= ack模式
spring.rabbitmq.listener.direct.auto-startup=true 是否在启动时自动启动容器
spring.rabbitmq.listener.direct.consumers-per-queue= 每个队列消费者数量.
spring.rabbitmq.listener.direct.default-requeue-rejected= 默认是否将拒绝传送的消息重新入队.
spring.rabbitmq.listener.direct.idle-event-interval= 空闲容器事件发布时间间隔.
spring.rabbitmq.listener.direct.missing-queues-fatal=false若容器声明的队列在代理上不可用，是否失败.
spring.rabbitmq.listener.direct.prefetch= 每个消费者可最大处理的nack消息数量.
spring.rabbitmq.listener.direct.retry.enabled=false  是否启用发布重试机制.
spring.rabbitmq.listener.direct.retry.initial-interval=1000ms # Duration between the first and second attempt to deliver a message.
spring.rabbitmq.listener.direct.retry.max-attempts=3 # Maximum number of attempts to deliver a message.
spring.rabbitmq.listener.direct.retry.max-interval=10000ms # Maximum duration between attempts.
spring.rabbitmq.listener.direct.retry.multiplier=1 # Multiplier to apply to the previous retry interval.
spring.rabbitmq.listener.direct.retry.stateless=true # Whether retries are stateless or stateful.
```

## 五. Template

```properties
spring.rabbitmq.template.mandatory: 启用强制信息；默认false
spring.rabbitmq.template.receive-timeout: receive() 操作的超时时间
spring.rabbitmq.template.reply-timeout: sendAndReceive() 操作的超时时间
spring.rabbitmq.template.retry.enabled=false: 发送重试是否可用 
spring.rabbitmq.template.retry.max-attempts=3: 最大重试次数
spring.rabbitmq.template.retry.initial-interva=1000msl: 第一次和第二次尝试发布或传递消息之间的间隔
spring.rabbitmq.template.retry.multiplier=1: 应用于上一重试间隔的乘数
spring.rabbitmq.template.retry.max-interval=10000: 最大重试时间间隔
```

