# let和const关键字

## 一. let <a name="let/var"> </a>

事实上var的设计可以看成JavaScript语言设计上的错误。但是为了向后兼容这些错误不能被修复。于是var关键字的替代者：

- **var属于ES5规范，let属于ES6规范**
- **let变量不能重复声明**
- **var有预处理机制，let没有。预处理机制也就是常说的声明提前**。
  - **声明提前：**不管变量被声明在函数什么位置，所有变量声明都会被提升至函数顶部（变量声明指 var a; 即声明还未赋值）比如声明变量**a**并赋值为**1**，即 **var a = 1;**  则 **var a;**会被提升至函数顶部 （只是a被提前，a的值1不会被提前）

下面立即函数执行后，控制台不会打印出**1**，而是**undefined**，因为只有声明被提前，值没有

```javascript
<script>
    (function() {
        console.log(a);
        var a = 1;
    })()
</script>
```

下面立即执行函数执行后，控制台不会打印出**1**和**undefined**，而是报错，因为let声明的变量不会被提前

```javascript
<script>
    (function() {
        console.log(a);
        let a = 1;
    })()
</script>
```

- **作用域的不同，var是全局作用域，let是块级作用域**。

下面代码控制台会打印出1　

```javascript
<script>    
     if(true) {
         var a = 1;
     }
     console.log(a);
 </script>
```

下面代码控制台不会打印出1，会报错，提示a没有定义（let定义的变量只在{}里才能访问到）

```javascript
<script>
    if(true) {
        var let = 1;
    }
    console.log(a);
</script>
```

**前方高能**，没有块级作用域会造成的后果：

我们尝试创建三个按钮，然后通过循环给这些按钮加上点击事件，试图在点击“按钮一”时打印“第1个按钮被点击了”，但是我们使用var这个关键字进行循环绑定事件，最终会发现三个按钮全部都是打印的是"第3个..."，这就是因为var关键字这个变量没有块作用域，事件绑定的三个函数实际上都是应用的for循环中的i，但是等创建绑定完成后i已经变成了3了。

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <button>按钮1</button>
    <button>按钮2</button>
    <button>按钮3</button>
</body>
<script>
    let buttons = document.getElementsByTagName("button");
    for (var i = 0; i < buttons.length; i++) {
        buttons[i].addEventListener('click',function () {
            alert("第"+i+"个按钮被点击了");
        })
    }
</script>
</html>
```

此时如果我们将for循环中的var改为let就可以恢复正常了。

## 二. const<a name="const"> </a>

const用于定义常量：

- const创建常量时必须初始化。

- 初始化后的常量不可修改，如果该常量是一个对象，那这个对象内部的属性可以修改。

- const拥有块级作用域

  ```js
  function fun(){
      const xx = "qwe";
  }
  console.info(xx);//报错
  ```