# 使用Zookeeper实现简单的服务注册与发现

Zookeeper作为一个分布式协调服务，它的核心就是“文件系统”+“监听机制”，我们可以借助它完成很多其他的功能，例如：

- 服务注册与发现
- 分布式锁
- 分布式队列
- master选举
- 命名服务等

下面我们就模拟一个`Product`服务和一个`Order`服务，其中订单服务（Order）依赖于商品服务，在分布式环境中两个服务会分开部署，甚至`Product`服务会根据实际情况部署成集群模式，那两个服务之间就需要依赖“服务注册与发现”进行解耦，在运行时动态的加载服务列表，然后进行客户端负载均衡完成，服务之间的连接。

## 一. Product

编写`ServletContextListener`在启动时完成服务注册：

```java
public class InitListener implements ServletContextListener {
    private String port;
    private String zkCluster;

    public InitListener(String port,String zkCluster) {
        this.port = port;
        this.zkCluster = zkCluster;
    }

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try {
            //获取当前节点的IP
            String hostAddress = InetAddress.getLocalHost().getHostAddress();
            //注册服务
            ServiceRegister.register(zkCluster,hostAddress, port);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

服务注册的工具类：

```java
public class ServiceRegister {

    private static final String BASE_SERVICES = "/SERVICES";
    private static final String SERVICE_NAME = "/PRODUCT";

    public static void register(String zkCluster,String ip, String port) {
        try {
            //连接Zookeeper
            ZooKeeper zooKeeper = new ZooKeeper(zkCluster, 5000, (watchedEvent) -> {});
            //获取根节点
            Stat baseServiceNode = zooKeeper.exists(BASE_SERVICES, false);
            if (baseServiceNode == null) {
                //如果没有则创建持久类型的根节点
                zooKeeper.create(BASE_SERVICES, "".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
            }
            //获取根节点下对应服务的节点
            Stat serviceNameNode = zooKeeper.exists(BASE_SERVICES + SERVICE_NAME, false);
            if (serviceNameNode == null) {
                //如果没有则创建持久类型的服务节点
                zooKeeper.create(BASE_SERVICES + SERVICE_NAME, "".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE,
                        CreateMode.PERSISTENT);
            }
            String serviceStr = ip + ":" + port;
            //创建临时顺序节点，值为当前服务对应的ip:port
            //创建临时顺序节点的目的：当节点挂掉的时候，创建的这个节点会自动删除，从而触发客户端的监听事件更新消费者机器上的节点列表
            zooKeeper.create(BASE_SERVICES + SERVICE_NAME + "/child", serviceStr.getBytes(),
                    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (KeeperException e) {
            e.printStackTrace();
        }
    }
}
```

配置Listener：

```java
@SpringBootApplication
public class ProductApplication {

    @Value("${server.port}")
    private String port;

    @Value("${zookeeper.cluster}")
    private String zkCluster;

    public static void main(String[] args) {
        SpringApplication.run(ProductApplication.class, args);
    }

    @Bean
    public ServletListenerRegistrationBean servletListenerRegistrationBean() {
        ServletListenerRegistrationBean servletListenerRegistrationBean = new ServletListenerRegistrationBean();
        servletListenerRegistrationBean.setListener(new InitListener(port, zkCluster));
        return servletListenerRegistrationBean;
    }
}
```

编写商品服务接口：

```java
@RestController
public class ProductController {

    @Value("${server.port}")
    private String port;

    @GetMapping("/product")
    public String product() {
        try {
            String hostAddress = InetAddress.getLocalHost().getHostAddress();
            return "此次任务调用了" + hostAddress + ":" + port + "上的product服务";
        } catch (UnknownHostException e) {
            e.printStackTrace();
        }
        return "product服务调用失败";
    }
}
```

## 二. Order

编写`ServletContextListener`在启动时完成服务列表的加载：

```java
public class InitListener implements ServletContextListener {

    private static final String BASE_SERVICES = "/SERVICES";
    private static final String SERVICE_NAME = "/PRODUCT";

    private ZooKeeper zooKeeper;

    private String zkCluster;

    public InitListener(String zkCluster) {
        this.zkCluster = zkCluster;
    }

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        try {
            zooKeeper = new ZooKeeper(zkCluster, 5000,
                    watchedEvent -> {
                        if (watchedEvent.getType() == Watcher.Event.EventType.NodeChildrenChanged && watchedEvent.getPath().equals(BASE_SERVICES + SERVICE_NAME)) {
                            //当BASE_SERVICES + SERVICE_NAME子节点发生变动时触发事件，调用updateServices()更新服务列表
                            updateServices();
                        }
                    });
            updateServices();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void updateServices(){
        System.out.println("节点信息更新");
        try {
            //服务对应的子节点，将watch参数设置true表示开启下一次监听，zk树的下一次修改仍然会被Watcher监听到
            List<String> childs = zooKeeper.getChildren(BASE_SERVICES + SERVICE_NAME, true);
            List<String> serviceList = new LinkedList<>();
            for (String child : childs) {
                byte[] data = zooKeeper.getData(BASE_SERVICES  + SERVICE_NAME + "/" + child, false, null);
                String host = new String(data, "UTF-8");
                serviceList.add(host);
            }
            //更新本地保存的服务列表
            LoadBalance.updateServiceList(serviceList);
        } catch (KeeperException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    }

}

```

配置Listener：

```java
@SpringBootApplication
public class OrderApplication {
    @Value("${zookeeper.cluster}")
    private String zkCluster;

    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }

    @Bean
    public ServletListenerRegistrationBean servletListenerRegistrationBean(){
        ServletListenerRegistrationBean servletListenerRegistrationBean =new ServletListenerRegistrationBean();
        servletListenerRegistrationBean.setListener(new InitListener(zkCluster));
        return servletListenerRegistrationBean;
    }
}
```

编写LoadBalance负载均衡工具类：

```java
public abstract class LoadBalance {
    static final List<String> SERVICE_LIST = new LinkedList<>();

    static final ReentrantReadWriteLock LOCK = new ReentrantReadWriteLock();


    public static void updateServiceList(List<String> serviceList){
        LOCK.writeLock().lock();
        try {
            //删除所有元素
            SERVICE_LIST.removeIf(s -> true);
            SERVICE_LIST.addAll(serviceList);
        } finally {
            LOCK.writeLock().unlock();
        }
    }

    public abstract String getService();
}
```

```java
/**
 * 根据随机数选择服务提供者
 * @Auther: TJD
 * @Date: 2020-06-18
 * @DESCRIPTION:
 **/
@Component
public class RandomLoadBalance extends LoadBalance {
    @Override
    public String getService() {
        List<String> serviceList = LoadBalance.SERVICE_LIST;
        if (serviceList.size()>0) {
            int index = new Random().nextInt(serviceList.size());
            return serviceList.get(index);
        }
        return null;
    }
}
```

编写订单服务的接口：

```java
@RestController
public class OrderController {
    @Autowired
    private LoadBalance loadBalance;

    @GetMapping("/order")
    public String order(){
        String service = loadBalance.getService();
        System.out.println(service);
        if (service != null) {
            OkHttpClient okHttpClient = new OkHttpClient();
            Request request = new Request.Builder().url("http://"+service+"/product").build();
            try (Response response = okHttpClient.newCall(request).execute()) {
                ResponseBody body = response.body();
                return body.string();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return "没有找到可用的product服务";
    }
}
```

本文项目源码请移步至：<https://github.com/tianjindong/zookeeper-register>