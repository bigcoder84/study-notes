# Dubbo SPI

## 一. 概述

本文主要分享 **Dubbo 的拓展机制 SPI**。

想要理解 Dubbo ，理解 Dubbo SPI 是非常必须的。在 Dubbo 中，提供了大量的**拓展点**，基于 Dubbo SPI 机制加载。如下图所示：

![](../images/46.png)

> Dubbo SPI官方文档：[Dubbo SPI 概述 | Apache Dubbo](https://dubbo.apache.org/zh/docs3-v2/java-sdk/reference-manual/spi/overview/)

## 二. Dubbo SPI特性

在看具体的 Dubbo SPI 实现之前，我们先理解 Dubbo SPI 产生的背景：

Dubbo 的扩展点加载从 JDK 标准的 SPI (Service Provider Interface) 扩展点发现机制加强而来。

Dubbo 改进了 JDK 标准的 SPI 的以下问题：

1. JDK 标准的 SPI 会一次性实例化扩展点所有实现，如果有扩展实现初始化很耗时，但如果没用上也加载，会很浪费资源。
2. 如果扩展点加载失败，连扩展点的名称都拿不到了。比如：JDK 标准的 ScriptEngine，通过 getName() 获取脚本类型的名称，但如果 RubyScriptEngine 因为所依赖的 jruby.jar 不存在，导致 RubyScriptEngine 类加载失败，这个失败原因被吃掉了，和 ruby 对应不起来，当用户执行 ruby 脚本时，会报不支持 ruby，而不是真正失败的原因。
3. 增加了对扩展点 IoC 和 AOP 的支持，一个扩展点可以直接 setter 注入其它扩展点。

用户能够基于 Dubbo 提供的扩展能力，很方便基于自身需求扩展其他协议、过滤器、路由等。下面介绍下 Dubbo 扩展能力的特性。

- 按需加载。Dubbo 的扩展能力不会一次性实例化所有实现，而是用那个扩展类则实例化那个扩展类，减少资源浪费。
- 增加扩展类的 IOC 能力。Dubbo 的扩展能力并不仅仅只是发现扩展服务实现类，而是在此基础上更进一步，如果该扩展类的属性依赖其他对象，则 Dubbo 会自动的完成该依赖对象的注入功能。
- 增加扩展类的 AOP 能力。Dubbo 扩展能力会自动的发现扩展类的包装类，完成包装类的构造，增强扩展类的功能。
- 具备动态选择扩展实现的能力。Dubbo 扩展会基于参数，在运行时动态选择对应的扩展类，提高了 Dubbo 的扩展能力。
- 可以对扩展实现进行排序。能够基于用户需求，指定扩展实现的执行顺序。
- 提供扩展点的 Adaptive 能力。该能力可以使的一些扩展类在 consumer 端生效，一些扩展类在 provider 端生效。

从 Dubbo 扩展的设计目标可以看出，Dubbo 实现的一些例如动态选择扩展实现、IOC、AOP 等特性，能够为用户提供非常灵活的扩展能力。

## 三. 代码结构

Dubbo SPI 在 `dubbo-common` 的 `org.apache.dubbo.common.extension` 包实现，如下图所示：

![](../images/47.png)

## 四. ExtensionLoader

`org.apache.dubbo.common.extension.ExtensionLoader` ，拓展加载器。这是 Dubbo SPI 的**核心**。

### 4.1 属性

```java
 /**
     * 拓展加载器集合
     */
    private static final ConcurrentMap<Class<?>, ExtensionLoader<?>> EXTENSION_LOADERS = new ConcurrentHashMap<>(64);

    /**
     * 拓展加载器集合
     * key：拓展接口
     */
    private static final ConcurrentMap<Class<?>, Object> EXTENSION_INSTANCES = new ConcurrentHashMap<>(64);
    /**
     * 拓展接口
     */
    private final Class<?> type;
    /**
     * 对象工厂
     *
     * 用于调用 {@link #injectExtension(Object)} 方法，向拓展对象注入依赖属性。
     *
     * 例如，StubProxyFactoryWrapper 中有 `Protocol protocol` 属性。
     */
    private final ExtensionFactory objectFactory;
    /**
     * 缓存的拓展名与拓展类的映射。
     *
     * 和 {@link #cachedClasses} 的 KV 对调。
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private final ConcurrentMap<Class<?>, String> cachedNames = new ConcurrentHashMap<>();

    /**
     * 缓存的拓展实现类集合。
     *
     * 不包含如下两种类型：
     *  1. 自适应拓展实现类。例如 AdaptiveExtensionFactory
     *  2. 带唯一参数为拓展接口的构造方法的实现类，或者说拓展 Wrapper 实现类。例如，ProtocolFilterWrapper 。
     *   拓展 Wrapper 实现类，会添加到 {@link #cachedWrapperClasses} 中
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private final Holder<Map<String, Class<?>>> cachedClasses = new Holder<>();
    /**
     * 拓展名与 @Activate 的映射
     *
     * 例如，AccessLogFilter。
     *
     * 用于 {@link #getActivateExtension(URL, String)}
     */
    private final Map<String, Object> cachedActivates = new ConcurrentHashMap<>();
    /**
     * 缓存的拓展对象集合
     *
     * key：拓展名
     * value：拓展对象
     *
     * 例如，Protocol 拓展
     *      key：dubbo value：DubboProtocol
     *      key：injvm value：InjvmProtocol
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private final ConcurrentMap<String, Holder<Object>> cachedInstances = new ConcurrentHashMap<>();
    /**
     * 缓存的自适应( Adaptive )拓展对象
     */
    private final Holder<Object> cachedAdaptiveInstance = new Holder<>();
    /**
     * 缓存的自适应拓展对象的类
     *
     * {@link #getAdaptiveExtensionClass()}
     */
    private volatile Class<?> cachedAdaptiveClass = null;
    /**
     * 缓存的默认拓展名
     *
     * 通过 {@link SPI} 注解获得
     */
    private String cachedDefaultName;
    /**
     * 创建 {@link #cachedAdaptiveInstance} 时发生的异常。
     *
     * 发生异常后，不再创建，参见 {@link #createAdaptiveExtension()}
     */
    private volatile Throwable createAdaptiveInstanceError;
    /**
     * 拓展 Wrapper 实现类集合
     *
     * 带唯一参数为拓展接口的构造方法的实现类
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private Set<Class<?>> cachedWrapperClasses;
    /**
     * 拓展名 与 加载对应拓展类发生的异常 的 映射
     *
     * key：拓展名
     * value：异常
     *
     * 在 {@link #loadFile(Map, String)} 时，记录
     */
    private Map<String, IllegalStateException> exceptions = new ConcurrentHashMap<>();

    private static volatile LoadingStrategy[] strategies = loadLoadingStrategies();
```

我们将属性分成了两类：1）静态属性；2）对象属性。这是为啥呢？

- 【静态属性】一方面，ExtensionLoader 是 ExtensionLoader 的**管理容器**。一个拓展( 拓展接口 )对应一个 ExtensionLoader 对象。例如，Protocol 和 Filter **分别**对应一个 ExtensionLoader 对象。
- 【对象属性】另一方面，一个拓展通过其 ExtensionLoader 对象，加载它的拓展实现们。我们会发现多个属性都是 “cached” 开头。ExtensionLoader 考虑到性能和资源的优化，读取拓展配置后，会首先进行**缓存**。等到 Dubbo 代码**真正**用到对应的拓展实现时，进行拓展实现的对象的初始化。并且，初始化完成后，也会进行**缓存**。也就是说：
  - 缓存加载的拓展配置
  - 缓存创建的拓展实现对象

### 4.2 获得拓展配置

#### 4.2.1 getExtensionClasses

```java
    /**
     * 缓存的拓展实现类集合。
     *
     * 不包含如下两种类型：
     *  1. 自适应拓展实现类。例如 AdaptiveExtensionFactory
     *  2. 带唯一参数为拓展接口的构造方法的实现类，或者说拓展 Wrapper 实现类。例如，ProtocolFilterWrapper 。
     *   拓展 Wrapper 实现类，会添加到 {@link #cachedWrapperClasses} 中
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private final Holder<Map<String, Class<?>>> cachedClasses = new Holder<>();
    /**
     * 缓存的自适应拓展对象的类
     *
     * {@link #getAdaptiveExtensionClass()}
     */
    private volatile Class<?> cachedAdaptiveClass = null;
    /**
     * 拓展 Wrapper 实现类集合
     *
     * 带唯一参数为拓展接口的构造方法的实现类
     *
     * 通过 {@link #loadExtensionClasses} 加载
     */
    private Set<Class<?>> cachedWrapperClasses;


	/**
     * 获得拓展实现
     *
     * @return 拓展实现类数组
     */
    private Map<String, Class<?>> getExtensionClasses() {
        // 从缓存中，获得拓展实现类数组
        Map<String, Class<?>> classes = cachedClasses.get();
        if (classes == null) {
            synchronized (cachedClasses) {
                classes = cachedClasses.get();
                if (classes == null) {
                    // 从配置文件中，加载拓展实现类数组
                    classes = loadExtensionClasses();
                    // 设置到缓存中
                    cachedClasses.set(classes);
                }
            }
        }
        return classes;
    }
```

- cachedClasses属性，缓存的拓展实现类集合。它不包含如下两种类型的拓展实现：
  - 自适应拓展实现类。例如 AdaptiveExtensionFactory 。
    - 拓展 Adaptive 实现类，会添加到 `cachedAdaptiveClass` 属性中。
  - 带唯一参数为拓展接口的构造方法的实现类，或者说拓展 Wrapper 实现类。例如，ProtocolFilterWrapper 。
    - 拓展 Wrapper 实现类，会添加到 `cachedWrapperClasses` 属性中。
  - 总结来说，`cachedClasses` + `cachedAdaptiveClass` + `cachedWrapperClasses` 才是**完整**缓存的拓展实现类的配置。

#### 4.2.2 loadExtensionClasses

```java
    private Map<String, Class<?>> loadExtensionClasses() {
        // 加载默认的拓展名
        cacheDefaultExtensionName();

        Map<String, Class<?>> extensionClasses = new HashMap<>();

        // 循环加载策略，加载对应的拓展实现
        for (LoadingStrategy strategy : strategies) {
            loadDirectory(extensionClasses, strategy.directory(), type.getName(), strategy.preferExtensionClassLoader(), strategy.overridden(), strategy.excludedPackages());
            // 为了兼容 2.7 之前的老版本。在2.7之前，Dubbo还未进入Apache孵化，包名还是Alibaba
            loadDirectory(extensionClasses, strategy.directory(), type.getName().replace("org.apache", "com.alibaba"), strategy.preferExtensionClassLoader(), strategy.overridden(), strategy.excludedPackages());
        }

        return extensionClasses;
    }
```

第一步：加载默认的扩展名

第二步：遍历加载策略数组，去加载不同文件夹下的扩展。

strategies属性是在启动时，在 `loadLoadingStrategies` 方法中通过 Java SPI 加载的 `LoadingStrategy` 接口的实现类。

```java
    private static volatile LoadingStrategy[] strategies = loadLoadingStrategies();

    private static LoadingStrategy[] loadLoadingStrategies() {
        return stream(load(LoadingStrategy.class).spliterator(), false)
                .sorted()
                .toArray(LoadingStrategy[]::new);
    }
```

它会读取 `META-INF/services` 下的 `org.apache.dubbo.common.extension.LoadingStrategy` 文件中注册的实现类：

![](../images/48.png)

这些实现类中会指定，需要加载的拓展的配置文件路径：

```java
public class DubboInternalLoadingStrategy implements LoadingStrategy {

    // 加载 META-INF/dubbo/internal/ 下的扩展实现
    @Override
    public String directory() {
        return "META-INF/dubbo/internal/";
    }

    @Override
    public int getPriority() {
        return MAX_PRIORITY;
    }
}
```

![](../images/49.png)

**loadDirectory方法**

```java
    private void loadDirectory(Map<String, Class<?>> extensionClasses, String dir, String type,
                               boolean extensionLoaderClassLoaderFirst, boolean overridden, String... excludedPackages) {
        // 获得完整的文件名( 相对路径 )。例如："META-INF/dubbo/internal/com.alibaba.dubbo.common.extension.ExtensionFactory" 。
        String fileName = dir + type;// 第4行
        try {
            // 获得文件名对应的所有文件数组
            Enumeration<java.net.URL> urls = null;
            ClassLoader classLoader = findClassLoader();

            // try to load from ExtensionLoader's ClassLoader first
            if (extensionLoaderClassLoaderFirst) {
                ClassLoader extensionLoaderClassLoader = ExtensionLoader.class.getClassLoader();
                if (ClassLoader.getSystemClassLoader() != extensionLoaderClassLoader) {
                    urls = extensionLoaderClassLoader.getResources(fileName);
                }
            }

            if (urls == null || !urls.hasMoreElements()) { // 第 18 行
                if (classLoader != null) {
                    urls = classLoader.getResources(fileName);
                } else {
                    urls = ClassLoader.getSystemResources(fileName);
                }
            } // 第 24 行

            if (urls != null) {
                while (urls.hasMoreElements()) { // 第 27 行
                    java.net.URL resourceURL = urls.nextElement();
                    // 加载指定配置文件（resourceURL）下的实现
                    loadResource(extensionClasses, classLoader, resourceURL, overridden, excludedPackages);
                }
            } // 第 32 行
        } catch (Throwable t) {
            logger.error("Exception occurred when loading extension class (interface: " +
                    type + ", description file: " + fileName + ").", t);
        }
    }
```

- 第 4 行：获得完整的文件名( 相对路径 )。例如：`"META-INF/dubbo/internal/com.alibaba.dubbo.common.extension.ExtensionFactory"` 。

- 第 18 至 24 行：获得文件名对应的所有文件 URL 数组。例如：

  ![](../images/50.png)

- 第 27 至 32 行：遍历逐个**文件**。

**loadResource方法**

```java
    private void loadResource(Map<String, Class<?>> extensionClasses, ClassLoader classLoader,
                              java.net.URL resourceURL, boolean overridden, String... excludedPackages) {
        try {
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(resourceURL.openStream(), StandardCharsets.UTF_8))) {
                String line;
                String clazz = null;
                while ((line = reader.readLine()) != null) {
                    // 去除 #注释
                    final int ci = line.indexOf('#');
                    if (ci >= 0) {
                        line = line.substring(0, ci);
                    }
                    line = line.trim();
                    if (line.length() > 0) {
                        try {
                            // 拆分，key=value 的配置格式
                            String name = null;
                            int i = line.indexOf('=');
                            if (i > 0) {
                                name = line.substring(0, i).trim();
                                clazz = line.substring(i + 1).trim();
                            } else {
                                // Dubbo SPI 会兼容 Java SPI 的配置格式，那么按照此处的解析方式，name 会为空。这种情况下，拓展名会自动生成
                                clazz = line;
                            }
                            if (StringUtils.isNotEmpty(clazz) && !isExcluded(clazz, excludedPackages)) {
                                // 加载配置文件配置拓展的实现类
                                loadClass(extensionClasses, resourceURL, Class.forName(clazz, true, classLoader), name, overridden);
                            }
                        } catch (Throwable t) {
                            IllegalStateException e = new IllegalStateException("Failed to load extension class (interface: " + type + ", class line: " + line + ") in " + resourceURL + ", cause: " + t.getMessage(), t);
                            exceptions.put(line, e);
                        }
                    }
                }
            }
        } catch (Throwable t) {
            logger.error("Exception occurred when loading extension class (interface: " +
                    type + ", class file: " + resourceURL + ") in " + resourceURL, t);
        }
    }
```

- 第 7 行：进入文件内部，逐**行**遍历。

**loadClass方法**

```java
    private void loadClass(Map<String, Class<?>> extensionClasses, java.net.URL resourceURL, Class<?> clazz, String name,
                           boolean overridden) throws NoSuchMethodException {
        // 判断拓展实现，是否实现拓展接口
        if (!type.isAssignableFrom(clazz)) {
            throw new IllegalStateException("Error occurred when loading extension class (interface: " +
                    type + ", class line: " + clazz.getName() + "), class "
                    + clazz.getName() + " is not subtype of interface.");
        }
        if (clazz.isAnnotationPresent(Adaptive.class)) {
            // 缓存自适应拓展对象的类到 `cachedAdaptiveClass`
            cacheAdaptiveClass(clazz, overridden);
        } else if (isWrapperClass(clazz)) {
            // 缓存拓展 Wrapper 实现类到 `cachedWrapperClasses`
            cacheWrapperClass(clazz);
        } else {
            clazz.getConstructor();
            // 未配置拓展名，自动生成。例如，DemoFilter 为 demo 。主要用于兼容 Java SPI 的配置。
            if (StringUtils.isEmpty(name)) {
                name = findAnnotationName(clazz);
                if (name.length() == 0) {
                    throw new IllegalStateException("No such extension name for the class " + clazz.getName() + " in the config " + resourceURL);
                }
            }

            // 获得拓展名，可以是数组，有多个拓展名。
            String[] names = NAME_SEPARATOR.split(name);
            if (ArrayUtils.isNotEmpty(names)) {
                // 缓存 @Activate 到 `cachedActivates` 。
                cacheActivateClass(clazz, names[0]);
                for (String n : names) {
                    // 缓存到 `cachedNames`
                    cacheName(clazz, n);
                    // 若 isWrapperClass 方法获取构造方法失败，则代表是普通的拓展实现类，缓存到 extensionClasses 变量中
                    saveInExtensionClass(extensionClasses, clazz, n, overridden);
                }
            }
        }
    }
```

### 4.3 获得拓展加载器

在 Dubbo 的代码里，常常能看到如下的代码：

```java
ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(name)
```

#### 4.3.1 getExtensionLoader

```java
    /**
      * 根据拓展点的接口，获得拓展加载器
      *
      * @param type 接口
      * @param <T> 泛型
      * @return 加载器
      */
    public static <T> ExtensionLoader<T> getExtensionLoader(Class<T> type) {
        if (type == null) {
            throw new IllegalArgumentException("Extension type == null");
        }
        // 必须是接口
        if (!type.isInterface()) {
            throw new IllegalArgumentException("Extension type (" + type + ") is not an interface!");
        }
        // 必须包含 @SPI 注解
        if (!withExtensionAnnotation(type)) {
            throw new IllegalArgumentException("Extension type (" + type +
                    ") is not an extension, because it is NOT annotated with @" + SPI.class.getSimpleName() + "!");
        }

        // 获得接口对应的拓展点加载器
        ExtensionLoader<T> loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        if (loader == null) {
            // 若不存在，则创建 ExtensionLoader 对象，并添加到 EXTENSION_LOADERS。
            EXTENSION_LOADERS.putIfAbsent(type, new ExtensionLoader<T>(type));
            loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        }
        return loader;
    }
```

#### 4.3.2 构造方法

构造方法，代码如下：

```java
/**
 * 拓展接口。
 * 例如，Protocol
 */
private final Class<?> type;
/**
 * 对象工厂
 *
 * 用于调用 {@link #injectExtension(Object)} 方法，向拓展对象注入依赖属性。
 *
 * 例如，StubProxyFactoryWrapper 中有 `Protocol protocol` 属性。
 */
private final ExtensionFactory objectFactory;

private ExtensionLoader(Class<?> type) {
    this.type = type;
    objectFactory = (type == ExtensionFactory.class ? null : ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension()); // 第 17 行
}
```

- `objectFactory` 属性，对象工厂，**功能上和 Spring IOC 一致**。
  - 用于调用 `#injectExtension(instance)` 方法时，向创建的拓展注入其依赖的属性。例如，`CacheFilter.cacheFactory` 属性。
  - 第 17 行：当拓展接口非 ExtensionFactory 时（如果不加这个判断，会是一个死循环），调用 `ExtensionLoader#getAdaptiveExtension()` 方法，获得 ExtensionFactory 拓展接口的**自适应**拓展实现对象。**为什么呢**？在 后文详细解释。

### 4.4 获得指定拓展对象

在 Dubbo 的代码里，常常能看到如下的代码：

```java
ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(name)
```

#### 4.4.1 getExtension

```java
     /**
      * 返回指定名字的扩展对象。如果指定名字的扩展不存在，则抛异常 {@link IllegalStateException}.
      *
      * @param name 拓展名
      * @return 拓展对象
      */
    @SuppressWarnings("unchecked")
    public T getExtension(String name) {
        return getExtension(name, true);
    }

    public T getExtension(String name, boolean wrap) {
        if (StringUtils.isEmpty(name)) {
            throw new IllegalArgumentException("Extension name == null");
        }
        // 查找 默认的 拓展对象
        if ("true".equals(name)) {
            return getDefaultExtension();
        }
        // 从 缓存中 获得对应的拓展对象
        final Holder<Object> holder = getOrCreateHolder(name);
        Object instance = holder.get();
        if (instance == null) {
            synchronized (holder) {
                instance = holder.get();
                // 从 缓存中 未获取到，进行创建缓存对象。
                if (instance == null) {
                    instance = createExtension(name, wrap);
                    // 设置创建对象到缓存中
                    holder.set(instance);
                }
            }
        }
        return (T) instance;
    }
```

#### 4.4.2 createExtension

`#createExtension(name)` 方法，创建拓展名的拓展对象，并缓存。代码如下：

```java
    /**
     * 创建拓展名的拓展对象，并缓存。
     *
     * @param name 拓展名
     * @return 拓展对象
     */
    @SuppressWarnings("unchecked")
    private T createExtension(String name, boolean wrap) {
        // 获得拓展名对应的拓展实现类
        Class<?> clazz = getExtensionClasses().get(name);
        if (clazz == null) {
            throw findException(name);
        }
        try {
            // 从缓存中，获得拓展对象。
            T instance = (T) EXTENSION_INSTANCES.get(clazz);
            if (instance == null) {
                // 当缓存不存在时，创建拓展对象，并添加到缓存中。
                EXTENSION_INSTANCES.putIfAbsent(clazz, clazz.getDeclaredConstructor().newInstance());
                instance = (T) EXTENSION_INSTANCES.get(clazz);
            }
            // 注入依赖的属性
            injectExtension(instance);


            if (wrap) {

                List<Class<?>> wrapperClassesList = new ArrayList<>();
                if (cachedWrapperClasses != null) {
                    wrapperClassesList.addAll(cachedWrapperClasses);
                    wrapperClassesList.sort(WrapperComparator.COMPARATOR);
                    Collections.reverse(wrapperClassesList);
                }

                if (CollectionUtils.isNotEmpty(wrapperClassesList)) {
                    for (Class<?> wrapperClass : wrapperClassesList) {
                        Wrapper wrapper = wrapperClass.getAnnotation(Wrapper.class);
                        if (wrapper == null
                                || (ArrayUtils.contains(wrapper.matches(), name) && !ArrayUtils.contains(wrapper.mismatches(), name))) {
                            // 创建 Wrapper 拓展对象
                            instance = injectExtension((T) wrapperClass.getConstructor(type).newInstance(instance));
                        }
                    }
                }
            }

            // 实例初始化
            initExtension(instance);
            return instance;
        } catch (Throwable t) {
            throw new IllegalStateException("Extension instance (name: " + name + ", class: " +
                    type + ") couldn't be instantiated: " + t.getMessage(), t);
        }
    }
```



> Wrapper 类同样实现了扩展点接口，但是 Wrapper 不是扩展点的真正实现。它的用途主要是用于从 ExtensionLoader 返回扩展点时，包装在真正的扩展点实现外。即从 ExtensionLoader 中返回的实际上是 Wrapper 类的实例，Wrapper 持有了实际的扩展点实现类。
>
> 扩展点的 Wrapper 类可以有多个，也可以根据需要新增。
>
> 通过 Wrapper 类可以把所有扩展点公共逻辑移至 Wrapper 中。新加的 Wrapper 在所有的扩展点上添加了逻辑，有些类似 AOP，即 Wrapper 代理了扩展点。
>
> - 例如：[ListenerExporterWrapper、[ProtocolFilterWrapper](https://github.com/YunaiV/dubbo/blob/6b8e51ac55880a0f10a34f297d0869fcdbb42369/dubbo-rpc/dubbo-rpc-api/src/main/java/com/alibaba/dubbo/rpc/protocol/ProtocolFilterWrapper.java) 。

#### 4.4.3 injectExtension

