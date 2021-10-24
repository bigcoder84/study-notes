# Redis慢查询日志

Redis对应提供了两个参数：slowlog-log-slower-than和slowlog-max-len，接下来我们详细介绍一下这两个参数。

#### slowlog-log-slower-than

slowlog-log-slower-than的作用是指定命令执行时长的阈值，执行命令的时长超过这个阈值时就会被记录下来。它的单位是微秒（1秒 = 1000毫秒 = 1000000微秒），默认是10000微秒。如果把slowlog-log-slower-than设置为0，将会记录所有命令到日志中。如果把slowlog-log-slower-than设置小于0，将会不记录任何命令到日志中。

在实际的生产环境中，需要根据Redis并发量来调整该配置。因为Redis采用单线程响应命令，如果命令执行时间在1000微秒以上，那么Redis最多可支撑OPS不到1000，所以对于高并发场景的Redis建议设置为**1000微秒**。

#### slowlog-max-len

slowlog-max-len的作用是指定慢查询日志最多存储的条数。实际上，Redis使用了一个列表存放慢查询日志，slowlog-max-len就是这个列表的最大长度。当一个新的命令满足满足慢查询条件时，被插入这个列表中。当慢查询日志列表已经达到最大长度时，最早插入的那条命令将被从列表中移出。比如，slowlog-max-len被设置为10，当有第11条命令插入时，在列表中的第1条命令先被移出，然后再把第11条命令放入列表。

记录慢查询是Redis会对长命令进行截断，不会大量占用大量内存。在实际的生产环境中，为了减缓慢查询被移出的可能和更方便地定位慢查询，建议将慢查询日志的长度调整的大一些。比如可以设置为**1000以上**。

#### 如何进行配置

在Redis中有两个修改配置的方法：

1. 修改Redis配置文件。比如，把slowlog-log-slower-than设置为1000，slowlog-max-len设置为1200：

```
slowlog-log-slower-than 1000
slowlog-max-len 1200
```

1. 使用`config set`命令动态修改。比如，还是把slowlog-log-slower-than设置为1000，slowlog-max-len设置为1200：

```
> config set slowlog-log-slower-than 1000
OK
> config set slowlog-max-len 1200
OK
> config rewrite
OK
```

如果要Redis把配置持久化到本地配置文件，需要执行`config rewrite`命令。