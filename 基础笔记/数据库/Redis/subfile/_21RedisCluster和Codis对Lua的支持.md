# Redis Cluster和Codis对Lua的支持

## 一. Codis对Lua的支持

在实际场景中，很多使用了lua脚本以扩展Redis的功能，其实Codis这边是支持的，但记住，Codis在涉及这种场景的时候，仅仅是转发而已，**它并不保证你的脚本操作的数据是否在正确的节点上**。比如，你的脚本里涉及操作多个key，**Codis能做的就是将这个脚本分配到参数列表中的第一个key的机器上执行**。所以这种场景下，你需要自己保证你的脚本所用到的key分布在同一个机器上，这里可以采用`hashtag`的方式。

- 比如你有一个脚本是操作某个用户的多个信息，如uid1age，uid1sex，uid1name形如此类的key，如果你不用hashtag的话，这些key可能会分散在不同的机器上，如果使用了hashtag(用花括号扩住计算hash的区域)：{uid1}age，{uid1}sex，{uid1}name，这样就保证这些key分布在同一个机器上。
- set {uid1}age value1
- set {uid1}sex value2
- set {uid1}name value3

小栗子：

```shell
我有个脚本aa.lua（接收三个key作为参数，将这3个key写到codis中）
redis-cli -h 127.0.0.1 -p 19000 --eval aa.lua key1 key2 key3

执行过程如下：
1、codis-proxy根据key1的hash值，把该脚本发送到某个codis-server实例A
2、把key1,key2,key3写入实例A
```

> 这个时候问题来了，我想取key2,key3怎么取呢？

- 如果你再次连上codis-proxy，输入命令get key2。这时并不一定能取到相应值，因为key2的hash值可能不在codis-server实例A（可能在codis-server实例B,codis-server实例C）
- 如果想明确取key2的话，则还需写一个lua脚本，传入参数key1 key2参数，利用key1将lua脚本引导到codis-server实例A，然后再get key2的值

## 二. Redis Cluster对Lua的支持

在一个节点接收到 EVAL 指令之后，他会检查 KEYS，算出对应的 Slots，如果所有 KEY 不是落到同一个 Slot 上，会提示 `CROSSSLOT Keys in request don't hash to the same slot`

那如果我不传 KEYS，直接在脚本中操作呢？还是会报错。

```shell
$ redis-cli EVAL "redis.call('get', 'slot a'); redis.call('get', 'slot-b')" 0
ERR Error running script (call to f_8ead0f68893988e15c455c0b6c8ab9982e2e707c): @user_script:1: @user_script: 1: Lua script attempted to access a non local key in a cluster node
```

所以 EVAL 的时候，脚本中操作的 Key 应当**保证落在同一个 Slot 里面**。同时 Redis 也提供了一个方法可以保证 Key 都会落到同一个 Slot 上面，下面讲 Slots 机制的时候会讲到

以上关于 EVAL 的操作都是建立在对 Redis Cluster 操作的基础上的，如果使用的是单一节点，则可以不考虑这些问题，可以胡来。

### 2.1 Slots 机制

> SLOT = CRC16(key) mod 16384

Redis 集群的拓扑结构是是一个全连通的网络，每一个节点之间都会建立一个 Cluster Bus，所以集群的任何配置变动都会立即同步到各个节点，也就是说，每一个节点都知道哪些 Slot 对应哪个节点。

所以不论客户端连接到哪个节点进行执行指令，服务端都会正确的指示客户端应当重定向到哪一个节点来操作。

Key 在做 CRC16 的时候，如果 Key 中存在花括号对，Redis 会使用花括号对里面字符串做 CRC16，例如：

```shell
{user:info:}1234 => crc16("user:info:") % 16384
{user:info:}5737 => crc16("user:info:") % 16384
```

虽然是两个不同的 Key，但是花括号中间部分是一样的，所以他们有相同的 Slot。