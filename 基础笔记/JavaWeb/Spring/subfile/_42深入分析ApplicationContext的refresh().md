# 深入分析 ApplicationContext 的 refresh()

上篇博客只是对 ApplicationContext 相关的接口做了一个简单的介绍，作为一个高富帅级别的 Spring 容器，它涉及的方法实在是太多了，全部介绍是不可能的，而且大部分功能都已经在前面系列博客中做了详细的介绍，所以这篇博问介绍 ApplicationContext 最重要的方法（小编认为的） ：`#refresh()` 方法。

`#refresh()` 方法，是定义在 ConfigurableApplicationContext 类中的，如下：

```java
// ConfigurableApplicationContext.java

/**
 * Load or refresh the persistent representation of the configuration,
 * which might an XML file, properties file, or relational database schema.
 * As this is a startup method, it should destroy already created singletons
 * if it fails, to avoid dangling resources. In other words, after invocation
 * of that method, either all or no singletons at all should be instantiated.
 * @throws BeansException if the bean factory could not be initialized
 * @throws IllegalStateException if already initialized and multiple refresh
 * attempts are not supported
 */
void refresh() throws BeansException, IllegalStateException;
```

- 作用就是：**刷新 Spring 的应用上下文**。

其实现是在 AbstractApplicationContext 中实现。如下：

