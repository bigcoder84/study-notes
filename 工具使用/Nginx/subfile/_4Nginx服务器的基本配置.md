# Nginx服务器的基本配置

在Nginx配置文件中每一条指令都需要用`;`结尾。

### 一. 配置运行Nginx的用户和用户组

```json
user user [group];
```

- user：指定可以运行Nginx服务器的用户
- group：可选项，指定可以运行Nginx服务器的用户组



### 二. 配置worker_processes

```shell
worker_processes number | auto;
```

- number：指定Nginx进程最多可以产生多少个worker_processes数。
- auto：Nginx将自动检测。

此命令只能在全局块中设置。



### 三. 配置Nginx进程PID存放的位置

Nginx是采用守护进程进行，我们需要在某文件中保存当前运行的程序的主进程号。Nginx支持对它的存放路径进行自定义配置，指令是pid：

```json
pid nginx.pid
```

注意：在指定文件时，一定要指定到具体的文件上，不能为目录名。

此命令只能在全局块中配置。



### 四. 配置错误日志的存放路径

在全局块、http块、server块中都可以对Nginx服务器的日志进行相关配置。

```json
error_log file|stderr [debug|info|notice|warn|error|crit|alert|emerg]
```

Nginx服务器的日志支持输出到固定文件file或者输出到标准错误输出stderr。

日志级别是可选项，debug的日志级别最低，emerg日志级别最高。在设置某一级别日志后，比它级别高的日志也会记录。

需要注意的是：指定的日志文件一定要对运行Nginx的用户具有写权限，否则在启动Nginx进程时就会报错。

例如：

```json
error_log logs/error.log error;
```



### 五. 配置文件的引入

在一些情况下，我们可能需要将其它Nginx配置或者第三方模块的配置引入到当前的主配置文件中。Nginx采用`include`指令来完成引入：

```json
include file;
```

注意：

- 此指令可放在配置文件任何地方
- 新引入的文件同样要求运行Nginx进程的用户需要对其具有写权限，并符合Nginx配置文件规定的相关语法和结构。



## 六. 设置是否允许同时接收多个网络连接

每个Nginx服务器的worker_processes都有能力同时接收多个新到达的网络请求，但这需要在配置文件中进行设置：

```json
multi_accept on|off;
```

此指令默认为关闭（off）状态。此指令只能在events块中进行配置。



### 七. 配置最大连接数

指令`worker_connections`主要用来设置每一个worker_processes同时开启的最大连接数。

```json
worker_connections number; #默认值为512
```

此指令只能在events块中配置。



### 八. 配置服务日志

Nginx服务日志支持对服务日志的格式、大小、输出等进行配置，需要使用两个指令，分别是`access_log`和`log_format`指令。

#### access_log指令

```json
access_log path [format [buffer=size]];
```

- path：配置服务日志的存放路径和名称。
- format：可选项，自定义服务日志的格式，也可以通过“格式串的名称”使用`log_format`指令定义好的格式。
- size：配置临时存放日志内存缓冲区大小。

此指令可以在http块、server块或者location块中进行配置，默认配置为：

```json
access_log logs/access.log combined; #combined为log_format指令默认定义的日志格式字符串名称
```

如果取消服务日志记录功能，则使用：

```json
access_log off;
```

#### log_format指令：

```json
log_format name string ...;
```

- name：格式字符串的名称
- string：服务日志的格式字符串。在定义过程中，可以使用Nginx预设定一些变量获取相关内容。

示例：

```json
http {
	log_format main '$remote_addr - $remote_user [$time_local] "$request" '
	        		'$status $body_bytes_sent "$http_referer" '
	        		'"$http_user_agent" $http_x_forwarded_for '
	 				'"$upstream_addr" "$upstream_status" "$upstream_response_time" "$request_time"'；
	access_log logs/access.log main;
}
```



