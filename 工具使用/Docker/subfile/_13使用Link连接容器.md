# 使用Link连接容器

我们启动两个centos容器，我们会发现容器会拥有自己的IP地址：

centos1:

```shell
[root@8e9a943d5d54 /]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
28: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

centos2:

```shell
[root@3aebf23ebd35 /]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
30: eth0@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:03 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.3/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

我们通过ip地址是能够ping通对方的，但是如果我们通过容器名称是ping不通的：

```shell
[root@3aebf23ebd35 /]# ping centos1
ping: centos1: Name or service not known
```

## 二. docker run --link的作用

`docker run --link`可以用来链接2个容器，使得源容器（被链接的容器）和接收容器（主动去链接的容器）之间可以互相通信，并且接收容器可以获取源容器的一些数据，如源容器的环境变量。

**--link的格式：**

```shell
--link [容器名称|容器ID]:[别名]
```

**源容器**

```
docker run -d --name selenium_hub selenium/hub
```

创建并启动名为selenium_hub的容器。

![img](../images/7.png)

selenium_hub容器

**接收容器**

```shell
docker run -d --name node --link selenium_hub:hub selenium/node-chrome-debug
```

创建并启动名为node的容器，并把该容器和名为selenium_hub的容器链接起来。其中：

```shell
--link selenium_hub:hub
```

selenium_hub是上面启动的1cbbf6f07804容器的名字，这里作为源容器，hub是该容器在link下的别名（alias），通俗易懂的讲，站在node容器的角度，selenium_hub和hub都是1cbbf6f07804容器的名字，并且作为容器的hostname，node用这2个名字中的哪一个都可以访问到1cbbf6f07804容器并与之通信（docker通过DNS自动解析）。我们可以来看下：

进入node容器：

```
docker exec -it node /bin/bash

root@c4cc05d832e0:~# ping selenium_hub
PING hub (172.17.0.2) 56(84) bytes of data.
64 bytes from hub (172.17.0.2): icmp_seq=1 ttl=64 time=0.184 ms
64 bytes from hub (172.17.0.2): icmp_seq=2 ttl=64 time=0.133 ms
64 bytes from hub (172.17.0.2): icmp_seq=3 ttl=64 time=0.216 ms

root@c4cc05d832e0:~# ping hub
PING hub (172.17.0.2) 56(84) bytes of data.
64 bytes from hub (172.17.0.2): icmp_seq=1 ttl=64 time=0.194 ms
64 bytes from hub (172.17.0.2): icmp_seq=2 ttl=64 time=0.218 ms
64 bytes from hub (172.17.0.2): icmp_seq=3 ttl=64 time=0.128 ms
```

可见，selenium_hub和hub都指向172.17.0.2。

## 三. --link下容器间的通信

按照上例的方法就可以成功的将selenium_hub和node容器链接起来，那这2个容器间是怎么通信传送数据的呢？另外，前言中提到的接收容器可以获取源容器的一些信息，比如环境变量，又是怎么一回事呢？

源容器和接收容器之间传递数据是通过以下2种方式：

- 设置环境变量
- 更新/etc/hosts文件

### 3.1 设置环境变量

当使用`--link`时，docker会自动在接收容器内创建基于--link参数的环境变量：

docker会在接收容器中设置名为`<alias>_NAME`的环境变量，该环境变量的值为：
` <alias>_NAME`=`/接收容器名/源容器alias`

我们进入node容器，看下此环境变量：

```shell
docker exec -it node /bin/bash
seluser@c4cc05d832e0:/$ env | grep -i hub_name
HUB_NAME=/node/hub
```

另外，docker还会在接收容器中创建关于源容器暴露的端口号的环境变量，这些环境变量有一个统一的前缀名称：

```shell
<name>_PORT_<port>_<protocol>
```

其中：

- `name`表示链接的源容器alias
- `port`是源容器暴露的端口号
- `protocol`是通信协议：TCP or UDP

docker用上面定义的前缀定义3个环境变量：

```shell
<name>_PORT_<port>_<protocol>ADDR
<name>_PORT_<port>_<protocol>PORT
<name>_PORT_<port>_<protocol>PROTO
```

注意，若源容器暴露了多个端口号，则每1个端口都有上面的一组环境变量（包含3个环境变量），即若源容器暴露了4个端口号，则会有4组12个环境变量。

[查看selenium/hub的Dockerfile](https://link.jianshu.com/?t=https://github.com/SeleniumHQ/docker-selenium/blob/master/Hub/Dockerfile)，可见只暴露了4444端口号：

```shell
EXPOSE 4444
```

我们进入node容器，看这些此环境变量：

```shell
docker exec -it node /bin/bash
seluser@c4cc05d832e0:/$ env | grep -i HUB_PORT_4444_TCP_
HUB_PORT_4444_TCP_PROTO=tcp
HUB_PORT_4444_TCP_ADDR=172.17.0.2
HUB_PORT_4444_TCP_PORT=4444
```

可见，确实有3个以`<name>_PORT_<port>_<protocol>`为前缀的环境变量存在。

另外，docker还在接收容器中创建1个名为`<alias>_PORT`的环境变量，值为源容器的URL：源容器暴露的端口号中最小的那个端口号。

我们进入node容器，看下此环境变量：

```shell
docker exec -it node /bin/bash
seluser@c4cc05d832e0:/$ env | grep -i HUB_PORT=
HUB_PORT=tcp://172.17.0.2:4444
```

...

文章参考至：

https://www.jianshu.com/p/21d66ca6115e

