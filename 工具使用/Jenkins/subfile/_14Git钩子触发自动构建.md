# Git钩子触发自动构建

刚才我们看到在Jenkins的内置构建触发器中，轮询SCM可以实现Gitlab代码更新，项目自动构建，但是该方案的性能不佳。那有没有更好的方案呢？ 有的。就是利用Gitlab的webhook实现代码push到仓库，立即触发项目自动构建。

#### 第一步：安装`Gitlab Hook`和`GitLab`插件

#### 第二步：Jenkins设置自动构建

![](../images/70.png)

等会需要把生成的webhook URL配置到Gitlab中。

#### 第三步：GitLab开启WebHook功能

使用root账户登录到后台，点击Admin Area -> Settings -> Outbound request。

勾选"Allow requests to the local network from web hooks and services"

![](../images/71.png)



#### 第四步：在GitLab仓库中添加WebHook

点击项目->Settings->Integrations

![](../images/72.png)

钩子新增成功后，我们可以进行测试，看是否能够触发构建：

![](../images/73.png)

测试可能会发生错误：

![](../images/74.png)

#### 第五步：配置Jenkins关闭身份验证，解决拒绝授权的问题

Manage Jenkins->Confifigure Syste->GitLab

![](../images/75.png)