# DockerSwarm集群创建与管理

- [一. 集群创建](#1)
  - [1.1 初始化集群](#1.1)
  - [1.2 查看系统状态](#1.2)
  - [1.3 增加工作节点](#1.3)
  - [1.4 查看节点信息](#1.4)
- [二. 解散集群](#2)
  - [2.1 节点离开集群](#2.1)
  - [2.2 在管理节点上删除节点](#2.2)
  - [2.3 解散集群](#2.3)
- [三. 节点的升降级](#3)
- [四. 更新节点](#4)
  - [4.1 更改节点可用性](#4.1)
  - [4.2 添加/移除标签元数据](#4.2)

## 一. 集群创建<a name="1"></a>

我们知道 Swarm 集群由管理节点和工作节点组成。我们来创建一个包含一个管理节点和两个工作节点的最小 Swarm 集群。

### 1.1 初始化集群<a name="1.1"></a>

我们使用 docker swarm init初始化一个 Swarm 集群。

```shell
$ docker swarm init --advertise-addr [IP]
```

如果你的 Docker 主机有多个网卡，拥有多个 IP，必须使用 --advertise-addr 指定 IP。执行 docker swarm init 命令的节点自动成为管理节点。

![](../images/36.png)

### 1.2 查看系统状态<a name="1.2"></a>

通过 `docker info` 可以查看 swarm 集群状态:

![](../images/37.png)

### 1.3 增加工作节点<a name="1.3"></a>

在我们使用`docker init`初始化集群时，docker会打印一条让其他机器加入swarm集群的命令：

![](../images/39.png)

我们在对应的机器上执行那个命令即可将机器加入Swarm管理。

我们还可以通过`docker swarm join-token`查看加入集群管理的token信息：

```shell
docker swarm join-token [manager|worker] # manager|worker 用于查看加入 管理节点|工作节点 的token
```

查看以Worker身份加入节点的token：

![](../images/40.png)

### 1.4 查看节点信息<a name="1.4"></a>

命令 `docker node ls` 可以查看集群节点信息:

```sh
$ docker node ls
```

![](../images/38.png)

**AVAILABILITY** 的三种状态：

- `Active`：调度器能够安排任务到该节点
- `Pause`：调度器不能够安排任务到该节点，但是已经存在的任务会继续运行
- `Drain`：调度器不能够安排任务到该节点，而且会停止已存在的任务，并将这些任务分配到其他 Active 状态的节点

**MANAGER STATUS** 的三种状态

- `Leader`：为群体做出所有群管理和编排决策的主要管理者节点

- `Reachable`：如果 Leader 节点变为不可用，该节点有资格被选举为新的 Leader

- `Unavailable`：该节点不能和其他 Manager 节点产生任何联系，这种情况下，应该添加一个新的 Manager 节点到集群，或者将一个 Worker  节点提升为 Manager 节点

  

## 二. 解散集群<a name="2"></a>

### 2.1 节点离开集群<a name="2.1"></a>

进入到需要离开swarm管理的机器上，执行下列命令：

```shell
$ docker swarm leave
```

### 2.2 在管理节点上删除节点<a name="2.2"></a>

通过`docker node ls`查看要删除节点对应的ID，然后执行删除命令：

```shell
$ docker node rm [节点ID]
```

### 2.3 解散集群<a name="2.3"></a>

管理节点，解散集群

```shell
docker swarm leave --force
```



## 三. 节点的升降级<a name="3"></a>

**升级**

```shell
docker node promote [节点ID]
```

**降级**

```shell
docker node demote [节点ID]
```



## 四. 更新节点<a name="4"></a>

### 4.1 更改节点可用性<a name="4.1"></a>

```shell
docker node update --availability  [active|pause|drain] [节点ID]
```

### 4.2 添加/移除标签元数据<a name="4.2"></a>

**添加标签**

```shell
docker node update --label-add [key=value] [节点ID]
```

**移除标签**

```shell
docker node update --label-rm [key] [节点ID]
```



