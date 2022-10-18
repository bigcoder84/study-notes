# watch命令的条件过滤

## 一. 前言

Arthas 的 watch 指令一直是我排查线上问题时使用最多的指令，没有之一。而按照条件进行 watch 也是很常见的一个需求，例如线上一个方法会有大量的调用，而我们可以按照指定的条件，watch 到我们希望观察的那一次调用。 说实话，我对 Arthas 也没有什么研究，一开始还真不清楚原来 Arthas watch 可以按条件过滤，翻看一下官方文档：https://arthas.aliyun.com/doc/watch#id6

## 二. watch的参数说明

watch 的参数比较多，主要是因为它能在 4 个不同的场景观察对象

|            参数名称 | 参数说明                                             |
| ------------------: | :--------------------------------------------------- |
|     *class-pattern* | 类名表达式匹配                                       |
|    *method-pattern* | 函数名表达式匹配                                     |
|           *express* | 观察表达式，默认值：`{params, target, returnObj}`    |
| *condition-express* | 条件表达式                                           |
|                 [b] | 在**函数调用之前**观察                               |
|                 [e] | 在**函数异常之后**观察                               |
|                 [s] | 在**函数返回之后**观察                               |
|                 [f] | 在**函数结束之后**(正常返回和异常返回)观察           |
|                 [E] | 开启正则表达式匹配，默认为通配符匹配                 |
|                [x:] | 指定输出结果的属性遍历深度，默认为 1，最大值是 **4** |

## 三. 条件表达式的例子

```shell
$ watch demo.MathGame primeFactors "{params[0],target}" "params[0]<0"
Press Ctrl+C to abort.
Affect(class-cnt:1 , method-cnt:1) cost in 68 ms.
ts=2018-12-03 19:36:04; [cost=0.530255ms] result=@ArrayList[
    @Integer[-18178089],
    @MathGame[demo.MathGame@41cf53f9],
]
```

喏，这不是很明显的例子吗？但是上面的例子，貌似只给出了一些简单的讯息

- 可以直接用 watch 命令的参数中增加“条件表达式”进行过滤
- 可以进行数值类型的过滤

但是，这个简单的示例，并没有解答我内心其他的疑惑：

- 我可以进行字符串、集合等复杂类型的判断吗？
- 这个表达式是 el、ognl 或者其他类型的表达式吗？

带着这些疑问，我记录下了这篇文章，给不了解 Arthas watch 条件表达式的读者们一些参考。

## 四. 一些条件表达式的示例

有一些读者可能仅仅是想知道“我该怎么实现使用 Arthas 条件 Watch”，为此，我在本文的第二节先介绍下我平时积累的一些实践命令。

**示例方法**

```java
public void methodForWatch(int id, User user) {
}
```

```java
@Data
public class User {
    private String name;
    private int age;
    private List<String> hobbies;
}
```

另外准备一些请求，我会在每个示例中执行相同的调用。**示例请求**：

```java
1, new User("hanmeimei", 16, Arrays.asList("pubg", "lol"));
2, new User("liming", 17, Collections.singletonList("pubg"));
3, new User("tom", 18, Collections.singletonList("running"));
4, new User("jacky", 19, Collections.singletonList("food"));
5, new User("kirito", 20, null);
```

**示例 1**：过滤 int 类型；过滤 id > 0 的请求

这其实就是官方的示例，我拿过来再贴一遍

```shell
watch moe.cnkirito.arthas.WatchDemo methodForWatch "{params,returnObj}" "params[0]>0" -x 2
```

**示例 2**：过滤对象中的字符串类型；过滤 User 中 name = haimeimei 的请求

```shell
watch moe.cnkirito.arthas.WatchDemo methodForWatch "{params,returnObj}" "params[1].getName().equals('liming')" -x 2
```

这里有三个注意点

- 使用 params[1] 这种数组访问的方式，对应到 methodForWatch 方法的第二个参数 `User user`
- 使用 getName() 这种方法调用的方式拿到 name 字段，并且使用 String 的 equals 方法进行字符串比对
- 由于 condition 表达式整体使用了双引号 “”，在 hanmeimei 该字面量上需要使用单引号 ‘’

**示例 3**：过滤集合中的元素;过滤对 pubg 感兴趣的 User 相关的请求

```shell
watch moe.cnkirito.arthas.WatchDemo methodForWatch {params,returnObj} "params[1].getHobbies().contains('pubg')" -x 2
```

**示例 4**：多个条件表达式

如果直接使用示例3的命令，可能会有NPE问题，因为hobbies字段可能为null。

```shell
watch failed, condition is: params[1].getHobbies().contains('pubg'), express is: {params,returnObj}, java.lang.NullPointerException: target is null for method contains, visit /Users/xujingfeng/logs/arthas/arthas.log for more details.
```

我们可以加上非空校验：

```shell
watch moe.cnkirito.actuator.demo.HelloController methodForWatch {params,returnObj} "params[1].getHobbies() != null && params[1].getHobbies().contains('pubg')" -x 2
```

## 五. OGNL实现条件过滤

可能大家看了上面的示例会觉得这个 condition 表达式不就是跟 Java 里面的表达式差不多吗？但其实我作为一个不太了解 Arthas 的弱鸡，上面的用法纯粹是我摸索出来的，在最开始的时候，参考 github 中的 issue，我使用的其实是其他的方式来实现的条件查询，参考 issue：https://github.com/alibaba/arthas/issues/71。

```shell
$ watch com.taobao.container.Test test "{params}" "params[0].{? #this.name == null }.size()>0" -x 2
Press Ctrl+C to abort.
Affect(class-cnt:1 , method-cnt:1) cost in 27 ms.
@ArrayList[
    @Pojo[
        name=null,
        age=@Integer[32],
        hobby=null,
    ],
]
@ArrayList[
    @Pojo[
        name=null,
        age=@Integer[31],
        hobby=null,
    ],
]
```

看下 github 中的 Arthas 开源作者提供的按条件过滤的示例，可以发现跟上文中我介绍的过滤方式好像，有那么一点点的不同。注意上文的示例

```shell
$ watch demo.MathGame primeFactors "{params[0],target}" "params[0]<0"
```

watch 后的参数是由 4 部分组成的，分别是类名表达式，方法名表达式，观察表达式，条件表达式。

而 issue 中给出的表达式

```shell
$ watch com.taobao.container.Test test "params[0].{? #this.name == null }" -x 2
```

没有第四部分：条件表达式。过滤条件被放到了观察表达式的对象后，并且不是 Java 里面的表达式，而是 ognl 表达式。

> ognl 表达式官方参考文档：https://commons.apache.org/proper/commons-ognl/language-guide.html

例如使用 ognl 表达式实现上面的示例 2，需要这么写

```shell
watch moe.cnkirito.actuator.demo.HelloController methodForWatch "params[1].{? #this.name == 'hanmeimei'}" -x 2
```

**示例 2 和示例 5 的对比**

聊到这里，如果你对 Arthas 比较熟悉，应该已经意识到示例5 OGNL过滤和 示例2 直接使用条件过滤表达式的区别了。ognl 这种过滤的方式，是针对对象的属性的过滤，无论是否匹配，都会被算进 watch 的匹配次数中，只不过没有匹配到的对象没有输出；而示例 2 中直接使用条件过滤表达式这种方式，更匹配我文首提出的需求，只有被条件表示式命中的请求，才会被算进 watch 次数中。你可以使用 -n 1 来限定 watch 匹配次数，直观地观察到这两个匹配方式的差异。