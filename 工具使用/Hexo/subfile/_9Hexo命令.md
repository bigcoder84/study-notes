# Hexo命令

​	在前面的学习中，我们完成了Hexo博客的基本搭建，在搭建过程中我们会使用到Hexo命令，在此我们对前面所学的Hexo命令做一个简单的总结：

## init命令

```shell
$ hexo init [folder]
```

该命令用于新建一个网站。如果没有设置 `folder` ，Hexo 默认在目前的文件夹建立网站。



## new命令

```shell
$ hexo new [layout] <title>
```

​	该命令用于新建一篇文章。如果没有设置 `layout` 的话，默认使用 [_config.yml](https://hexo.io/zh-cn/docs/configuration) 中的 `default_layout` 参数代替。如果标题包含空格的话，请使用引号括起来。



## generate命令

```shell
$ hexo generate #可简写为 hexo g
```

选项：

- -d，--deploy：文件生成后立即部署网站
- -w，--watch：监视文件变动

该命令用于解析Markdown文件，从而生成静态页面。



## clean命令

```shell
$ hexo clean
```

清除缓存文件 (`db.json`) 和已生成的静态文件 (`public`)。

在某些情况（尤其是更换主题后），如果发现您对站点的更改无论如何也不生效，您可能需要运行该命令	



## server命令

```shell
$ hexo server #可简写为 hexo s
```

选项：

- -p，--port：重设端口（默认是4000端口）

该命令用于启动本地服务器



## deploy命令

```shell
$ hexo deploy #可简写为 hexo d
```

该命令用于将博客系统部署到远程服务器（Github或Gitee）