# venv

Python有各种各样的系统包和第三方开发的包，让我们的开发变得异常容易。不过也引入了一个问题，不同代码需要的包版本可能是不一样的，所以常常回出现这种情况，为了代码B修改了依赖包的版本，代码B能work了，之前使用的代码A就没法正常工作了。因此常常需要对不同的代码设置不同的Python虚拟环境。[venv](https://docs.python.org/zh-cn/3/tutorial/venv.html)是Python自带的虚拟环境管理工具，使用很方便，这里简单记录一下使用方法。

需要注意的是，venv 工具没法创建不同版本的python环境，也就是如果你用python3.5没法创建python3.6的虚拟环境。如果想要使用不同python版本的虚拟环境，请安装 virtual env包。

### 1. 安装

python3.6及以上已经默认安装，python3.5需要通过系统的包管理工具安装：

```
sudo apt install python3-venv
```

### 2. 创建虚拟环境

在`~/test_env`目录下创建虚拟环境：

```shell
python3 -m venv test_env
```

### 3. 启用虚拟环境

```shell
source ~/test_env/bin/activate #Linux环境
```

可以看到，命令行的提示符前面会出现括号，里面是虚拟环境名称。

使用`pip`安装需要的包：

```
pip install tensorflow
```

注意这里不需要root权限，因此无需添加`sudo`。

安装的包会放在`~/test_env/lib/pythonx.x/site-packages` 目录下。

### 4. 退出虚拟环境

退出虚拟的python环境，在命令行执行下面的命令即可：

```
deactivate
```