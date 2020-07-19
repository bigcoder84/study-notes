# 对数组进行赋值Vue无法响应

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <script src="js/vue.js" type="text/javascript" charset="UTF-8"></script>
</head>
<body>
<div id="app">

  <h3>学生列表</h3>
  <ul>
    <li v-for="(item,key) in items">
      <h4>{{item.name}}</h4>
      <p>{{item.age}}</p>
    </li>
  </ul>
  <button @click="changeButton">直接赋值操作</button>
  <button @click="changeButton2">通过数组内置方法操作</button>
</div>
<script type="text/javascript">
  let count = 1;
  let vue = new Vue({
    el: "#app",
    data: {
      items: [
        {
          name: "张三",
          age: 12
        },
        {
          name: "张三",
          age: 12
        },
        {
          name: "张三",
          age: 12
        }
      ]
    },
    methods: {
      changeButton() {
        count++;
        this.items[0] = {
          name: '张三' + count,
          age: count
        }
      },
      changeButton2() {
        count++;
        this.items.splice(0,1,{
          name: '张三' + count,
          age: count
        })
      }
    }
  });
</script>
</body>
</html>
```

在上面代码中`changeButton`事件是直接修改数组的某一个值，但是我们在触发这个事件后发现页面上与这个数组元素绑定的显示并没有发生改变。

这是因为Vue并没有监听我们对数组元素的直接修改，我们需要需要借助`splice`对数组元素进行替换，这种方式的赋值Vue是能够监听到的，然后实时改变页面Dom的显示。

### splice方法

- `splice(start: number, deleteCount: number, ...items: T[])`
  - start：用于指明删除操作开始位置的索引值
  - deleteCount: 删除元素的个数
  - items：可变参数，表示在删除完成后，需要插入的元素

借助splice我们可以完成删除、替换、新增操作，例：

- `arr.splice(5,0,'A','B')`：在index=5的后面插入`A、B`两个元素。
- `arr.splice(3,1)`：删除index=3的元素
- `arr.splice(5,2,'A','B')`：将index=5,6的元素分别替换为'A'、'B'

我们在前面看到了对数组中的元素直接进行赋值操作，是无法被Vue响应的，我们需要借助数组中的方法才能触发Vue的响应。但是我们如果修改数组元素中的属性值，是能够被Vue响应的，我们在上面代码的基础上创建一个新的事件：

```java
changeButton3() {
  count++;
  this.items[0].name='new Value ' + count;
}
```

当我们触发这个事件时，我们可以发现Vue做出了响应。