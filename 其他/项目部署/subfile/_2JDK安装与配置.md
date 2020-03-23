# JDK安装与配置（Linux）

## 一. 解压包的安装(.tar.gz)

**第一步：解压JDK至/usrl/local/**

```shell
$ tar -zxvf jdk-8u241-linux-x64.tar.gz -C /usr/local/
```

**第二步：配置`/etc/profile`**

```shell
vi /etc/profile 
```

进入后输入G进入文件末尾，加入下列配置：

```shell
export JAVA_HOME=/usr/java/jdk1.8.0_60
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
```

**第三步：重新加载配置文件**

```shell
source /etc/profile
```



## 二. rpm包安装

将文件上传至服务器，然后在文件所在目录执行下列语句即可：

```shell
rpm -ivh jdk-8u241-linux-x64.rpm
```

