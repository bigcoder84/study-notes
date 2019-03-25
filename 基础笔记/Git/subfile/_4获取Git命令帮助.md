## 获取Git命令帮助

​	在日常使用中，我们不可能记住所有的命令和参数，我们可以通过一些命令查看Git命令的帮助说明。

```shell
$ git help <verb>
$ git <verb> --help
$ man git-<verb>
```

### 获取系统所有命令帮助

如果我们想查看Git所有命令的粗略作用，则使用`git help`即可：

![](../images/4.png)

### 获取特定命令帮助

如果我们想要想获得某个命令的 详细手册，例如获取`config`命令的帮组，执行：

```shell
$ git help config
$ git config --help   #两种方式都可以
```

执行命令后，不会在命令行中显示文档，而是会通过系统默认浏览器弹出`config`命令的帮助文档：

![](../images/5.png)

