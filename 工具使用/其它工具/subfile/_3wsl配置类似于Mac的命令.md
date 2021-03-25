# wsl配置类似于Mac的open命令

针对默认Shell的Ubuntu系统（如果是其它Shell，则自行查找Shell的启动配置文件），编辑`/etc/profile`文件，在末尾添加下列命令：

```shell
alias open='cmd.exe /C start'
```

然后执行：

```shell
source /etc/profile
```

