# URL hash和HTML5 history

由于Vue项目的最佳实践是SPA（单页面复应用），而如何做到改变URL但是页面不刷新就成了问题的关键了。而常见的方式分为URL hash和HTML5 history两种方式：

## 一. URL hash

URL hash实际上在页面中我们通常会以锚点的形式运用它，但是SPA中我们可利用通过hash方式改变URL但不刷新页面：

```js
location.hash = 'foo'
//它会将路径更改为：http://localhost:8080/#/foo

location.hash  = 'haha/aaa'
//它会将路径更改为：http://localhost:8080/#/haha/aaa
```

使用这种方式貌似已经解决了页面不刷新的问题，但是通过hash改变的URL都会带有一个`#`号，这就不像一个传统的URL了。

## 二. HTML5 History

我们还可以利用H5的History特性来实现改变URL但页面不刷新的目的：

```js
location.href
>>> http://localhost:8080

history.pushState({},'','foo')
>>> http://localhost:8080/foo

history.pushState({},'','about')
>>> http://localhost:8080/about

history.pushState({},'','bar')
>>> http://localhost:8080/bar

history.replaceState({},'','/about')//替换栈顶元素，pushState是压栈操作，浏览器可以通过回退键回退到上一个URL

history.back()
>>> http://localhost:8080/about

history.back()
```

实际上history底层数据结构是一个栈，URL始终显示的是栈顶元素，当我们压入一个新的元素进栈自然就改变了URL。