## Git别名

​	在Git系统中，与Linux一样可以为命令取别名：

```shell
git config --global alias.自定义别名 命令 #--global是别名的作用域，通常有local、global、system
```

​	例如：我们需要使用`st`代替`status`

```shel
git config --global alias.st status
```

​	此时`git st`与`git status`等价

