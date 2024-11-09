# IDEA使用WSL作为命令行

![](../images/111.png)

在输入框中输入：

```shell
"cmd.exe" /k "wsl.exe"    
```

![](../images/112.png)

如果上述命令报错，我们可以使用下列命令：
```shell
# 第一步：查看安装的WSL版本和名称
C:\Windows\System32>wsl --list --verbose
  NAME                   STATE           VERSION
* docker-desktop-data    Stopped         2
  Ubuntu-20.04           Running         2
  docker-desktop         Stopped         2

# 第二部：指定WSL版本，看是否能在CMD中启动WSL 
# 格式：wsl --set-version <distribution name> <versionNumber>

wsl --distribution Ubuntu-20.04
```

如果 `wsl --distribution` 命令能在CMD中可以打开WSL，那么在IDEA配置 `"cmd.exe" /k "wsl --distribution Ubuntu-20.04"` 即可
