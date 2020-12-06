# 构建SpringBoot镜像

创建Dockerfile

```shell
FROM openjdk:8u111
LABEL maintainer "bigcoder <bigcoder84@gmail.com>"
EXPOSE 8080/tcp
WORKDIR /opt
COPY web-test.jar /opt/
CMD java -jar web-test.jar
```

构建镜像：

```shell
docker build -t bigcoder/webtest:v1.0 .
```

启动镜像

```shell
docker run -d --name web-test -P bigcoder/web-test:v1.0
```



