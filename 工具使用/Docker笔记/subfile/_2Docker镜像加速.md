# Docker镜像加速

鉴于国内网络问题，后续拉取 Docker 镜像十分缓慢，我们可以需要配置加速器来解决，我使用的是网易的镜像地址：**http://hub-mirror.c.163.com**。

新版的 Docker 使用` /etc/docker/daemon.json`（Linux） 或者 `%programdata%\docker\config\daemon.json`（Windows） 来配置 Daemon。

```json
{
  "registry-mirrors": ["http://hub-mirror.c.163.com"]
}
```

