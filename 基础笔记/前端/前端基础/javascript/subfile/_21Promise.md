# Promise

> 本文转载至：<https://www.liaoxuefeng.com/wiki/1022910821149312/1023024413276544>

在JavaScript的世界中，所有代码都是单线程执行的。

由于这个“缺陷”，导致JavaScript的所有网络操作，浏览器事件，都必须是异步执行。异步执行可以用回调函数实现：

```js
function callback() {
    console.log('Done');
}
console.log('before setTimeout()');
setTimeout(callback, 1000); // 1秒钟后调用callback函数
console.log('after setTimeout()');
```

观察上述代码执行，在Chrome的控制台输出可以看到：

```
before setTimeout()
after setTimeout()
(等待1秒后)
Done
```

可见，异步操作会在将来的某个时间点触发一个函数调用。

AJAX就是典型的异步操作。以上一节的代码为例：

```js
request.onreadystatechange = function () {
    if (request.readyState === 4) {
        if (request.status === 200) {
            return success(request.responseText);
        } else {
            return fail(request.status);
        }
    }
}
```

把回调函数`success(request.responseText)`和`fail(request.status)`写到一个AJAX操作里很正常，但是不好看，而且不利于代码复用。

有没有更好的写法？比如写成这样：

```js
var ajax = ajaxGet('http://...');
ajax.ifSuccess(success)
    .ifFail(fail);
```

这种链式写法的好处在于，先统一执行AJAX逻辑，不关心如何处理结果，然后，根据结果是成功还是失败，在将来的某个时候调用`success`函数或`fail`函数。

古人云：“君子一诺千金”，这种“承诺将来会执行”的对象在JavaScript中称为Promise对象。

**Promise是ES6引入的异步编程的新解决方案。语法上Promise是一个构造函数，用来封装异步操作并可以获取其成功或失败的结果**。

Promise有各种开源实现，在ES6中被统一规范，由浏览器直接支持。我们先看一个最简单的Promise例子：生成一个0-2之间的随机数，如果小于1，则等待一段时间后返回成功，否则返回失败：

```js
function test(resolve, reject) {
    var timeOut = Math.random() * 2;
    console.log('set timeout to: ' + timeOut + ' seconds.');
    setTimeout(function () {
        if (timeOut < 1) {
            log('call resolve()...');
            resolve('200 OK');
        }
        else {
            log('call reject()...');
            reject('timeout in ' + timeOut + ' seconds.');
        }
    }, timeOut * 1000);
}
```

这个`test()`函数有两个参数，这两个参数都是函数，如果执行成功，我们将调用`resolve('200 OK')`，如果执行失败，我们将调用`reject('timeout in ' + timeOut + ' seconds.')`。可以看出，`test()`函数只关心自身的逻辑，并不关心具体的`resolve`和`reject`将如何处理结果。

有了执行函数，我们就可以用一个Promise对象来执行它，并在将来某个时刻获得成功或失败的结果：

```js
var p1 = new Promise(test);
var p2 = p1.then(function (result) {
    console.log('成功：' + result);
});
var p3 = p2.catch(function (reason) {
    console.log('失败：' + reason);
});
```

Promise对象可以串联起来，所以上述代码可以简化为：

```js
new Promise(test).then(function (result) {
    console.log('成功：' + result);
}).catch(function (reason) {
    console.log('失败：' + reason);
});
```

需要注意的是，成功方法不仅可以使用then-catch分开写，还可以写在一起：

```js
//第一个参数是成功时调用的函数，第二个参数是失败时调用的函数 
var p2 = p1.then(result=> {
    console.log('成功：' + result);
  },reason=>{
    console.log('失败' + reason);
  });
```

实际上catch方法就是一个语法糖，它就是调用then方法，然后第一个参数传null。

then()方法会返回一个**新**的Promise实例，所以then()方法后面可以继续跟另一个then()方法进行链式调用。

```js
let p = new Promise((resolve, reject) => {
    setTimeout(resolve, 1000, 'success');
});
p.then(
    res => {
        console.log(res);
        return `${res} again`;
    }
).then(
    res => console.log(res)
);
```

实际上我们使用return直接返回结果，实际上返回的是一个Promise实例，是下面这种方式的简写：

```js
return Promise.resolve(`${res} again`);
```

而这种方式又是下面的简写：

```js
return new Promise(resolve => {
    return `${res} again`;
})
```



