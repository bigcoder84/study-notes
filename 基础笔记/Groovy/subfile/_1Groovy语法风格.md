# Groovy语法风格

> 本文转载至：https://wiki.jikexueyuan.com/project/groovy-introduction/style-guide.html

愿意使用 Groovy 的 Java 开发者往往还是会保留着 Java 的思维，通过对 Groovy 的逐渐学习，每次了解一个特性，他们的努力越来越具有成效，Groovy 代码写得也越来越娴熟。我们的文档力图继续指导开发者，教授一些常用的 Groovy 语法风格、新的操作符，以及一些新的特性，比如闭包等。这篇指南并不完整，只能作为快速入门以及今后深入的奠基石，你可能以后会为本文档贡献内容并对它作出一番改进。

## 1. 不用分号

拥有 C/C++/C#/Java 背景的开发者往往习惯于到处使用分号。更严重的是，Groovy 支持绝大部分的 Java 语法格式。因此，很容易就能将 Java 代码复制粘贴到 Groovy 程序中继续使用，其结果就是到处都是分号。但是，在 Groovy 中，分号是可选择采用的，你可以忽略不用它们，而且往往这种方法才是地道的用法。

## 2. 可选择性使用的 `return` 关键字

在 Groovy 中，方法主体内部的最后一个求值表达式不必非得带上 `return` 关键字就能返回。所以对于短方法和闭包而言，忽略这个关键字会显得更简洁。

```groovy
String toString() { return "a server" }
String toString() { "a server" }
```

 但有时在使用变量时，在两行上分别出现了两次这个变量，让人看起来会不很舒服。

```groovy
def props() {
    def m1 = [a: 1, b: 2]
    m2 = m1.findAll { k, v -> v % 2 == 0 }
    m2.c = 3
    m2
}
```

在这种情况下，在最后的表达式前换行，或者使用 `return` ，可读性就会大大增强。

就我个人而言，并不一定会一直使用 `return` 关键字，这往往是凭感觉作出的。但在闭包中，我多数情况下不会使用它。所以如果该关键字是可选择使用的，而如果它给你的感觉是为代码可读性套上了枷锁，那么也你也可以不使用它，但这并非是强制性的。

然而，要提请大家注意的是，在使用 `def` 关键字（而非某种具体类型）定义的方法时，最后一个表达式有时会被返回。所以建议最好指定某些具体的返回类型，比如 void 或某种其他类型。在上面所展示的例子中，假如我们把 m2 作为最后要返回的语句，那么最后的表达式应该为 `m2.c = 3`，即返回 `3`，而并非是你所期望的映射。

像 `if`/`else`、`try`/`catch` 这些语句也能返回值，就好像在这些语句中也存在“最后一个表达式”一样。

```
def foo(n) {
    if(n == 1) {
        "Roshan"
    } else {
        "Dawrani"
    }
}

assert foo(1) == "Roshan"
assert foo(2) == "Dawrani"
```

## 3. `def` 和类型

很多开发者往往会同时使用 `def` 和类型，但这里的 `def` 是多余的。因此，要么使用 `def`，要么使用类型。

所以不要这样写：

```
def String name = "Guillaume"
```

这样写就足够了：

```
String name = "Guillaume"
```

在 Groovy 中使用 `def` 时，实际的类型持有者是 `Object`，所以可以将任何对象赋予利用 `def` 定义的变量，如果一个方法声明为返回 `def` 类型值，则它会返回任何类型的对象。

定义带有无类型参数的方法时，可以使用 `def`，但并不是必需条件，因此我们习惯上会忽略使用它。所以，与其采用如下方式：

```
void doSomething(def param1, def param2) { }
```

我们会更多建议采用如下方式：

```
void doSomething(param1, param2) { }
```

但正如我们在上一节中所提到的那样，为方法参数确定类型通常是一个不错的习惯，这样做不仅能够便于注释代码，而且也有助于 IDE 的代码补全，或者利用 Groovy 的静态类型检查或静态编译功能。

另一个 `def` 显得多余并且应该避免使用的地方是构造函数的构造：

```
class MyClass {
    def MyClass() {}
}
```

去掉 `def` 就可以了：

```
class MyClass {
    MyClass() {}
}
```

## 4. 默认采用 `public`

默认情况下，Groovy 会将类及方法认为是 `public` 型，所以不必使用 `public` 修饰符了，只有当非公开时，才需要加上。

所以与其这样：

```
public class Server {
    public String toString() { return "a server" }
}
```

不如这样：

```
class Server {
    String toString() { "a server" }
}
```

你可能还纠结于“包范围内”可见性这个问题。事实上，Groovy 允许忽略 `public` 修饰符的潜台词即是说默认并不支持该范围。但 Groovy 确实提供了一个注释来实现这种可见性。

