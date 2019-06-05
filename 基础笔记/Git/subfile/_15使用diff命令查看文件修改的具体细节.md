## 使用diff命令查看文件修改的具体细节

​	我们通过`git status`命令只能看到当前工作区内哪些文件被修改了，而如果我们想要查看修改的细节那就得使用`git diff`命令了:

#### **查看工作区中文件与暂存区文件的区别：**

```shell
git diff 文件名
```

```shell
$ git diff hello.java
diff --git a/hello.java b/hello.java
index f761ec1..b2a7546 100644
--- a/hello.java
+++ b/hello.java
@@ -1 +1 @@
-bbb
+ccc
```

#### 查看暂存区中的文件与上次提交的快照的具体区别：

```shell
git diff --cached 文件名
```

```shell
$ git diff --cached hello.java
diff --git a/hello.java b/hello.java
index 8f22c74..f761ec1 100644
--- a/hello.java
+++ b/hello.java
@@ -1 +1 @@
-aaa`
+bbb
```

#### 查看两个提交对象的具体差别

```shell
git diff <SHA-1> <SHA-1>
```

```shell
git log 
commit c689ddfc8fdc6b689a13d3a7dd861df3230d0947 (HEAD -> master) # A Commit
Author: tianjindong <tianjindong98@qq.com>
Date:   Tue Jun 4 09:52:42 2019 +0800

    dsa

commit d21c01b28f1b21bffab3a64286fdc180405d6120
Merge: 86984d0 8b43fc7
Author: tianjindong <tianjindong98@qq.com>
Date:   Tue Jun 4 09:28:36 2019 +0800

    dsadas

commit 8b43fc7441ced8d19b4edd1aaa333444b931b075 # B commit
Author: tianjindong <tianjindong98@qq.com>
Date:   Tue Jun 4 09:26:41 2019 +0800

    dasdsad
     
git diff HEAD 8b43fc744  #查看A和B commit的区别

```

