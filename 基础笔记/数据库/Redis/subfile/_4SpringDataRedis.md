# Spring Data Redis

spring-data-redis针对jedis提供了如下功能：

1. 连接池自动管理，提供了一个高度封装的`RedisTemplate`类

2. 针对jedis客户端中大量API进行了归类封装，将同一类型操作封装为operation接口：

   - ValueOperations：简单K-V操作

   - SetOperations：set类型数据操作

   - ZSetOperations：zset类型数据操作

   - HashOperations：针对map类型的数据操作

   - ListOperations：针对list类型的数据操作

3. 提供了对key的“bound”(绑定)便捷化操作API，可以通过bound封装指定的key，然后进行一系列的操作而无须“显式”的再次指定Key，即BoundKeyOperations：
   - BoundValueOperations
   - BoundSetOperations
   - BoundListOperations
   - BoundSetOperations
   - BoundHashOperations
4. 将事务操作封装，有容器控制。
5. 针对数据的“序列化/反序列化”，提供了多种可选择策略(RedisSerializer)
   - JdkSerializationRedisSerializer：POJO对象的存取场景，使用JDK本身序列化机制，将pojo类通过ObjectInputStream/ObjectOutputStream进行序列化操作，最终redis-server中将存储字节序列。是目前最常用的序列化策略。
   - StringRedisSerializer：Key或者value为字符串的场景，根据指定的charset对数据的字节序列编码成string，是“new String(bytes, charset)”和“string.getBytes(charset)”的直接封装。是最轻量级和高效的策略。
   - JacksonJsonRedisSerializer：jackson-json工具提供了javabean与json之间的转换能力，可以将pojo实例序列化成json格式存储在redis中，也可以将json格式的数据转换成pojo实例。因为jackson工具在序列化和反序列化时，需要明确指定Class类型，因此此策略封装起来稍微复杂。【需要jackson-mapper-asl工具支持】

## 一. 基本使用

### 1.1 引入依赖

```xml
<!--Redis-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

### 1.2 配置文件

```properties
# Redis服务器连接端口
spring.redis.port=6379
# Redis服务器地址
spring.redis.host=127.0.0.1
# Redis数据库索引（默认为0）
spring.redis.database=0
# Redis服务器连接密码（默认为空）
spring.redis.password=
# 连接池最大连接数（使用负值表示没有限制）
spring.redis.jedis.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制）
spring.redis.jedis.pool.max-wait=-1ms
# 连接池中的最大空闲连接
spring.redis.jedis.pool.max-idle=8
# 连接池中的最小空闲连接
spring.redis.jedis.pool.min-idle=0
# 连接超时时间（毫秒）
spring.redis.timeout=5000ms
```

### 1.3 使用API

```java
@Autowired
private RedisTemplate redisTemplate;

redis.
```

二. 
