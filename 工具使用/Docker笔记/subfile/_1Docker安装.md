# Docker安装（CentOS）

Docker 要求 CentOS 系统的内核版本高于 3.10 ，查看本页面的前提条件来验证你的CentOS 版本是否支持 Docker 。

通过下列命令查看系统内核：

```shell
$ uname -r
```

## 第一步：移除旧的版本

```shell
$sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
```

## 第二步：安装必要的工具

```shell
$ sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

## 第三步：添加软件源信息

```shell
$ sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 第四步：更新YUM缓存

```shell
$ sudo yum makecache fast
```

## 第五步：安装docker-ce

```shell
$ sudo yum -y install docker-ce
```

## 第六步：启动后台服务

```shell
$ sudo systemctl start docker
```

## 第七步：测试HelloWorld

```shell
$ docker run hello-world
```