```
class Server {
    @PackageScope Cluster cluster
}
```

## 5. 省略括号

对于顶级表达式，Groovy 允许省去括号，比如 `println` 命令：

```
println "Hello"
method a, b
```

对比一下之前的用法：

```
println("Hello")
method(a, b)
```

当闭包成为方法调用的最后一个参数时，比如在使用 Groovy 的 `each{}` 迭代机制时，你可以将闭包放到括号对外面，甚至将括号对去除。

```
list.each( { println it } )
list.each(){ println it }
list.each  { println it }
```

一般往往推荐采用第三种方法，它显得更自然一些。从语法层面上来看，内容为空的括号对是一种无用的垃圾。

然而，在有些情况下，Groovy 是不允许去除括号的。遇到顶级的表达式，自然可以忽略括号，但对于内嵌的方法调用或在赋值语句的右侧，则是不允许忽略括号的。

```
def foo(n) { n }

println foo 1 // 不起作用   
def m = foo 1
```

## 6. 作为一等公民存在的类

Groovy 中并不需要 `.class` 后缀，这有点像 Java 中的 `instanceof`。

比如：

```
connection.doPost(BASE_URI + "/modify.hqu", params, ResourcesResponse.class)
```

使用之后介绍的 GString，应用头等公民的结果是这样的：

```
connection.doPost("${BASE_URI}/modify.hqu", params, ResourcesResponse)
```

## 7. Getter 与 Setter

Groovy 中的 getter 与 setter 构成了我们称之为 “属性”（property）的形式，从而为访问这种属性提供了一种快捷标记。因此，我们完全可以舍弃 Java 式的调用方法，而采用字段样式的访问标记：

```
resourceGroup.getResourcePrototype().getName() == SERVER_TYPE_NAME
resourceGroup.resourcePrototype.name == SERVER_TYPE_NAME

resourcePrototype.setName("something")
resourcePrototype.name = "something"
```

用 Groovy 编写 bean 时，通常会调用 POGO（普通 Groovy 对象），不必自己创建字段和 getter/setter，只需把这些活儿留给 Groovy 编译器即可：

与其像下面这样：

```
class Person {
    private String name
    String getName() { return name }
    void setName(String name) { this.name = name }
}
```

不如这样写，简单明快：

```
class Person {
    String name
}
```

如你所见，实际上，没有任何修饰符的独立“字段”导致 Groovy 编译器为你生成了一个私有字段和 getter 及 setter。

在使用这样来自 Java 的POGO 时，getter 与 setter 确实存在，当然可以像通常那样使用。

虽然编译器创建了常见的 getter 和 setter 逻辑，但如果你希望在这些 getter/setter 中实现不同或者更多的逻辑，完全可以添加进去，编译器自会用你提供的逻辑来代替默认生成的逻辑。

## 8. 利用命名参数及默认构造函数初始化 bean

假如有一个如下的 bean：

```
class Server {
    String name
    Cluster cluster
}
```

与其像下面这样在随后的语句中设置每一个 setter：

```
def server = new Server()
server.name = "Obelix"
server.cluster = aCluster
```

可以利用命名参数及默认构造函数（首先调用该构造函数，然后 setter 按照它们在映射中所指定的顺序被依次调用）来设置：

```
def server = new Server(name: "Obelix", cluster: aCluster)   
```

## 9. 利用 `with()` 来处理对于同一 bean 的重复操作

在创建新实例时，带有默认构造函数的命名参数是非常有用的。但是，如果更新一个已有实例呢？难道你还必须一遍一遍重复 `server` 前缀？不必如此，Groovy 所提供的 `with()` 方法可以应用于所有类型的对象，比如像下面这样：

```
server.name = application.name
server.status = status
server.sessionCount = 3
server.start()
server.stop()
```

就可以转换成如下的形式：

```
server.with {
    name = application.name
    status = status
    sessionCount = 3
    start()
    stop()
}
```

## 10. 相等与 `==`

Java 的 `==` 实际相当于 Groovy 的 `is()` 方法，而 Groovy 的 `==` 则是一个更巧妙的 `equals()`。

要想比较对象的引用，不能用 `==`，而应该用 `a.is(b)`。

但要想进行常见的 `equals()` 比对，应该首选使用 Groovy 的 `==`，因为该操作符不会产生`NullPointerException`，与等号左右两边是否为 `null` 无关。

所以与其这样：

```
status != null && status.equals(ControlConstants.STATUS_COMPLETED)
```

不如这样：

```
status == ControlConstants.STATUS_COMPLETED    
```

## 11. GString（插值、多行）

