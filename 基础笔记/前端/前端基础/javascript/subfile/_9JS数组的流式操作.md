# JS数组的流式操作

- [filter](#filter)
- [reduce](#reduce)
- [map](#map)

JavaScript也有类似于Java中的Stream的操作方式，JS中的数组拥有filter、reduce、map三个函数可以实现对数组的操作。

## 一. filter<a name="filter"> </a>

filter用于过滤元素，内部传入一个函数，该函数需要返回一个boolean类型的值，true代表生成的新数组中保留当前这个元素，false代表剔除这个元素。

```javascript
let books = [
  {
    id: 1,
    name: '《算法导论》',
    date: '2006-9',
    price: 85.00,
    count: 1
  },
  {
    id: 2,
    name: '《UNIX编程艺术》',
    date: '2006-2',
    price: 59.00,
    count: 1
  },
  {
    id: 3,
    name: '《编程珠玑》',
    date: '2008-10',
    price: 39.00,
    count: 1
  },
  {
    id: 4,
    name: '《代码大全》',
    date: '2006-3',
    price: 128.00,
    count: 1
  }
]
books = books.filter(value => {
  return value.price > 100;
})
```

## 二. reduce<a name="reduce"> </a>

reduce函数对数组元素进行汇总。该函数传入两个参数：

- 第一个参数：是一个函数，函数拥有三个参数`reduce(previousValue,currentValue,currentIndex)`：
  - previousValue：上一次函数返回的值
  - currentValue：当前遍历的元素
  - currentIndex：当前遍历的索引
- 第二个参数：初始化值，也就是第一次调用参数一那个函数时传到previousValue的值。

```java
//求所有书籍的价钱总和
let totalPrice = books.reduce((previousValue, currentValue, currentIndex) => {
  return previousValue + currentValue.price;
}, 0);
```

## 三. map<a name="map"> </a>

map函数表示映射，就是将原数组中的每一个元素映射成另一种类型的对象。map函数传入一个函数，函数拥有一个入参，返回值类型是任意的，返回的元素将组成新的数组。

```javascript
//取出books中每一个book对象的name属性，组成一个新数组
let bookNames = books.map(value => {
  return value.name;
})
```

