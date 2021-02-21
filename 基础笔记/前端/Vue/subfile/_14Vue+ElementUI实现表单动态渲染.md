# Vue+ElementUI实现表单动态渲染、可视化配置

> 本文转载至：[Vue+ElementUI实现表单动态渲染、可视化配置 (juejin.cn)](https://juejin.cn/post/6844903569896767495)

# 写在前面

前些日子碰到了动态渲染表单的需求，在这里记录一下，也许能帮到大家。

本文着重梳理动态渲染思路，关于超级表单，由于还不够完善，就不做赘述。

> GitHub: [github.com/bowencool/s…](https://github.com/bowencool/super-form)

# 动态渲染

动态渲染就是有一个异步的数据，大概长这样：

```
{
  "inline": true,
  "labelPosition": "right",
  "labelWidth": "",
  "size": "small",
  "statusIcon": true,
  "formItemList": [
    {
      "type": "input",
      "label": "姓名",
      "disable": false,
      "readonly": false,
      "value": "",
      "placeholder": "请输入姓名",
      "rules": [],
      "key": "name",
      "subtype": "text"
    },
    {
      "type": "radio",
      "label": "性别",
      "value": "",
      "button": false,
      "border": true,
      "rules": [],
      "key": "gender",
      "options": [
        {
          "value": "1",
          "label": "男",
          "disabled": false
        },
        {
          "value": "0",
          "label": "女",
          "disabled": false
        }
      ]
    }
  ]
}
复制代码
```

然后你需要把这个json渲染成这样：

![](../images/24.png)

最后提交表单的数据长这样：

```
{
    "name": "Genji",
    "gender": "1"
}
```

然后我们目标就是封装这样一个组件：

```
<dynamic-form :config="someConfig" v-model="someData" />
```

## 实现

开始之前，你需要知道[`v-model`的工作原理](https://cn.vuejs.org/v2/guide/components.html#使用自定义事件的表单输入组件)：

```
<input v-model="something">
```

这不过是以下示例的语法糖：

```
<input
  :value="something"
  @input="something = $event.target.value">
```

了解这些后，我们再来一步一步实现这个组件。

### 首先，把配置转发到`el-form`：

```
<template>
  <el-form 
    class="dynamic-form" 
    :inline="formConfig.inline" 
    :model="value" 
    :label-position="formConfig.labelPosition" 
    :label-width="formConfig.labelWidth" 
    :size='formConfig.size' 
    :status-icon="formConfig.statusIcon">

    <slot/>

  </el-form>
</template>

<script>
export default {
  props: {
    formConfig: {
      type: Object,
      required: true
    },
    value: {
      type: Object,
      required: true
    }
  },
}
</script>
```

### 第二步，设置默认值。

因为在每个`form-item`都会需要一个`v-model`，所以在渲染之前，保证每个字段都有值。这里需要注意一点，组件内不要直接修改父组件传入的`prop`，所以我们在这里用`{...this.value}`快速拷贝一份，最后别忘了通知父组件。代码如下：

```
export default {
  props: {
    formConfig: {...},
    value: {...},
  },
  methods: {
    setDefaultValue() {
      const formData = { ...this.value }
      // 设置默认值
      this.formConfig.formItemList.forEach(({ key, value }) => {
        if (formData[key] === undefined || formData[key] === null) {
          formData[key] = value
        }
      })
      this.$emit('input', formData)
    }
  },
  mounted() {
    this.setDefaultValue()
  },
}
```

### 第三步，渲染`form-item`。

如何把下面的数据渲染为我们熟悉的`el-form-item`？

```
{
    "type": "input",
    "label": "姓名",
    "disable": false,
    "readonly": false,
    "value": "",
    "placeholder": "请输入姓名",
    "rules": [],
    "key": "name",
    "subtype": "text"
}
```

第一种，利用`vue`内置的`component`组件，写起来可能像这样：

```
<el-form-item>
    <component :is="`el-${item.type}`" />
</el-form-item>
```

第二种，使用`v-if`逐个判断：

```
<el-form-item>
    <el-input v-if="item.type === 'input'" />
    <span v-else>未知控件类型</span>
</el-form-item>
```

考虑到每种表单控件的处理逻辑千差万别，楼主采用了第二种方式。

根据这个思路，我们来封装一个`dynamic-form-item`，接收一个`item`，渲染一个`el-form-item`：

```
<template>
  <el-form-item :rules="item.rules" :label="item.label" :prop="item.key">

    <el-input 
        v-if="item.type==='input'" 
        v-bind="$attrs" v-on="$listeners" 
        :type="item.subtype" 
        :placeholder="item.placeholder" 
        :disabled="item.disable" 
        :readonly="item.readonly" 
        :autosize="item.autosize"></el-input>

    <el-select 
        v-else-if="item.type==='select'" 
        v-bind="$attrs" v-on="$listeners"
        :multiple="item.multiple" 
        :disabled="item.disabled" 
        :multiple-limit="item.multipleLimit">
            <el-option 
                v-for="o in item.options" 
                :key="o.value" 
                :label="o.label" 
                :value="o.value" 
                :disabled="o.disabled">
            </el-option>
    </el-select>
    
    ...

    <span v-else>未知控件类型</span>

  </el-form-item>
</template>

<script>
export default {
  props: {
    item: {
      type: Object,
      required: true
    }
  }
}
</script>
```

> tips: 使用`v-bind="$attrs" v-on="$listeners"`可以方便地转发父组件的`v-model`指令，详见vue高阶组件。

### 最后，我们就可以循环输出一个完整的表单了：

```
<dynamic-form-item
    v-for="item in formConfig.formItemList"
    :key="item.key"
    v-if="value[item.key]!==undefined"
    :item="item"
    :value="value[item.key]"
    @input="handleInput($event, item.key)" />
```

这里不能用`v-model="value[item.key]"`，上文说了，组件内不能直接修改props，所以这里我们还是转发一下`input事件`。

```
methods: {
    handleInput(val, key) {
      // 这里element-ui没有上报event，直接就是value了
      this.$emit('input', { ...this.value, [key]: val })
    },
    setDefaultValue() {...}
},
```

完整代码地址：[`src/components/dynamic-form/form.vue`](https://github.com/bowencool/super-form/blob/master/src/components/dynamic-form/form.vue)

# 扩展功能

## 1.数字显示单位，限制小数位数

`element-ui`没有做这个功能，不过我觉得还是挺常见的，所以使用`el-input`手动封装了一个`input-number`:

![](../images/25.gif)

```
<!--普通使用-->
<input-number 
    v-model="someNumber"
    :min="1" 
    :max="99" 
    :decimal1="2" 
    append="元"></input-number>
    
<!--在dynamic-form-item中的应用-->
<input-number 
    v-else-if="item.type==='number'" 
    v-bind="$attrs" v-on="$listeners" 
    :min="item.min" 
    :max="item.max" 
    :decimal1="item.decimal1" 
    :append="item.append" 
    :prepend="item.prepend" 
    :disabled="item.disabled"></input-number>
复制代码
```

> 完整代码：[`src/components/dynamic-form/input-number.vue`](https://github.com/bowencool/super-form/blob/master/src/components/dynamic-form/input-number.vue)

## 2.异步验证

得益于[`async-validator`](https://github.com/yiminghe/async-validator)，我们可以很方便地自定义验证规则。

![](../images/26.gif)

在配置中

```
{
    "type": "input",
    ...
    "rules":[
        {
            "sql": "SELECT {key} FROM balabala",
            "message": "xx已被占用",
            "trigger": "blur"
        }
    ]
}
```

在`dynamic-form-item`组件中, 遍历`item.rules`, 将sql验证转化为自定义`validator`函数:

```
<template>
    <el-form-item :rules="Rules" >
        ...
    </el-form-item>
</template>

<script>
import request from '@/utils/request'
export default {
  props: {
    item: {...}
  },
  computed: {
    Rules() {
      const rules = this.item.rules
      if (rules === undefined) return undefined
      const R = []
      rules.forEach(rule => {
        if (rule.sql) {
          const validator = (rule2, value, callback) => {
            // 根据项目自行修改
            request('/api/validate', 'POST', {
              key: rule2.field,
              value,
              sql: rule.sql.replace(/{key}/ig, rule2.field)
            })
              .then(res => {
                callback(!res || undefined)
              })
              .catch(err => {
                this.$message.error(err.message)
                callback(false)
              })
          }
          R.push({ validator, message: rule.message, trigger: 'blur' })
        } else {
          R.push(rule)
        }
      })
      return R
    }
  },
}
</script>
```

## 3.省市区快捷配置

感谢[`element-china-area-data`](https://github.com/Plortinus/element-china-area-data)的作者。

在配置中:

```
{
    "type": "cascader",
    ...
    "areaShortcut": "provinceAndCityData"
}

```

在`dynamic-form-item`组件中:

```
<template>
    <el-form-item>
    
        ...
        
        <el-cascader 
            :options="item.options || require('element-china-area-data')[item.areaShortcut]"
            ></el-cascader>
    </el-form-item>
</template>
```

## 4.从远程加载选项

包括但不限于`radio`、`checkbox`、`cascader`、`select`。

在配置中:

```
{
    "type": "checkbox",
    ...
    "optionsUrl": "/api/some/options"
}
```

在`dynamic-form-item`组件中:

```
<template>
    <el-form-item>
    
        ...
        
        <el-select>
            <el-option 
                v-for="o in item.options || ajaxOptions"
                ></el-option>
        </el-select>

    </el-form-item>
</template>

<script>
import request from '@/utils/request'
export default {
  props: {
    item: {...}
  },
  computed: {...},
  data() {
    return {
      ajaxOptions: []
    }
  },
  created() {
    const { optionsUrl, key, type } = this.item
    if (optionsUrl) {
      // 根据项目自行修改
      request(`${optionsUrl}?key=${key}`, 'GET')
        .then(res => {
          this.ajaxOptions = res
        })
        .catch(err => { this.$message.error(err.message) })
    }
  }
}
</script>
```