在 Java 中，我们常常联合使用字符串与变量，通常会带有很多开闭的双引号、加号，以及用于换行的 `\n` 字符。利用插入字符串（也叫 GString），以前的字符串看起来就会优雅多了，输入起来也变得简洁了：

```
throw new Exception("Unable to convert resource: " + resource)
```

跟下面的方式对比一下：

```
throw new Exception("Unable to convert resource: ${resource}")
```

在大括号内，可以放入各种表达式，而不只是变量。对于较简单的变量，或者 `variable.property`，甚至还可以去掉大括号。

```
throw new Exception("Unable to convert resource: $resource")
```

甚至还可以使用 `${→ resource }` 和闭包形式来拖延计算那些表达式。当 GString 被迫转换为字符串时，就会计算闭包，获得返回值的 `toString()` 表示形式。

范例：

```
int i = 3

def s1 = "i's value is: ${i}"
def s2 = "i's value is: ${-> i}"

i++

assert s1 == "i's value is: 3" // 急切地计算，一创建时就求值
assert s2 == "i's value is: 4" // 拖延式计算，考虑新值   
```

当字符串与它们的联合表达式用 Java 表示显得很长时，比如像下面这个：

```
throw new PluginException("Failed to execute command list-applications:" +
    " The group with name " +
    parameterMap.groupname[0] +
    " is not compatible group of type " +
    SERVER_TYPE_NAME)
```

你可以使用 `\` 行连续字符（这并不是一个多行字符串）：

```
throw new PluginException("Failed to execute command list-applications: \
The group with name ${parameterMap.groupname[0]} \
is not compatible group of type ${SERVER_TYPE_NAME}")
```

或者利用三个引号的多行字符串来表示：

```
throw new PluginException("""Failed to execute command list-applications:
    The group with name ${parameterMap.groupname[0]}
    is not compatible group of type ${SERVER_TYPE_NAME)}""")
```

另外，还可以在多行字符串调用 `.stripIndent()` 去除字符串左边的缩进。

注意，在 Groovy 中，单引号与双引号的区别在于：单引号常用于创建没有插入变量的 Java 字符串，而双引号则既能创建 Java 字符串，也能在出现插值变量时创建 GString。

对于多行字符串，可以使用三重引号，比如对 GString 用三重双引号，对单纯的字符串用三重单引号。

如果需要编写正则表达式模式，应该使用“斜杠式”字符串标记法：

```
assert "foooo/baaaaar" ==~ /fo+\/ba+r/  
```

这样写的好处在于不必使用双重转义反斜杠，从而更便于使用 regex。

最后要强调的是，在需要字符串常量时，尽量优先使用单引号字符串，而在显然需要字符串插值时，才使用双引号字符串。

## 12. 数据结构的原生语法

Groovy 为一些数据结构（如列表、映射、正则表达式以及值范围）提供了原生的语法结构，一定要利用好它们。

下面是一些原生构造：

```
def list = [1, 4, 6, 9]

// 默认，键是 String 类型，所以不需要用引号括起来
// 你可以用像 [(variableStateAcronym): stateName] 这样的带有 () 的结构来封装键，插入变量或对象  

def map = [CA: 'California', MI: 'Michigan']

def range = 10..20
def pattern = ~/fo*/

// 等同于 add()  
list << 5

// 调用 contains()
assert 4 in list
assert 5 in list
assert 15 in range

// 下标符号  
assert list[1] == 4

// 添加一个新的键值对   
map << [WA: 'Washington']
// 下标符号  
assert map['CA'] == 'California'
// 属性标记  
assert map.WA == 'Washington'

// 判断字符串是否与模式匹配   
assert 'foo' =~ pattern
```

## 13. Groovy 开发工具包

继续探讨数据结构，在需要对集合迭代时，Groovy 提供了多种方法，通过装饰模式强化 Java 的核心数据结构，比如：`each{}`、`find{}`、`findAll{}`、`every{}`、`collect{}`以及`inject{}`等。这些方法不仅为编程语言提供了功能性帮助，而且还能便于人们实现复杂的算法。通过装饰模式，很多新方法已经添加到不同的类型中，这要感谢语言本身的动态特性。可以在下面这个网站找到很多的有用方法，它们可以用于字符串、文件、流以及集合等：http://beta.groovy-lang.org/gdk.html。

## 14. `switch` 的魔力

`switch` 在 Groovy 中的作用要比在 C 族语言中更为强大，后者往往只接受原语并将其同化。Groovy 中的 `switch` 能够接受更多的类型。

```
def x = 1.23
def result = ""
switch (x) {
    case "foo": result = "found foo"
    // lets fall through
    case "bar": result += "bar"
    case [4, 5, 6, 'inList']:
        result = "list"
        break
    case 12..30:
        result = "range"
        break
    case Integer:
        result = "integer"
        break
    case Number:
        result = "number"
        break
    case { it > 3 }:
        result = "number > 3"
        break
    default: result = "default"
}
assert result == "number"
```

一般地说，利用 `isCase()` 方法可以确定值是否对应一个 case。

## 15. 导入别名

在 Java 中，使用不同包而同名的两个类时（比如 `java.util.List` 和 `java.awt.List` 这两个包），你可以导入其中一个类，而对另一个类使用完整限定名。

有时在代码中经常使用长类名，代码就会变得冗长啰嗦。

为了改善这种状况，Groovy 提供了导入别名机制。

```
import java.util.List as juList
import java.awt.List as aList

