# Docker实践-部署Nginx

最近在工作中遇到一个问题，产品需要让我将接近800字的说明放到系统中，由于HTML无法保证原有的格式，所以不能无法复制到代码。然后突发奇想想到了使用富文本转成HTML，但是发现市面上貌似没有类似的工具可以使用，自己就借助 [wangEditor](https://github.com/wangeditor-team/wangEditor/) 富文本组件实现了一个简单的富文本转HTML工具 [online-editor](https://github.com/tianjindong/online-editor)。

花了点时间把工具写完后，就需要把它部署到线上环境，正好最近在学习Docker就想着用Docker来部署Nginx，这就是故事的开始。

## 一. 拉取官方镜像

```shell
$ docker pull nginx:1.19.4
```

## 二. 启动容器


由于将Nginx的配置目录和资源目录挂载到主机上了，由于这两目录都是空的，nginx容器无法启动，我们需要启动一个临时容器将容器中徐亚的文件拷贝出来：

```shell
#启动一个临时容器（—P 端口随机映射）
docker run -d --name nginx-temp -P nginx:1.19.4
# 复制资源文件夹，到我们挂载的目录下
$ docker cp nginx-temp:/usr/share/nginx/html /usr/local/nginx-online-editor/
# 复制配置文件，到我们挂载的目录下
$ docker cp nginx-temp:/etc/nginx /usr/local/nginx-online-editor/conf/
# 删除临时启动的容器
docker rm -f nginx-temp
```
启动容器：
```shell
docker run  -d --name nginx-online-editor -p 7009:80 -v /usr/local/nginx-online-editor/html:/usr/share/nginx/html -v /usr/local/nginx-online-editor/conf/default.conf:/etc/nginx/conf.d/default.conf -v /usr/local/nginx-online-editor/conf/nginx.conf:/etc/nginx/nginx.conf  nginx:1.19.4
```
命令参数：
```shell
docker run  
	-d #后台运行
	--name mynginx1 #指定容器名称
	-p 7009:80 #端口映射
	-v /usr/local/nginx-online-editor/html:/usr/share/nginx/html #挂载目录
	-v /usr/local/nginx-online-editor/conf/nginx.conf:/etc/nginx/nginx.conf
	nginx:1.19.4 #镜像名称
```

