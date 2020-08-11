# Webpack配置

前面我们介绍了Webpack打包构建的基本操作，但是如果每次使用webpack的命令都需要写上入口和出口作为参数，就非常麻烦，我们可以对Webpack进行配置后让它自动进行打包构建。

## 一. 打包入口和出口的配置

我们需要在项目根路径下创建`webpack.config.js`文件，然后在其内部配置打包的入口和出口：

```js
const path = require('path')

const config = {
  entry: './src/main.js',
  output: {
    path: path.resolve(__dirname,'dist'), //注意，打包出口路径必须是一个绝对路径，所以这里借助path模块来获取项目的绝对路径。
    filename: 'bundle.js' //打包的出口文件
  }
}
module.exports = config;
```

由于打包的出口路径要求是一个绝对路径，所以我们可以借助`path`模块来获取项目的绝对路径，所以我们在