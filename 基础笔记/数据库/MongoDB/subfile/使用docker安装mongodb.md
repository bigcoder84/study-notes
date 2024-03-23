# 使用Docker安装MongoDB

第一步：拉取mongodb镜像

```shell
docker pull mongo
```

第二步：创建文件夹

```shell
mkdir -p /home/mongo/conf/
mkdir -p /home/mongo/data/
mkdir -p /home/mongo/logs/
```

第三步：创建文件夹新增mongod.conf文件

```shell
cd /home/mongo/conf && vi mongod.conf
```

mongod.conf文件内容：

```ini
# 数据库文件存储位置
dbpath = /data/db
# log文件存储位置
logpath = /data/log/mongod.log
# 使用追加的方式写日志
logappend = true
# 是否以守护进程方式运行
# fork = true
# 全部ip可以访问
bind_ip = 0.0.0.0
# 端口号
port = 27017
# 是否启用认证
auth = true
# 设置oplog的大小(MB)
oplogSize=2048
```

第四步：新增mongod.log文件

```shell
cd /home/mongo/logs/ && vi mongod.log

##log文件不需要内容##
chmod  777 mongod.log 
```

第五步：docker容器构建以及启动mongodb

```haskell
cd /
docker run -it \
	--name mongodb \
	--restart=always \
    --privileged \
    -p 27017:27017 \
    -v /home/mongo/data:/data/db \
    -v /home/mongo/conf:/data/configdb \
    -v /home/mongo/logs:/data/log/  \
    -d mongo:latest \
    -f /data/configdb/mongod.conf
```

第六步：进入容器创建账号密码

```bash
##进入容器##
docker exec -it mongodb /bin/bash

##进入mongodb shell##
mongo

##切换到admin库##
> use admin

##创建账号/密码##
db.createUser({ user: 'admin', pwd: 'admin', roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });
```