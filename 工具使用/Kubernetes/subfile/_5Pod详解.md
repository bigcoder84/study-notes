# Pod详解

> 本文转载至：[5 第五章 Pod详解 - 孤独的小人物 - 博客园 (cnblogs.com)](https://www.cnblogs.com/weicunqi/p/14931793.html)

## 一. Pod介绍

### 1.1 Pod结构

![](../images/19.png)

每一个Pod中都可以包含一个或多个容器，这些容器可以分为两类：

- 用户程序所在的容器，数量可多可少
- Pause容器，这是每个Pod都会有的一个**根容器**，它的作用有两个：
  - 可以以它为依据，评估整个Pod的健康状态
  - 可以在根容器上设置IP地址，其它容器都以此IP（Pod IP），以实现Pod内部的网络通信。这里Pod内部的通讯，Pod的之间的通讯采用虚拟二层网络技术来实现，我们当前环境用的是Flannel。

### 1.2 Pod定义

下面是Pod的资源清单：

```yaml
apiVersion: v1 #必选，版本号，例如：v1
kind: Pod #必选，资源类型，例如：Pod
metadata: #必选，元数据
  name: string #必选，Pod名称，
  namaspace: string #Pod所属命名空间，默认是“default”
  labels: #自定义标签列表
  - name: string
  annotations: 
  - name: string
spec: #必选，Pod中容器的详细定义
  containers: #必选，Pod中容器列表
  - name: string #必选，容器名称
    images: string #必选，容器镜像名称
    imagePullPolicy: [Always | Never | IfNotPresent] #获取镜像的策略
    command: [string] #容器的启动命令列表，如果不指定，使用打包时使用的启动命令
    args: [string] #容器的启动命令参数列表
    workingDir: string #容器的工作目录
    volumeMounts: #挂载到容器内部的存储卷位置
    - name: string #引用Pod定义的共享存储卷的名称，需要用volumns[]部分定义的卷名
      mountPath: string #存储卷在容器内mount的绝对路径，应少于512字符
      readOnly: boolean #是否是只读模式
    ports: #需要暴露的端口号列表
    - name: string #端口的名称
      containerPort: int #容器需要监听的端口号
      hostPort: int #容器所在主机需要监听的端口号，默认与Container相同
      protocol: string #端口协议，支持TCP和UDP，默认TCP
    env: #容器运行时需要配置的环境变量列表
    - name: string #环境变量名称
      value: string #环境变量的值
    resources: #资源限制和请求的设置
      limits: #资源限制的设置
        cpu: string #CPU的限制，单位是core数量，将用于 docker run --cpu-shares参数
        memory: string #内存限制，单位以Mib/Gib，将用于docker run --memory参数
      requests: #资源请求设置
        cpu: string #CPU请求，容器启动的初始可用数量
        memory: string #内存请求，容器启动的初始可用数量
    livenessProbe: #对Pod内各个容器健康检查的设置，当探测无响应几次后将自动重启该容器
      exec: #对Pod容器内检查方式设置为exec方式
        command: [string] #exec方式需要制定的命令或脚本
      httpGet: # 对Pod内各个容器健康检查方法设置为httpGet，需要指定path和port
        path: string
        port: int
        host: string
        scheme: string
        httpHeaders:
        - name: string
          value: string
      tcpSocket: # 对Pod内各个容器健康检查方式设置为tcpSocket
        port: int
      initialDelaySeconds: number #容器内完成首次探测的时间，单位为秒
      timeoutSeconds: number #对容器健康探测等待响应的超时时间，单位为秒，默认1秒
      periodSeconds: number #对容器健康检查定期探测时间，单位为秒，默认10秒一次
      successThreshold: 0
      failureThreshold: 0
    securityContext:
      privileged: false
  restartPolicy: [Always | Never | OnFailure] #Pod重启策略
  nodeName: <string> #设置nodeName表示将该Pod调度到指定名称的Node节点上
  nodeSelector: object #设置nodeSelector表示将该Pod调度到包含这个label的Node上
  imagePullSecrets: #Pull镜像时使用的secret名称，以key：secretkey格式指定
  - name: string
  hostNetwork: false #是够使用主机网络模式，默认为false，如果设置为true，表示使用宿主机网络
  volumes: #在该Pod上定义共享存储卷列表
  - name: string #共享存储卷名称（volumns类型有很多种）
    emptyDir: {} #类型为emptyDor的存储卷，与Pod同生命周期的一个临时目录。为空值
    hostPath: #类型为hostPath的存储卷，表示挂载Pod所在宿主机的目录
      path: string 
    secret: #类型为secret的存储卷，表示挂载集群定义的secret对象到容器内部
      secretName: string 
      items:
      - key: string
        path: string
    configMap: #类型为configMap的存储卷，挂载预定义的configMap对象到容器内部
      name: string
      items:
      - key: string
        path: string
```

### 1.3 文档查看

```shell
#小提示：
#   在这里，可通过一个命令来查看每种资源的可配置项
#   kubectl explain 资源类型         查看某种资源可以配置的一级属性
#   kubectl explain 资源类型.属性     查看属性的子属性
[root@k8s-master01 ~]# kubectl explain pod
KIND:     Pod
VERSION:  v1
FIELDS:
   apiVersion   <string>
   kind <string>
   metadata     <Object>
   spec <Object>
   status       <Object>

[root@k8s-master01 ~]# kubectl explain pod.metadata
KIND:     Pod
VERSION:  v1
RESOURCE: metadata <Object>
FIELDS:
   annotations  <map[string]string>
   clusterName  <string>
   creationTimestamp    <string>
   deletionGracePeriodSeconds   <integer>
   deletionTimestamp    <string>
   finalizers   <[]string>
   generateName <string>
   generation   <integer>
   labels       <map[string]string>
   managedFields        <[]Object>
   name <string>
   namespace    <string>
   ownerReferences      <[]Object>
   resourceVersion      <string>
   selfLink     <string>
   uid  <string>
```

在kubernetes中基本所有资源的一级属性都是一样的，主要包含5部分：

- apiVersion： 版本，由kubernetes内部定义，版本号必须可以用 kubectl api-versions 查询到
- kind： 类型，由kubernetes内部定义，版本号必须可以用 kubectl api-resources 查询到
- metadata：元数据，主要是资源标识和说明，常用的有name、namespace、labels等
- spec：描述，这是配置中最重要的一部分，里面是对各种资源配置的详细描述
- status： 状态信息，里面的内容不需要定义，由kubernetes自动生成

在上面的属性中，spec是接下来研究的重点，继续看下它的常见子属性:

- containers： 容器列表，用于定义容器的详细信息
- nodeName： 根据nodeName的值将pod调度到指定的Node节点上
- nodeSelector： 根据NodeSelector中定义的信息选择将该Pod调度到包含这些label的Node 上
- hostNetwork：是否使用主机网络模式，默认为false，如果设置为true，表示使用宿主机网络
- volumes：存储卷，用于定义Pod上面挂在的存储信息
- restartPolicy： 重启策略，表示Pod在遇到故障的时候的处理策略

## 二. Pod配置

本小节主要来研究`pod.spec.containers`属性，这也是pod配置中最为关键的一项配置。

```shell
[root@k8s-master01 ~]# kubectl explain pod.spec.containers
KIND:     Pod
VERSION:  v1
RESOURCE: containers <[]Object>   # 数组，代表可以有多个容器
FIELDS:
   name  <string>     # 容器名称
   image <string>     # 容器需要的镜像地址
   imagePullPolicy  <string> # 镜像拉取策略 
   command  <[]string> # 容器的启动命令列表，如不指定，使用打包时使用的启动命令
   args     <[]string> # 容器的启动命令需要的参数列表
   env      <[]Object> # 容器环境变量的配置
   ports    <[]Object>     # 容器需要暴露的端口号列表
   resources <Object>      # 资源限制和资源请求的设置
```

### 2.1 基本配置

创建pod-base.yaml文件，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-base
  namespace: dev
  labels:
    user: heima
spec:
  containers:
  - name: nginx
    image: nginx:1.17.1
  - name: busybox
    image: busybox:1.30
```

上面定义了一个比较简单Pod的配置，里面有两个容器：

- nginx：用1.17.1版本的nginx镜像创建，（nginx是一个轻量级web容器）
- busybox：用1.30版本的busybox镜像创建，（busybox是一个小巧的linux命令集合）

```shell
# 创建Pod
[root@k8s-master01 pod]# kubectl apply -f pod-base.yaml
pod/pod-base created

# 查看Pod状况
# READY 1/2 : 表示当前Pod中有2个容器，其中1个准备就绪，1个未就绪
# RESTARTS  : 重启次数，因为有1个容器故障了，Pod一直在重启试图恢复它
[root@k8s-master01 pod]# kubectl get pod -n dev
NAME       READY   STATUS    RESTARTS   AGE
pod-base   1/2     Running   4          95
```

最终我们发现Pod的Ready状态一直处于未就绪（1/2），这说明Pod中有容器未启动成功，我们可以使用`describe`命令查看具体的事件信息：

```shell
# 可以通过describe查看内部的详情
# 此时已经运行起来了一个基本的Pod，虽然它暂时有问题
[root@node01 ~]# kubectl describe pod pod-base -n dev
...
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  <unknown>              default-scheduler  Successfully assigned dev/pod-base to node02
  Normal   Pulled     3m29s                  kubelet, node02    Container image "nginx:1.17.1" already present on machine
  Normal   Created    3m29s                  kubelet, node02    Created container nginx
  Normal   Started    3m28s                  kubelet, node02    Started container nginx
  Normal   Pulling    3m28s                  kubelet, node02    Pulling image "busybox:1.30"
  Normal   Pulled     2m54s                  kubelet, node02    Successfully pulled image "busybox:1.30"
  Normal   Created    2m10s (x4 over 2m54s)  kubelet, node02    Created container busybox
  Normal   Started    2m10s (x4 over 2m54s)  kubelet, node02    Started container busybox
  Warning  BackOff    91s (x8 over 2m52s)    kubelet, node02    Back-off restarting failed container
  Normal   Pulled     77s (x4 over 2m53s)    kubelet, node02    Container image "busybox:1.30" already present on machine
```

### 2.2 镜像拉取

创建pod-imagepullpolicy.yaml文件，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-imagepullpolicy
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:1.17.1
    imagePullPolicy: Never # 用于设置镜像拉取策略
  - name: busybox
    image: busybox:1.30
```

imagePullPolicy，用于设置镜像拉取策略，kubernetes支持配置三种拉取策略：

- Always：总是从远程仓库拉取镜像（一直远程下载）
- IfNotPresent：本地有则使用本地镜像，本地没有则从远程仓库拉取镜像（本地有就本地 本地没远程下载）
- Never：只使用本地镜像，从不去远程仓库拉取，本地没有就报错 （一直使用本地）

> 默认值说明：
>
> 如果镜像tag为具体版本号， 默认策略是：IfNotPresent
>
> 如果镜像tag为：latest（最终版本） ，默认策略是always

### 2.3 启动命令

在前面的案例中，一直有一个问题没有解决，就是的busybox容器一直没有成功运行，那么到底是什么原因导致这个容器的故障呢？

原来busybox并不是一个程序，而是类似于一个工具类的集合，kubernetes集群启动管理后，它会自动关闭。解决方法就是让其一直在运行，这就用到了command配置。

创建pod-command.yaml文件，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-command
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:1.17.1
  - name: busybox
    image: busybox:1.30
    command: ["/bin/sh","-c","touch /tmp/hello.txt;while true;do /bin/echo $(date +%T) >> /tmp/hello.txt; sleep 3; done;"]
```

command用于在pod中的容器初始化完毕之后运行一个命令。

> 稍微解释下上面命令的意思：
>
> "/bin/sh","-c", 使用sh执行命令
>
> touch /tmp/hello.txt; 创建一个/tmp/hello.txt 文件
>
> while true;do /bin/echo $(date +%T) >> /tmp/hello.txt; sleep 3; done; 每隔3秒向文件中写入当前时间

```shell
# 创建Pod
[root@k8s-master01 pod]# kubectl create  -f pod-command.yaml
pod/pod-command created

# 查看Pod状态
# 此时发现两个pod都正常运行了
[root@k8s-master01 pod]# kubectl get pods pod-command -n dev
NAME          READY   STATUS   RESTARTS   AGE
pod-command   2/2     Runing   0          2s

# 进入pod中的busybox容器，查看文件内容
# 补充一个命令: kubectl exec  pod名称 -n 命名空间 -it -c 容器名称 /bin/sh  在容器内部执行命令
# 使用这个命令就可以进入某个容器的内部，然后进行相关操作了
# 比如，可以查看txt文件的内容
[root@k8s-master01 pod]# kubectl exec pod-command -n dev -it -c busybox /bin/sh
/ # tail -f /tmp/hello.txt
14:44:19
14:44:22
14:44:25
```

```shell
特别说明：
    通过上面发现command已经可以完成启动命令和传递参数的功能，为什么这里还要提供一个args选项，用于传递参数呢?这其实跟docker有点关系，kubernetes中的command、args两项其实是实现覆盖Dockerfile中ENTRYPOINT的功能。
 1 如果command和args均没有写，那么用Dockerfile的配置。
 2 如果command写了，但args没有写，那么Dockerfile默认的配置会被忽略，执行输入的command
 3 如果command没写，但args写了，那么Dockerfile中配置的ENTRYPOINT的命令会被执行，使用当前args的参数
 4 如果command和args都写了，那么Dockerfile的配置被忽略，执行command并追加上args参数
```

### 2.4 环境变量

创建pod-env.yaml文件，内容如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-env
  namespace: dev
spec:
  containers:
  - name: busybox
    image: busybox:1.30
    command: ["/bin/sh","-c","while true;do /bin/echo $(date +%T);sleep 60; done;"]
    env: # 设置环境变量列表
    - name: "username"
      value: "admin"
    - name: "password"
      value: "123456"
```

env，环境变量，用于在pod中的容器设置环境变量。

```shell
# 创建Pod
[root@k8s-master01 ~]# kubectl create -f pod-env.yaml
pod/pod-env created

# 进入容器，输出环境变量
[root@k8s-master01 ~]# kubectl exec pod-env -n dev -c busybox -it /bin/sh
/ # echo $username
admin
/ # echo $password
123456
```

这种方式不是很推荐，推荐将这些配置单独存储在配置文件中，这种方式将在后面介绍。

### 2.5 端口设置

本小节来介绍容器的端口设置，也就是containers的ports选项。

首先看下ports支持的子选项：

```shell
[root@k8s-master01 ~]# kubectl explain pod.spec.containers.ports
KIND:     Pod
VERSION:  v1
RESOURCE: ports <[]Object>
FIELDS:
   name         <string>  # 端口名称，如果指定，必须保证name在pod中是唯一的		
   containerPort<integer> # 容器要监听的端口(0<x<65536)
   hostPort     <integer> # 容器要在主机上公开的端口，如果设置，主机上只能运行容器的一个副本(一般省略) 
   hostIP       <string>  # 要将外部端口绑定到的主机IP(一般省略)
   protocol     <string>  # 端口协议。必须是UDP、TCP或SCTP。默认为“TCP”。
```

接下来，编写一个测试案例，创建pod-ports.yaml：

```shell
apiVersion: v1
kind: Pod
metadata:
  name: pod-ports
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:1.17.1
    ports: # 设置容器暴露的端口列表
    - name: nginx-port
      containerPort: 80
      protocol: TCP
```

### 2.6 资源配额

容器中的程序要运行，肯定是要占用一定资源的，比如cpu和内存等，如果不对某个容器的资源做限制，那么它就可能吃掉大量资源，导致其它容器无法运行。针对这种情况，kubernetes提供了对内存和cpu的资源进行配额的机制，这种机制主要通过resources选项实现，他有两个子选项：

- limits：用于限制运行时容器的最大占用资源，当容器占用资源超过limits时会被终止，并进行重启（资源上限）
- requests ：用于设置容器需要的最小资源，如果环境资源不够，容器将无法启动（资源下限）

可以通过上面两个选项设置资源的上下限。

接下来，编写一个测试案例，创建pod-resources.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-resources
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:1.17.1
    resources: # 资源配额
      limits:  # 限制资源（上限）
        cpu: "2" # CPU限制，单位是core数
        memory: "10Gi" # 内存限制
      requests: # 请求资源（下限）
        cpu: "1"  # CPU限制，单位是core数
        memory: "10Mi"  # 内存限制
```

在这对cpu和memory的单位做一个说明：

- cpu：core数，可以为整数或小数
- memory： 内存大小，可以使用Gi、Mi、G、M等形式

## 三. Pod生命周期

我们一般将pod对象从创建至终的这段时间范围称为pod的生命周期，它主要包含下面的过程：

- pod创建过程
- 运行初始化容器（init container）过程
- 运行主容器（main container）
  - 容器启动后钩子（post start）、容器终止前钩子（pre stop）
  - 容器的存活性探测（liveness probe）、就绪性探测（readiness probe）
- pod终止过程

![](../images/20.png)

在整个生命周期中，Pod会出现5种**状态**（**相位**），分别如下：

- 挂起（Pending）：apiserver已经创建了pod资源对象，但它尚未被调度完成或者仍处于下载镜像的过程中
- 运行中（Running）：pod已经被调度至某节点，并且所有容器都已经被kubelet创建完成
- 成功（Succeeded）：pod中的所有容器都已经成功终止并且不会被重启
- 失败（Failed）：所有容器都已经终止，但至少有一个容器终止失败，即容器返回了非0值的退出状态
- 未知（Unknown）：apiserver无法正常获取到pod对象的状态信息，通常由网络通信失败所导致

### 3.1 创建和终止

**pod的创建过程**

1. 用户通过kubectl或其他api客户端提交需要创建的pod信息给apiServer
2. apiServer开始生成pod对象的信息，并将信息存入etcd，然后返回确认信息至客户端
3. apiServer开始反映etcd中的pod对象的变化，其它组件使用watch机制来跟踪检查apiServer上的变动
4. scheduler发现有新的pod对象要创建，开始为Pod分配主机并将结果信息更新至apiServer
5. node节点上的kubelet发现有pod调度过来，尝试调用docker启动容器，并将结果回送至apiServer
6. apiServer将接收到的pod状态信息存入etcd中

![](../images/1.png)

**pod的终止过程**

1. 用户向apiServer发送删除pod对象的命令
2. apiServcer中的pod对象信息会随着时间的推移而更新，在宽限期内（默认30s），pod被视为dead
3. 将pod标记为terminating状态
4. kubelet在监控到pod对象转为terminating状态的同时启动pod关闭过程
5. 端点控制器监控到pod对象的关闭行为时将其从所有匹配到此端点的service资源的端点列表中移除
6. 如果当前pod对象定义了preStop钩子处理器，则在其标记为terminating后即会以同步的方式启动执行
7. pod对象中的容器进程收到停止信号
8. 宽限期结束后，若pod中还存在仍在运行的进程，那么pod对象会收到立即终止的信号
9. kubelet请求apiServer将此pod资源的宽限期设置为0从而完成删除操作，此时pod对于用户已不可见

### 3.2 初始化容器

初始化容器是在pod的主容器启动之前要运行的容器，主要是做一些主容器的前置工作，它具有两大特征：

1. 初始化容器必须运行完成直至结束，若某初始化容器运行失败，那么kubernetes需要重启它直到成功完成
2. 初始化容器必须按照定义的顺序执行，当且仅当前一个成功之后，后面的一个才能运行

初始化容器有很多的应用场景，下面列出的是最常见的几个：

- 提供主容器镜像中不具备的工具程序或自定义代码
- 初始化容器要先于应用容器串行启动并运行完成，因此可用于延后应用容器的启动直至其依赖的条件得到满足

接下来做一个案例，模拟下面这个需求：

假设要以主容器来运行nginx，但是要求在运行nginx之前先要能够连接上mysql和redis所在服务器

为了简化测试，事先规定好mysql`(192.168.5.4)`和redis`(192.168.5.5)`服务器的地址

