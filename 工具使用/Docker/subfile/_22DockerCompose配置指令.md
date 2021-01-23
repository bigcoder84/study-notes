# yml配置指令

> 本文参考至：[Docker Compose配置文件详解（V3） - 三度 - 博客园 (cnblogs.com)](https://www.cnblogs.com/sanduzxcvbnm/p/13188274.html)

- [一. 配置文件基本结构](#1)
- [二. 指令](#2)
  - [version](#version)
  - [services](#services)
    - [build](#build)
      - [context](#context)
      - [dockerfile](#dockerfile)
      - [args](#args)
      - [cache_from](#cache_from)
      - [labels](#labels)
      - [network](#network)
    - [command](#command)
    - [container_name](#container_name)
    - [depends_on](#depends_on)
    - [deploy](#deploy)
      - [endpoint_mode](#endpoint_mode)
      - [labels](#labels)
      - [mode](#mode)
      - [placement](#placement)
      - [max_replicas_per_node](#max_replicas_per_node)
      - [replicas](#replicas)
      - [resources](#resources)
      - [restart_policy](#restart_policy)
      - [rollback_config](#rollback_config)
      - [update_config](#update_config)
    - [devices](#devices)
    - [dns](dns)
    - [dns_search](#dns_search)

## 一. 配置文件基本结构<a name="1"></a>

```yml
version: "3.8"
services:

  redis:
    image: redis:alpine
    ports:
      - "6379"
    networks:
      - frontend
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  db:
    image: postgres:9.4
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints:
          - "node.role==manager"

  vote:
    image: dockersamples/examplevotingapp_vote:before
    ports:
      - "5000:80"
    networks:
      - frontend
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure

  result:
    image: dockersamples/examplevotingapp_result:before
    ports:
      - "5001:80"
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints:
          - "node.role==manager"

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints:
          - "node.role==manager"

networks:
  frontend:
  backend:

volumes:
  db-data:
```

## 二. 指令<a name="2"></a>

### version<a name="version"></a>

指定本 yml 依从的 compose 哪个版本制定的。这个版本需要根据当前机器的Docker版本而定，具体的对应关系可以查看官网 [Compose file version 3 reference](https://docs.docker.com/compose/compose-file/)

### services<a name="services"></a>

配置服务节点，下面每一个子节点就是一个服务：

```yml
version: "3.8"
services:
  admin-dl:
  	...
  user-dl:
    ...
```

`admin-dl`和`user-dl`就是我们配置的服务名称

#### build<a name="build"></a>

`DOCKER STACK DEPLOY`不支持。

在构建时应用的配置项。一般直接指定Dockerfile所在文件夹路径，可以是绝对路径，或者相对于Compose配置文件的路径。可以指定为包含构建上下文（context）路径的字符串。例如：

```yaml
version: "3.8"
services:
  webapp:
    build: ./dir
```

也可以使用context指定上下文路径，使用dockerfile基于上下文路径指定Dockerfile文件，使用args指定构建参数。例如：

```yaml
version: "3.8"
services:
  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1
```

如果同时指定了build和image。例如：

```yaml
build: ./dir
image: webapp:tag
```

Compose会在./dir目录下构建一个名为webapp，标签为tag的镜像。

> 使用docker stack deploy时的注意事项：在swarm mode下部署堆栈时，build配置项被忽略。因为docker stack命令不会在部署之前构建镜像。

### context<a name="context"></a>

指定包含Dockerfile的目录路径或git仓库url。该目录是发送给Docker守护进程（Daemon）的构建上下文（context）。当配置的值是相对路径时，它将被解释为相对于Compose配置文件的路径。例如：

```yaml
build:
  context: ./dir
```

指定上下文为Compose配置文件目录下的dir目录。

#### dockerfile<a name="dockerfile"></a>

Compose使用另一个文件进行构建。还必须指定构建路径

```yaml
build:
  context: .
  dockerfile: Dockerfile-alternate
```

#### args<a name="args"></a>

添加构建参数，这些只能在构建过程中访问的环境变量。首先在Dockerfile文件中指定参数：

```yaml
ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Based on commit: $gitcommithash"
```

然后build中指定参数，以下两种写法都可以：

```yaml
build:
  context: .
  args:
    buildno: 1
    gitcommithash: cdc3b19
build:
  context: .
  args:
    - buildno=1
    - gitcommithash=cdc3b19
```

这时构建过程中使用的参数的值为args指定的值。在指定构建参数时也可以不指定值，在这种情况下，构建过程中使用的参数的值为运行Compose的环境中的值。例如：

```yaml
args:
  - buildno
  - gitcommithash
```

> 使用布尔值时的注意事项：YMAL中布尔类型的值（"true"、"false"、"yes"、"no"、"on"、"off"）必须用引号引起来，以便解析器将它们解释为字符串。

#### cache_from<a name="cache_from"></a>

在3.2版的配置文件格式中加入

指定缓存解析镜像列表。例如：

```yml
build:
  context: .
  cache_from:
    - alpine:latest
    - corp/web_app:3.14
```

#### labels<a name="labels"></a>

> 在3.3版的配置文件格式中加入

将元数据以标签的形式添加到生成的镜像中。可以使用数组或字典两种格式。推荐使用反向DNS写法以避免和其他应用的标签冲突。例如：

```yaml
build:
  context: .
  labels:
    com.example.description: "Accounting webapp"
    com.example.department: "Finance"
    com.example.label-with-empty-value: ""
build:
  context: .
  labels:
    - "com.example.description=Accounting webapp"
    - "com.example.department=Finance"
    - "com.example.label-with-empty-value"
```

#### network<a name="network"></a>

> 在3.4版的配置文件格式中加入

设置容器网络连接以获取构建过程中的RUN指令。例如：

```yaml
build:
  context: .
  network: custom_network_1
```

设置为none可以在构建期间禁用网络连接。例如：

```yaml
build:
  context: .
  network: none
```

### command<a name="command"></a>

覆盖容器默认的启动命令：

```yaml
command: ["bundle", "exec", "thin", "-p", "3000"]
```

### container_name<a name="container_name"></a>

`DOCKER STACK DEPLOY`不支持。

指定自定义容器名称，而不是生成一个默认名称。

```yaml
container_name: my-web-container
```

因为Docker容器的名称必须唯一，所以你在自定义名称后如果尝试将服务扩展至一个以上将会报错。

### depends_on<a name="depends_on"></a>

该指令用于表达服务之间的依赖关系，服务之间的依赖会有如下行为：

- `docker-compose up`启动项目时按照依赖顺序启动。
- `docker-compose up SERVICE` 启动特定服务时，会将依赖的服务也创建并启动。在下面的例子中，执行`docker-compose up web`时，也会创建并运行`db`和`redis`。
- `docker-compose stop` 停止时会按照依赖顺序停止。

一个简单的例子：

```yaml
version: "3.9"
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```

启动时会先启动db和redis，最后才启动web。在使用docker-compose up web启动web时，也会启动db和redis，因为在web服务中指定了依赖关系。在停止时也在web之前先停止db和redis。

> 使用depends_on时的注意事项：
>
> - 服务不会等待该服务所依赖的服务完全启动之后才启动。例如上例，web不会等到db和redis完全启动之后才启动。
> - V3版不再支持的condition形式的depends_on。
> - V3版中，在swarm mode下部署堆栈时，depends_on配置项将被忽略。

### deploy<a name="deploy"></a>

> 在3版的配置文件格式中加入

指定部署和运行服务的相关配置。该配置仅在swarm mode下生效，并只能通过docker stack deploy命令部署，docker-compose up和docker-compose run命令将被忽略。例如：

```yaml
version: "3.8"
services:
  redis:
    image: redis:alpine
    deploy:
      replicas: 6
      placement:
        max_replicas_per_node: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
```

deploy配置项中包含endpoint_mode、labels、mode、placement、replicas、resources、restart_policy、update_config等子配置项。

#### endpoint_mode<a name="endpoint_mode"></a>

> 在3.2版的配置文件格式中加入

为外部客户端连接到swarm指定服务发现方式：

- endpoint_mode: vip：Docker为服务分配了一个前端的虚拟IP，客户端通过该虚拟IP访问网络上的服务。Docker在客户端和服务的可用工作节点之间进行路由请求，而无须关系有多少节点正在参与该服务或这些节点的IP地址或者端口。这是默认设置。
- endpoint_mode: dnsrr：DNS轮询（DNSRR），Docker设置服务的DNS条目，以便对服务名称的DNS查询返回IP地址列表，并且客户端通过轮询的方式直接连接到其中之一。

例如：

```yaml
version: "3.8"
services:
  wordpress:
    image: wordpress
    ports:
      - "8080:80"
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: vip
```

#### labels<a name="labels"></a>

指定服务的标签。这些标签仅在服务上设置，而不在服务的任何容器上设置。例如：

```yaml
version: "3.8"
services:
  web:
    image: web
    deploy:
      labels:
        com.example.description: "This label will appear on the web service"
```

#### mode<a name="mode"></a>

指定服务的容器副本模式。可以为：

- global：每个swarm节点只有一个该服务容器。
- replicated：整个集群中存在指定份数的服务容器副本，为默认值。

例如，指定容器副本模式为global：

```yaml
version: "3.8"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    deploy:
      mode: global
```

#### placement<a name="placement"></a>

指定constraints和preferences。constraints可以指定只有符合要求的节点上才能运行该服务容器，preferences可以指定容器分配策略。例如，指定集群中只有满足node.rolemanager和engine.labels.operatingsystemubuntu 18.04条件的节点上能运行db服务容器，并且在满足node.labels.zone的节点上均匀分配：

```yaml
version: "3.8"
services:
  db:
    image: postgres
    deploy:
      placement:
        constraints:
          - "node.role==manager"
          - "engine.labels.operatingsystem==ubuntu 18.04"
        preferences:
          - spread: node.labels.zone
```

#### max_replicas_per_node<a name="max_replicas_per_node"></a>

> 在3.8版的配置文件格式中加入

如果服务的容器副本模式为replicated（默认），可以指定每个节点上运行的最大容器副本数量。当指定的容器副本数量大于最大容器副本数量时，将引发no suitable node (max replicas per node limit exceed)错误。例如：

```yaml
version: "3.8"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
      placement:
        max_replicas_per_node: 1
```

#### replicas<a name="replicas"></a>

如果服务的容器副本模式为replicated（默认），指定运行的容器副本数量。例如：

```yaml
version: "3.8"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
```

#### resources<a name="resources"></a>

配置资源限制。例如，指定redis服务使用的cpu份额为25%到50%，内存为20M到50M：

```yaml
version: "3.8"
services:
  redis:
    image: redis:alpine
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
```

> 在V3版Compose配置文件中的改变：resources取代了V3版之前的Compose配置文件中旧的资源限制的配置项，包括cpu_shares、cpu_quota、cpuset、mem_limit、memswap_limit、mem_swappiness。
> 在非swarm mode容器上设置资源限制：此处的resources配置项只有用于deploy配置项之下和swarm mode。如果要在非swarm mode部署中设置资源限制，需使用V2版Compose配置文件中CPU、memory和其他资源的配置项。

#### restart_policy<a name="restart_policy"></a>

指定容器的重启策略。代替restart。有以下配置选项：

- condition：重启策略。值可以为none、on-failure或any，默认为any。
- delay：尝试重启的等待时间。指定为持续时间（durations）。默认值为0。
- max_attempts：重启最多尝试的次数，超过该次数将放弃。默认为永不放弃。如果在window配置的时间之内未成功重启，则此次尝试不计入max_attempts的值。
- window：在决定重启是否成功之前的等待时间。指定为持续时间（durations）。默认值为立即决定。

例如，指定重启策略为失败时重启，等待5s，重启最多尝试3次，决定重启是否成功前的等待时间为120s：

```yaml
version: "3.8"
services:
  redis:
    image: redis:alpine
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

#### rollback_config<a name="rollback_config"></a>

> 在3.7版的配置文件格式中加入

配置在更新失败的情况下如何回滚服务。有以下配置选项：

- parallelism：一次回滚的容器数量。如果设置为0，则所有容器同时回滚。
- delay：每个容器组之间的回滚所等待的时间。默认值为0s。
- failure_action：回滚失败后的行为。有continue和pause两种，默认值为pause。
- monitor：每次任务更新后监视失败的时间（ns|us|ms|s|m|h）。默认值为0s。
- max_failure_ratio：在回滚期间能够容忍的最大失败率。默认值为0。
- order：设置回滚顺序。stop-first为在开启新任务之前停止旧任务，start-first为首先启动新任务，和正在运行任务短暂重叠，默认值为stop-first。

#### update_config<a name="update_config"></a>

配置如何更新服务。该配置对滚动更新很有用。有以下配置选项：

- parallelism：一次更新的容器数量。
- delay：更新一组容器之间的等待时间。
- failure_action：更新失败后的行为。有continue、rollback和pause三种，默认值为pause。
- monitor：每次任务更新后监视失败的时间（ns|us|ms|s|m|h）。默认值为0s。
- max_failure_ratio：在更新期间能够容忍的最大失败率。
- order：设置更新顺序。stop-first为在开启新任务之前停止旧任务，start-first为首先启动新任务，和正在运行任务短暂重叠，默认值为stop-first。注意该配置项在3.4版的配置文件格式中加入，仅支持3.4或更高版本。

例如，指定每次更新2个容器，更新等待时间10s，更新顺序为先停止旧任务再开启新任务：

```yaml
version: "3.8"
services:
  vote:
    image: dockersamples/examplevotingapp_vote:before
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
        order: stop-first
```

### devices<a name="devices"></a>

指定设备映射列表。与Docker客户端create的--device选项类似。例如：

```yaml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
```

> 使用docker stack deploy时的注意事项：在swarm mode下部署堆栈时，devices配置选项将被忽略。

### dns<a name="dns"></a>

自定义DNS服务器。可以是一个值或一个列表。例如：

```yaml
dns: 8.8.8.8
dns:
  - 8.8.8.8
  - 9.9.9.9
```

### dns_search<a name="dns_search"></a>

自定义DNS搜索域。可以是一个值或一个列表。例如：

```yaml
dns_search: example.com
dns_search:
  - dc1.example.com
  - dc2.example.com
```

### entrypoint