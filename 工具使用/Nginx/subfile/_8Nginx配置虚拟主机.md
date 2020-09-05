# Nginx虚拟主机配置

有时候我们需要通过三级域名来实现访问不同的应用实例，此时我们就可以通过Nginx进行反向代理，让所有80端口的请求进入Nginx，然后通过用户访问的三级域名，转发到实际的应用服务器上：

```json

#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
        server_name  www.bigcoder.cn;

        location / {
            proxy_pass http://localhost:7001/;
        }
    }
    server {
        listen       80;
        server_name  jenkins.bigcoder.cn;

        location / {
            proxy_pass http://localhost:7000/;
        }
    }
    server {
        listen       80;
        server_name  blog.bigcoder.cn;

        location / {
            proxy_pass http://localhost:7002/;
        }
    }
}

```

