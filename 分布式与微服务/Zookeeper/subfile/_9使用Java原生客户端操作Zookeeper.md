# 使用Java原生客户端操作Zookeeper

> 说明：本文转载至：<https://blog.csdn.net/vbirdbest/article/details/82699076>

## 一. Zookeeper常用客户端

- zookeeper：官方提供的，原生的api，使用起来比较麻烦，比较底层，不够直接，不建议使用。

- zkclient: 对原生api的封装，开源项目(https://github.com/adyliu/zkclient)，dubbo中使用的是这个。

- Apache Curator：Apache的开源项目，对原生客户端zookeeper进行封装，易于使用, 功能强大， 一般都是使用这个框架。

## 二. 原生客户端使用

引入依赖：

```xml
<dependency>
    <groupId>org.apache.zookeeper</groupId>
    <artifactId>zookeeper</artifactId>
    <version>3.4.12</version>
</dependency>
```

### 2.1 连接ZK

```java
public class ZkSession {
    public static ZooKeeper getZkSession(String IP) {
        CountDownLatch countDownLatch = new CountDownLatch(1);
        ZooKeeper zooKeeper = null;
        try {
            zooKeeper = new ZooKeeper(IP, 5000, new Watcher() {
                @Override
                public void process(WatchedEvent watchedEvent) {
                    if (watchedEvent.getState() == Event.KeeperState.SyncConnected) {
                       //连接成功后才能将getZkSession方法放行
                        countDownLatch.countDown();
                    }
                    if (watchedEvent.getType() == Event.EventType.NodeCreated) {
                        //创建节点事件
                        System.out.println("创建了一个节点：" + watchedEvent.getPath());
                    }
                    if (watchedEvent.getType() == Event.EventType.NodeDeleted) {
                        //创建节点事件
                        System.out.println("删除了一个节点：" + watchedEvent.getPath());
                    }
                }
            }, true);
            countDownLatch.await();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return zooKeeper;
    }
    public static void main(String[] args) {
        ZooKeeper zkSession = ZkSession.getZkSession("192.168.0.11:2181");
    }
}
```

这里需要指定连接的字符串，超时时间和一个watch接口。zookeeper的连接和数据库的连接不同，数据库通过DriverManager的getConnect方法就可以直接获取到连接，但zookeeper在获取连接的过程中，使用了Future。也就意味着，new之后所拿到的仅仅是一个zookeeper对象，而这个对象可能还没有连接到zookeeper服务。

这么说，zookeeper的连接过程可能会受到网络，zookeeper集群各种问题的影响，连接的过程可能会比较慢，因此，为了提高程序的执行性能，在new的时候就给你一个协议，你可以通过这个协议，来拿到连接。这里其实就是一个Futrue模式，如果对Future不是很了解的朋友可以去网络上找些资料学习。

为了我们能够拿到真实可用的zookeeper对象，我们这里使用了CountDownLatch，这是一个并发工具类，在初始化的时候指定一个int类型的值，每次调用countDown方法，这个值都会减一，当减到0时，所有的await线程都会被叫醒。

当连接成功之后，zookeeper会发出一个通知，所以我们要定义一个观察者（Watch）来监听这个通知，这就是代码第6行的implements Watcher的原因。 Watcher接口中有一个process方法，在这个方法中，当我们监听到连接成功，就把CountDownLatch的值减1，这样，第23行的代码就会被叫醒，于是就返回zookeeper实例成功。

这就是连接zookeeper的整个过程。这里涉及到了多线程并发相关的内容比较多，如果你对多线程并发相关的内容不够了解，看这段代码可能还是会有些困惑的。

### 2.2 创建节点

创建`world:anyone:cdrwa`权限的节点：

```JAVA
public void testCreateNode() throws KeeperException, InterruptedException {
    ZooKeeper zooKeeper = ZkSession.getZkSession("192.168.0.11:2181");
    /**
     * ZooDefs.Ids.OPEN_ACL_UNSAFE //相当于 world:anyone:cdrwa
     * CreateMode.PERSISTENT  创建持久类型的节点
     */
    zooKeeper.create("/java_cli/test1", "test".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
}
```

创建`digest:tjd:123:cdrwa`权限的节点：

```java
public void testCreateNode2() throws KeeperException, InterruptedException, NoSuchAlgorithmException {
    ZooKeeper zooKeeper = ZkSession.getZkSession("192.168.0.11:2181");
    List<ACL> acls = new ArrayList<>();
    ACL acl = new ACL(ZooDefs.Perms.ALL, new Id("digest", DigestAuthenticationProvider.generateDigest("tjd:123456")));
    acls.add(acl);
    zooKeeper.create("/java_cli", "test".getBytes(), acls, CreateMode.PERSISTENT);
}
```

### 2.3 获取节点数据

获取子节点的内容可以通过zookeeper的getData方法，getData方法有多个重载，主要就是分为直接获取和异步获取，异步获取多了一个回掉，直接获取则直接返回获取的结果。下面是一个直接获取的例子。

```shell
public void testReadNode() throws KeeperException, InterruptedException {
    Stat stat = new Stat();
    byte[] data = zooKeeper.getData("/java_cli/test1", true, stat);
    System.out.println(new String(data));
    System.out.println(stat);
}
```

### 2.4 修改节点数据

与getData类似，setData也有两种模式，一种是直接修改，另外一种是异步修改，异步修改之后可以通过回调将修改后的数据带回。这里仅演示同步修改。

```java
@Test
public void testWriteNode() throws KeeperException, InterruptedException {
    Stat stat = zooKeeper.setData("/java_cli/test1", "hello".getBytes(), -1);
    System.out.println(stat);
}
```

这里主要说的是version，这里的version指的是znode节点的dataVersion的值，每次数据的修改都会更新这个值，主要是为了保证一致性，具体请了解CAS。通俗来讲就是如果你指定的version比当前实际的version值小，则表示已经有其他线程所更新了，你也就不能更新成功了，否则则可以更新成功。如果你不管别的线程有没有更新成功都要更新这个节点的值，则version可以指定为-1

#### 关于Watcher

我们在get的时候，看到有参数为Watcher，这里Watcher是干嘛的呢，就是可以在数据做了修改之后，zookeeper会发出通知，那么注册的Wacher就可以接收到数据的修改。

### 2.5 删除节点

对于节点的删除，同样有同步删除和异步删除，异步删除比同步删除多了一个回调。这里仅演示同步删除，代码如下：

```java
public void testDeleteNode() throws KeeperException, InterruptedException {
    zooKeeper.delete("/java_cli/test1",-1);
}
```

注意删除这里也有一个version，这个version和setData的version意义相同。删除只能删除单个节点，不能进行递归删除。

