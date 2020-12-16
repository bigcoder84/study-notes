# 安装Redis

## 一. 基本安装

### **第一步：安装gcc编译器**

由于 redis 是用 C 语言开发，安装之前必先确认是否安装 gcc 环境（gcc -v），如果没有安装，执行以下命令进行安装

```shell
 yum install gcc -y
```

### **第二步：下载安装包**

```shell
wget https://download.redis.io/releases/redis-6.0.8.tar.gz
```

如果没有wget命令，则执行下列语句安装wget：

```shell
yum install wget -y
```

### **第三步：解压安装包**

```java
tar -zxvf redis-5.0.3.tar.gz
```

### **第四步：编译并安装Redis**

```shell
# 进入刚刚解压的文件夹
cd redis-5.0.3

# 编译源文件
make

# 将编译好的执行文件，安装至指定文件夹
make install PREFIX=/usr/local/redis
```

### **第五步：启动服务**

至此Redis安装完成，我们可以通过以下命令启动服务：

#### **前台启动**

```shell
cd /usr/local/redis/bin/
./redis-server
```

#### **后台启动**

**第一步：复制配置文件**

从 redis 的源码目录中复制 redis.conf 到 redis 的安装目录（其中`redis-source`是redis安装包的解压目录）：

```shell
cp ${redis-source}/redis.conf /usr/local/redis/bin/
```

**第二步：将redis设为后台启动**

修改 redis.conf 文件，将`daemonize no` 改为` daemonize yes`：

```shell
vi /usr/local/redis/bin/redis.conf
```

**第三步：启动服务**

```shell
#启动服务时，指定配置文件路径
./redis.server redis.conf 
```



## 二. 必要配置

### 2.1 配置开机自启

Redis源文件中提供了Linux自启动脚本模板：`${redis-source}/utils/redis_init_script`。

**第一步：将`redis_init_script`文件拷贝至`/etc/init.d`文件夹中，并重命名为`redis`**

```shell
cp /root/redis-5.0.3/utils/redis_init_script /etc/init.d/redis
```

**第二步：编辑该脚本文件**

按需更改以下配置：

- REDISPORT
- EXEC
- CLIEXEC
- CONF

```shell
#!/bin/sh
#
# Simple Redis init.d script conceived to work on Linux systems
# chkconfig: 2345 90 10
# description: Redis is a persistent key-value database
# as it does use of the /proc filesystem.

# Redis的端口(按需更改)
REDISPORT=6379
# 指定Redis服务器启动的可执行文件的位置(按需更改)
EXEC=/usr/local/redis/bin/redis-server
# Redis客户端的可执行文件（按需更改）
CLIEXEC=/usr/local/redis/bin/redis-cli

# 指定PIDFILE
PIDFILE=/var/run/redis_${REDISPORT}.pid

# 指定Redis启动读取的配置文件(按需更改)
CONF="/etc/user/redis/bin/redis.conf"
 
case "$1" in
    start)
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo "Starting Redis server..."
               $EXEC $CONF
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $CLIEXEC -p $REDISPORT shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
```

**第三步：修改文件权限**

```shell
chmod +x redis #给redis文件添加可执行权限
```

**第四步：将脚本添加到系统服务列表**

```shell
chkconfig --add redis
chkconfig redis on
chkconfig --list   //查看所有注册的脚本文件
```



### 2.2 配置redis客户端快捷命令

我们如果要使用redis提供的命令行客户端，还需要进入到安装目录中去执行`redis-cli`，这样很不方便。我们可以创建一个该执行文件的软连接搭配/usr/bin中即可：

```shell
 ln -s /usr/local/redis/bin/redis-cli /usr/bin/redis
```

这样我们就可以使用`redis`命令来执行`redis-cli`客户端了。



### 2.3 配置远程访问

#### 第一步：开放redis使用的端口

```shell
iptables -I INPUT 4 -p tcp -m state --state NEW -m tcp --dport 6379 -j ACCEPT
service iptables save
```

如果报`not loaded`错误，则代表未安装`iptbles`服务，centos从7开始默认用的是firewalld，这个是基于iptables的，虽然有iptables的核心，但是iptables的服务是没安装的。我们需要手动安装它：

```shell
sudo yum install iptables-services 
sudo systemctl enable iptables && sudo systemctl enable ip6tables 
sudo systemctl start iptables && sudo systemctl start ip6tables
```

安装完成后再次执行上面命令，关闭端口即可。

#### 第二步：配置`redis.conf`

默认情况下，Redis只能在本机访问。如果我们需要远程访问，或者通过图形化工具访问Redis服务器，我们就需要配置Redis服务器所依赖的`redis.conf`配置文件，如果严格按照上文的配置方式，我们就需要编辑`/usr/local/redis/bin/redis.conf`文件：

- 将`bind 127.0.0.1`注释掉
- 将`protected-mode yes`改为`protected-mode no`
- 通过`requirepass`设置远程访问密码

```shell
# bind 127.0.0.1
protected-mode no
requirepass admin
```

**注意**：如果设置了访问密码后，我们使用redis-cli客户端操作Redis时，会发现会报出没有权限的错误：(error) NOAUTH Authentication required.

我们需要在客户端环境中执行`auth xxx`，来执行认证操作。

```shell
127.0.0.1:6379> set testkey testvalue
(error) NOAUTH Authentication required.
127.0.0.1:6379> auth admin
OK
127.0.0.1:6379> 
```

#### 第三步：重启redis

**查看redis服务器进程**：

```shell
ps aux | grep redis

[root@localhost ~]# ps aux |grep redis
root       1012  0.1  0.7 153900  7836 ?        Ssl  18:28   0:04 /usr/local/redis/bin/redis-server *:6379
root       1603  0.0  0.0 112728   968 pts/0    R+   19:22   0:00 grep --color=auto redis
```

**停止该进程**：

```shell
kill -9 1012 #-9表示强制中断一个进程的执行，1012是redis服务进程的pid
```

**启动redis服务器**：

```shell
cd /usr/local/redis/bin
./redis-server redis.conf
```