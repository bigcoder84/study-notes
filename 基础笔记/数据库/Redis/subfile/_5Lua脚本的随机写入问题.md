# Lua脚本的随机写入问题

> 本文转载至：[Redis · 引擎特性 · Lua脚本新姿势 (taobao.org)](http://mysql.taobao.org/monthly/2019/01/06/)

## 一. 前言

Redis内嵌了Lua环境来支持用户扩展功能，但是出于数据一致性考虑，要求脚本必须是纯函数的形式，也就是说对于一段Lua脚本给定相同的参数，写入Redis的数据也必须是相同的，对于随机性的写入Redis是拒绝的。

从Redis 3.2开始Lua脚本支持随机性写入，云Redis跨过了3.2这个版本，所以这一新特性体现在4.0版本中。

## 二. Redis中的Lua脚本

### 2.1 Lua脚本简介

在Redis中使用Lua脚本不可避免的要用到以下三个命令：EVAL、EVALSHA和SCRIPT，下面我们来简单介绍一下：

```shell
EVAL script numkeys key [key …] arg [arg …]
```

- script参数就是一段Lua脚本     
- numkeys参数用于指明后面key的数量     
- key键名，在Lua脚本中可以通过全局变量KEYS[]数组访问，其数量已经由numkeys指明     
- arg为辅助参数，在Lua脚本中可以通过全局变量ARGV[]数组访问，其个数并没有限制

```shell
EVALSHA sha1 numkeys key [key …] arg [arg …]
```

- EVALSHA与EVAL基本一致，只不过其中script脚本替换成了这段脚本的sha1校验码
- sha1校验码通常是取SCRIPT LOAD的返回值

```shell
SCRIPT subcommand
```

- SCRIPT LOAD script: 将一段Lua脚本加载到Redis中缓存起来，并返回其sha1校验码 
- SCRIPT EXISTS sha1 [sha1 ...]: 判断给定的一个或多个sha1校验码在Redis中是否有对应的Lua脚本 
- SCRIPT FLUSH: 清空所有已加载的Lua脚本
- SCRIPT KILL: 杀死正在运行的Lua脚本，当且仅当这个脚本没有执行过任何写命令时才生效，如果执行过写命令那么就只能等待这个脚本执行完毕，或者执行SHUTDOWN NOSAVE来关闭Redis

关于Lua脚本的用法此处就不详细展开了，具体可以参考官网的文档：https://redis.io/commands/eval

### 2.2 Lua脚本的持久化及主从复制

Redis允许在Lua脚本中调用redis.call()或者redis.pcall()来执行Redis命令，如果Lua脚本对Redis的数据做了更改，那么除了执行脚本本身以外还需要两个额外的操作：

1. 把这段Lua脚本持久化到AOF文件中，保证Redis重启时可以回放执行过的Lua脚本。
2. 把这段Lua脚本复制给备库执行，保证主备库的数据一致性。

由于上述两步，现在就很容易理解为什么Redis要求Lua脚本必须是纯函数的形式了，想象一下给定一段Lua脚本和输入参数却得到了不同的结果，这就会造成重启前后和主备库之间的数据不一致，Redis不允许对数据一致性的破坏。

### 2.3 Redis如何防止随机写入

上一节我们介绍了Lua脚本的持久化及主从复制，很明显随机写入会对数据一致性造成破坏，那么本节就来介绍Redis是如何防止Lua脚本中随机写入的。

首先我们来执行一段脚本，尝试把time命令返回的当前时间写入到键now中，看下会怎样：

```shell
127.0.0.1:6379> eval "local now = redis.call('time')[1]; redis.call('set','now',now); return redis.call('get','now')" 0
(error) ERR Error running script (call to f_e745355f11745192bd45376618a34bec9145653b): @user_script:1: @user_script: 1: Write commands not allowed after non deterministic commands. Call redis.replicate_commands() at the start of your script in order to switch to single commands replication mode.
```

不出意外的被拒绝了，这是因为在Redis中time命令是一个随机命令（时间是变化的），在Lua脚本中调用了随机命令之后禁止再调用写命令，Redis中一共有10个随机类命令：

spop、srandmember、sscan、zscan、hscan、randomkey、scan、lastsave、pubsub、time

熟悉Lua的读者也许会问，那要是使用math.random()来生成随机数呢？

Redis是允许在Lua脚本中使用随机数发生器的，不过大家也应该知道生成的其实都是伪随机序列，除非显示调用math.randomseed()。通常情况下都会选择系统时间来作为math.randomseed()的参数，然而Redis在初始化Lua环境时出于安全考虑并没有加载os库，所以os.time无法使用，而Redis的time命令属于随机命令就又回到了上面的问题。

- 这里小插曲下，Redis自己实现了随机数发生器，替换掉了math.randomseed()和math.random()，以保证在不同运行环境下生成的伪随机数序列总是相同的。

### 2.4 使用redis.replicate_commands()允许随机写入

综上所述，Redis无法在Lua脚本中进行随机写入，是因为受到了持久化和主从复制的制约，而制约的根本原因是持久化和复制的粒度是整个Lua脚本，如果能够只把发生更改的数据做持久化和主从复制，那么就可以化随机为确定，进一步丰富Lua在Redis中的使用。

OK，从新版本开始，Redis提供了redis.replicate_commands() 函数来实现这一功能，把发生数据变更的命令以事务的方式做持久化和主从复制，从而允许在Lua脚本内进行随机写入，下面来举例说明：

```shell
127.0.0.1:6379> eval "redis.replicate_commands(); local now = redis.call('time')[1]; redis.call('set','now',now); return redis.call('get','now')" 0
"1504460040"
```

可以看到，相同的脚本只是在开头插入了redis.replicate_commands()就可以成功把时间写入；这是因为执行了redis.replicate_commands()之后，Redis就开始使用multi/exec来包围Lua脚本中调用的写命令，持久化和复制的只是：

```shell
*1\r\n$5\r\nMULTI\r\n*3\r\n$3\r\nset\r\n$3\r\nnow\r\n$10\r\n1504460595\r\n*1\r\n$4\r\nEXEC\r\n

# 转义后
*1
$5
MULTI
*3
$3
set
$3
now
$10
1504460595
*1
$4
EXEC
```

而不是整个Lua脚本，那么AOF文件和备库中拿到的就是一个确定的结果。

并且在Lua脚本中读多写少的情况下，只持久化和复制写命令，可以节省重启和备库的CPU时间。

### 2.5 redis.replicate_commands()注意事项

replicate_commands虽好但是也不能乱用，有几个事项还是需要注意的：

- 在写命令之前调用redis.replicate_commands():

上一节说道调用redis.replicate_commands()之后Redis开始用事务来替代整个Lua脚本做持久化和主从复制。    但是Redis并没有缓存redis.replicate_commands()之前的命令，如果在此之前调用了写命令是会破坏数据一致性的（因为Redis不支持undo操作，无法回滚到执行Lua脚本的初始状态）。此时redis.replicate_commands()并不会生效。


```shell
127.0.0.1:6379> eval "redis.call('set','foo','bar'); redis.replicate_commands(); local now = redis.call('time')[1]; redis.call('set','now',now); return redis.call('get','now')" 0
(error) ERR Error running script (call to f_7dd09c943ce6841d59c54b1f4618f9cc670c7b74): @user_script:1: @user_script: 1: Write commands not allowed after non deterministic commands. Call redis.replicate_commands() at the start of your script in order to switch to single commands replication mode.
```

可以看到在redis.replicate_commands()之前先调用了写命令会造成失败。所以建议如果想进行随机写入的话，在脚本一开始就调用redis.replicate_commands()。

- 当有大流量写入时不建议用redis.replicate_commands()

诚然redis.replicate_commands()丰富了Lua的用法，但是不可避免的也会有些副作用。比如有时候会放大主备复制的流量：

```shell
127.0.0.1:6379> eval "for i=1,10000,1 do redis.call('set',i,i) end" 0
```

以上这段脚本会进行1万次的循环写入，在不调用redis.replicate_commands()的情况下只会给备库复制这段脚本，而调用之后就会进行10000次写命令的复制，增加了主从复制的流量。所以在不需要进行随机写入时，如果有可能造成大流量写入的话尽量不要使用redis.replicate_commands()。

- 慎用redis.set_repl()

```shell
redis.replicate_commands()可以和redis.set_repl()配合，来控制写命令是否进行持久化和主从复制：
redis.set_repl(redis.REPL_ALL) -- 既持久化也主从复制。
redis.set_repl(redis.REPL_AOF) -- 只持久化不主从复制。
redis.set_repl(redis.REPL_SLAVE) -- 只主从复制不持久化。
redis.set_repl(redis.REPL_NONE) -- 既不持久化也不主从复制。
```

默认REPL_ALL，当设置为其他模式时会有数据不一致的风险，所以不建议使用redis.set_repl()，使用redis.replicate_commands()来进行随机写入足矣。