# Nginx搭建静态页面服务器

我们只需要在Nginx中配置静态页面的根路径即可，可以是相对路径，也可以是绝对路径。

```json
#user  nobody;
user tjd;
worker_processes  1;

error_log  logs/error.log;

pid        nginx.pid;#指定记录nginx进程pid的文件

events {
    worker_connections  1024;
}


http {
    server {
        listen       80;
        server_name  localhost;

        location / {	
            root   web/;    #指定静态资源的根路径
            index  index.html index.htm; #默认访问的页面
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }
    
}

```

我们只需要在Nginx根目录下创建`web`目录，然后在该文件夹中放入静态资源即可。

