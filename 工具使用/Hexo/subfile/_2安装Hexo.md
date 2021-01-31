# 安装Hexo

## 第一步：安装cnpm

​	安装Hexo我们需要借助npm包管理器来安装Hexo，但是受限于国内网络环境影响（下载速度会非常慢），我们需要借助npm安装cnpm（淘宝的镜像源）：

​	在CMD中执行:

```shell
npm install -g cnpm --registry=https://registry.npm.taobao.org
```

![](../images/4.png)



## 第二步：利用cnpm安装Hexo

执行下列命令：

```shell
cnpm install -g hexo-cli
```

![](../images/5.png)

通过`hexo -v`查看hexo是否安装成功，如果现实出了一堆信息，则代表安装成功。

