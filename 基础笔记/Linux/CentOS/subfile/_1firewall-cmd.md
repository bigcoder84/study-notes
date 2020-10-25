# firewall-cmd

Linux上新用的防火墙软件，跟iptables差不多的工具

## 一. 常用命令

- 重新加载防火墙（在开启或关闭端口需要执行重新加载动作才会生效）

  `firewall-cmd --reload`

- 查看防火墙某个端口是否开放
  `firewall-cmd --query-port=3306/tcp`

- 开放防火墙端口3306
  `firewall-cmd --zone=public --add-port=3306/tcp [--permanent]`

  permanent代表永久开启

- 关闭防火墙端口3306
  `firewall-cmd --zone=public --remove-port=3306/tcp [--permanent]`

- 查看防火墙状态
  `systemctl status firewalld`

- 关闭防火墙
  `systemctl stop firewalld`

- 打开防火墙
  `systemctl start firewalld`

- 开放一段端口
  `firewall-cmd --zone=public --add-port=40000-45000/tcp --permanent`

- 查看开放的端口列表
  `firewall-cmd --zone=public --list-ports`

## 补充说明

firewall-cmd 是 firewalld的字符界面管理工具，firewalld是centos7的一大特性，最大的好处有两个：支持动态更新，不用重启服务；第二个就是加入了防火墙的“zone”概念。

firewalld跟iptables比起来至少有两大好处：

1. firewalld可以动态修改单条规则，而不需要像iptables那样，在修改了规则后必须得全部刷新才可以生效。
2. firewalld在使用上要比iptables人性化很多，即使不明白“五张表五条链”而且对TCP/IP协议也不理解也可以实现大部分功能。

firewalld自身并不具备防火墙的功能，而是和iptables一样需要通过内核的netfilter来实现，也就是说firewalld和 iptables一样，他们的作用都是用于维护规则，而真正使用规则干活的是内核的netfilter，只不过firewalld和iptables的结构以及使用方法不一样罢了。
