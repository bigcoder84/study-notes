# Mockito 中文文档 (3.0.6)

> 说明：本文clone至https://github.com/hehonghui/mockito-doc-zh，一下内容会根据实际情况对原文有所修改和删减。

![](../images/3.png)

> 由于缺乏校对，难免有谬误之处，如果发现任何语句不通顺、翻译错误，都可以在[github中的项目](https://github.com/hehonghui/mockito-doc-zh)提出issue。谢谢~ 

Mockito框架官方地址[mockito](http://mockito.org/)，[文档地址](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html)。

Mockito库能够Mock对象、验证结果以及打桩(stubbing)。

该文档您也可以通过[http://mockito.org](http://mockito.org)获取到。所有文档都保存在javadocs中，因为它能够保证文档与源代码的一致性。这样也能够让离线的用户从IDE直接访问到文档。这样一来也能够激励Mockito开发者在每次写代码、每次提交时更新对应的文档。


## 目录

0. [迁移到Mockito 2.0](#dsa)
1. [验证某些行为](#1)
2. [如何做一些测试桩 (Stub)](#2)
3. [参数匹配器 (matchers)](#3)
4. [验证函数的确切、最少、从未调用次数](#4)
5. [为返回值为void的函数通过Stub抛出异常](#5)
6. [按照顺序验证执行结果](#6)
7. [验证mock对象从未发生交互动作](#7)
8. [查找冗余的调用](#8)
9. [简化mock对象的创建](#9)
10. [为连续的调用做测试桩 (stub) ](#10)
11. [为回调做测试桩](#11)
12. [doReturn()、doThrow()、doAnswer()、doNothing()、doCallRealMethod()系列方法的运用](#12)
13. [监控真实对象](#13)
14. [修改没有测试桩的调用的默认返回值 ( 1.7版本之后 ) ](#14)
15. [为下一步的断言捕获参数 (1.8版本之后)](#15)
16. [真实的局部mocks (1.8版本之后)](#16)
17. [重置mocks对象 (1.8版本之后)](#17)
18. [故障排查与验证框架的使用 (1.8版本之后)](#18)
19. [行为驱动开发的别名 (1.8版本之后)](#19)
20. [序列化mock对象](#20)
21. [新的注解 : @Captor,@Spy,@ InjectMocks (1.8.3版本之后) ](#21)
22. [验证超时 (1.8.5版本之后) ](#22)
23. [自动初始化被@Spies, @InjectMocks注解的字段以及构造函数注入 (1.9.0版本之后)](#23)
24. [单行测试桩 (1.9.0版本之后) ](#24)
25. [验证被忽略的测试桩 (1.9.0版本之后)](#25)
26. [mock详情 (1.9.5版本之后)](#26)
27. [delegate调用真实的实例 (1.9.5版本之后)](#27)
28. [MockMaker API (1.9.5版本之后)](#28)
29. [BDD风格的验证 (1.10.0版本之后)](#29)
30. [追踪或者Mock抽象类 (1.10.12版本之后)](#30)
31. [Mockito mock对象通过ClassLoader能被序列化/反序列化 (1.10.0版本之后)](#31)
32. [deep stubs更好的支持泛型 (1.10.0版本之后)](#32)
33. [Mockito JUnit 规则 (1.10.17版本之后)](#33)
34. [开/关插件 (1.10.15版本之后)](#34)
35. [自定义验证失败消息 (2.0.0版本之后)](#35)

<a name="0"></a>

### 0. 迁移到Mockito 2.0


为了持续提升Mockito以及更进一步的提升单元测试体验,我们希望你升级到Mockito 2.0.Mockito遵循语意化的版本控制，除非有非常大的改变才会变化主版本号。在一个库的生命周期中,为了引入一系列有用的特性，修改已存在的行为或者API等重大变更是在所难免的。因此，我们希望你能够爱上 Mockito 2.0!

重要变更 : 

* Mockito从Hamcrest中解耦，自定义的matchers API也发生了改变,查看[ArgumentMatcher](http://site.mockito.org/mockito/docs/current/org/mockito/ArgumentMatcher.html) 的基本原理以及迁移指南。

跟着我们的示例来mock 一个List,因为大家都知道它的接口（例如add(),get(), clear()）。不要mock一个真实的List类型,使用一个真实的实例来替代。

<a name="1"></a>

### 1. 让我们验证某些行为

```java
 // 静态导入会使代码更简洁
 import static org.mockito.Mockito.*;

 // 创建mock对象
 List mockedList = mock(List.class);

 // 使用mock对象
 mockedList.add("one");
 mockedList.clear();

 // 进行验证
 verify(mockedList).add("one");
 verify(mockedList).clear();
```
一旦mock对象被创建了，mock对象会记住所有的交互动作。然后你就可能选择性的验证你感兴趣的交互。


<a name="2"></a>
### 2. 如何做一些测试桩 (Stub)

所谓的测试桩就是模拟对象行为，一个刚刚创建mock对象是没有任何行为的，我们在使用mock对象参与测试时需要提前埋入对象行为，这一过程在官方文档中称为`打入测试桩`

```java
 // 你可以mock具体的类型,不仅只是接口
 LinkedList mockedList = mock(LinkedList.class);

 // 测试桩
 when(mockedList.get(0)).thenReturn("first");
 when(mockedList.get(1)).thenThrow(new RuntimeException());

 // 输出“first”
 System.out.println(mockedList.get(0));

 // 抛出异常
 System.out.println(mockedList.get(1));

 // 因为get(999) 没有打桩，因此输出null
 System.out.println(mockedList.get(999));

 //Although it is possible to verify a stubbed invocation, usually it's just redundant
 //尽管可以验证存根调用，但通常它只是多余的
 // 验证get(0)被调用的次数
 verify(mockedList).get(0);
```

* 默认情况下，所有的函数都有返回值。mock函数默认返回的是null，一个空的集合或者一个被对象类型包装的内置类型，例如0、false对应的对象类型为Integer、Boolean；
* 测试桩函数可以被覆写 : 例如常见的测试桩函数可以用于初始化mock对象，但是测试函数能够覆写它。请注意，覆写测试桩函数是一种可能存在潜在问题的做法；
* 一旦测试桩函数被调用，该函数将会一直返回固定的值，除非再该点再次埋入测试桩，才会改变它的行为。


<a name="3"></a>
### 3. 参数匹配器 (matchers)

Mockito以自然的java风格来验证参数值: 使用equals()函数。有时，当需要额外的灵活性时你可能需要使用参数匹配器:

```java
 // stubbing using built-in anyInt() argument matcher
 // 使用内置的anyInt()参数匹配器
 when(mockedList.get(anyInt())).thenReturn("element");

 //stubbing using custom matcher (let's say isValid() returns your own matcher implementation):
 // 使用自定义的参数匹配器( 在isValid()函数中返回你自己的匹配器实现 )
 when(mockedList.contains(argThat(isValid()))).thenReturn("element");

 // following prints "element"
 // 输出element
 System.out.println(mockedList.get(999));

 // you can also verify using an argument matcher
 // 你也可以验证参数匹配器
 verify(mockedList).get(anyInt());
```

参数匹配器使验证和测试桩变得更灵活。[点击这里](https://javadoc.io/static/org.mockito/mockito-core/3.6.0/org/mockito/Matchers.html)查看更多内置的匹配器以及自定义参数匹配器或者hamcrest 匹配器的示例。


如果仅仅是获取自定义参数匹配器的信息，查看[ArgumentMatcher类文档](http://site.mockito.org/mockito/docs/current/org/mockito/ArgumentMatcher.html)即可。

为了合理的使用复杂的参数匹配，使用equals()与anyX() 的匹配器会使得测试代码更简洁、简单。有时，会迫使你重构代码以使用equals()匹配或者实现equals()函数来帮助你进行测试。

同时建议你阅读[第15章节](#15)或者[ArgumentCaptor类文档](http://site.mockito.org/mockito/docs/current/org/mockito/ArgumentCaptor.html)。ArgumentCaptor是一个能够捕获参数值的特俗参数匹配器。

**参数匹配器的注意点** : 如果你使用参数匹配器,所有参数都必须由匹配器提供。

示例 : ( 该示例展示了如何多次应用于测试桩函数的验证 ) 

```java
verify(mock).someMethod(anyInt(), anyString(), eq("third argument"));
//above is correct - eq() is also an argument matcher
// 上述代码是正确的,因为eq()也是一个参数匹配器

verify(mock).someMethod(anyInt(), anyString(), "third argument");
//above is incorrect - exception will be thrown because third argument 
// 上述代码是错误的,因为所有参数必须由匹配器提供，而参数"third argument"并非由参数匹配器提供，因此的缘故会抛出异常
```

像`anyObject()`,` eq()`这样的匹配器函数不会返回匹配器。它们会在内部将匹配器记录到一个栈当中，并且返回一个假的值，通常为null。`这样的实现是由于被Java编译器强加的静态类型安全`。结果就是**匹配器函数不能在测试桩函数和验证函数之外使用**。

<a name="4"></a>
### 4. 验证函数调用的次数

```java
 //using mock
 mockedList.add("once");

 mockedList.add("twice");
 mockedList.add("twice");

 mockedList.add("three times");
 mockedList.add("three times");
 mockedList.add("three times");

 //following two verifications work exactly the same - times(1) is used by default
 // 下面的两个验证函数效果一样,因为verify默认验证的就是times(1)
 verify(mockedList).add("once");
 verify(mockedList, times(1)).add("once");

 //exact number of invocations verification
 // 验证具体的执行次数
 verify(mockedList, times(2)).add("twice");
 verify(mockedList, times(3)).add("three times");

 //verification using never(). never() is an alias to times(0)
 // 使用never()进行验证,never相当于times(0)
 verify(mockedList, never()).add("never happened");

 //verification using atLeast()/atMost()
 // 使用atLeast()/atMost()
 verify(mockedList, atLeastOnce()).add("three times");
 verify(mockedList, atLeast(2)).add("five times");
 verify(mockedList, atMost(5)).add("three times");

```

verify函数默认验证的是执行了times(1)，也就是某个测试函数是否执行了1次.因此，times(1)通常被省略了。

<a name="5"></a>
### 5. 为返回值为void的函数通过Stub抛出异常

没有返回值的方法在埋入测试桩时不能使用`when().thenThrow()`方式，而应采用下面这种方式：

```java
doThrow(new RuntimeException()).when(mockedList).clear();

//following throws RuntimeException:
// 调用这句代码会抛出异常
mockedList.clear();
```

关于doThrow|doAnswer 等函数族的信息请阅读第十二章节。

最初，[stubVoid(Object)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#stubVoid(T)) 函数用于为无返回值的函数打桩。现在`stubVoid()`函数已经过时,`doThrow(Throwable)`成为了它的继承者。这是为了提升与 `doAnswer(Answer) `函数族的可读性与一致性。


<a name="6"></a>
### 6. 验证执行执行顺序

```java
 // A. Single mock whose methods must be invoked in a particular order
 // A. 验证mock一个对象的函数执行顺序
 List singleMock = mock(List.class);

 //using a single mock
 singleMock.add("was added first");
 singleMock.add("was added second");

 //create an inOrder verifier for a single mock
 // 为该mock对象创建一个inOrder对象
 InOrder inOrder = inOrder(singleMock);

 //following will make sure that add is first called with "was added first, then with "was added second"
 // 确保add函数首先执行的是add("was added first"),然后才是add("was added second")
 inOrder.verify(singleMock).add("was added first");
 inOrder.verify(singleMock).add("was added second");

 // B. Multiple mocks that must be used in a particular order
 // B .验证多个mock对象的函数执行顺序
 List firstMock = mock(List.class);
 List secondMock = mock(List.class);

 //using mocks
 firstMock.add("was called first");
 secondMock.add("was called second");

 //create inOrder object passing any mocks that need to be verified in order
 // 为这两个Mock对象创建inOrder对象
 InOrder inOrder = inOrder(firstMock, secondMock);

 //following will make sure that firstMock was called before secondMock
 // 验证它们的执行顺序
 inOrder.verify(firstMock).add("was called first");
 inOrder.verify(secondMock).add("was called second");

 // Oh, and A + B can be mixed together at will
```

验证执行顺序是非常灵活的-你不需要一个一个的验证所有交互,只需要验证你感兴趣的对象即可。
另外，你可以仅通过那些需要验证顺序的mock对象来创建InOrder对象。


<a name="7"></a>
### 7. 验证mock对象从未发生交互动作

```java
 //using mocks - only mockOne is interacted
 // 使用Mock对象
 mockOne.add("one");

 //ordinary verification
 // 普通验证
 verify(mockOne).add("one");

 //verify that method was never called on a mock
 // 验证某个交互是否从未被执行
 verify(mockOne, never()).add("two");

 //verify that other mocks were not interacted
 // 验证mock对象没有交互过
 verifyZeroInteractions(mockTwo, mockThree);
```

<a name="8"></a>
### 8. 查找冗余的调用

```java
//using mocks
mockedList.add("one");
mockedList.add("two");

verify(mockedList).add("one");

//following verification will fail
// 下面的验证将会失败
verifyNoMoreInteractions(mockedList);
```

一些用户可能会在频繁地使用`verifyNoMoreInteractions()`，甚至在每个测试函数中都用。但是`verifyNoMoreInteractions()`并不建议在每个测试函数中都使用。`verifyNoMoreInteractions()`在交互测试套件中只是一个便利的验证，它的作用是当你需要验证是否存在冗余调用时。滥用它将导致测试代码的可维护性降低。你可以阅读[这篇文档](http://monkeyisland.pl/2008/07/12/should-i-worry-about-the-unexpected/)来了解更多相关信息。

`never()`是一种更为明显且易于理解的形式。

<a name="9"></a>

### 9. 简化mock对象的创建

* 最小化重复的创建代码
* 使测试类的代码可读性更高
* 使验证错误更易于阅读，因为字段名可用于标识mock对象

```java
public class ArticleManagerTest {

   @Mock private ArticleCalculator calculator;
   @Mock private ArticleDatabase database;
   @Mock private UserProvider userProvider;

   private ArticleManager manager;
```

注意！下面这句代码需要在运行测试函数之前被调用,一般放到测试类的基类或者test runner中:

```java
 MockitoAnnotations.openMocks(testClass);
```

<a name="10"></a>

### 10. 为连续的调用做测试桩 (stub)

有时我们需要为同一个函数调用的不同的返回值或异常做测试桩。典型的运用就是使用mock迭代器。
原始版本的Mockito并没有这个特性，例如，可以使用Iterable或者简单的集合来替换迭代器。这些方法提供了更自然的方式，在一些场景中为连续的调用做测试桩会很有用。示例如下 ： 

```java
 when(mock.someMethod("some arg"))
   .thenThrow(new RuntimeException())
   .thenReturn("foo");

 //First call: throws runtime exception:
 // 第一次调用 : 抛出运行时异常
 mock.someMethod("some arg");

 //Second call: prints "foo"
 // 第二次调用 : 输出"foo"
 System.out.println(mock.someMethod("some arg"));

 //Any consecutive call: prints "foo" as well (last stubbing wins).
 // 后续调用 : 也是输出"foo"
 System.out.println(mock.someMethod("some arg"));
```

另外，连续调用的另一种更简短的版本 : 

```java
// 第一次调用时返回"one",第二次返回"two",第三次返回"three"
 when(mock.someMethod("some arg"))
   .thenReturn("one", "two", "three");
```

<a name="11"></a>
### 11. 为回调做测试桩

允许为泛型接口Answer打桩。

在最初的Mockito里也没有这个具有争议性的特性。我们建议使用thenReturn() 或thenThrow()来打桩。这两种方法足够用于测试或者测试驱动开发。

```java
 when(mock.someMethod(anyString())).thenAnswer(new Answer() {
     Object answer(InvocationOnMock invocation) {
         Object[] args = invocation.getArguments();
         Object mock = invocation.getMock();
         return "called with arguments: " + args;
     }
 });

 //Following prints "called with arguments: foo"
 // 输出 : "called with arguments: foo"
 System.out.println(mock.someMethod("foo"));
```

<a name="12"></a>
### 12. doReturn()、doThrow()、doAnswer()、doNothing()、doCallRealMethod()系列方法的运用

通过`when(Object)`为无返回值的函数打桩有不同的方法,因为编译器不喜欢void函数在括号内...

使用`doThrow(Throwable)` 替换`stubVoid(Object)`来为void函数打桩是为了与`doAnswer()`等函数族保持一致性。

当你想为void函数打桩时使用含有一个exception 参数的`doAnswer()` : 

```java
doThrow(new RuntimeException()).when(mockedList).clear();

//following throws RuntimeException:
// 下面的代码会抛出异常
mockedList.clear();
```

当你调用`doThrow()`, `doAnswer()`, `doNothing()`, `doReturn()` and `doCallRealMethod()` 这些函数时可以在适当的位置调用`when()`函数. 当你需要下面这些功能时这是必须的: 

* 测试void函数
* 在受监控的对象上测试函数
* 同时测试多次方法，在测试过程中改变mock对象的行为。

但是在调用`when()`函数时你可以选择是否调用这些上述这些函数。

阅读更多关于这些方法的信息:

* [doReturn(Object)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doReturn(java.lang.Object)) 
* [doThrow(Throwable)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doThrow(java.lang.Throwable))
* [doThrow(Class)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doThrow(java.lang.Class))
* [doAnswer(Answer)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doAnswer(org.mockito.stubbing.Answer))
* [doNothing()](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doNothing())
* [doCallRealMethod()](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#doCallRealMethod())


<a name="13"></a>
### 13. 监控真实对象

你可以为真实对象创建一个监控(spy)对象。当你使用这个监控对象时真实的对象也会也调用，除非它的函数被埋入测试桩了。尽量少使用spy对象，使用时也需要小心形式，例如监控对象可以用来处理遗留代码。

监控一个真实的对象可以与“局部mock对象”概念结合起来。在1.8之前，mockito的监控功能并不是真正的局部mock对象。原因是我们认为局部mock对象的实现方式并不好，在某些时候我发现一些使用局部mock对象的合法用例。（第三方接口、临时重构遗留代码，完整的文章在[这里](http://monkeyisland.pl/2009/01/13/subclass-and-override-vs-partial-mocking-vs-refactoring/) ）

```java
List list = new LinkedList();
List spy = spy(list);

//optionally, you can stub out some methods:
// 你可以为某些函数打桩
when(spy.size()).thenReturn(100);

//using the spy calls *real* methods
// 通过spy对象调用真实对象的函数
spy.add("one");
spy.add("two");

//prints "one" - the first element of a list
// 输出第一个元素
System.out.println(spy.get(0));

//size() method was stubbed - 100 is printed
// 因为size()函数被打桩了,因此这里返回的是100
System.out.println(spy.size());

//optionally, you can verify
// 交互验证
verify(spy).add("one");
verify(spy).add("two");
```

理解监控真实对象非常重要！

有时，在监控对象上使用`when(Object)`来进行打桩是不可能或者不切实际的。因此，当使用监控对象时请考虑`doReturn|Answer|Throw()`函数族来进行打桩。例如 : 

```java
List list = new LinkedList();
List spy = spy(list);

//Impossible: real method is called so spy.get(0) throws IndexOutOfBoundsException (the list is yet empty)
// 不可能 : 因为当调用spy.get(0)时会调用真实对象的get(0)函数,此时会发生IndexOutOfBoundsException异常，因为真实List对象是空的
when(spy.get(0)).thenReturn("foo");

//You have to use doReturn() for stubbing
// 你需要使用doReturn()来打桩
doReturn("foo").when(spy).get(0);
```

Mockito并不会为真实对象代理函数调用，实际上它会拷贝真实对象。因此如果你保留了真实对象并且与之交互，不要期望从监控对象得到正确的结果。当你在监控对象上调用一个没有被stub的函数时并不会调用真实对象的对应函数，你不会在真实对象上看到任何效果。

因此结论就是 : 当你在监控一个真实对象时，你想在stub这个真实对象的函数，那么就是在自找麻烦。或者你根本不应该验证这些函数。

<a name="14"></a>
### 14. 修改没有测试桩的调用的默认返回值 ( 1.7版本之后 ) 

你可以指定策略来创建mock对象的返回值。这是一个高级特性，通常来说，你不需要写这样的测试。然后，它对于遗留系统来说是很有用处的。当你不需要为函数调用打桩时你可以指定一个默认的answer。

```java
Foo mock = mock(Foo.class, Mockito.RETURNS_SMART_NULLS);
Foo mockTwo = mock(Foo.class, new YourOwnAnswer());
```

关于RETURNS_SMART_NULLS更多的信息请查看 : 
[RETURNS_SMART_NULLS文档](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#RETURNS_SMART_NULLS) 。

<a name="15"></a>
### 15. 为下一步的断言捕获参数 (1.8版本之后)

Mockito以java代码风格的形式来验证参数值 : 即通过使用`equals()`函数。这也是我们推荐用于参数匹配的方式，因为这样会使得测试代码更简单、简洁。在某些情况下，当验证交互之后要检测真实的参数值时这将变得有用。例如 ： 

```java
ArgumentCaptor<Person> argument = ArgumentCaptor.forClass(Person.class);
// 参数捕获
verify(mock).doSomething(argument.capture());
// 使用equal断言
assertEquals("John", argument.getValue().getName());
```

警告 : 我们建议使用没有测试桩的ArgumentCaptor来验证，因为使用含有测试桩的ArgumentCaptor会降低测试代码的可读性，因为captor是在断言代码块之外创建的。另一个好处是它可以降低本地化的缺点，因为如果测试桩函数没有被调用，那么参数就不会被捕获。总之，ArgumentCaptor与自定义的参数匹配器相关(可以查看[ArgumentMatcher类的文档](ArgumentMatcher) )。这两种技术都能用于检测外部传递到Mock对象的参数。然而，使用ArgumentCaptor在以下的情况下更合适 : 

* 自定义不能被重用的参数匹配器
* 你仅需要断言参数值

自定义参数匹配器相关的资料你可以参考[ArgumentMatcher](ArgumentMatcher)文档。

[ArgumentMatcher]: http://site.mockito.org/mockito/docs/current/org/mockito/ArgumentMatcher.html

### 16. 真实的局部mocks (1.8版本之后)<a name="16"></a>

在内部通过邮件进行了无数争辩和讨论后，最终 Mockito 决定支持部分测试，早前我们不支持是因为我们认为部分测试会让代码变得糟糕。然而，我们发现了部分测试真正合理的用法。[详情点这](http://monkeyisland.pl/2009/01/13/subclass-and-override-vs-partial-mocking-vs-refactoring/)

在 Mockito 1.8 之前，spy() 方法并不会产生真正的部分测试，而这无疑会让一些开发者困惑。更详细的内容可以看：[这里](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#13) 或 [Java 文档](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#spy(T))

```java
    //you can create partial mock with spy() method:
    List list = spy(new LinkedList());

    //you can enable partial mock capabilities selectively on mocks:
    Foo mock = mock(Foo.class);
    //Be sure the real implementation is 'safe'.
    //If real implementation throws exceptions or depends on specific state of the object then you're in trouble.
    when(mock.someMethod()).thenCallRealMethod();
```

一如既往，你会去读部分测试的警告部分：面向对象编程通过将抽象的复杂度拆分为一个个独立，精确的 SRPy 对象中，降低了抽象处理的复杂度。那部分测试是怎么遵循这个规范的呢？事实上部分测试并没有遵循这个规范……部分测试通常意味着抽象的复杂度被移动到同一个对象的不同方法中，在大多数情况下，这不会是你想要的应用架构方式。

然而，在一些罕见的情况下部分测试才会是易用的：处理不能轻易修改的代码（第三方接口，临时重构的遗留代码等等）。然而，为了新的，测试驱动和架构优秀的代码，我是不会使用部分测试的。

### 17. 重置mocks对象 (1.8版本之后)<a name="17"></a>

聪明的 Mockito 使用者很少会用到这个特性，因为他们知道这是出现糟糕测试单元的信号。通常情况下你不会需要重设你的测试单元，只需要为每一个测试方法重新创建一个测试单元就可以了。

如果你真的想通过 reset() 方法满足某些需求的话，请考虑实现简单，小而且专注于测试方法而不是冗长，精确的测试。首先可能出现的代码异味就是测试方法中间那的 reset() 方法。这可能意味着你已经过度测试了。请遵循测试方法的呢喃：请让我们小，而且专注于单一的行为上。在 Mockito 邮件列表中就有好几个讨论是和这个有关的。

添加 reset() 方法的唯一原因就是让它能与容器注入的测试单元协作。详情看 [issue 55](http://code.google.com/p/mockito/issues/detail?id=55) 或 [FAQ](http://code.google.com/p/mockito/wiki/FAQ)。

别自己给自己找麻烦，reset() 方法在测试方法的中间确实是代码异味。


```java
   List mock = mock(List.class);
   when(mock.size()).thenReturn(10);
   mock.add(1);

   reset(mock);
   //at this point the mock forgot any interactions & stubbing
```

### 18. 故障排查与验证框架的使用 (1.8版本之后)<a name="18"></a>

首先，如果出现了任何问题，我建议你先看 [Mockito FAQ](http://code.google.com/p/mockito/wiki/FAQ)。

任何你提的问题都会被提交到 Mockito 的[邮件列表](http://groups.google.com/group/mockito)中。

然后你应该知道 Mockito 会验证你是否始终以正确的方式使用它，对此有疑惑的话不妨看看 [validateMockitoUsage()](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#validateMockitoUsage()) 的文档说明。

### 19. 行为驱动开发的别名 (1.8版本之后)<a name="19"></a>

行为驱动开发实现测试单元的模式将 //given //when //then comments 视作测试方法的基础，这也是我们实现单元测试时被建议做的！

[你可以在这开始学习有关 BDD 的知识](http://en.wikipedia.org/wiki/Behavior_Driven_Development)

问题是当信息没有很好地与 //given //when //then comments 交互时，扮演规范角色的测试桩 API 就会出现问题。这是因为测试桩属于给定测试单元的组件，而且不是任何测试的组件。因此 [BDDMockito](http://site.mockito.org/mockito/docs/current/org/mockito/BDDMockito.html) 类介绍了一个别名，使你的测试桩方法调用 [BDDMockito.given(Object)](http://site.mockito.org/mockito/docs/current/org/mockito/BDDMockito.html#given(T)) 方法。现在它可以很好地和给定的 BDD 模式的测试单元组件进行交互。

```java
 import static org.mockito.BDDMockito.*;

 Seller seller = mock(Seller.class);
 Shop shop = new Shop(seller);

 public void shouldBuyBread() throws Exception {
   //given
   given(seller.askForBread()).willReturn(new Bread());

   //when
   Goods goods = shop.buyBread();

   //then
   assertThat(goods, containBread());
 }
```

### 20. 序列化mock对象<a name="20"></a>

模拟对象可以被序列化。有了这个特性你就可以在依赖被序列化的情况下使用模拟对象了。

警告：这个特性很少在单元测试中被使用。


To create serializable mock use [MockSettings.serializable()](http://site.mockito.org/mockito/docs/current/org/mockito/MockSettings.html#serializable()):

这个特性通过 BDD 拥有不可考外部依赖的特性的具体用例实现，来自外部依赖的 Web 环境和对象会被序列化，然后在不同层之间被传递。

```java
   List serializableMock = mock(List.class, withSettings().serializable());
```

The mock can be serialized assuming all the normal [serialization requirements](http://java.sun.com/j2se/1.5.0/docs/api/java/io/Serializable.html) are met by the class.

模拟对象能被序列化假设所有普通的序列化要求都被类满足了。

让一个真实的侦查对象可序列化需要多一些努力，因为 spy(...) 方法没有接收 MockSettings 的重载版本。不过不用担心，你几乎不可能用到这。

```java
 List<Object> list = new ArrayList<Object>();
 List<Object> spy = mock(ArrayList.class, withSettings()
                 .spiedInstance(list)
                 .defaultAnswer(CALLS_REAL_METHODS)
                 .serializable());
```

### 21. 新的注解 : @Captor,@Spy,@InjectMocks (1.8.3版本之后)<a name="21"></a>

V1.8.3 带来的新注解在某些场景下可能会很实用

@[Captor](http://site.mockito.org/mockito/docs/current/org/mockito/Captor.html) 简化 [ArgumentCaptor](http://site.mockito.org/mockito/docs/current/org/mockito/ArgumentCaptor.html) 的创建 - 当需要捕获的参数是一个令人讨厌的通用类，而且你想避免编译时警告。

@[Spy](http://site.mockito.org/mockito/docs/current/org/mockito/Spy.html) - 你可以用它代替 [spy(Object) 方法](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#spy(T))

@[InjectMocks](http://site.mockito.org/mockito/docs/current/org/mockito/InjectMocks.html) - 自动将模拟对象或侦查域注入到被测试对象中。需要注意的是 @InjectMocks 也能与 @Spy 一起使用，这就意味着 Mockito 会注入模拟对象到测试的部分测试中。它的复杂度也是你应该使用部分测试原因。

所有新的注解仅仅在 [MockitoAnnotations.initMocks(Object)](http://site.mockito.org/mockito/docs/current/org/mockito/MockitoAnnotations.html#initMocks(java.lang.Object)) 方法中被处理，就像你在 built-in runner 中使用的 @[Mock](http://site.mockito.org/mockito/docs/current/org/mockito/Mock.html) 注解：[MockitoJUnitRunner](http://site.mockito.org/mockito/docs/current/org/mockito/runners/MockitoJUnitRunner.html) 或 规范: [MockitoRule](http://site.mockito.org/mockito/docs/current/org/mockito/junit/MockitoRule.html).

### 22. 验证超时 (1.8.5版本之后)<a name="22"></a>

允许带有暂停的验证。这使得一个验证去等待一段特定的时间，以获得想要的交互而不是如果还没有发生事件就带来的立即失败。在并发条件下的测试这会很有用。

感觉起来这个特性应该很少被使用 - 指出更好的测试多线程系统的方法。

还没有实现去和 InOrder 验证协作。

例子：

```java
   //passes when someMethod() is called within given time span
   verify(mock, timeout(100)).someMethod();
   //above is an alias to:
   verify(mock, timeout(100).times(1)).someMethod();

   //passes when someMethod() is called *exactly* 2 times within given time span
   verify(mock, timeout(100).times(2)).someMethod();

   //passes when someMethod() is called *at least* 2 times within given time span
   verify(mock, timeout(100).atLeast(2)).someMethod();

   //verifies someMethod() within given time span using given verification mode
   //useful only if you have your own custom verification modes.
   verify(mock, new Timeout(100, yourOwnVerificationMode)).someMethod();
```

### 23. 自动初始化被@Spies, @InjectMocks注解的字段以及构造函数注入 (1.9.0版本之后)<a name="23"></a>

Mockito 现在会通过注入构造方法、setter 或域注入尽可能初始化带有 @[Spy](http://site.mockito.org/mockito/docs/current/org/mockito/Spy.html) 和 @[InjectMocks](http://site.mockito.org/mockito/docs/current/org/mockito/InjectMocks.html) 注解的域或方法。

为了利用这一点特性，你需要使用 [MockitoAnnotations.initMocks(Object)](http://site.mockito.org/mockito/docs/current/org/mockito/MockitoAnnotations.html#initMocks(java.lang.Object)), [MockitoJUnitRunner](http://site.mockito.org/mockito/docs/current/org/mockito/runners/MockitoJUnitRunner.html) 或 [MockitoRule](http://site.mockito.org/mockito/docs/current/org/mockito/junit/MockitoRule.html)。

为了 InjectMocks 请在 Java 文档中了解更多可用的技巧和注入的规范

```java
 //instead:
 @Spy BeerDrinker drinker = new BeerDrinker();
 //you can write:
 @Spy BeerDrinker drinker;

 //same applies to @InjectMocks annotation:
 @InjectMocks LocalPub;
```

### 24. 单行测试桩 (1.9.0版本之后)<a name="24"></a>

Mockito 现在允许你在使用测试桩时创建模拟对象。基本上，它允许在一行代码中创建一个测试桩，这对保持代码的整洁很有用。举例来说，有些乏味的测试桩会被创建，并在测试初始化域时被打入，例如：

```java
 public class CarTest {
   Car boringStubbedCar = when(mock(Car.class).shiftGear()).thenThrow(EngineNotStarted.class).getMock();

   @Test public void should... {}
```

### 25. 验证被忽略的测试桩 (1.9.0版本之后)<a name="25"></a>

Mockito 现在允许为了验证无视测试桩。在与 verifyNoMoreInteractions() 方法或验证 inOrder() 方法耦合时，有些时候会很有用。帮助避免繁琐的打入测试桩调用验证 - 显然我们不会对验证测试桩感兴趣。

警告，ignoreStubs() 可能会导致 verifyNoMoreInteractions(ignoreStubs(...)) 的过度使用。谨记在心，Mockito 没有推荐用 [verifyNoMoreInteractions()](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#verifyNoMoreInteractions(java.lang.Object...)) 方法连续地施用于每一个测试中，原因在 Java 文档中有。

一些例子：

```java
 verify(mock).foo();
 verify(mockTwo).bar();

 //ignores all stubbed methods:
 verifyNoMoreInvocations(ignoreStubs(mock, mockTwo));

 //creates InOrder that will ignore stubbed
 InOrder inOrder = inOrder(ignoreStubs(mock, mockTwo));
 inOrder.verify(mock).foo();
 inOrder.verify(mockTwo).bar();
 inOrder.verifyNoMoreInteractions();
```

更好的例子和更多的细节都可以在 Java 文档的 [ignoreStubs(Object...)](http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#ignoreStubs(java.lang.Object...)) 部分看到。

### 26. mock详情 (1.9.5版本之后)<a name="26"></a>

为了区别一个对象是模拟对象还是侦查对象：

```java
     Mockito.mockingDetails(someObject).isMock();
     Mockito.mockingDetails(someObject).isSpy();
```

[MockingDetails.isMock()](http://site.mockito.org/mockito/docs/current/org/mockito/MockingDetails.html#isMock()) 和 [MockingDetails.isSpy()](http://site.mockito.org/mockito/docs/current/org/mockito/MockingDetails.html#isSpy()) 方法都会返回一个布尔值。因为一个侦查对象只是模拟对象的一种变种，所以 isMock() 方法在对象是侦查对象是会返回 true。在之后的 Mockito 版本中 MockingDetails 会变得更健壮，并提供其他与模拟对象相关的有用信息，例如：调用，测试桩信息，等等……

### 27.委托调用真实实例<a name="27"></a>

当**使用常规的 spy API 去 mock 或者 spy 一个对象很困难**时可以用 delegate 来 spy 或者 mock 对象的某一部分。
从 Mockito 的 1.10.11 版本开始， delegate 有可能和 mock 的类型相同也可能不同。如果不是同一类型，
delegate 类型需要提供一个匹配方法否则就会抛出一个异常。下面是关于这个特性的一些用例:

- 带有 interface 的 final 类
- 已经自定义代理的对象
- 带有 finalize 方法的特殊对象，就是避免重复执行。

和常规 spy 的不同:

- 标准的 spy [(spy(Object))][spy] 包含被 spy 实例的所有状态信息，方法在 spy 对象上被调用。被 spy 的对象只在 mock
创建时被用来拷贝状态信息。如果你通过标准 spy 调用一个方法，这个 spy 会调用其内部的其他方法记录这次操作，
以便后面验证使用。等效于存根 (stubbed)操作。

- mock delegates 只是简单的把所有方法委托给 delegate。delegate 一直被当成它代理的方法使用。如果你
从一个 mock 调用它被委托的方法，它会调用其内部方法，这些调用不会被记录，stubbing 在这里也不会生效。
Mock 的 delegates 相对于标准的 spy 来说功能弱了很多，不过在标准 spy 不能被创建的时候很有用。

更多信息可以看这里 [AdditionalAnswers.delegatesTo(Object)][AdditionalAnswers].

[delegating_call_to_real_instance]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#delegating_call_to_real_instance
[spy]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#spy(T)
[AdditionalAnswers]:http://site.mockito.org/mockito/docs/current/org/mockito/AdditionalAnswers.html#delegatesTo(java.lang.Object)

---

### 28. MockMaker API <a name="28"></a>

为了满足用户的需求和 Android 平台使用。Mockito 现在提供一个扩展点，允许替换代理生成引擎。默认情况下，Mockito 使用 cglib 创建动态代理。

这个扩展点是为想要扩展 Mockito 功能的高级用户准备的。比如，我们现在就可以在 dexmaker 的帮助下使用 Mockito
测试 Android。

更多的细节，原因和示例请看 [MockMaker][MockMaker] 的文档。


[mock_maker_plugin]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#mock_maker_plugin
[MockMaker]:http://site.mockito.org/mockito/docs/current/org/mockito/plugins/MockMaker.html

---

### 29. (new) BDD 风格的验证)<a name="29"></a>

开启 Behavior Driven Development (BDD) 风格的验证可以通过 BBD 的关键词 **then** 开始验证。

```java
 given(dog.bark()).willReturn(2);

 // when
 ...

 then(person).should(times(2)).ride(bike);

```

更多信息请查阅 [ BDDMockito.then(Object)][then] .


[BDD_behavior_verification]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#BDD_behavior_verification
[then]:http://site.mockito.org/mockito/docs/current/org/mockito/BDDMockito.html#then(T)

---

### 30. (new) Spying 或 mocking 抽象类<a name="30"></a>

现在可以方便的 spy 一个抽象类。注意，过度使用 spy 或许意味着代码的设计上有问题。(see [spy(Object)][spy]).

之前，spying 只可以用在实例对象上。而现在新的 API 可以在创建一个 mock 实例时使用构造函数。这对 mock
一个抽象类来说是很重要的，这样使用者就不必再提供一个抽象类的实例了。目前的话只支持无参构造函数，
如果你认为这样还不够的话欢迎向我们反馈。

```java
//convenience API, new overloaded spy() method:
 SomeAbstract spy = spy(SomeAbstract.class);

 //Robust API, via settings builder:
 OtherAbstract spy = mock(OtherAbstract.class, withSettings()
    .useConstructor().defaultAnswer(CALLS_REAL_METHODS));

 //Mocking a non-static inner abstract class:
 InnerAbstract spy = mock(InnerAbstract.class, withSettings()
    .useConstructor().outerInstance(outerInstance).defaultAnswer(CALLS_REAL_METHODS));

```

更多信息请见 [MockSettings.useConstructor()][useConstructor] .

[spying_abstract_classes]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#spying_abstract_classes
[useConstructor]:http://site.mockito.org/mockito/docs/current/org/mockito/MockSettings.html#useConstructor()

---

### 31. (new) Mockito mocks 可以通过 classloaders 序列化/反序列化<a name="31"></a>

 Mockito 通过 classloader 引入序列化。和其他形式的序列化一样，所有 mock 层的对象都要被序列化，
 包括 answers。因为序列化模式需要大量的工作，所以这是一个可选择设置。

 ```java
 // 常规的 serialization
 mock(Book.class, withSettings().serializable());

 // 通过 classloaders 序列化
 mock(Book.class, withSettings().serializable(ACROSS_CLASSLOADERS));
 ```

更多信息请查看 [MockSettings.serializable(SerializableMode)][serializable].


[serilization_across_classloader]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#serilization_across_classloader
[serializable]:http://site.mockito.org/mockito/docs/current/org/mockito/MockSettings.html#serializable(org.mockito.mock.SerializableMode)

---

### 32. (new) Deep stubs 更好的泛型支持<a name="32"></a>

 Deep stubbing 现在可以更好的查找类的泛型信息。这就意味着像这样的类
 不必去 mock 它的行为就可以使用。

```java
class Lines extends List<Line> {
     // ...
 }

 lines = mock(Lines.class, RETURNS_DEEP_STUBS);

 // Now Mockito understand this is not an Object but a Line
 Line line = lines.iterator().next();

```

请注意，大多数情况下 mock 返回一个 mock 对象是错误的。

[better_generic_support_with_deep_stubs]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#better_generic_support_with_deep_stubs

---

### 33. (new) Mockito Junit rule<a name="33"></a>


Mockito 现在提供一个 JUnit rule。目前为止，有两种方法可以初始化 fields ，使用 Mockito 提供的注解比如
[@Mock][Mock_], [@Spy][Spy_], [@InjectMocks][InjectMocks_] 等等。

- 用 @RunWith([@MockitoJUnitRunner.class][MockitoJUnitRunner]) 标注 JUnit 测试类
- 在 @Before 之前调用 [MockitoAnnotations.initMocks(Object)][initMocks]

现在你可以选择使用一个 rule:

```java
 @RunWith(YetAnotherRunner.class)
 public class TheTest {
     @Rule public MockitoRule mockito = MockitoJUnit.rule();
     // ...
 }
```

更多信息到这里查看 [MockitoJUnit.rule()][rule].

[mockito_junit_rule]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#mockito_junit_rule
[Mock_]:http://site.mockito.org/mockito/docs/current/org/mockito/Mock.html
[Spy_]:http://site.mockito.org/mockito/docs/current/org/mockito/Spy.html
[InjectMocks_]:http://site.mockito.org/mockito/docs/current/org/mockito/InjectMocks.html
[MockitoJUnitRunner]:http://site.mockito.org/mockito/docs/current/org/mockito/runners/MockitoJUnitRunner.html
[initMocks]:http://site.mockito.org/mockito/docs/current/org/mockito/MockitoAnnotations.html#initMocks(java.lang.Object)

[rule]:http://site.mockito.org/mockito/docs/current/org/mockito/junit/MockitoJUnit.html#rule()

---

### 34. (new) 开启和关闭 plugins<a name="34"></a>

这是一个测试特性，可以控制一个 mockito-plugin 开启或者关闭。详情请查看 [PluginSwitch][PluginSwitch]

[plugin_switch]:http://site.mockito.org/mockito/docs/current/org/mockito/Mockito.html#plugin_switch
[PluginSwitch]:http://site.mockito.org/mockito/docs/current/org/mockito/plugins/PluginSwitch.html

---

### 35. 自定义验证失败信息 (Since 2.0.0)<a name="35"></a>

允许声明一个在验证失败时输出的自定义消息
示例:

```java
 // will print a custom message on verification failure
 verify(mock, description("This will print on failure")).someMethod();

 // will work with any verification mode
 verify(mock, times(2).description("someMethod should be called twice")).someMethod();
```