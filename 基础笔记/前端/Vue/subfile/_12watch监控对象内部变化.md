# watch监控对象内部变化

默认情况下watch指令只会监控一个变量引用的变化，而变相内部的变化不会监控，如果需要监控对象内部的变化，我们可以这样做：

```js
watch: {
  filterCondition: {
    handler(){
      this.filterProjectByCondition();
    },
    deep: true // 深度监控
  }
},
```

