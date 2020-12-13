# Compose网络

> 本文转载至：[Networking in Compose | Docker Documentation](https://docs.docker.com/compose/networking/)

本节适用于版本大于2的Compose文件版本。

默认情况下Compose会为每一个项目设置一个单独的网络。服务的每一个容器都加入这一个网络，并且该网络上的其他容器都可以访问到它，并且它们可以在与容器名称相同的主机名上发现它。

> 你的应用程序的网络将会基于“项目名称”去命名，这是基于它所在的目录名称。你可以使用 `--project-name`标签或者`COMPOSE_PROJECT_NAME`环境变量去覆盖项目名称。

举个例子，假设你的应用在`myapp`目录下，你的`docker-compose.yml`是这样的：

```yaml
version: "3.9"
services:
  web:
    build: .
    ports:
      - "8000:8000"
  db:
    image: postgres
    ports:
      - "8001:5432"
```

当你执行`docker-compose up`，将会发生如下事情：

1. 创建一个名为`myapp_default`的网络。
2. 一个使用web配置的容器创建。它以web的名称加入myapp默认的网络。
3. 一个使用db配置的容器创建。它以db的名称加入myapp默认的网络。

> 从Compose2.1开始，覆盖网络总是在新建时被设置为`attachable`，并且它是无法配置的，这意味着所有独立的容器也能连接到这个覆盖网络
>
> 在Compose3.1中，你可以自己将`attachable`设置为false.

现在每一个容器可以通过hostname（`web`or`db`）获取适当的容器的IP地址。举个例子：在web应用中的代码可以通过`postgres://db:5432`这一URL连接使用Postgres数据库。

`主机端口`和`容器端口`是很重要的，在上面的例子中，`db`的`主机端口`是8001，容器端口是5432（postgres默认值）。service与service的通信使用`容器端口`。如果配置了`主机端口`，那么服务将能在集群外部访问。

在`web`容器中，你连接`db`容器的字符串就像是`postgres://db:5432`，从主机连接`db`容器的字符串就像是`postgres://{DOCKER_IP}:8001`

## 二. 更新容器

如果您对服务配置进行了更改并且使用`docker-compose up`去更新了它，那么老的容器将会关闭，新的容器将以不同的IP地址但相同的名称加入网络。运行的容器可以查找该名称并连接到新地址，但是旧地址将会停止工作。

如果有些容器仍然视图连接老的容器，则它们将被关闭。容器负责检测此情况、再次查找名称并重新连接。