# Loader

loader 用于对模块的源代码进行转换。loader 可以使你在 `import` 或"加载"模块时预处理文件。因此，loader 类似于其他构建工具中“任务(task)”，并提供了处理前端构建步骤的强大方法。loader 可以将文件从不同的语言（如 TypeScript）转换为 JavaScript，或将内联图像转换为 data URL。loader 甚至允许你直接在 JavaScript 模块中 `import` CSS文件！

## 一. webpack中使用css的配置

webpack默认情况下只会对js文件进行打包，打包时会从入口文件进入，递归查找所有依赖的模块（js文件），然后对这些搜索到的文件进行打包处理，但是css文件由于不会直接在js中引入，所以它不会参与打包，但是一个缺少css文件的前端项目你敢用吗？所以我们需要将css文件也看做一个模块，然后让webpack在打包时将css文件也打包进来，此时我们需要在`main.js`入口文件中对css文件进行依赖：

```js
import normal from "./css/mormal.css" //js自带模块引入语法
require('./css/mormal.css') //CommonJS引入模块的语法，两种方式引入模块都支持
```

如果我们引入css文件后进行打包，就会打包失败。

第一步：安装`css-loader`才能正确加载css文件

```shell
npm install --save-dev css-loader
```

第二步：配置`webpack.config.js`文件

```js
const path = require('path')

const config = {
  entry: './src/main.js',
  output: {
    path: path.resolve(__dirname,'dist'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      { test: /\.css$/, use: 'css-loader' } //css-loader只负责css文件的加载
    ]
  }
}
module.exports = config;
```

此时我们打包就能成功了。但是我们会发现css样式并没有作用到DOM上，我们还需要配置`style-loader`才能使得css样式加载到DOM上：

```shell
npm install --save-dev style-loader
```

```json
const path = require('path')

const config = {
  entry: './src/main.js',
  output: {
    path: path.resolve(__dirname,'dist'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      { test: /\.css$/, use: ['style-loader','css-loader'] } 
    ]
  }
}
module.exports = config;
```

需要注意的是，loader是从后往前执行的，由于要先保证css-loader在style-loader之前工作，所以rules中的顺序不能颠倒。



## 一. Loader使用过程

第一步：通过npm安装需要使用的loader

```shell
npm install --save-dev css-loader
npm install --save-dev ts-loader
```

第二步：在webpack.config.js中的modules关键字下进行配置

