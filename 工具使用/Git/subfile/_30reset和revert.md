# reset和revert

> 本文转载至：https://juejin.im/post/6844903614767448072

## 一. 概述

1. git revert 后会多出一条commit，这里可进行回撤操作
2. git reset 直接把之前 commit 删掉，非 git reset --hard 的操作是不会删掉修改代码，如果远程已经有之前代码，需要强推 git push -f

## 二. git reset

git reset命令用于将HEAD所在分支指针回退至历史版本。

```js
develop ----1      3-----
             \   /
branch a       a
```

develop将a分支合并后，想要不留痕迹的撤回合并。这个时候用`git reset`就是很好的选择了。

具体的操作步骤如下：

1. 切换分支到develop

2. git log 查看当前分支日志

   例如我的日志是这样的：

   ```
   commit 3
   Merge 1 2
   Author: admin <admin@163.com>
   Date: Wed May 30 15:00:00 2018 +0800
   
       Merge branch 'feature/a' into 'develop'
   
       close a
   
       See merge request !20
   
   commit 2
   Author: admin <admin@163.com>
   Date: Wed May 30 14:00:00 2018 +0800
   
       close a
   
   commit 1
   Author: admin <admin@163.com>
   Date: Wed May 30 13:00:00 2018 +0800
       init project
   复制代码
   ```

   我要将develop回退到合并之前的状态，那就是退到 commit 1这了，将commit号复制下来。退出编辑界面。

### 2.1 reset参数定义

1. --soft 回退后a分支修改的代码被保留并标记为add的状态（git status 是绿色的状态）
2.  --mixed 重置索引，但不重置工作树，更改后的文件标记为未提交（add）的状态。默认操作。
3.  --hard 重置索引和工作树，并且a分支修改的所有文件和中间的提交，没提交的代码都被丢弃了。
4.  --merge 和--hard类似，只不过如果在执行reset命令之前你有改动一些文件并且未提交，merge会保留你的这些修改，hard则不会。【注：如果你的这些修改add过或commit过，merge和hard都将删除你的提交】
5.  --keep 和--hard类似，执行reset之前改动文件如果是a分支修改了的，会提示你修改了相同的文件，不能合并。如果不是a分支修改的文件，会移除缓存区。git status还是可以看到

### 2.2 巧用reset

**提交完成后，撤销提交**

```shell
git reset HEAD^
```

- git reset 默认参数是--mixed
- `HEAD^`表示回退到当前指针的上一个提交

**撤销暂存区的所有修改**

```shell
git reset --hard HEAD
```



## 三. git revert

还是这个例子

```
develop ----1      3-----
             \   /
branch a       a
```

还是之前的需求，不想要合并a，只想要没合并a时的样子。

操作步骤：

1. 切分支到develop：`git checkout develop`

2. 查看日志：`git log `，还是上面的日志：

   ```
   commit 3
   Merge 1 2
   Author: admin <admin@163.com>
   Date: Wed May 30 15:00:00 2018 +0800
   
       Merge branch 'feature/a' into 'develop'
   
       close a
   
       See merge request !20
   
   commit 2
   Author: admin <admin@163.com>
   Date: Wed May 30 14:00:00 2018 +0800
   
       close a
   
   commit 1
   Author: admin <admin@163.com>
   Date: Wed May 30 13:00:00 2018 +0800
       init project
   复制代码
   ```

   这次和`git reset` 不同的是我不能复制 `commit 1`这个commit号了，我需要复制的是`commit 2`的commit号。因为revert后面跟的是具体需要哪个已经合并了的分支，而并不是需要会退到哪的commit号。

1. 开始回退：`git revert 2`

   ```
   Revert "close a"
   This reverts commit 2
   #.......
   复制代码
   ```

   这是相当于又新增了一个commit，把a分支上的所有修改又改了回去。

2. Ctrl+X离开编辑commit信息页面。

     `git log`查看一下是不是我想的那样

   ```
   commit 4
   Author: admin <admin@163.com>
   Date: Wed May 30 17:00:00 2018 +0800
       Revert "close a"
       This reverts commit 2
   commit 3
   Merge 1 2
   Author: admin <admin@163.com>
   Date: Wed May 30 15:00:00 2018 +0800
   
       Merge branch 'feature/a' into 'develop'
   
       close a
   
       See merge request !20
   
   commit 2
   ....
   复制代码
   ```

   确实是新增加了一个commit，查看代码发现a分支的修改都不存在了，也达到了我想要的效果。

3. push的远程服务器上`git push origin develop`

查看network,是这样的：

```
develop ----1      3-----revert a------
             \   /
branch a       a
```

如此看来，`git reset`和`git revert`都能实现我现在的需求，那这两个到底有什么区别呢，在网上查了这个问题，我觉得说的有些抽象，看的不是很明白，于是自己实践了之后才明白。

## 四. revert和reset的区别

1. git revert是用一次新的commit来回滚之前的commit，git reset是直接删除指定的commit。 

   这个很好理解，在刚才的操作中我们看日志已经可以看到这个现象。

   `git reset`操作之后，我们查看上面例子的network已经可以看到network中只有`commit 1`,`分支a`和`合并分支后的commit 3`都消失了；

   `git revert`操作之后，network中还是可以看到a分支和合并a分支的操作，只不过在其基础上又增加了一个revert的commit而已。

2. git reset 是把HEAD向后移动了一下，而git revert是HEAD继续前进，只是新的commit的内容和要revert的内容正好相反，能够抵消要被revert的内容。

   这个也是可以清晰明了的看到，我就不做过多的解释了

3. 在回滚这一操作上看，效果差不多。但是在日后继续merge以前的老版本时有区别。因为git revert是用一次逆向的commit“中和”之前的提交，因此日后合并老的branch时，导致这部分改变不会再次出现，但是git reset是直接把某些commit在某个branch上删除，因而和老的branch再次merge时，这些被回滚的commit应该还会被引入。

