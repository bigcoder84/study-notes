# IoC 之加载 Bean：创建Bean的流程

## 一. createBean 抽象方法

﻿在上篇博客 [《IoC 之加载 Bean：分析各 scope 的 Bean 创建》](./_28分析各scope的Bean创建.md) 中，有一个核心方法没有讲到， `#createBean(String beanName, RootBeanDefinition mbd, Object[] args)` 方法，代码如下：

```java
// AbstractBeanFactory.java

protected abstract Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
		throws BeanCreationException;
```

- 该方法定义在 AbstractBeanFactory 中，其含义是根据给定的 BeanDefinition 和 `args` 实例化一个 Bean 对象。
- 如果该 BeanDefinition 存在父类，则该 BeanDefinition 已经合并了父类的属性。
- 所有 Bean 实例的创建，都会委托给该方法实现。
- 该方法接受三个方法参数：
  - `beanName` ：bean 的名字。
  - `mbd` ：已经合并了父类属性的（如果有的话）BeanDefinition 对象。
  - `args` ：用于构造函数或者工厂方法创建 Bean 实例对象的参数。

## 二. createBean 默认实现

该抽象方法的默认实现是在类 AbstractAutowireCapableBeanFactory 中实现，代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

@Override
protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
        throws BeanCreationException {

    if (logger.isTraceEnabled()) {
        logger.trace("Creating instance of bean '" + beanName + "'");
    }
    RootBeanDefinition mbdToUse = mbd;

    // Make sure bean class is actually resolved at this point, and
    // clone the bean definition in case of a dynamically resolved Class
    // which cannot be stored in the shared merged bean definition.
    // <1> 确保此时的 bean 已经被解析了
    // 如果获取的class 属性不为null，则克隆该 BeanDefinition
    // 主要是因为该动态解析的 class 无法保存到到共享的 BeanDefinition
    Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        mbdToUse.setBeanClass(resolvedClass);
    }

    // Prepare method overrides.
    try {
        // <2> 验证和准备覆盖方法
        mbdToUse.prepareMethodOverrides();
    } catch (BeanDefinitionValidationException ex) {
        throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
                beanName, "Validation of method overrides failed", ex);
    }

    try {
        // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
        // <3> 实例化的前置处理
        // 给 BeanPostProcessors 一个机会用来返回一个代理类而不是真正的类实例
        // AOP 的功能就是基于这个地方
        Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
        if (bean != null) {
            return bean;
        }
    } catch (Throwable ex) {
        throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
                "BeanPostProcessor before instantiation of bean failed", ex);
    }

    try {
        // <4> 创建 Bean 对象
        Object beanInstance = doCreateBean(beanName, mbdToUse, args);
        if (logger.isTraceEnabled()) {
            logger.trace("Finished creating instance of bean '" + beanName + "'");
        }
        return beanInstance;
    } catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
        // A previously detected exception with proper bean creation context already,
        // or illegal singleton state to be communicated up to DefaultSingletonBeanRegistry.
        throw ex;
    } catch (Throwable ex) {
        throw new BeanCreationException(
                mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
    }
}
```

过程如下：

- `<1>` 处，解析指定 BeanDefinition 的 class 属性。
- `<2>` 处，处理 `override` 属性。
- `<3>` 处，实例化的前置处理。
- `<4>` 处，创建 Bean 对象。

### 2.1 解析指定 BeanDefinition 的 class

```java
// AbstractAutowireCapableBeanFactory.java

Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
    mbdToUse = new RootBeanDefinition(mbd);
    mbdToUse.setBeanClass(resolvedClass);
}
```

- `#resolveBeanClass(final RootBeanDefinition mbd, String beanName, final Class<?>... typesToMatch)` 方法，主要是解析 bean definition 的 class 类，并将已经解析的 Class 存储在 bean definition 中以供后面使用。
- 如果解析的 class 不为空，则会将该 BeanDefinition 进行设置到 `mbdToUse` 中。这样做的主要目的是，以为动态解析的 class 是无法保存到共享的 BeanDefinition 中。

### 2.2 处理 override 属性

大家还记得 `lookup-method` 和 `replace-method` 这两个配置功能？在博客 [《IoC 之解析 `<bean>` 标签下子元素》](./_21IoC之解析bean标签下子元素.md) 中，已经详细分析了这两个标签的用法和解析过程，知道解析过程其实就是讲这两个配置存放在 BeanDefinition 中的 `methodOverrides` 属性中。

我们知道在 bean 实例化的过程中如果检测到存在 `methodOverrides` ，则会动态地位为当前 bean 生成代理并使用对应的拦截器为 bean 做**增强处理**。具体的实现我们后续分析，现在先看 `mbdToUse.prepareMethodOverrides()` 代码块，都干了些什么事，代码如下：

```java
// AbstractBeanDefinition.java

public void prepareMethodOverrides() throws BeanDefinitionValidationException {
    // Check that lookup methods exists.
    if (hasMethodOverrides()) {
        Set<MethodOverride> overrides = getMethodOverrides().getOverrides();
        synchronized (overrides) { // 同步
            // 循环，执行 prepareMethodOverride
            for (MethodOverride mo : overrides) {
                prepareMethodOverride(mo);
            }
        }
    }
}
```

如果存在 `methodOverrides` ，则获取所有的 override method ，然后通过迭代的方法一次调用 `#prepareMethodOverride(MethodOverride mo)` 方法。代码如下：

```java
// AbstractBeanDefinition.java

protected void prepareMethodOverride(MethodOverride mo) throws BeanDefinitionValidationException {
	int count = ClassUtils.getMethodCountForName(getBeanClass(), mo.getMethodName());
	if (count == 0) {
		throw new BeanDefinitionValidationException(
				"Invalid method override: no method with name '" + mo.getMethodName() +
				"' on class [" + getBeanClassName() + "]");
	} else if (count == 1) {
		// Mark override as not overloaded, to avoid the overhead of arg type checking.
		mo.setOverloaded(false);
	}
}
```

- 根据方法名称，从 class 中获取该方法名的个数：
  - 如果个数为 0 ，则抛出 BeanDefinitionValidationException 异常。
  - 如果个数为 1 ，则设置该重载方法**没有被重载**。
- 若一个类中存在**多个**重载方法，则在方法调用的时候还需要根据参数类型来判断到底重载的是哪个方法。在设置重载的时候其实这里做了一个**小小优化**，那就是当 `count == 1` 时，设置 `overloaded = false` ，这样表示该方法没有重载。这样，在后续调用的时候，便可以直接找到方法而不需要进行方法参数的校验。

诚然，其实 `mbdToUse.prepareMethodOverrides()` 代码块，并没有做什么实质性的工作，只是对 `methodOverrides` 属性做了一些简单的校验而已。

### 2.3 实例化的前置处理

`#resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd)` 方法的作用，是给 BeanPostProcessors 后置处理器返回一个**代理对象**的机会。其，实在调用该方法之前 Spring 一直都没有创建 bean ，那么这里返回一个 bean 的代理类有什么作用呢？作用体现在后面的 `if` 判断，代码如下：

```java
// AbstractBeanDefinition.java

Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
// ↓↓↓ 
if (bean != null) {
	return bean;
}
```

- 如果代理对象不为空，则直接返回代理对象，这一步骤有非常重要的作用，Spring 后续实现 AOP 就是基于这个地方判断的。
- `#resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd)` 方法，代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

