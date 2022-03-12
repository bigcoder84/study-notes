# JedisPool资源池优化

> 本文转载至：[JedisPool资源池优化 - 蚂蚁集团金融科技 (antfin.com)](https://tech.antfin.com/docs/2/98726#section-m2c-5kr-zfb)

合理的JedisPool资源池参数设置能够有效地提升Redis性能。本文档将对JedisPool的使用和资源池的参数进行详细说明，并提供优化配置的建议。

```java
JedisPool jedisPool = new JedisPool(jedisPoolConfig, redisHost, redisPort, timeout, redisPassword//);
//执命令如下
Jedis jedis = null;
try {
    jedis = jedisPool.getResource();
    //具体的命令
    jedis.executeCommand()
} catch (Exception e) {
    logger.error(e.getMessage(), e);
} finally {
    //在 JedisPool 模式下，Jedis 会被归还给资源池
    if (jedis != null) 
        jedis.close();
}
```

## 参数说明

Jedis连接就是连接池中JedisPool管理的资源，JedisPool保证资源在一个可控范围内，并且保障线程安全。使用合理的GenericObjectPoolConfig配置能够提升Redis的服务性能，降低资源开销。下列两表将对一些重要参数进行说明，并提供设置建议。

| 参数               | 说明                                                         | 默认值             | 建议                                                         |
| ------------------ | ------------------------------------------------------------ | ------------------ | ------------------------------------------------------------ |
| maxTotal           | 资源池中的最大连接数                                         | 8                  | 参见[关键参数设置建议](https://tech.antfin.com/docs/2/98726#section-m2c-5kr-zfb)。 |
| maxIdle            | 资源池允许的最大空闲连接数                                   | 8                  | 参见[关键参数设置建议](https://tech.antfin.com/docs/2/98726#section-m2c-5kr-zfb)。 |
| minIdle            | 资源池确保的最少空闲连接数                                   | 0                  | 参见[关键参数设置建议](https://tech.antfin.com/docs/2/98726#section-m2c-5kr-zfb)。 |
| blockWhenExhausted | 当资源池用尽后，调用者是否要等待。只有当值为true时，下面的maxWaitMillis才会生效。 | true               | 建议使用默认值。                                             |
| maxWaitMillis      | 当资源池连接用尽后，调用者的最大等待时间（单位为毫秒）。     | -1（表示永不超时） | 不建议使用默认值。                                           |
| testOnBorrow       | 向资源池借用连接时是否做连接有效性检测（ping）。检测到的无效连接将会被移除。 | false              | 业务量很大时候建议设置为false，减少一次ping的开销。          |
| testOnReturn       | 向资源池归还连接时是否做连接有效性检测（ping）。检测到无效连接将会被移除。 | false              | 业务量很大时候建议设置为false，减少一次ping的开销。          |
| jmxEnabled         | 是否开启JMX监控                                              | true               | 建议开启，请注意应用本身也需要开启。                         |

空闲Jedis对象检测由下列四个参数组合完成。

| 名称                          | 说明                                                         | 默认值                | 建议                                                         |
| ----------------------------- | ------------------------------------------------------------ | --------------------- | ------------------------------------------------------------ |
| testWhileIdle                 | 是否在空闲资源监测时通过ping命令监测连接有效性，无效连接将被销毁。 | false                 | true                                                         |
| timeBetweenEvictionRunsMillis | 空闲资源的检测周期（单位为毫秒）                             | -1（不检测）          | 建议设置，周期自行选择，也可以默认也可以使用下方JedisPoolConfig 中的配置。 |
| minEvictableIdleTimeMillis    | 资源池中资源的最小空闲时间（单位为毫秒），达到此值后空闲资源将被移除。 | 1,800,000（即30分钟） | 可根据自身业务决定，一般默认值即可，也可以考虑使用下方JeidsPoolConfig中的配置。 |
| numTestsPerEvictionRun        | 做空闲资源检测时，每次检测资源的个数。                       | 3                     | 可根据自身应用连接数进行微调，如果设置为 -1，就是对所有连接做空闲监测。 |

为了方便使用，Jedis提供了JedisPoolConfig，它继承了GenericObjectPoolConfig在空闲检测上的一些设置。

```java
public class JedisPoolConfig extends GenericObjectPoolConfig {
  public JedisPoolConfig() {
    // defaults to make your life with connection pool easier :)
    setTestWhileIdle(true);
    //
    setMinEvictableIdleTimeMillis(60000);
    //
    setTimeBetweenEvictionRunsMillis(30000);
    setNumTestsPerEvictionRun(-1);
    }
}
```

**说明** 可以在org.apache.commons.pool2.impl.BaseObjectPoolConfig中查看全部默认值。

## 关键参数设置建议

maxTotal（最大连接数）

想合理设置maxTotal（最大连接数）需要考虑的因素较多，如：

- 业务希望的Redis并发量；
- 客户端执行命令时间；
- Redis资源，例如nodes （如应用ECS个数等） * maxTotal不能超过Redis的最大连接数（可在实例详情页面查看）；
- 资源开销，例如虽然希望控制空闲连接，但又不希望因为连接池中频繁地释放和创建连接造成不必要的开销。

假设一次命令时间，即borrow|return resource加上Jedis执行命令 （ 含网络耗时）的平均耗时约为1ms，一个连接的QPS大约是1s/1ms = 1000，而业务期望的单个Redis的QPS是50000（业务总的QPS/Redis分片个数），那么理论上需要的资源池大小（即MaxTotal）是50000 / 1000 = 50。

但事实上这只是个理论值，除此之外还要预留一些资源，所以maxTotal可以比理论值大一些。这个值不是越大越好，一方面连接太多会占用客户端和服务端资源，另一方面对于Redis这种高QPS的服务器，如果出现大命令的阻塞，即使设置再大的资源池也无济于事。

maxIdle与minIdle

maxIdle实际上才是业务需要的最大连接数，maxTotal 是为了给出余量，所以 maxIdle 不要设置得过小，否则会有`new Jedis`（新连接）开销，而minIdle是为了控制空闲资源检测。

连接池的最佳性能是maxTotal=maxIdle，这样就避免了连接池伸缩带来的性能干扰。如果您的业务存在突峰访问，建议设置这两个参数的值相等；如果并发量不大或者maxIdle设置过高，则会导致不必要的连接资源浪费。

您可以根据实际总QPS和调用Redis的客户端规模整体评估每个节点所使用的连接池大小。

**使用监控获取合理值**

在实际环境中，比较可靠的方法是通过监控来尝试获取参数的最佳值。可以考虑通过JMX等方式实现监控，从而找到合理值。

## 常见问题

**资源不足**

下面两种情况均属于无法从资源池获取到资源。

- 超时：

  ```txt
  redis.clients.jedis.exceptions.JedisConnectionException: Could not get a resource from the pool
  …
  Caused by: java.util.NoSuchElementException: Timeout waiting for idle object
  at org.apache.commons.pool2.impl.GenericObjectPool.borrowObject(GenericObjectPool.java:449)
  ```

-  

  blockWhenExhausted 为false，因此不会等待资源释放：

  ```txt
  redis.clients.jedis.exceptions.JedisConnectionException: Could not get a resource from the pool
  …
  Caused by: java.util.NoSuchElementException: Pool exhausted
  at org.apache.commons.pool2.impl.GenericObjectPool.borrowObject(GenericObjectPool.java:464)
  ```

此类异常的原因不一定是资源池不够大，请参见**[关键参数设置建议](https://tech.antfin.com/docs/2/98726#section-m2c-5kr-zfb)**中的分析。建议从网络、资源池参数设置、资源池监控（如果对JMX监控）、代码（例如没执行`jedis.close()`）、慢查询、DNS等方面进行排查。

**预热JedisPool**

由于一些原因（如超时时间设置较小等），项目在启动成功后可能会出现超时。JedisPool定义最大资源数、最小空闲资源数时，不会在连接池中创建Jedis连接。初次使用时，池中没有资源使用则会先`new Jedis`，使用后再放入资源池，该过程会有一定的时间开销，所以建议在定义JedisPool后，以最小空闲数量为基准对JedisPool进行预热，示例如下：

```java
List<Jedis> minIdleJedisList = new ArrayList<Jedis>(jedisPoolConfig.getMinIdle());
 
for (int i = 0; i < jedisPoolConfig.getMinIdle(); i++) {
    Jedis jedis = null;
    try {
        jedis = pool.getResource();
        minIdleJedisList.add(jedis);
        jedis.ping();
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    } finally {
    }
}
 
for (int i = 0; i < jedisPoolConfig.getMinIdle(); i++) {
    Jedis jedis = null;
    try {
        jedis = minIdleJedisList.get(i);
        jedis.close();
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    } finally {
    
    }
}
```