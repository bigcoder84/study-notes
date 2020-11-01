# Docker安装（CentOS8）

Docker 要求 CentOS 系统的内核版本高于 3.10 ，查看本页面的前提条件来验证你的CentOS 版本是否支持 Docker 。

通过下列命令查看系统内核：

```shell
$ uname -r
```

## 第一步：移除旧的版本

```shell
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

## 第二步：安装必要的工具

```shell
sudo yum install -y yum-utils
```

## 第三步：添加软件源信息

```shell
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

## 第四步：安装

```shell
sudo yum install docker-ce docker-ce-cli containerd.io
```

## 第五步：启动后台服务

```shell
sudo systemctl start docker
```

## 第六步：测试HelloWorld

```shell
sudo docker run hello-world
```