@Nullable
protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
    Object bean = null;
    if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
        // Make sure bean class is actually resolved at this point.
        if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
            Class<?> targetType = determineTargetType(beanName, mbd);
            if (targetType != null) {
                // 前置
                bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
                if (bean != null) {
                    // 后置
                    bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
                }
            }
        }
        mbd.beforeInstantiationResolved = (bean != null);
    }
    return bean;
}
```

- 这个方法核心就在于 `applyBeanPostProcessorsBeforeInstantiation()` 和 `applyBeanPostProcessorsAfterInitialization()` 两个方法，before 为实例化前的后处理器应用，after 为实例化后的后处理器应用。
- 由于本文的主题是创建 bean ，关于 Bean 的增强处理后续 LZ 会单独出博文来做详细说明。

### 2.4 创建 Bean

如果没有代理对象，就只能走常规的路线进行 bean 的创建了，该过程有 `#doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)` 方法来实现。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
        throws BeanCreationException {

    // Instantiate the bean.
    // BeanWrapper 是对 Bean 的包装，其接口中所定义的功能很简单包括设置获取被包装的对象，获取被包装 bean 的属性描述器
    BeanWrapper instanceWrapper = null;
    // <1> 单例模型，则从未完成的 FactoryBean 缓存中删除
    if (mbd.isSingleton()) {
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }
    // <2> 使用合适的实例化策略来创建新的实例：工厂方法、构造函数自动注入、简单初始化
    if (instanceWrapper == null) {
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
    // 包装的实例对象
    final Object bean = instanceWrapper.getWrappedInstance();
    // 包装的实例对象的类型
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        mbd.resolvedTargetType = beanType;
    }

    // Allow post-processors to modify the merged bean definition.
    // <3> 判断是否有后置处理
    // 如果有后置处理，则允许后置处理修改 BeanDefinition
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // 后置处理修改 BeanDefinition
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            } catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                        "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // Eagerly cache singletons to be able to resolve circular references
    // even when triggered by lifecycle interfaces like BeanFactoryAware.
    // <4> 解决单例模式的循环依赖
    boolean earlySingletonExposure = (mbd.isSingleton() // 单例模式
            && this.allowCircularReferences // 运行循环依赖
            && isSingletonCurrentlyInCreation(beanName)); // 当前单例 bean 是否正在被创建
    if (earlySingletonExposure) {
        if (logger.isTraceEnabled()) {
            logger.trace("Eagerly caching bean '" + beanName +
                    "' to allow for resolving potential circular references");
        }
        // 提前将创建的 bean 实例加入到 singletonFactories 中
        // 这里是为了后期避免循环依赖
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    }

    // Initialize the bean instance.
    // 开始初始化 bean 实例对象
    Object exposedObject = bean;
    try {
        // <5> 对 bean 进行填充，将各个属性值注入，其中，可能存在依赖于其他 bean 的属性
        // 则会递归初始依赖 bean
        populateBean(beanName, mbd, instanceWrapper);
        // <6> 调用初始化方法
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    } catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        } else {
            throw new BeanCreationException(
                    mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }

    // <7> 循环依赖处理
    if (earlySingletonExposure) {
        // 获取 earlySingletonReference
        Object earlySingletonReference = getSingleton(beanName, false);
        // 只有在存在循环依赖的情况下，earlySingletonReference 才不会为空
        if (earlySingletonReference != null) {
            // 如果 exposedObject 没有在初始化方法中被改变，也就是没有被增强
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            // 处理依赖
            } else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
                            "Bean with name '" + beanName + "' has been injected into other beans [" +
                            StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                            "] in its raw version as part of a circular reference, but has eventually been " +
                            "wrapped. This means that said other beans do not use the final version of the " +
                            "bean. This is often the result of over-eager type matching - consider using " +
                            "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }

    // Register bean as disposable.
    // <8> 注册 bean
    try {
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    } catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```

整体的思路：

- `<1>` 处，如果是单例模式，则清除缓存。
- `<2>` 处，调用 `#createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args)` 方法，实例化 bean ，主要是将 BeanDefinition 转换为 `org.springframework.beans.BeanWrapper` 对象。代码详解见:[《三. createBeanInstance》](#createBeanInstance)
- `<3>` 处，MergedBeanDefinitionPostProcessor 的应用。
- `<4>` 处，单例模式的循环依赖处理。
- `<5>` 处，调用 `#populateBean(String beanName, RootBeanDefinition mbd, BeanWrapper bw)` 方法，进行属性填充。将所有属性填充至 bean 的实例中。代码详解见:[《四. populateBean》](#populateBean)
- `<6>` 处，调用 `#initializeBean(final String beanName, final Object bean, RootBeanDefinition mbd)` 方法，初始化 bean 。代码见：[《五.initializeBean》](#initializeBean)
- `<7>` 处，依赖检查。
- `<8>` 处，注册 DisposableBean 。

## 三. createBeanInstance<a name="createBeanInstance"></a>

实例化 bean，对应的方法为 `#createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args)` 。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {
    // Make sure bean class is actually resolved at this point.
    // 解析 bean ，将 bean 类名解析为 class 引用。
    Class<?> beanClass = resolveBeanClass(mbd, beanName);

    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) { // 校验
        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    }

    // <1> 如果存在 Supplier 回调，则使用给定的回调方法初始化策略
    Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
    if (instanceSupplier != null) {
        return obtainFromSupplier(instanceSupplier, beanName);
    }

    // <2> 使用 FactoryBean 的 factory-method 来创建，支持静态工厂和实例工厂
    if (mbd.getFactoryMethodName() != null)  {
        return instantiateUsingFactoryMethod(beanName, mbd, args);
    }

    // <3> Shortcut when re-creating the same bean...
    boolean resolved = false;
    boolean autowireNecessary = false;
    if (args == null) {
        // constructorArgumentLock 构造函数的常用锁
        synchronized (mbd.constructorArgumentLock) {
            // 如果已缓存的解析的构造函数或者工厂方法不为空，则可以利用构造函数解析
            // 因为需要根据参数确认到底使用哪个构造函数，该过程比较消耗性能，所有采用缓存机制
            if (mbd.resolvedConstructorOrFactoryMethod != null) {
                resolved = true;
                autowireNecessary = mbd.constructorArgumentsResolved;
            }
        }
    }
    // 已经解析好了，直接注入即可
    if (resolved) {
        // <3.1> autowire 自动注入，调用构造函数自动注入
        if (autowireNecessary) {
            return autowireConstructor(beanName, mbd, null, null);
        } else {
            // <3.2> 使用默认构造函数构造
            return instantiateBean(beanName, mbd);
        }
    }

    // Candidate constructors for autowiring?
    // <4> 确定解析的构造函数
    // 主要是检查已经注册的 SmartInstantiationAwareBeanPostProcessor
    Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
    // <4.1> 有参数情况时，创建 Bean 。先利用参数个数，类型等，确定最精确匹配的构造方法。
    if (ctors != null || mbd.getResolvedAutowireMode() == AUTOWIRE_CONSTRUCTOR ||
            mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args))  {
        return autowireConstructor(beanName, mbd, ctors, args);
    }

    // Preferred constructors for default construction?
    // <4.1> 选择构造方法，创建 Bean 。
    ctors = mbd.getPreferredConstructors();
    if (ctors != null) {
        return autowireConstructor(beanName, mbd, ctors, null); // args = null
    }

    // No special handling: simply use no-arg constructor.
    // <4.2> 有参数时，又没获取到构造方法，则只能调用无参构造方法来创建实例了(兜底方法)
    return instantiateBean(beanName, mbd);
}
```

实例化 Bean 对象，是一个**复杂**的过程，其主要的逻辑为：

- `<1>` 处，如果存在 Supplier 回调，则调用 `#obtainFromSupplier(Supplier<?> instanceSupplier, String beanName)` 方法，进行初始化。
- `<2>` 处，如果存在工厂方法，则使用工厂方法进行初始化。
- `<3>` 处，首先判断缓存，如果**缓存中存在**，即已经解析过了，则直接使用已经解析了的。根据 `constructorArgumentsResolved` 参数来判断：
  - `<3.1>` 处，是使用构造函数自动注入，即调用 `#autowireConstructor(String beanName, RootBeanDefinition mbd, Constructor<?>[] ctors, Object[] explicitArgs)` 方法。
  - `<3.2>` 处，还是默认构造函数，即调用 `#instantiateBean(final String beanName, final RootBeanDefinition mbd)` 方法。
- `<4>` 处，如果**缓存中没有**，则需要先确定到底使用哪个构造函数来完成解析工作，因为一个类有多个构造函数，每个构造函数都有不同的构造参数，所以需要根据参数来锁定构造函数并完成初始化。
  - `<4.1>` 处，如果存在参数，则使用相应的带有参数的构造函数，即调用 `#autowireConstructor(String beanName, RootBeanDefinition mbd, Constructor<?>[] ctors, Object[] explicitArgs)` 方法。
  - `<4.2>` 处，否则，使用默认构造函数，即调用 `#instantiateBean(final String beanName, final RootBeanDefinition mbd)` 方法。

### 3.1 obtainFromSupplier

调用对应代码块如下：

```java
// AbstractAutowireCapableBeanFactory.java
// protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {}

Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
if (instanceSupplier != null) {
    return obtainFromSupplier(instanceSupplier, beanName);
}
```

#### 3.1.1 Supplier

那么 Supplier 是什么呢？在这之前也没有提到过这个字段。`java.util.function.Supplier` 接口，代码如下：

```java
public interface Supplier<T> {

    T get();
    
}
```

- Supplier 接口仅有一个功能性的 `#get()` 方法，该方法会返回一个 `<T>` 类型的对象，有点儿类似工厂方法。
- 这个接口有什么作用？用于指定创建 bean 的回调。如果我们设置了这样的回调，那么其他的构造器或者工厂方法都会没有用。

在什么设置该 Supplier 参数呢？Spring 提供了相应的 setter 方法，如下：

```java
// AbstractBeanDefinition.java

/**
 * 创建 Bean 的 Supplier 对象
 */
@Nullable
private Supplier<?> instanceSupplier;

public void setInstanceSupplier(@Nullable Supplier<?> instanceSupplier) {
	this.instanceSupplier = instanceSupplier;
}
```

在构造 BeanDefinition 对象的时候，设置了 `instanceSupplier` 该值，代码如下（以 RootBeanDefinition 为例）：

```java
// RootBeanDefinition.java

public <T> RootBeanDefinition(@Nullable Class<T> beanClass, String scope, @Nullable Supplier<T> instanceSupplier) {
	super();
	setBeanClass(beanClass);
	setScope(scope);
	// 设置 instanceSupplier 属性
	setInstanceSupplier(instanceSupplier);
}
```

#### 3.1.2 obtainFromSupplier

如果设置了 `instanceSupplier` 属性，则可以调用 `#obtainFromSupplier(Supplier<?> instanceSupplier, String beanName)` 方法，完成 Bean 的初始化。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

/**
 * 当前线程，正在创建的 Bean 对象的名字
 *
 * The name of the currently created bean, for implicit dependency registration
 * on getBean etc invocations triggered from a user-specified Supplier callback.
 */
private final NamedThreadLocal<String> currentlyCreatedBean = new NamedThreadLocal<>("Currently created bean");

protected BeanWrapper obtainFromSupplier(Supplier<?> instanceSupplier, String beanName) {
    Object instance;
    // 获得原创建的 Bean 的对象名
    String outerBean = this.currentlyCreatedBean.get();
    // 设置新的 Bean 的对象名，到 currentlyCreatedBean 中
    this.currentlyCreatedBean.set(beanName);
    try {
        // <1> 调用 Supplier 的 get()，返回一个 Bean 对象
        instance = instanceSupplier.get();
    } finally {
        // 设置原创建的 Bean 的对象名，到 currentlyCreatedBean 中
        if (outerBean != null) {
            this.currentlyCreatedBean.set(outerBean);
        } else {
            this.currentlyCreatedBean.remove();
        }
    }

    // 未创建 Bean 对象，则创建 NullBean 对象
    if (instance == null) {
        instance = new NullBean();
    }
    // <2> 创建 BeanWrapper 对象
    BeanWrapper bw = new BeanWrapperImpl(instance);
    // <3> 初始化 BeanWrapper 对象
    initBeanWrapper(bw);
    return bw;
}
```

代码很简单，流程如下：

- `<1>` 首先，调用 Supplier 的 `get()` 方法，获得一个 Bean 实例对象。
- `<2>` 然后，根据该实例对象构造一个 BeanWrapper 对象 `bw` 。
- `<3>` 最后，初始化该对象。

有关于 BeanWrapper ，后面专门出文讲解。

### 3.2 instantiateUsingFactoryMethod()

如果存在工厂方法，则调用 `#instantiateUsingFactoryMethod(String beanName, RootBeanDefinition mbd, @Nullable Object[] explicitArgs)` 方法完成 bean 的初始化工作（方法实现比较长，细节比较复杂，**各位就硬着头皮看吧**）。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected BeanWrapper instantiateUsingFactoryMethod(String beanName, RootBeanDefinition mbd, @Nullable Object[] explicitArgs) {
	return new ConstructorResolver(this).instantiateUsingFactoryMethod(beanName, mbd, explicitArgs);
}
```

- 构造一个 ConstructorResolver 对象，然后调用其 `#instantiateUsingFactoryMethod(EvaluationContext context, String typeName, List<TypeDescriptor> argumentTypes)` 方法。

#### 3.2.1 ConstructorResolver

`org.springframework.expression.ConstructorResolver` 是构造方法或者工厂类初始化 bean 的委托类。代码如下：

```java
// ConstructorResolver.java

public BeanWrapper instantiateUsingFactoryMethod(
        String beanName, RootBeanDefinition mbd, @Nullable Object[] explicitArgs) {
    // 构造 BeanWrapperImpl 对象
    BeanWrapperImpl bw = new BeanWrapperImpl();
    // 初始化 BeanWrapperImpl
    // 向BeanWrapper对象中添加 ConversionService 对象和属性编辑器 PropertyEditor 对象
    this.beanFactory.initBeanWrapper(bw);

    // <1> 获得 factoryBean、factoryClass、isStatic、factoryBeanName 属性
    Object factoryBean;
    Class<?> factoryClass;
    boolean isStatic;
    String factoryBeanName = mbd.getFactoryBeanName();

    // 工厂名不为空
    if (factoryBeanName != null) {
        if (factoryBeanName.equals(beanName)) { // 抛出 BeanDefinitionStoreException 异常
            throw new BeanDefinitionStoreException(mbd.getResourceDescription(), beanName,
                    "factory-bean reference points back to the same bean definition");
        }
        // 获取工厂实例
        factoryBean = this.beanFactory.getBean(factoryBeanName);
        if (mbd.isSingleton() && this.beanFactory.containsSingleton(beanName)) { // 抛出 ImplicitlyAppearedSingletonException 异常
            throw new ImplicitlyAppearedSingletonException();
        }
        factoryClass = factoryBean.getClass();
        isStatic = false;
    } else {
        // 工厂名为空，则其可能是一个静态工厂
        // 静态工厂创建bean，必须要提供工厂的全类名
        // It's a static factory method on the bean class.
        if (!mbd.hasBeanClass()) {
            throw new BeanDefinitionStoreException(mbd.getResourceDescription(), beanName,
                    "bean definition declares neither a bean class nor a factory-bean reference");
        }
        factoryBean = null;
        factoryClass = mbd.getBeanClass();
        isStatic = true;
    }

    // <2> 获得 factoryMethodToUse、argsHolderToUse、argsToUse 属性
    Method factoryMethodToUse = null;  // 工厂方法
    ArgumentsHolder argsHolderToUse = null;
    Object[] argsToUse = null; // 参数

    // <2.1> 如果指定了构造参数则直接使用
    // 在调用 getBean 方法的时候指定了方法参数
    if (explicitArgs != null) {
        argsToUse = explicitArgs;
    } else {
        // 没有指定，则尝试从配置文件中解析
        Object[] argsToResolve = null;
        // <2.2> 首先尝试从缓存中获取
        synchronized (mbd.constructorArgumentLock) {
            // 获取缓存中的构造函数或者工厂方法
            factoryMethodToUse = (Method) mbd.resolvedConstructorOrFactoryMethod;
            if (factoryMethodToUse != null && mbd.constructorArgumentsResolved) {
                // Found a cached factory method...
                // 获取缓存中的构造参数
                argsToUse = mbd.resolvedConstructorArguments;
                if (argsToUse == null) {
                    // 获取缓存中的构造函数参数的包可见字段
                    argsToResolve = mbd.preparedConstructorArguments;
                }
            }
        }
        // 缓存中存在,则解析存储在 BeanDefinition 中的参数
        // 如给定方法的构造函数 A(int ,int )，则通过此方法后就会把配置文件中的("1","1")转换为 (1,1)
        // 缓存中的值可能是原始值也有可能是最终值
        if (argsToResolve != null) {
            argsToUse = resolvePreparedArguments(beanName, mbd, bw, factoryMethodToUse, argsToResolve, true);
        }
    }

    // <3> 
    if (factoryMethodToUse == null || argsToUse == null) {
        // Need to determine the factory method...
        // Try all methods with this name to see if they match the given arguments.
        // 获取工厂方法的类全名称
        factoryClass = ClassUtils.getUserClass(factoryClass);

        // 获取所有待定方法
        Method[] rawCandidates = getCandidateMethods(factoryClass, mbd);
        // 检索所有方法，这里是对方法进行过滤
        List<Method> candidateList = new ArrayList<>();
        for (Method candidate : rawCandidates) {
            // 如果有static 且为工厂方法，则添加到 candidateSet 中
            if (Modifier.isStatic(candidate.getModifiers()) == isStatic && mbd.isFactoryMethod(candidate)) {
                candidateList.add(candidate);
            }
        }

        // TODO 芋艿 创建 Bean
        if (candidateList.size() == 1 && explicitArgs == null && !mbd.hasConstructorArgumentValues()) {
            Method uniqueCandidate = candidateList.get(0);
            if (uniqueCandidate.getParameterCount() == 0) {
                synchronized (mbd.constructorArgumentLock) {
                    mbd.resolvedConstructorOrFactoryMethod = uniqueCandidate;
                    mbd.constructorArgumentsResolved = true;
                    mbd.resolvedConstructorArguments = EMPTY_ARGS;
                }
                bw.setBeanInstance(instantiate(beanName, mbd, factoryBean, uniqueCandidate, EMPTY_ARGS));
                return bw;
            }
        }

        Method[] candidates = candidateList.toArray(new Method[0]);
        // 排序构造函数
        // public 构造函数优先参数数量降序，非 public 构造函数参数数量降序
        AutowireUtils.sortFactoryMethods(candidates);

        // 用于承载解析后的构造函数参数的值
        ConstructorArgumentValues resolvedValues = null;
        boolean autowiring = (mbd.getResolvedAutowireMode() == AutowireCapableBeanFactory.AUTOWIRE_CONSTRUCTOR);
        int minTypeDiffWeight = Integer.MAX_VALUE;
        Set<Method> ambiguousFactoryMethods = null;

        int minNrOfArgs;
        if (explicitArgs != null) {
            minNrOfArgs = explicitArgs.length;
        } else {
            // We don't have arguments passed in programmatically, so we need to resolve the
            // arguments specified in the constructor arguments held in the bean definition.
            // <2.3> getBean() 没有传递参数，则需要解析保存在 BeanDefinition 构造函数中指定的参数
            if (mbd.hasConstructorArgumentValues()) {
                // 构造函数的参数
                ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
                resolvedValues = new ConstructorArgumentValues();
                // 解析构造函数的参数
                // 将该 bean 的构造函数参数解析为 resolvedValues 对象，其中会涉及到其他 bean
                minNrOfArgs = resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
            } else {
                minNrOfArgs = 0;
            }
        }

        LinkedList<UnsatisfiedDependencyException> causes = null; // 记录 UnsatisfiedDependencyException 异常的集合
        // 遍历 candidates 数组
        for (Method candidate : candidates) {
            // 方法体的参数
            Class<?>[] paramTypes = candidate.getParameterTypes();

            if (paramTypes.length >= minNrOfArgs) {
                // 保存参数的对象
                ArgumentsHolder argsHolder;

                // #getBean(...) 传递了参数
                if (explicitArgs != null) {
                    // Explicit arguments given -> arguments length must match exactly.
                    // 显示给定参数，参数长度必须完全匹配
                    if (paramTypes.length != explicitArgs.length) {
                        continue;
                    }
                    // 根据参数创建参数持有者 ArgumentsHolder 对象
                    argsHolder = new ArgumentsHolder(explicitArgs);
                } else {
                    // Resolved constructor arguments: type conversion and/or autowiring necessary.
                    // 为提供参数，解析构造参数
                    try {
                        String[] paramNames = null;
                        // 获取 ParameterNameDiscoverer 对象
                        // ParameterNameDiscoverer 是用于解析方法和构造函数的参数名称的接口，为参数名称探测器
                        ParameterNameDiscoverer pnd = this.beanFactory.getParameterNameDiscoverer();
                        // 获取指定构造函数的参数名称
                        if (pnd != null) {
                            paramNames = pnd.getParameterNames(candidate);
                        }
                        // 在已经解析的构造函数参数值的情况下，创建一个参数持有者 ArgumentsHolder 对象
                        argsHolder = createArgumentArray(beanName, mbd, resolvedValues, bw,
                                paramTypes, paramNames, candidate, autowiring, candidates.length == 1);
                    } catch (UnsatisfiedDependencyException ex) {
                        // 若发生 UnsatisfiedDependencyException 异常，添加到 causes 中。
                        if (logger.isTraceEnabled()) {
                            logger.trace("Ignoring factory method [" + candidate + "] of bean '" + beanName + "': " + ex);
                        }
                        // Swallow and try next overloaded factory method.
                        if (causes == null) {
                            causes = new LinkedList<>();
                        }
                        causes.add(ex);
                        continue; // continue ，继续执行
                    }
                }

                // isLenientConstructorResolution 判断解析构造函数的时候是否以宽松模式还是严格模式
                // 严格模式：解析构造函数时，必须所有的都需要匹配，否则抛出异常
                // 宽松模式：使用具有"最接近的模式"进行匹配
                // typeDiffWeight：类型差异权重
                int typeDiffWeight = (mbd.isLenientConstructorResolution() ?
                        argsHolder.getTypeDifferenceWeight(paramTypes) : argsHolder.getAssignabilityWeight(paramTypes));
                // Choose this factory method if it represents the closest match.
                // 代表最接近的类型匹配，则选择作为构造函数
                if (typeDiffWeight < minTypeDiffWeight) {
                    factoryMethodToUse = candidate;
                    argsHolderToUse = argsHolder;
                    argsToUse = argsHolder.arguments;
                    minTypeDiffWeight = typeDiffWeight;
                    ambiguousFactoryMethods = null;
                }
                // Find out about ambiguity: In case of the same type difference weight
                // for methods with the same number of parameters, collect such candidates
                // and eventually raise an ambiguity exception.
                // However, only perform that check in non-lenient constructor resolution mode,
                // and explicitly ignore overridden methods (with the same parameter signature).
                // 如果具有相同参数数量的方法具有相同的类型差异权重，则收集此类型选项
                // 但是，仅在非宽松构造函数解析模式下执行该检查，并显式忽略重写方法（具有相同的参数签名）
                else if (factoryMethodToUse != null && typeDiffWeight == minTypeDiffWeight &&
                        !mbd.isLenientConstructorResolution() &&
                        paramTypes.length == factoryMethodToUse.getParameterCount() &&
                        !Arrays.equals(paramTypes, factoryMethodToUse.getParameterTypes())) {
                    // 查找到多个可匹配的方法
                    if (ambiguousFactoryMethods == null) {
                        ambiguousFactoryMethods = new LinkedHashSet<>();
                        ambiguousFactoryMethods.add(factoryMethodToUse);
                    }
                    ambiguousFactoryMethods.add(candidate);
                }
            }
        }

        // 没有可执行的工厂方法，抛出异常
        if (factoryMethodToUse == null) {
            if (causes != null) {
                UnsatisfiedDependencyException ex = causes.removeLast();
                for (Exception cause : causes) {
                    this.beanFactory.onSuppressedException(cause);
                }
                throw ex;
            }
            List<String> argTypes = new ArrayList<>(minNrOfArgs);
            if (explicitArgs != null) {
                for (Object arg : explicitArgs) {
                    argTypes.add(arg != null ? arg.getClass().getSimpleName() : "null");
                }
            } else if (resolvedValues != null) {
                Set<ValueHolder> valueHolders = new LinkedHashSet<>(resolvedValues.getArgumentCount());
                valueHolders.addAll(resolvedValues.getIndexedArgumentValues().values());
                valueHolders.addAll(resolvedValues.getGenericArgumentValues());
                for (ValueHolder value : valueHolders) {
                    String argType = (value.getType() != null ? ClassUtils.getShortName(value.getType()) :
                            (value.getValue() != null ? value.getValue().getClass().getSimpleName() : "null"));
                    argTypes.add(argType);
                }
            }
            String argDesc = StringUtils.collectionToCommaDelimitedString(argTypes);
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "No matching factory method found: " +
                    (mbd.getFactoryBeanName() != null ?
                        "factory bean '" + mbd.getFactoryBeanName() + "'; " : "") +
                    "factory method '" + mbd.getFactoryMethodName() + "(" + argDesc + ")'. " +
                    "Check that a method with the specified name " +
                    (minNrOfArgs > 0 ? "and arguments " : "") +
                    "exists and that it is " +
                    (isStatic ? "static" : "non-static") + ".");
        } else if (void.class == factoryMethodToUse.getReturnType()) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Invalid factory method '" + mbd.getFactoryMethodName() +
                    "': needs to have a non-void return type!");
        } else if (ambiguousFactoryMethods != null) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Ambiguous factory method matches found in bean '" + beanName + "' " +
                    "(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities): " +
                    ambiguousFactoryMethods);
        }

        if (explicitArgs == null && argsHolderToUse != null) {
            // 将解析的构造函数加入缓存
            argsHolderToUse.storeCache(mbd, factoryMethodToUse);
        }
    }

    // 创建 Bean 对象，并设置到 bw 中
    bw.setBeanInstance(instantiate(beanName, mbd, factoryBean, factoryMethodToUse, argsToUse));
    return bw;
}

private Object instantiate(
        String beanName, RootBeanDefinition mbd, Constructor constructorToUse, Object[] argsToUse) {

    try {
        InstantiationStrategy strategy = this.beanFactory.getInstantiationStrategy();
        if (System.getSecurityManager() != null) {
            return AccessController.doPrivileged((PrivilegedAction<Object>) () ->
                    strategy.instantiate(mbd, beanName, this.beanFactory, constructorToUse, argsToUse),
                    this.beanFactory.getAccessControlContext());
        } else {
            return strategy.instantiate(mbd, beanName, this.beanFactory, constructorToUse, argsToUse);
        }
    } catch (Throwable ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                "Bean instantiation via constructor failed", ex);
    }
}
```

- `#instantiateUsingFactoryMethod(...)` 方法，实在是**太大**了，处理细节感觉很复杂，LZ是硬着头皮看完的，中间断断续续的。吐槽这里的代码风格，完全不符合我们前面看的 Spring 代码风格。Spring 的一贯做法是将一个复杂逻辑进行拆分，分为多个细小的模块进行嵌套，每个模块负责一部分功能，模块与模块之间层层嵌套，上一层一般都是对下一层的总结和概括，这样就会使得每一层的逻辑变得清晰易懂。
- 回归到上面的方法体，虽然代码体量大，但是总体我们还是可看清楚这个方法要做的事情。**一句话概括就是**：确定工厂对象，然后获取构造函数和构造参数，最后调用 InstantiationStrategy 对象的 `#instantiate(RootBeanDefinition bd, String beanName, BeanFactory owner, Constructor<?> ctor, Object... args)` 方法，**来创建 Bean 实例**。

下面我们就这个句概括的话进行拆分并详细说明。

##### **第一步：确定工厂对象（对应 `<1>` 处）**

首先获取工厂方法名：

- 若工厂方法名不为空，则调用 `AbstractAutowireCapableBeanFactory#getBean(String name)` 方法，获取工厂对象，
- 若为空，则可能为一个静态工厂，对于静态工厂则必须提供工厂类的全类名，同时设置 `factoryBean = null` 。

##### **第二步：构造参数确认（对应 `<2>` 处）**

工厂对象确定后，则是确认构造参数。构造参数的确认主要分为**三种**情况：

- `explicitArgs` 参数（对应 `<2.1>` 处）：`explicitArgs` 参数，是我们调用 `#getBean(...)` 方法时传递进来的。一般该参数，该参数就是用于初始化 Bean 时所传递的参数。如果该参数不为空，则可以确定构造函数的参数就是它了。

- 缓存中获取（对应 `<2.2>` 处）：在该方法的最后，我们会发现这样一段 `argsHolderToUse.storeCache(mbd, factoryMethodToUse)` 代码。这段代码主要是将构造函数、构造参数保存到缓存中，代码如下：

  ```java
  // ConstructorResolver.ArgumentsHolder.java
  
  public void storeCache(RootBeanDefinition mbd, Executable constructorOrFactoryMethod) {
  	synchronized (mbd.constructorArgumentLock) {
  		mbd.resolvedConstructorOrFactoryMethod = constructorOrFactoryMethod;
  		mbd.constructorArgumentsResolved = true;
  		if (this.resolveNecessary) {
  			mbd.preparedConstructorArguments = this.preparedArguments;
  		} else {
  			mbd.resolvedConstructorArguments = this.arguments;
  		}
  	}
  }
  
  // RootBeanDefinition.java
  
  /** Common lock for the four constructor fields below. */
  final Object constructorArgumentLock = new Object(); // 构造函数的缓存锁
  
  /** Package-visible field for caching the resolved constructor or factory method. */
  @Nullable
  Executable resolvedConstructorOrFactoryMethod; // 缓存已经解析的构造函数或者工厂方法
  
  /** Package-visible field that marks the constructor arguments as resolved. */
  boolean constructorArgumentsResolved = false; // 标记字段，标记构造函数、参数已经解析了。默认为 `false` 。
  
  /** Package-visible field for caching fully resolved constructor arguments. */
  @Nullable
  Object[] resolvedConstructorArguments; // 缓存已经解析的构造函数参数，包可见字段。
  
  /** Package-visible field for caching partly prepared constructor arguments. */
  @Nullable
  Object[] preparedConstructorArguments;
  ```

  其中涉及到的几个参数，都是跟构造函数、构造函数缓存有关的。如下：

  - `constructorArgumentLock` ：构造函数的缓存锁。
  - `resolvedConstructorOrFactoryMethod` ：缓存已经解析的构造函数或者工厂方法。
  - `constructorArgumentsResolved` ：标记字段，标记构造函数、参数已经解析了。默认为 `false` 。
  - `resolvedConstructorArguments` ：缓存已经解析的构造函数参数，包可见字段 。
  - `preparedConstructorArguments`

  所以，从缓存中获取就是提取这几个参数的值。代码如下：

  ```java
  // ConstructorResolver.java
  
  // 没有指定，则尝试从配置文件中解析
  Object[] argsToResolve = null;
  // <2.2> 首先尝试从缓存中获取
  synchronized (mbd.constructorArgumentLock) {
      // 获取缓存中的构造函数或者工厂方法
      factoryMethodToUse = (Method) mbd.resolvedConstructorOrFactoryMethod;
      if (factoryMethodToUse != null && mbd.constructorArgumentsResolved) {
          // Found a cached factory method...
          // 获取缓存中的构造参数
          argsToUse = mbd.resolvedConstructorArguments;
          if (argsToUse == null) {
              // 获取缓存中的构造函数参数的包可见字段
              argsToResolve = mbd.preparedConstructorArguments;
          }
      }
  }
  // 缓存中存在,则解析存储在 BeanDefinition 中的参数
  // 如给定方法的构造函数 A(int ,int )，则通过此方法后就会把配置文件中的("1","1")转换为 (1,1)
  // 缓存中的值可能是原始值也有可能是最终值
  if (argsToResolve != null) {
      argsToUse = resolvePreparedArguments(beanName, mbd, bw, factoryMethodToUse, argsToResolve, true);
  }
  ```

  如果缓存中存在构造参数，则需要调用`#resolvePreparedArguments(String beanName, RootBeanDefinition mbd, BeanWrapper bw, Executable executable, Object[] argsToResolve, boolean fallback)` 方法，进行转换。

  因为缓存中的值有可能是最终值，**也有可能不是最终值**。比如我们构造函数中的类型为 Integer 类型的 1 ，但是原始的参数类型有可能是 String 类型的 `"1"` ，所以即便是从缓存中得到了构造参数，也**需要经过一番的类型转换确保参数类型完全对应**。

- 配置文件中解析（对应 `<2.3>` 处）：即没有通过传递参数的方式传递构造参数，缓存中也没有，那就只能通过解析配置文件获取构造参数了。在 bean 解析类的博文中我们了解了，配置文件中的信息都会转换到 BeanDefinition 实例对象中，所以配置文件中的参数可以直接通过 BeanDefinition 对象获取。代码如下：

  ```java
  // AbstractAutowireCapableBeanFactory.java
  
  // <2.3> getBean() 没有传递参数，则需要解析保存在 BeanDefinition 构造函数中指定的参数
  if (mbd.hasConstructorArgumentValues()) {
      // <2.3.1> 构造函数的参数
      ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
      resolvedValues = new ConstructorArgumentValues();
      // <2.3.2> 解析构造函数的参数
      // 将该 bean 的构造函数参数解析为 resolvedValues 对象，其中会涉及到其他 bean
      minNrOfArgs = resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
  }
  ```

  - `<2.3.1>` ，通过 BeanDefinition 的 `#getConstructorArgumentValues()` 方法，就可以获取构造信息了。
  - `<2.3.2>` ，有了构造信息就可以获取相关的参数值信息了，获取的参数信息包括直接值和引用，这一步骤的处理交由 `#resolveConstructorArguments(String beanName, RootBeanDefinition mbd, BeanWrapper bw, ConstructorArgumentValues cargs, ConstructorArgumentValues resolvedValues)` 方法来完成。该方法会将构造参数信息解析为 `resolvedValues` 对象 并返回解析到的参数个数 `minNrOfArgs` 。

##### **第三步：确认构造函数（对应 `<3>` 处）**

确定构造参数后，下一步则是确定构造函数。

- 第一步，是通过 `#getCandidateMethods()` 方法，获取所有的构造方法，同时对构造方法进行刷选。
- 然后，在对其进行排序处理（`AutowireUtils.sortFactoryMethods(candidates)`）。排序的主要目的，是为了能够**更加方便的**找到匹配的构造函数，因为构造函数的确认是根据参数个数确认的。排序的规则是：先按照 `public` / 非 `public` 构造函数**升序**，再按照构造参数数量**降序**。

通过迭代 `candidates`（包含了所有要匹配的构造函数）的方式，依次比较其参数：

- 如果显示提供了参数（`explicitArgs != null`），则直接比较两者**长度**是否相等，如果相等则表示找到了，否则继续比较。
- 如果没有显示提供参数，则需要获取 `org.springframework.core.ParameterNameDiscoverer` 对象。该对象为参数名称探测器，主要用于发现方法和构造函数的参数名称。

将参数包装成 `ConstructorResolver.ArgumentsHolder` 对象。该对象用于保存参数，我们称之为参数持有者。当将对象包装成 ArgumentsHolder 对象后，我们就可以通过它来进行构造函数**匹配**。匹配分为严格模式和宽松模式：

- 严格模式：解析构造函数时，必须所有参数都需要匹配，否则抛出异常。
- 宽松模式：使用具有”最接近的模式”进行匹配。

判断的依据是根据 BeanDefinition 的 `isLenientConstructorResolution` 属性（该参数是我们在构造 AbstractBeanDefinition 对象是传递的）来获取类型差异权重（`typeDiffWeight`） 的。

- 如果 `typeDiffWeight < minTypeDiffWeight` ，则代表“最接近的模式”，选择其作为构造函数。
- 否则，只有两者具有相同的参数数量，且类型差异权重相等才会纳入考虑范围。

至此，构造函数已经确认了。

##### 第四步：创建Bean实例（对应 `<4>` 处）

工厂对象、构造函数、构造参数都已经确认了，则最后一步就是调用 `org.springframework.beans.factory.support.InstantiationStrategy` 对象的 `#instantiate(RootBeanDefinition bd, String beanName, BeanFactory owner, Object factoryBean, final Method factoryMethod, @Nullable Object... args)` 方法，来创建 bean 实例。代码如下：

```java
// SimpleInstantiationStrategy.java

/**
 * 线程变量，正在创建 Bean 的 Method 对象
 */
private static final ThreadLocal<Method> currentlyInvokedFactoryMethod = new ThreadLocal<>();

@Override
public Object instantiate(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner,
        @Nullable Object factoryBean, final Method factoryMethod, Object... args) {
    try {
        // 设置 Method 可访问
        if (System.getSecurityManager() != null) {
            AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
                ReflectionUtils.makeAccessible(factoryMethod);
                return null;
            });
        } else {
            ReflectionUtils.makeAccessible(factoryMethod);
        }

        // 获得原 Method 对象
        Method priorInvokedFactoryMethod = currentlyInvokedFactoryMethod.get();
        try {
            // 设置新的 Method 对象，到 currentlyInvokedFactoryMethod 中
            currentlyInvokedFactoryMethod.set(factoryMethod);
            // <x> 创建 Bean 对象
            Object result = factoryMethod.invoke(factoryBean, args);
            // 未创建，则创建 NullBean 对象
            if (result == null) {
                result = new NullBean();
            }
            return result;
        } finally {
            // 设置老的 Method 对象，到 currentlyInvokedFactoryMethod 中
            if (priorInvokedFactoryMethod != null) {
                currentlyInvokedFactoryMethod.set(priorInvokedFactoryMethod);
            } else {
                currentlyInvokedFactoryMethod.remove();
            }
        }
    } catch (IllegalArgumentException ex) {
        throw new BeanInstantiationException(factoryMethod,
                "Illegal arguments to factory method '" + factoryMethod.getName() + "'; " +
                "args: " + StringUtils.arrayToCommaDelimitedString(args), ex);
    } catch (IllegalAccessException ex) {
        throw new BeanInstantiationException(factoryMethod,
                "Cannot access factory method '" + factoryMethod.getName() + "'; is it public?", ex);
    } catch (InvocationTargetException ex) {
        String msg = "Factory method '" + factoryMethod.getName() + "' threw exception";
        if (bd.getFactoryBeanName() != null && owner instanceof ConfigurableBeanFactory &&
                ((ConfigurableBeanFactory) owner).isCurrentlyInCreation(bd.getFactoryBeanName())) {
            msg = "Circular reference involving containing bean '" + bd.getFactoryBeanName() + "' - consider " +
                    "declaring the factory method as static for independence from its containing instance. " + msg;
        }
        throw new BeanInstantiationException(factoryMethod, msg, ex.getTargetException());
    }
}
```

核心的部分，在于 `<x>` 处，利用 Java 反射执行工厂方法并返回创建好的实例。

### 3.3 autowireConstructor

这个初始化方法，我们可以简单理解为是**带有参数的构造方法**，来初始化 Bean 对象。代码段如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected BeanWrapper autowireConstructor(String beanName, RootBeanDefinition mbd, @Nullable Constructor<?>[] ctors, @Nullable Object[] explicitArgs) {
    return new ConstructorResolver(this).autowireConstructor(beanName, mbd, ctors, explicitArgs);
}

// ConstructorResolver.java

public BeanWrapper autowireConstructor(String beanName, RootBeanDefinition mbd,
        @Nullable Constructor<?>[] chosenCtors, @Nullable Object[] explicitArgs) {
    // 封装 BeanWrapperImpl 对象，并完成初始化
    BeanWrapperImpl bw = new BeanWrapperImpl();
    this.beanFactory.initBeanWrapper(bw);

    // 获得 constructorToUse、argsHolderToUse、argsToUse
    Constructor<?> constructorToUse = null; // 构造函数
    ArgumentsHolder argsHolderToUse = null; // 构造参数
    Object[] argsToUse = null; // 构造参数

    // 确定构造参数
    // 如果 getBean() 已经传递，则直接使用
    if (explicitArgs != null) {
        argsToUse = explicitArgs;
    } else {
        // 尝试从缓存中获取
        Object[] argsToResolve = null;
        synchronized (mbd.constructorArgumentLock) {
            // 缓存中的构造函数或者工厂方法
            constructorToUse = (Constructor<?>) mbd.resolvedConstructorOrFactoryMethod;
            if (constructorToUse != null && mbd.constructorArgumentsResolved) {
                // Found a cached constructor...
                // 缓存中的构造参数
                argsToUse = mbd.resolvedConstructorArguments;
                if (argsToUse == null) {
                    argsToResolve = mbd.preparedConstructorArguments;
                }
            }
        }
        // 缓存中存在,则解析存储在 BeanDefinition 中的参数
        // 如给定方法的构造函数 A(int ,int )，则通过此方法后就会把配置文件中的("1","1")转换为 (1,1)
        // 缓存中的值可能是原始值也有可能是最终值
        if (argsToResolve != null) {
            argsToUse = resolvePreparedArguments(beanName, mbd, bw, constructorToUse, argsToResolve, true);
        }
    }

    // 没有缓存，则尝试从配置文件中获取参数
    if (constructorToUse == null || argsToUse == null) {
        // Take specified constructors, if any.
        // 如果 chosenCtors 未传入，则获取构造方法们
        Constructor<?>[] candidates = chosenCtors;
        if (candidates == null) {
            Class<?> beanClass = mbd.getBeanClass();
            try {
                candidates = (mbd.isNonPublicAccessAllowed() ?
                        beanClass.getDeclaredConstructors() : beanClass.getConstructors());
            } catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                        "Resolution of declared constructors on bean Class [" + beanClass.getName() +
                        "] from ClassLoader [" + beanClass.getClassLoader() + "] failed", ex);
            }
        }

        // TODO 芋艿 创建 Bean
        if (candidates.length == 1 && explicitArgs == null && !mbd.hasConstructorArgumentValues()) {
            Constructor<?> uniqueCandidate = candidates[0];
            if (uniqueCandidate.getParameterCount() == 0) {
                synchronized (mbd.constructorArgumentLock) {
                    mbd.resolvedConstructorOrFactoryMethod = uniqueCandidate;
                    mbd.constructorArgumentsResolved = true;
                    mbd.resolvedConstructorArguments = EMPTY_ARGS;
                }
                bw.setBeanInstance(instantiate(beanName, mbd, uniqueCandidate, EMPTY_ARGS));
                return bw;
            }
        }

        // 是否需要解析构造器
        // Need to resolve the constructor.
        boolean autowiring = (chosenCtors != null ||
                mbd.getResolvedAutowireMode() == AutowireCapableBeanFactory.AUTOWIRE_CONSTRUCTOR);
        // 用于承载解析后的构造函数参数的值
        ConstructorArgumentValues resolvedValues = null;
        int minNrOfArgs;
        if (explicitArgs != null) {
            minNrOfArgs = explicitArgs.length;
        } else {
            // 从 BeanDefinition 中获取构造参数，也就是从配置文件中提取构造参数
            ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
            resolvedValues = new ConstructorArgumentValues();
            // 解析构造函数的参数
            // 将该 bean 的构造函数参数解析为 resolvedValues 对象，其中会涉及到其他 bean
            minNrOfArgs = resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
        }

        // 对构造函数进行排序处理
        // public 构造函数优先参数数量降序，非public 构造函数参数数量降序
        AutowireUtils.sortConstructors(candidates);

        // 最小参数类型权重
        int minTypeDiffWeight = Integer.MAX_VALUE;
        Set<Constructor<?>> ambiguousConstructors = null;
        LinkedList<UnsatisfiedDependencyException> causes = null;

        // 迭代所有构造函数
        for (Constructor<?> candidate : candidates) {
            // 获取该构造函数的参数类型
            Class<?>[] paramTypes = candidate.getParameterTypes();

            // 如果已经找到选用的构造函数或者需要的参数个数小于当前的构造函数参数个数，则终止。
            // 因为，已经按照参数个数降序排列了
            if (constructorToUse != null && argsToUse.length > paramTypes.length) {
                // Already found greedy constructor that can be satisfied ->
                // do not look any further, there are only less greedy constructors left.
                break;
            }
            // 参数个数不等，继续
            if (paramTypes.length < minNrOfArgs) {
                continue;
            }

            // 参数持有者 ArgumentsHolder 对象
            ArgumentsHolder argsHolder;
            if (resolvedValues != null) {
                try {
                    // 注释上获取参数名称
                    String[] paramNames = ConstructorPropertiesChecker.evaluate(candidate, paramTypes.length);
                    if (paramNames == null) {
                        // 获取构造函数、方法参数的探测器
                        ParameterNameDiscoverer pnd = this.beanFactory.getParameterNameDiscoverer();
                        if (pnd != null) {
                            // 通过探测器获取构造函数的参数名称
                            paramNames = pnd.getParameterNames(candidate);
                        }
                    }
                    // 根据构造函数和构造参数，创建参数持有者 ArgumentsHolder 对象
                    argsHolder = createArgumentArray(beanName, mbd, resolvedValues, bw, paramTypes, paramNames,
                            getUserDeclaredConstructor(candidate), autowiring, candidates.length == 1);
                } catch (UnsatisfiedDependencyException ex) {
                    // 若发生 UnsatisfiedDependencyException 异常，添加到 causes 中。
                    if (logger.isTraceEnabled()) {
                        logger.trace("Ignoring constructor [" + candidate + "] of bean '" + beanName + "': " + ex);
                    }
                    // Swallow and try next constructor.
                    if (causes == null) {
                        causes = new LinkedList<>();
                    }
                    causes.add(ex);
                    continue; // continue ，继续执行
                }
            } else {
                // continue 构造函数没有参数
                // Explicit arguments given -> arguments length must match exactly.
                if (paramTypes.length != explicitArgs.length) {
                    continue;
                }
                // 根据 explicitArgs ，创建 ArgumentsHolder 对象
                argsHolder = new ArgumentsHolder(explicitArgs);
            }

            // isLenientConstructorResolution 判断解析构造函数的时候是否以宽松模式还是严格模式
            // 严格模式：解析构造函数时，必须所有的都需要匹配，否则抛出异常
            // 宽松模式：使用具有"最接近的模式"进行匹配
            // typeDiffWeight：类型差异权重
            int typeDiffWeight = (mbd.isLenientConstructorResolution() ?
                    argsHolder.getTypeDifferenceWeight(paramTypes) : argsHolder.getAssignabilityWeight(paramTypes));
            // Choose this constructor if it represents the closest match.
            // 如果它代表着当前最接近的匹配则选择其作为构造函数
            if (typeDiffWeight < minTypeDiffWeight) {
                constructorToUse = candidate;
                argsHolderToUse = argsHolder;
                argsToUse = argsHolder.arguments;
                minTypeDiffWeight = typeDiffWeight;
                ambiguousConstructors = null;
            } else if (constructorToUse != null && typeDiffWeight == minTypeDiffWeight) {
                if (ambiguousConstructors == null) {
                    ambiguousConstructors = new LinkedHashSet<>();
                    ambiguousConstructors.add(constructorToUse);
                }
                ambiguousConstructors.add(candidate);
            }
        }

        // 没有可执行的工厂方法，抛出异常
        if (constructorToUse == null) {
            if (causes != null) {
                UnsatisfiedDependencyException ex = causes.removeLast();
                for (Exception cause : causes) {
                    this.beanFactory.onSuppressedException(cause);
                }
                throw ex;
            }
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Could not resolve matching constructor " +
                    "(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities)");
        } else if (ambiguousConstructors != null && !mbd.isLenientConstructorResolution()) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Ambiguous constructor matches found in bean '" + beanName + "' " +
                    "(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities): " +
                    ambiguousConstructors);
        }

        if (explicitArgs == null) {
            // 将解析的构造函数加入缓存
            argsHolderToUse.storeCache(mbd, constructorToUse);
        }
    }

    // 创建 Bean 对象，并设置到 bw 中
    bw.setBeanInstance(instantiate(beanName, mbd, constructorToUse, argsToUse));
    return bw;
}
```

- 代码与 `#instantiateUsingFactoryMethod(String beanName, RootBeanDefinition mbd, @Nullable Object[] explicitArgs)` 方法，一样，又长又难懂。但是如果理解了 `#instantiateUsingFactoryMethod(...)` 方法的初始化 bean 的过程，那么 `#autowireConstructor(...)` 方法，**也不存在什么难的地方了**。
- 一句话概括：首先确定构造函数参数、构造函数，然后调用相应的初始化策略进行 bean 的初始化。关于如何确定构造函数、构造参数，该部分逻辑和 `#instantiateUsingFactoryMethod(...)` 方法，基本一致。所以这里不再重复阐述了，具体过程请移步[【死磕 Spring】—— IoC 之加载 bean：创建 bean（二）](http://svip.iocoder.cn/Spring/IoC-get-Bean-createBean-2)，这里我们重点分析初始化策略。

#### 3.1 instantiate

```java
private Object instantiate(
		String beanName, RootBeanDefinition mbd, Constructor<?> constructorToUse, Object[] argsToUse) {

	try {
        // <1> 获取实例化 Bean 的策略 InstantiationStrategy 对象。
		InstantiationStrategy strategy = this.beanFactory.getInstantiationStrategy();
		// 安全模式
		if (System.getSecurityManager() != null) {

			return AccessController.doPrivileged((PrivilegedAction<Object>) () ->
					strategy.instantiate(mbd, beanName, this.beanFactory, constructorToUse, argsToUse),
					this.beanFactory.getAccessControlContext());
		}
		else {
			// 创建对象
			return strategy.instantiate(mbd, beanName, this.beanFactory, constructorToUse, argsToUse);
		}
	}
	catch (Throwable ex) {
		throw new BeanCreationException(mbd.getResourceDescription(), beanName,
				"Bean instantiation via constructor failed", ex);
	}
}
```

- `<1>` 首先，是获取实例化 Bean 的策略 InstantiationStrategy 对象。
- `<2>` 然后，调用其 `#instantiate(RootBeanDefinition bd, String beanName, BeanFactory owner, Constructor<?> ctor, Object... args)` 方法，该方法在 SimpleInstantiationStrategy 中实现。代码如下：

```java
// SimpleInstantiationStrategy.java
@Override
public Object instantiate(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner,
		final Constructor<?> ctor, Object... args) {

	// <x1> 没有覆盖，直接使用反射实例化即可
	if (!bd.hasMethodOverrides()) {
		if (System.getSecurityManager() != null) {
			// 设置构造方法，可访问
			// use own privileged to change accessibility (when security is on)
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
				ReflectionUtils.makeAccessible(ctor);
				return null;
			});
		}
		// 通过 BeanUtils 直接使用构造器对象实例化 Bean 对象
		return BeanUtils.instantiateClass(ctor, args);
	}
	else {
		// <x2> 生成 CGLIB 创建的子类对象
		return instantiateWithMethodInjection(bd, beanName, owner, ctor, args);
	}
}
```

- `<x1>` 如果该 bean 没有配置 `lookup-method`、`replaced-method` 标签或者 `@Lookup` 注解，则直接通过**反射**的方式实例化 Bean 对象即可，方便快捷。详细解析，见 [「3.1.1 反射创建 Bean 对象」](#反射创建Bean) 中。
- `<x2>` 但是，如果存在需要覆盖的方法或者动态替换的方法时，则需要使用 CGLIB 进行动态代理，因为可以在创建代理的同时将动态方法织入类中。详细解析，见 [「3.1.2 CGLIB 创建 Bean 对象」](#CGLIB创建Bean对象) 中。

#### 3.1.1 反射创建 Bean 对象<a name="反射创建Bean"></a>

```java
// BeanUtils.java

public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
    Assert.notNull(ctor, "Constructor must not be null");
    try {
        // 设置构造方法，可访问
        ReflectionUtils.makeAccessible(ctor);
        // 使用构造方法，创建对象
        return (KotlinDetector.isKotlinReflectPresent() && KotlinDetector.isKotlinType(ctor.getDeclaringClass()) ?
                KotlinDelegate.instantiateClass(ctor, args) : ctor.newInstance(args));
    // 各种异常的翻译，最终统一抛出 BeanInstantiationException 异常
    } catch (InstantiationException ex) {
        throw new BeanInstantiationException(ctor, "Is it an abstract class?", ex);
    } catch (IllegalAccessException ex) {
        throw new BeanInstantiationException(ctor, "Is the constructor accessible?", ex);
    } catch (IllegalArgumentException ex) {
        throw new BeanInstantiationException(ctor, "Illegal arguments for constructor", ex);
    } catch (InvocationTargetException ex) {
        throw new BeanInstantiationException(ctor, "Constructor threw exception", ex.getTargetException());
    }
}
```

#### 3.1.2 CGLIB 创建 Bean 对象<a name="CGLIB创建Bean对象"></a>

```java
// SimpleInstantiationStrategy.java

protected Object instantiateWithMethodInjection(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner) {
	throw new UnsupportedOperationException("Method Injection not supported in SimpleInstantiationStrategy");
}
```

方法默认是**没有实现**的，具体过程由其子类 `org.springframework.beans.factory.support.CglibSubclassingInstantiationStrategy` 来实现。代码如下：

```java
// CglibSubclassingInstantiationStrategy.java

@Override
protected Object instantiateWithMethodInjection(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner) {
    return instantiateWithMethodInjection(bd, beanName, owner, null);
}
@Override
protected Object instantiateWithMethodInjection(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner, @Nullable Constructor<?> ctor, Object... args) {
    // Must generate CGLIB subclass...
    // 通过CGLIB生成一个子类对象
    return new CglibSubclassCreator(bd, owner).instantiate(ctor, args);
}
```

创建一个 CglibSubclassCreator 对象，后调用其 `#instantiate(Constructor<?> ctor, Object... args)` 方法，生成其子类对象。代码如下：

```java
// CglibSubclassingInstantiationStrategy.java

public Object instantiate(@Nullable Constructor<?> ctor, Object... args) {
    // 通过 Cglib 创建一个代理类
    Class<?> subclass = createEnhancedSubclass(this.beanDefinition);
    Object instance;
    // 没有构造器，通过 BeanUtils 使用默认构造器创建一个bean实例
    if (ctor == null) {
        instance = BeanUtils.instantiateClass(subclass);
    } else {
        try {
            // 获取代理类对应的构造器对象，并实例化 bean
            Constructor<?> enhancedSubclassConstructor = subclass.getConstructor(ctor.getParameterTypes());
            instance = enhancedSubclassConstructor.newInstance(args);
        } catch (Exception ex) {
            throw new BeanInstantiationException(this.beanDefinition.getBeanClass(),
                    "Failed to invoke constructor for CGLIB enhanced subclass [" + subclass.getName() + "]", ex);
        }
    }
    // SPR-10785: set callbacks directly on the instance instead of in the
    // enhanced class (via the Enhancer) in order to avoid memory leaks.
    // 为了避免 memory leaks 异常，直接在 bean 实例上设置回调对象
    Factory factory = (Factory) instance;
    factory.setCallbacks(new Callback[] {NoOp.INSTANCE,
            new LookupOverrideMethodInterceptor(this.beanDefinition, this.owner),
            new ReplaceOverrideMethodInterceptor(this.beanDefinition, this.owner)});
    return instance;
}
```

- 到这类 CGLIB 的方式分析完毕了，当然这里还没有具体分析 CGLIB 生成子类的详细过程，具体的过程等后续分析 AOP 的时候再详细地介绍。

### 3.4 instantiateBean

```java
// AbstractAutowireCapableBeanFactory.java

protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
    try {
        Object beanInstance;
        final BeanFactory parent = this;
        // 安全模式
        if (System.getSecurityManager() != null) {
            beanInstance = AccessController.doPrivileged((PrivilegedAction<Object>) () ->
                    // 获得 InstantiationStrategy 对象，并使用它，创建 Bean 对象
                    getInstantiationStrategy().instantiate(mbd, beanName, parent),
                    getAccessControlContext());
        } else {
            // 获得 InstantiationStrategy 对象，并使用它，创建 Bean 对象
            beanInstance = getInstantiationStrategy().instantiate(mbd, beanName, parent);
        }
        // 封装 BeanWrapperImpl  并完成初始化
        BeanWrapper bw = new BeanWrapperImpl(beanInstance);
        initBeanWrapper(bw);
        return bw;
    } catch (Throwable ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
    }
}
```

- 这个方法,相比于 `#instantiateUsingFactoryMethod(...)` 、 `#autowireConstructor(...)` 方法，**实在是太简单了**，因为，它没有参数，所以不需要确认经过复杂的过来来确定构造器、构造参数，所以这里就不过多阐述了。

#### 3.4.1 instantiate

```java
// SimpleInstantiationStrategy.java

@Override
public Object instantiate(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner) {
    // Don't override the class with CGLIB if no overrides.
    // 没有覆盖，直接使用反射实例化即可
    if (!bd.hasMethodOverrides()) {
        Constructor<?> constructorToUse;
        synchronized (bd.constructorArgumentLock) {
            // 获得构造方法 constructorToUse
            constructorToUse = (Constructor<?>) bd.resolvedConstructorOrFactoryMethod;
            if (constructorToUse == null) {
                final Class<?> clazz = bd.getBeanClass();
                // 如果是接口，抛出 BeanInstantiationException 异常
                if (clazz.isInterface()) {
                    throw new BeanInstantiationException(clazz, "Specified class is an interface");
                }
                try {
                    // 从 clazz 中，获得构造方法
                    if (System.getSecurityManager() != null) { // 安全模式
                        constructorToUse = AccessController.doPrivileged(
                                (PrivilegedExceptionAction<Constructor<?>>) clazz::getDeclaredConstructor);
                    } else {
                        constructorToUse =  clazz.getDeclaredConstructor();
                    }
                    // 标记 resolvedConstructorOrFactoryMethod 属性
                    bd.resolvedConstructorOrFactoryMethod = constructorToUse;
                } catch (Throwable ex) {
                    throw new BeanInstantiationException(clazz, "No default constructor found", ex);
                }
            }
        }
        // 通过 BeanUtils 直接使用构造器对象实例化 Bean 对象
        return BeanUtils.instantiateClass(constructorToUse);
    } else {
        // Must generate CGLIB subclass.
        // 生成 CGLIB 创建的子类对象
        return instantiateWithMethodInjection(bd, beanName, owner);
    }
}
```

## 四. populateBean<a name="populateBean"></a>

```java
/**
 * 使用 bean 定义中的属性值填充给定 BeanWrapper 中的 bean 实例。
 * Populate the bean instance in the given BeanWrapper with the property values
 * from the bean definition.
 * @param beanName the name of the bean
 * @param mbd the bean definition for the bean
 * @param bw the BeanWrapper with bean instance
 */
@SuppressWarnings("deprecation")  // for postProcessPropertyValues
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
	// 没有实例化对象
	if (bw == null) {
		// 有属性，则抛出 BeanCreationException 异常
		if (mbd.hasPropertyValues()) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
			// 没有属性，直接 return 返回
		}
		else {
			// Skip property population phase for null instance.
			return;
		}
	}

	// Give any InstantiationAwareBeanPostProcessors the opportunity to modify the
	// state of the bean before properties are set. This can be used, for example,
	// to support styles of field injection.
	// <1> 在设置属性之前给 InstantiationAwareBeanPostProcessors 最后一次改变 bean 的机会
	if (!mbd.isSynthetic()  // bean 不是"合成"的，即未由应用程序本身定义
			&& hasInstantiationAwareBeanPostProcessors()) // 是否持有 InstantiationAwareBeanPostProcessor
	{
		for (InstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().instantiationAware) {
			// 返回值为是否继续填充 bean
			// postProcessAfterInstantiation：如果应该在 bean上面设置属性则返回 true，否则返回 false
			// 一般情况下，应该是返回true 。
			// 返回 false 的话，将会阻止在此 Bean 实例上调用任何后续的 InstantiationAwareBeanPostProcessor 实例。
			if (!bp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
				return;
			}
		}
	}

	// bean 的属性值
	PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);

	int resolvedAutowireMode = mbd.getResolvedAutowireMode();
	// <2> 自动注入
	if (resolvedAutowireMode == AUTOWIRE_BY_NAME || resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
		// 将 PropertyValues 封装成 MutablePropertyValues 对象
		// MutablePropertyValues 允许对属性进行简单的操作，并提供构造函数以支持Map的深度复制和构造。
		MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
		// Add property values based on autowire by name if applicable.
		// 根据名称自动注入
		if (resolvedAutowireMode == AUTOWIRE_BY_NAME) {
			autowireByName(beanName, mbd, bw, newPvs);
		}
		// Add property values based on autowire by type if applicable.
		// 根据类型自动注入
		if (resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
			autowireByType(beanName, mbd, bw, newPvs);
		}
		pvs = newPvs;
	}

	// 是否已经注册了 InstantiationAwareBeanPostProcessors
	boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
	// 是否需要进行【依赖检查】
	boolean needsDepCheck = (mbd.getDependencyCheck() != AbstractBeanDefinition.DEPENDENCY_CHECK_NONE);

	// <3> BeanPostProcessor 处理
	PropertyDescriptor[] filteredPds = null;
	if (hasInstAwareBpps) {
		if (pvs == null) {
			pvs = mbd.getPropertyValues();
		}
		// 遍历 BeanPostProcessor 数组
		for (InstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().instantiationAware) {
			// 对所有需要依赖检查的属性进行后处理
			PropertyValues pvsToUse = bp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
			if (pvsToUse == null) {
				// 从 bw 对象中提取 PropertyDescriptor 结果集
				// PropertyDescriptor：可以通过一对存取方法提取一个属性
				if (filteredPds == null) {
					filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
				}
				pvsToUse = bp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
				if (pvsToUse == null) {
					return;
				}
			}
			pvs = pvsToUse;
		}
	}
	// <4> 依赖检查
	if (needsDepCheck) {
		if (filteredPds == null) {
			filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
		}
		// 依赖检查，对应 depends-on 属性
		checkDependencies(beanName, mbd, filteredPds, pvs);
	}

	// <5> 将属性应用到 bean 中
	if (pvs != null) {
		applyPropertyValues(beanName, mbd, bw, pvs);
	}
}
```

- `<1>` ，根据 `hasInstantiationAwareBeanPostProcessors` 属性来判断，是否需要在注入属性之前给 InstantiationAwareBeanPostProcessors 最后一次改变 bean 的机会。**此过程可以控制 Spring 是否继续进行属性填充**。
- 统一存入到 PropertyValues 中，PropertyValues 用于描述 bean 的属性。
  - `<2>` ，根据注入类型( `AbstractBeanDefinition#getResolvedAutowireMode()` 方法的返回值 )的不同来判断：
    - 是根据名称来自动注入（`#autowireByName(...)`）
    - 还是根据类型来自动注入（`#autowireByType(...)`）
  - 详细解析，见 [《4.1自动注入》](#自动注入)
  - `<3>` ，进行 BeanPostProcessor 处理。
  - `<4>` ，依赖检测。
- `<5>` ，将所有 PropertyValues 中的属性，填充到 BeanWrapper 中。

### 4.1 自动注入<a name="自动注入"></a>

Spring 会根据注入类型（ `byName` / `byType` ）的不同，调用不同的方法来注入属性值。代码如下：

```java
// AbstractBeanDefinition.java

/**
 * 注入模式
 */
private int autowireMode = AUTOWIRE_NO;

public int getResolvedAutowireMode() {
	if (this.autowireMode == AUTOWIRE_AUTODETECT) { // 自动检测模式，获得对应的检测模式
		// Work out whether to apply setter autowiring or constructor autowiring.
		// If it has a no-arg constructor it's deemed to be setter autowiring,
		// otherwise we'll try constructor autowiring.
		Constructor<?>[] constructors = getBeanClass().getConstructors();
		for (Constructor<?> constructor : constructors) {
			if (constructor.getParameterCount() == 0) {
				return AUTOWIRE_BY_TYPE;
			}
		}
		return AUTOWIRE_CONSTRUCTOR;
	} else {
		return this.autowireMode;
	}
}
```

#### 4.1.1 autowireByName

`#autowireByName(String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs)` 方法，是根据**属性名称**，完成自动依赖注入的。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected void autowireByName(String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {
    // <1> 对 Bean 对象中非简单属性
    String[] propertyNames = unsatisfiedNonSimpleProperties(mbd, bw);
    // 遍历 propertyName 数组
    for (String propertyName : propertyNames) {
        // 如果容器中包含指定名称的 bean，则将该 bean 注入到 bean中
        if (containsBean(propertyName)) {
            // 递归初始化相关 bean
            Object bean = getBean(propertyName);
            // 为指定名称的属性赋予属性值
            pvs.add(propertyName, bean);
            // 属性依赖注入
            registerDependentBean(propertyName, beanName);
            if (logger.isTraceEnabled()) {
                logger.trace("Added autowiring by name from bean name '" + beanName +
                        "' via property '" + propertyName + "' to bean named '" + propertyName + "'");
            }
        } else {
            if (logger.isTraceEnabled()) {
                logger.trace("Not autowiring property '" + propertyName + "' of bean '" + beanName +
                        "' by name: no matching bean found");
            }
        }
    }
}
```

`<1>` 处，该方法逻辑很简单，获取该 bean 的非简单属性。**什么叫做非简单属性呢**？就是类型为对象类型的属性，但是这里并不是将所有的对象类型都都会找到，比如 8 个原始类型，String 类型 ，Number类型、Date类型、URL类型、URI类型等都会被忽略。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected String[] unsatisfiedNonSimpleProperties(AbstractBeanDefinition mbd, BeanWrapper bw) {
    // 创建 result 集合
    Set<String> result = new TreeSet<>();
    PropertyValues pvs = mbd.getPropertyValues();
    // 遍历 PropertyDescriptor 数组
    PropertyDescriptor[] pds = bw.getPropertyDescriptors();
    for (PropertyDescriptor pd : pds) {
        if (pd.getWriteMethod() != null // 有可写方法
                && !isExcludedFromDependencyCheck(pd) // 依赖检测中没有被忽略
                && !pvs.contains(pd.getName()) // pvs 不包含该属性名
                && !BeanUtils.isSimpleProperty(pd.getPropertyType())) { // 不是简单属性类型
            result.add(pd.getName()); // 添加到 result 中
        }
    }
    return StringUtils.toStringArray(result);
}
```

- 过滤**条件**为：有可写方法、依赖检测中没有被忽略、不是简单属性类型。
- 过滤**结果**为：其实这里获取的就是需要依赖注入的属性。

获取需要依赖注入的属性后，通过迭代、递归的方式初始化相关的 bean ，然后调用 `#registerDependentBean(String beanName, String dependentBeanName)` 方法，完成注册依赖。代码如下：

```java
// DefaultSingletonBeanRegistry.java

/**
 * Map between dependent bean names: bean name to Set of dependent bean names.
 *
 * 保存的是依赖 beanName 之间的映射关系：beanName - > 依赖 beanName 的集合
 */
private final Map<String, Set<String>> dependentBeanMap = new ConcurrentHashMap<>(64);

/**
 * Map between depending bean names: bean name to Set of bean names for the bean's dependencies.
 *
 * 保存的是依赖 beanName 之间的映射关系：依赖 beanName - > beanName 的集合
 */
private final Map<String, Set<String>> dependenciesForBeanMap = new ConcurrentHashMap<>(64);

public void registerDependentBean(String beanName, String dependentBeanName) {
    // 获取 beanName
    String canonicalName = canonicalName(beanName);
    // 添加 <canonicalName, <dependentBeanName>> 到 dependentBeanMap 中
    synchronized (this.dependentBeanMap) {
        Set<String> dependentBeans =
                this.dependentBeanMap.computeIfAbsent(canonicalName, k -> new LinkedHashSet<>(8));
        if (!dependentBeans.add(dependentBeanName)) {
            return;
        }
    }
    // 添加 <dependentBeanName, <canonicalName>> 到 dependenciesForBeanMap 中
    synchronized (this.dependenciesForBeanMap) {
        Set<String> dependenciesForBean =
                this.dependenciesForBeanMap.computeIfAbsent(dependentBeanName, k -> new LinkedHashSet<>(8));
        dependenciesForBean.add(canonicalName);
    }
}
```

#### 4.1.2 autowireByType

`#autowireByType(String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs)` 方法，是根据**属性类型**，完成自动依赖注入的。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected void autowireByType(String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {

    // 获取 TypeConverter 实例
    // 使用自定义的 TypeConverter，用于取代默认的 PropertyEditor 机制
    TypeConverter converter = getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }

    Set<String> autowiredBeanNames = new LinkedHashSet<>(4);
    // 获取非简单属性
    String[] propertyNames = unsatisfiedNonSimpleProperties(mbd, bw);
    // 遍历 propertyName 数组
    for (String propertyName : propertyNames) {
        try {
            // 获取 PropertyDescriptor 实例
            PropertyDescriptor pd = bw.getPropertyDescriptor(propertyName);
            // Don't try autowiring by type for type Object: never makes sense,
            // even if it technically is a unsatisfied, non-simple property.
            // 不要尝试按类型
            if (Object.class != pd.getPropertyType()) {
                // 探测指定属性的 set 方法
                MethodParameter methodParam = BeanUtils.getWriteMethodParameter(pd);
                // Do not allow eager init for type matching in case of a prioritized post-processor.
                boolean eager = !PriorityOrdered.class.isInstance(bw.getWrappedInstance());
                DependencyDescriptor desc = new AutowireByTypeDependencyDescriptor(methodParam, eager);
                // 解析指定 beanName 的属性所匹配的值，并把解析到的属性名称存储在 autowiredBeanNames 中
                // 当属性存在过个封装 bean 时将会找到所有匹配的 bean 并将其注入
                Object autowiredArgument = resolveDependency(desc, beanName, autowiredBeanNames, converter);
                if (autowiredArgument != null) {
                    pvs.add(propertyName, autowiredArgument);
                }
                // 遍历 autowiredBeanName 数组
                for (String autowiredBeanName : autowiredBeanNames) {
                    // 属性依赖注入
                    registerDependentBean(autowiredBeanName, beanName);
                    if (logger.isTraceEnabled()) {
                        logger.trace("Autowiring by type from bean name '" + beanName + "' via property '" +
                                propertyName + "' to bean named '" + autowiredBeanName + "'");
                    }
                }
                // 清空 autowiredBeanName 数组
                autowiredBeanNames.clear();
            }
        } catch (BeansException ex) {
            throw new UnsatisfiedDependencyException(mbd.getResourceDescription(), beanName, propertyName, ex);
        }
    }
}
```

实主要过程和根据名称自动注入**差不多**，都是找到需要依赖注入的属性，然后通过迭代的方式寻找所匹配的 bean，最后调用 `#registerDependentBean(...)` 方法，来注册依赖。不过相对于 `#autowireByName(...)` 方法而言，根据类型寻找相匹配的 bean 过程**比较复杂**。

**resolveDependency:**

```java
// DefaultListableBeanFactory.java

@Nullable
private static Class<?> javaxInjectProviderClass;

static {
	try {
		javaxInjectProviderClass = ClassUtils.forName("javax.inject.Provider", DefaultListableBeanFactory.class.getClassLoader());
	} catch (ClassNotFoundException ex) {
		// JSR-330 API not available - Provider interface simply not supported then.
		javaxInjectProviderClass = null;
	}
}

@Override
@Nullable
public Object resolveDependency(DependencyDescriptor descriptor, @Nullable String requestingBeanName,
        @Nullable Set<String> autowiredBeanNames, @Nullable TypeConverter typeConverter) throws BeansException {
    // 初始化参数名称发现器，该方法并不会在这个时候尝试检索参数名称
    // getParameterNameDiscoverer 返回 parameterNameDiscoverer 实例，parameterNameDiscoverer 方法参数名称的解析器
    descriptor.initParameterNameDiscovery(getParameterNameDiscoverer());
    // 依赖类型为 Optional 类型
    if (Optional.class == descriptor.getDependencyType()) {
        return createOptionalDependency(descriptor, requestingBeanName);
    // 依赖类型为ObjectFactory、ObjectProvider
    } else if (ObjectFactory.class == descriptor.getDependencyType() ||
            ObjectProvider.class == descriptor.getDependencyType()) {
        return new DependencyObjectProvider(descriptor, requestingBeanName);
    // javaxInjectProviderClass 类注入的特殊处理
    } else if (javaxInjectProviderClass == descriptor.getDependencyType()) {
        return new Jsr330Factory().createDependencyProvider(descriptor, requestingBeanName);
    } else {
        // 为实际依赖关系目标的延迟解析构建代理
        // 默认实现返回 null
        Object result = getAutowireCandidateResolver().getLazyResolutionProxyIfNecessary(descriptor, requestingBeanName);
        if (result == null) {
            // 通用处理逻辑
            result = doResolveDependency(descriptor, requestingBeanName, autowiredBeanNames, typeConverter);
        }
        return result;
    }
}
```

这里我们关注**通用处理逻辑** `#doResolveDependency(DependencyDescriptor descriptor, @Nullable String beanName, Set<String> autowiredBeanNames, TypeConverter typeConverter)` 方法，代码如下：

```java
// DefaultListableBeanFactory.java

@Nullable
public Object doResolveDependency(DependencyDescriptor descriptor, @Nullable String beanName,
    @Nullable Set<String> autowiredBeanNames, @Nullable TypeConverter typeConverter) throws BeansException {
    // 注入点
    InjectionPoint previousInjectionPoint = ConstructorResolver.setCurrentInjectionPoint(descriptor);
    try {
        // 针对给定的工厂给定一个快捷实现的方式，例如考虑一些预先解析的信息
        // 在进入所有bean的常规类型匹配算法之前，解析算法将首先尝试通过此方法解析快捷方式。
        // 子类可以覆盖此方法
        Object shortcut = descriptor.resolveShortcut(this);
        if (shortcut != null) {
            // 返回快捷的解析信息
            return shortcut;
        }
        // 依赖的类型
        Class<?> type = descriptor.getDependencyType();
        // 支持 Spring 的注解 @value
        Object value = getAutowireCandidateResolver().getSuggestedValue(descriptor);
        if (value != null) {
            if (value instanceof String) {
                String strVal = resolveEmbeddedValue((String) value);
                BeanDefinition bd = (beanName != null && containsBean(beanName) ? getMergedBeanDefinition(beanName) : null);
                value = evaluateBeanDefinitionString(strVal, bd);
            }
            TypeConverter converter = (typeConverter != null ? typeConverter : getTypeConverter());
            return (descriptor.getField() != null ?
                    converter.convertIfNecessary(value, type, descriptor.getField()) :
                    converter.convertIfNecessary(value, type, descriptor.getMethodParameter()));
        }
        // 解析复合 bean，其实就是对 bean 的属性进行解析
        // 包括：数组、Collection 、Map 类型
        Object multipleBeans = resolveMultipleBeans(descriptor, beanName, autowiredBeanNames, typeConverter);
        if (multipleBeans != null) {
            return multipleBeans;
        }
        // 查找与类型相匹配的 bean
        // 返回值构成为：key = 匹配的 beanName，value = beanName 对应的实例化 bean
        Map<String, Object> matchingBeans = findAutowireCandidates(beanName, type, descriptor);
        // 没有找到，检验 @autowire  的 require 是否为 true
        if (matchingBeans.isEmpty()) {
            // 如果 @autowire 的 require 属性为 true ，但是没有找到相应的匹配项，则抛出异常
            if (isRequired(descriptor)) {
                raiseNoMatchingBeanFound(type, descriptor.getResolvableType(), descriptor);
            }
            return null;
        }
        String autowiredBeanName;
        Object instanceCandidate;
        if (matchingBeans.size() > 1) {
            // 确认给定 bean autowire 的候选者
            // 按照 @Primary 和 @Priority 的顺序
            autowiredBeanName = determineAutowireCandidate(matchingBeans, descriptor);
            if (autowiredBeanName == null) {
                if (isRequired(descriptor) || !indicatesMultipleBeans(type)) {
                    // 唯一性处理
                    return descriptor.resolveNotUnique(descriptor.getResolvableType(), matchingBeans);
                }
                else {
                    // In case of an optional Collection/Map, silently ignore a non-unique case:
                    // possibly it was meant to be an empty collection of multiple regular beans
                    // (before 4.3 in particular when we didn't even look for collection beans).
                    // 在可选的Collection / Map的情况下，默默地忽略一个非唯一的情况：可能它是一个多个常规bean的空集合
                    return null;
                }
            }
            instanceCandidate = matchingBeans.get(autowiredBeanName);
        } else {
            // We have exactly one match.
            Map.Entry<String, Object> entry = matchingBeans.entrySet().iterator().next();
            autowiredBeanName = entry.getKey();
            instanceCandidate = entry.getValue();
        }
        if (autowiredBeanNames != null) {
            autowiredBeanNames.add(autowiredBeanName);
        }
        if (instanceCandidate instanceof Class) {
            instanceCandidate = descriptor.resolveCandidate(autowiredBeanName, type, this);
        }
        Object result = instanceCandidate;
        if (result instanceof NullBean) {
            if (isRequired(descriptor)) {
                raiseNoMatchingBeanFound(type, descriptor.getResolvableType(), descriptor);
            }
            result = null;
        }
        if (!ClassUtils.isAssignableValue(type, result)) {
            throw new BeanNotOfRequiredTypeException(autowiredBeanName, type, instanceCandidate.getClass());
        }
        return result;
    } finally {
        ConstructorResolver.setCurrentInjectionPoint(previousInjectionPoint);
    }
}
```

到这里就已经完成了所有属性的注入了。`populateBean()` 该方法就已经完成了一大半工作了：

- 下一步，则是对依赖 bean 的依赖检测和 PostProcessor 处理，**这个我们后面分析**。
- 下面，分析该方法的最后一步：`#applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs)` 方法。

### 4.2 applyPropertyValues

其实，上面只是完成了所有注入属性的获取，将获取的属性封装在 PropertyValues 的实例对象 `pvs` 中，并没有应用到已经实例化的 bean 中。而 `#applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs)` 方法，则是完成这一步骤的。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected void applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs) {
    if (pvs.isEmpty()) {
        return;
    }

    // 设置 BeanWrapperImpl 的 SecurityContext 属性
    if (System.getSecurityManager() != null && bw instanceof BeanWrapperImpl) {
        ((BeanWrapperImpl) bw).setSecurityContext(getAccessControlContext());
    }

    // MutablePropertyValues 类型属性
    MutablePropertyValues mpvs = null;

    // 原始类型
    List<PropertyValue> original;
    // 获得 original
    if (pvs instanceof MutablePropertyValues) {
        mpvs = (MutablePropertyValues) pvs;
        // 属性值已经转换
        if (mpvs.isConverted()) {
            // Shortcut: use the pre-converted values as-is.
            try {
                // 为实例化对象设置属性值 ，依赖注入真真正正地实现在此！！！！！
                bw.setPropertyValues(mpvs);
                return;
            } catch (BeansException ex) {
                throw new BeanCreationException(
                        mbd.getResourceDescription(), beanName, "Error setting property values", ex);
            }
        }
        original = mpvs.getPropertyValueList();
    } else {
        // 如果 pvs 不是 MutablePropertyValues 类型，则直接使用原始类型
        original = Arrays.asList(pvs.getPropertyValues());
    }

    // 获取 TypeConverter = 获取用户自定义的类型转换
    TypeConverter converter = getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }

    // 获取对应的解析器
    BeanDefinitionValueResolver valueResolver = new BeanDefinitionValueResolver(this, beanName, mbd, converter);

    // Create a deep copy, resolving any references for values.
    List<PropertyValue> deepCopy = new ArrayList<>(original.size());
    boolean resolveNecessary = false;
    // 遍历属性，将属性转换为对应类的对应属性的类型
    for (PropertyValue pv : original) {
        // 属性值不需要转换
        if (pv.isConverted()) {
            deepCopy.add(pv);
        // 属性值需要转换
        } else {
            String propertyName = pv.getName();
            Object originalValue = pv.getValue(); // 原始的属性值，即转换之前的属性值
            Object resolvedValue = valueResolver.resolveValueIfNecessary(pv, originalValue); // 转换属性值，例如将引用转换为IoC容器中实例化对象引用 ！！！！！ 对属性值的解析！！
            Object convertedValue = resolvedValue; // 转换之后的属性值
            boolean convertible = bw.isWritableProperty(propertyName) &&
                    !PropertyAccessorUtils.isNestedOrIndexedProperty(propertyName);  // 属性值是否可以转换
            // 使用用户自定义的类型转换器转换属性值
            if (convertible) {
                convertedValue = convertForProperty(resolvedValue, propertyName, bw, converter);
            }
            // Possibly store converted value in merged bean definition,
            // in order to avoid re-conversion for every created bean instance.
            // 存储转换后的属性值，避免每次属性注入时的转换工作
            if (resolvedValue == originalValue) {
                if (convertible) {
                    // 设置属性转换之后的值
                    pv.setConvertedValue(convertedValue);
                }
                deepCopy.add(pv);
            // 属性是可转换的，且属性原始值是字符串类型，且属性的原始类型值不是
            // 动态生成的字符串，且属性的原始值不是集合或者数组类型
            } else if (convertible && originalValue instanceof TypedStringValue &&
                    !((TypedStringValue) originalValue).isDynamic() &&
                    !(convertedValue instanceof Collection || ObjectUtils.isArray(convertedValue))) {
                pv.setConvertedValue(convertedValue);
                deepCopy.add(pv);
            } else {
                resolveNecessary = true;
                // 重新封装属性的值
                deepCopy.add(new PropertyValue(pv, convertedValue));
            }
        }
    }
    // 标记属性值已经转换过
    if (mpvs != null && !resolveNecessary) {
        mpvs.setConverted();
    }

    // Set our (possibly massaged) deep copy.
    // 进行属性依赖注入，依赖注入的真真正正实现依赖的注入方法在此！！！
    try {
        bw.setPropertyValues(new MutablePropertyValues(deepCopy));
    } catch (BeansException ex) {
        throw new BeanCreationException(
                mbd.getResourceDescription(), beanName, "Error setting property values", ex);
    }
}
```

总结 `#applyPropertyValues(...)` 方法（完成属性转换）：

- 属性值类型**不需要**转换时，不需要解析属性值，直接准备进行依赖注入。
- 属性值**需要**进行类型转换时，如对其他对象的引用等，首先需要解析属性值，然后对解析后的属性值进行依赖注入。

## 五. initializeBean<a name="initializeBean"></a>

﻿一个 bean 经历了 `#createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args)` 方法，被创建出来，然后又经过一番属性注入，依赖处理，历经千辛万苦，千锤百炼，终于有点儿 bean 实例的样子，能堪大任了，只需要经历最后一步就破茧成蝶了。

这**最后一步**就是初始化，也就是 `#initializeBean(final String beanName, final Object bean, RootBeanDefinition mbd)` 方法。所以，这篇文章我们分析 `#doCreateBean(...)` 方法的中最后一步：初始化 bean 对象。

```java
// AbstractAutowireCapableBeanFactory.java

protected Object initializeBean(final String beanName, final Object bean, @Nullable RootBeanDefinition mbd) {
    if (System.getSecurityManager() != null) { // 安全模式
        AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
            // <1> 激活 Aware 方法，对特殊的 bean 处理：Aware、BeanClassLoaderAware、BeanFactoryAware
            invokeAwareMethods(beanName, bean);
            return null;
        }, getAccessControlContext());
    } else {
        // <1> 激活 Aware 方法，对特殊的 bean 处理：Aware、BeanClassLoaderAware、BeanFactoryAware
        invokeAwareMethods(beanName, bean);
    }

    // <2> 后处理器，before
    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }

    // <3> 激活用户自定义的 init 方法
    try {
        invokeInitMethods(beanName, wrappedBean, mbd);
    } catch (Throwable ex) {
        throw new BeanCreationException(
                (mbd != null ? mbd.getResourceDescription() : null),
                beanName, "Invocation of init method failed", ex);
    }

    // <2> 后处理器，after
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }

    return wrappedBean;
}
```

初始化 bean 的方法其实就是三个步骤的处理，而这三个步骤主要还是根据**用户设定**的来进行初始化，这三个过程为：

- `<1>` 激活 Aware 方法。
- `<3>` 后置处理器的应用。
- `<2>` 激活自定义的 init 方法。

### 5.1 激活 Aware 方法

Aware ，英文翻译是意识到的，感知的。Spring 提供了诸多 Aware 接口，用于辅助 Spring Bean 以编程的方式调用 Spring 容器，通过实现这些接口，可以增强 Spring Bean 的功能。

Spring 提供了如下系列的 Aware 接口：

- LoadTimeWeaverAware：加载Spring Bean时织入第三方模块，如AspectJ
- BeanClassLoaderAware：加载Spring Bean的类加载器
- BootstrapContextAware：资源适配器BootstrapContext，如JCA,CCI
- ResourceLoaderAware：底层访问资源的加载器
- BeanFactoryAware：声明BeanFactory
- PortletConfigAware：PortletConfig
- PortletContextAware：PortletContext
- ServletConfigAware：ServletConfig
- ServletContextAware：ServletContext
- MessageSourceAware：国际化
- ApplicationEventPublisherAware：应用事件
- NotificationPublisherAware：JMX通知
- BeanNameAware：声明Spring Bean的名字

`#invokeAwareMethods(final String beanName, final Object bean)` 方法，代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

private void invokeAwareMethods(final String beanName, final Object bean) {
    if (bean instanceof Aware) {
        // BeanNameAware
        if (bean instanceof BeanNameAware) {
            ((BeanNameAware) bean).setBeanName(beanName);
        }
        // BeanClassLoaderAware
        if (bean instanceof BeanClassLoaderAware) {
            ClassLoader bcl = getBeanClassLoader();
            if (bcl != null) {
                ((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
            }
        }
        // BeanFactoryAware
        if (bean instanceof BeanFactoryAware) {
            ((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
        }
    }
}
```

这里代码就没有什么好说的，主要是处理 BeanNameAware、BeanClassLoaderAware、BeanFactoryAware 。

关于 Aware 接口，后面会专门出篇文章对其进行详细分析说明的。

### 5.2 后置处理器的应用

BeanPostProcessor 在前面介绍 bean 加载的过程曾多次遇到，相信各位不陌生，这是 Spring 中开放式框架中必不可少的一个亮点。

BeanPostProcessor 的作用是：如果我们想要在 Spring 容器完成 Bean 的实例化，配置和其他的初始化后添加一些自己的逻辑处理，那么请使用该接口，这个接口给与了用户充足的权限去更改或者扩展 Spring，是我们对 Spring 进行扩展和增强处理一个必不可少的接口。

`#applyBeanPostProcessorsBeforeInitialization(...)` 方法，代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

@Override
public Object applyBeanPostProcessorsBeforeInitialization(Object existingBean, String beanName)
        throws BeansException {
    Object result = existingBean;
    // 遍历 BeanPostProcessor 数组
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        // 处理
        Object current = processor.postProcessBeforeInitialization(result, beanName);
        // 返回空，则返回 result
        if (current == null) {
            return result;
        }
        // 修改 result
        result = current;
    }
    return result;
}
```

`#applyBeanPostProcessorsAfterInitialization(...)` 方法，代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

@Override
public Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName)
        throws BeansException {
    Object result = existingBean;
    // 遍历 BeanPostProcessor
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        // 处理
        Object current = processor.postProcessAfterInitialization(result, beanName);
        // 返回空，则返回 result
        if (current == null) {
            return result;
        }
        // 修改 result
        result = current;
    }
    return result;
}
```

其实，逻辑就是通过 `#getBeanPostProcessors()` 方法，获取定义的 BeanPostProcessor ，然后分别调用其 `#postProcessBeforeInitialization(...)`、`#postProcessAfterInitialization(...)` 方法，进行**自定义**的业务处理。

### 5.3 激活自定义的 init 方法

如果熟悉 `<bean>` 标签的配置，一定不会忘记 `init-method` 方法，该方法的执行就是在这里执行的。代码如下：

```java
// AbstractAutowireCapableBeanFactory.java

protected void invokeInitMethods(String beanName, final Object bean, @Nullable RootBeanDefinition mbd)
        throws Throwable {
    // 首先会检查是否是 InitializingBean ，如果是的话需要调用 afterPropertiesSet()
    boolean isInitializingBean = (bean instanceof InitializingBean);
    if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
        if (logger.isTraceEnabled()) {
            logger.trace("Invoking afterPropertiesSet() on bean with name '" + beanName + "'");
        }
        if (System.getSecurityManager() != null) { // 安全模式
            try {
                AccessController.doPrivileged((PrivilegedExceptionAction<Object>) () -> {
                    // <1> 属性初始化的处理
                    ((InitializingBean) bean).afterPropertiesSet();
                    return null;
                }, getAccessControlContext());
            } catch (PrivilegedActionException pae) {
                throw pae.getException();
            }
        } else {
            // <1> 属性初始化的处理
            ((InitializingBean) bean).afterPropertiesSet();
        }
    }

    if (mbd != null && bean.getClass() != NullBean.class) {
        String initMethodName = mbd.getInitMethodName();
        if (StringUtils.hasLength(initMethodName) &&
                !(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
                !mbd.isExternallyManagedInitMethod(initMethodName)) {
            // <2> 激活用户自定义的初始化方法
            invokeCustomInitMethod(beanName, bean, mbd);
        }
    }
}
```

- 首先，检查是否为 InitializingBean 。如果**是**的话，需要执行 `#afterPropertiesSet()` 方法，因为我们除了可以使用 `init-method` 来自定初始化方法外，还可以实现 InitializingBean 接口。接口仅有一个 `#afterPropertiesSet()` 方法。
- 两者的执行先后顺序是先 `<1>` 的 `#afterPropertiesSet()` 方法，后 `<2>` 的 `init-method` 对应的方法
