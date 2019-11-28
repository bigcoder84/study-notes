# Nginx反向代理配置

## 1. proxy_pass指令

该指令用来设置被代理服务器的地址，可以是主机名称、IP地址加端口号的形式。其语法如下：

```json
proxy_pass URL;
```

其中URL就是要设置的被代理服务器的地址，包含传输协议、主机名称、IP地址加端口号。传输协议通常是`http://`和`https://`。

```json
proxy_pass http://192.168.0.12:8080/uri;
proxy_pass http://192.168.0.13:8080/uri;
proxy_pass http://192.168.0.14:8080/uri;
```

如果被代理的是一组服务器的话，可以使用upstream指令配置后端服务器组。例如：

```json
upstream proxy_svrs{
    server http://192.168.0.12:8080/uri;
	server http://192.168.0.13:8080/uri;
	server http://192.168.0.14:8080/uri;
}
server{
    listen 80;
    server_name www.myweb.com;
    location /{
    	proxy_pass proxy_svrs;
	}
}
```

### 1.1 配置细节

#### 1.1.1 细节一

这里需要注意的是：在组内的各个服务器已经指定传输协议`http://`，而在proxy_pass指令中就不需要指明了。如果现在将upstream中指令改为：

```json
proxy_pass	192.168.0.12:8080/uri;
proxy_pass	192.168.0.13:8080/uri;
proxy_pass	192.168.0.14:8080/uri;
```

我们就需要在proxy_pass指令中指明传输协议：

```json
proxy_pass http://proxy_srvs
```

#### 1.1.2 细节二

在使用proxy_pass指令的过程中还需要注意的是，URL中是否包含URI。Nginx处理方式是不同的。如果URL中不包含URI，Nginx将不会改变原地址的URI；但如果包含了URI，Nginx服务器将会使用新的URI替代原来的URI。

请看下面的Nginx片段：

```json
server {
    listen 80;
    server_name www.myweb.com;
    location /server/ {
    	proxy_pass http://192.168.1.1;
	}
}
```

如果客户端使用`http://www.myweb.name/server`发起请求，该请求被配置中的location块进行处理，由于proxy_pass指令的URL变量不包含URI，所以转向的地址为`http://192.168.1.1/server`。

我们在看下面Nginx片段：

```json
server {
    listen 80;
    server_name www.myweb.com;
    location /server/ {
    	proxy_pass http://192.168.1.1/loc/;
	}
}
```

在该配置实例中，proxy_pass指令的URL包含了"/loc"。如果客户端使用`http://www.myweb.name/server`发送请求，Nginx将会把请求转向`http://192.168.1.1/loc/`。

通过上面的实例，我们可以总结出，在使用proxy_pass指令时，如果不想改变原地址中的URI，请不要在URL变量中配置URI。

明白了上面这两个例子的用法，我们来解释大家经常讨论的一个问题，就是proxy_pass指令的URL变量末尾是否加斜杠"/"的问题。

请看这两个配置：

```json
proxy_pass http://192.168.1.1; #配置一
proxy_pass http://192.168.1.1/; #配置二
```

配置一和配置二的区别在于，配置二中proxy_pass指令后面的URL末尾加上了"/"，这意味着在配置二中的URL中包含了URI "/"，而配置1中proxy_pass指令的URL变量不包含URI。理解这一点，我们就可以解释下面实例和现象了：

**实例1**：

```json
server {
    listen 80;
    server_name www.myweb.com;
    location / {
    	#配置一 proxy_pass http://192.168.1.1;
    	#配置二 proxy_pass http://192.168.1.1/;
	}
}
```

在该配置中，location块使用“/”作为URI变量的值来匹配不包含URI的请求URL。由于请求URL中不包含URI，因此配置1和配置2的效果都是一样的。比如客户端请求的URL为`http://www.myweb.com/index.html`，其将会被实例1中的location块匹配成功并处理。不管使用配置1还是配置二，转向的URL都为：`http://192.168.1.1/index.htm`。

**实例2**：

```json
server {
    listen 80;
    server_name www.myweb.com;
    location /server/ {
    	#配置一 proxy_pass http://192.168.1.1;
    	#配置二 proxy_pass http://192.168.1.1/;
	}
}
```

在该配置中，location块中使用`/server/`作为uri变量的值匹配包含URI`/server/`的请求URL。这时，使用配置一和配置二的转向结果就会不相同了。使用配置1的时候。proxy_pass指令中的URL变量不包含URI，Nginx将不改变原地址的URI；使用配置2的时候，proxy_pass指令中的URL变量包含URI “/”，Nginx服务器会将原地址的URI替换为“/”。

例如，客户端的请求URL为`http://www.myweb.com/server/index.html`，使用配置一时，转向的URL为`http://192.168.1.1/server/index.html`；但使用配置2时，转向的URL为`http://192.168.1.1/index.html`，可以看到，原地址的“/server/”被替换为了"/"。



## 2. proxy_hide_header指令

该指令用于设置Nginx服务器在发送Http相应时，隐藏的头域信息。其语法结构为：

```json
proxy_hide_header field;
```

其中field是需要隐藏的头域信息，该指令可以配置在http块、server块或者location块中。



## 3. proxy_pass_header指令

默认情况下，Nginx服务器在发送相应报文时，报文头中不会包含"Date"、“Server”、“X-Accel”等来自被代理服务器的头域信息。该指令可以设置这些头域信息已被发送，其语法结构如下：

```json
proxy_pass_header field;
```

其中field是头域信息，该指令可以配置在http块、server块或者location块中。



## 4. proxy_set_header指令

指令可以更改Nginx服务器接收到的客户端请求的请求头信息，然后将新的请求头发送给被代理服务器。其语法如下：

```json
proxy_set_header field value;
```

默认情况下，该指令是这样设置的：

```json
proxy_set_header Host $proxy_host;
proxy_set_header Connection close;
```

请看一些配置实例：

```json
location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

