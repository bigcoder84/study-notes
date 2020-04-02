## 配置Terminal执行gitbash

​	在windows开发环境下开发，我们通常会用到一些命令，而Terminal刚好可以解决这个问题。

![](../images/50.png)

​	但是默认情况下，该Terminal使用的是windows自带的cmd，大多数人对windows控制台命令不太熟悉，所以就需要一个linux模拟器，gitbash正好可以解决这个问题（安装windows版本的Git后自带该bash环境），我们只需要配置好后，就可以在Terminal中使用Linux命令了：

![](../images/51.png)

但是gitbash有一个中文乱码的问题我们需要在，Git的安装目录下的`etc/bash.bashrc`末尾添加：

```shell
# support chinese
export LANG="zh_CN.UTF-8"
export LC_ALL="zh_CN.UTF-8"
```



如果我们想通过Terminal运行Windows自带的cmd，只需要在`Shell path`中写成`cmd`。

如果我们想通过Terminal运行Windows下的Linux子系统（windows10 1903开始才支持此功能），只需要在`Shell path`中写成`bash`