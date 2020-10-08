# Vuex

Vue中每一个组件都拥有自己的data域，内部保存着当前组件所依赖的数据，Vue如果在多个组件之间想要共享数据就变得非常困难了，此时Vuex就是用来帮忙解决全局变量值的管理，官方称之为**状态管理模式**

## 一. 基本使用

### 第一步：在项目中安装Vuex依赖

```shell
npm install vuex --save
```

### 第二步：在`src`下创建`store`文件夹，然后创建`index.js`文件

```js
import Vue from 'vue';
import Vuex from 'vuex'

//第一步，安装插件(安装时会将store实例放入Vue.prototype原型上，这样我们可以在任何组件中通过$store引用到它)
Vue.use(Vuex)
//第二步：创建对象
const store = new Vuex.Store({
    state: {
        count: 0;                                    
    },
    mutations: {},
    actions: {},
    getters: {},
    modules: {}
});

//第三步：导出对象
export default store;
```

### 第三步：在Vue实例中挂载Vuex

```js
import Vue from 'vue'
import App from './App.vue'
import vuex from "@/router/index"

new Vue({
  render: h => h(App),
  vuex
}).$mount('#app')
```

### 第四步：使用state

```js
$store.state.count
```



二. 