# JS中Call方法调用

this总是指向调用某个方法的对象，但是使用call()和apply()方法时，就会改变this的指向。

```js
let student  = {
    name: '张三',
    age: 16
}
function getInfo(){
    console.info(this.name);
    console.info(this.age);
}

getInfo();//由于此时this指针是指向window对象的，而window对象没有name和age属性，所以会输出undefiend
getInfo.call(student);
```

我们可以理解让`student`对象去调用getInfo方法，然后this指针就指向了`student`对象。

call方法和apply都能改变函数的this指针，他们唯一的区别是当它们需要为函数传递参数call允许传递多个参数，而apply是以数组的形式传递。

```js
function getInfo(a,b){
    console.info(this.name);
    console.info(this.age);
    console.info(a);
    console.info(b);
}

getInfo.apply(student,["123","456"]);
getInfo.call(student,"123","456");
```

