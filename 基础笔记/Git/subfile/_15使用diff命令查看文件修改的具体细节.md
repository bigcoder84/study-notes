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