import java.awt.WindowConstants as WC
```

还可以静态地导入方法：

```
import static pkg.SomeClass.foo
foo()
```

## 16. Groovy Truth

任何对象都可以被强制转换为布尔值：任何为 `null`、`void`的对象，等同于 0 或空的值，都会解析为 `false`，凡之则为 `true`。

所以不必这样写：

```
if (name != null && name.length > 0) {}
```

只需这样写就好了：

```
if (name) {}
```

这一原则也可以用于集合等对象。

因此，可以在诸如 `while()`、`if()`、三元运算子以及 Elvis 操作符等结构中使用一些快捷形式。

甚至可以自定义 Groovy Truth 对象，只需为类加入一个 `asBoolean()` 布尔方法即可。

## 17. `?.`操作符防止NPE

为了安全地在对象图表中导航，Groovy 支持 `.` 操作符的一个变体。

在 Java 中，如果你对图表中的某个较深的节点比较感兴趣，需要检查 `null`，你可能经常会写复杂的 `if` 或内嵌的 `if` 语句，就像下面这样：

```
if (order != null) {
    if (order.getCustomer() != null) {
        if (order.getCustomer().getAddress() != null) {
            System.out.println(order.getCustomer().getAddress());
        }
    }
}
```

利用 `?.` 安全解除引用操作符，可以将上面的代码利用下面的形式来简化：

```
println order?.customer?.address
```

会在调用链中检查 null 值，如果有元素为 `null`，则不会抛出 `NullPointerException` 异常。如果有 元素为 `null`，则结果值必为 `null`。

## 18. 断言

可以使用 `assert` 语句来检查参数、返回值以及更多类型的值。

与 Java 的 `assert` 有所不同，Groovy 的 `assert` 并不需要激活，它是一直被检查的。

```
def check(String name) {
    // 根据 Groovy Truth，name 应为非 null 与非空
    assert name
    // 安全导航 + Groovy Truth  
    assert name?.size() > 3
}
```

另外要注意的是，Groovy 的 “强力断言” 语句提供的输出结果是很出色的，在生成的图表中对每个子表达式的各种值都进行了断言。

## 19. 用于默认值的 Elvis 操作符

Elvis 操作符是一种特殊的三元操作符，对于处理默认值来说不啻是一种快捷方式。

我们往往会像下面这样来书写：

```
def result = name != null ? name : "Unknown"
```

多亏有了 Groovy Truth，`null` 检查可以简化为只用 `name` 就可以了。

进一步来说，既然要返回 `name`，那么与其在这个三元表达式中重复两次名称，不如去掉问号和冒号之间的东西，使用 Elvis 操作符，可以这样来完成：

```
def result = name ?: "Unknown"
```

## 20. 异常捕捉

如果不关心 `try` 语句块中所要抛出的异常类型，可以只捕捉异常而忽略它们的类型。所以，像下面这样的语句：

```
try {
    // ...
} catch (Exception t) {
    // 一些糟糕的事情   
}
```

就可以变成下面这样捕捉任何异常（`any` 或 `all` 都可以，只要是能让你认为是任何东西的词儿就可以用）：

```
try {
    // ...
} catch (any) {
    // 一些糟糕的事情  
}
```

它会捕捉所有异常，而并不仅是 `Throwable` 的异常。如果需要捕捉的是“每一个”异常，必须明确地声明要捕捉的是 `Throwable` 异常。

## 21. 额外的类型建议

最后讲讲什么时候以及如何使用可选类型。Groovy 允许自己决定是否使用显式的强类型，或何时使用 `def`。

简单的经验法则是：如果你写的代码将被其他人用作公共 API，你就应该使用强类型，它能有助于合约的健壮性，避免可能通过的参数类型错误，形成更好的文档，有助于 IDE 自动完成代码。假如代码只是自用，比如私有方法，或 IDE 能够轻松地推断类型，那么你就可以更自由地确定何时利用类型。