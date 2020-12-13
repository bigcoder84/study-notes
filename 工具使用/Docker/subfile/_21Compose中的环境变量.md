# Compose中的环境变量

> 本文转载至：[Environment variables in Compose | Docker Documentation](https://docs.docker.com/compose/environme)

## 一. 在Compose文件中使用环境变量

可以在compose文件中当前shell中的环境变量：

```yaml
web:
  image: "webapp:${TAG}"
```

如果你有多套环境变量，你可以提供一个环境变量的声明文件来替换shell中的环境变量。默认情况下，`docker-compose`命令会在命令执行的文件夹下寻找`.env`的文件。但是你可以将文件放置在任何目录下，并以任何方式命名（例如：`.env.dev`、`.env.prod`），只需要在启动时通过`--env-file`来指定它即可：

```shell
docker-compose --env-file ./config/.env.dev up 
```

## 二. 为容器设置环境变量

你可以为启动后的服务设置环境变量，就像`docker run -e VARIABLE=VALUE`一样：

```yaml
web:
  environment:
    - DEBUG=1
```

### 将宿主机环境变量直接注入容器中

你可以通过不给环境变量赋值的方式直接将环境变量从你的shell传递到服务容器，就像`docker run -e`变量一样。

```yaml
web:
  environment:
    - DEBUG
```

实际上，此种方式与下面的声明意义相同：

```yaml
web:
  environment:
    - DEBUG=${DEBUG}
```

### 使用`env`文件进行配置

您可以使用env文件选项将多个外部文件中的环境变量传递到服务容器中：

```yaml
web:
  env_file:
    - web-variables.env
```

### 在运行时设置环境变量

就像`docker run -r`命令一样，你可以在使用`docker-compose run`命令时一次性的设置环境变量：

```shell
docker-compose run -e DEBUG=1 web python console.py
```

你也可以将Shell中的环境变量直接注入容器：

```shell
docker-compose run -e DEBUG web python console.py
```

## 三. env文件

您可以在名为`.env`的环境文件中为Compose文件中引用的或用于配置Compose的任何环境变量**设置默认值**：

```shell
$ cat .env
TAG=v1.5

$ cat docker-compose.yml
version: '3'
services:
  web:
    image: "webapp:${TAG}"
```

当你运行`docker-compose up`，上面定义的web服务将使用`webapp:v1.5`的镜像：

```shell
$ docker-compose config

version: '3'
services:
  web:
    image: 'webapp:v1.5'
```

需要记住的是：Shell中的环境变量的优先级要高于`.env`文件中声明的变量。如果Shell中的值不一样，那么它将代替文件中声明的变量：

```shell
$ export TAG=v2.0
$ docker-compose config

version: '3'
services:
  web:
    image: 'webapp:v2.0'
```

### 3.1 优先级

如果你在多个地方设置了相同的环境变量，那么Compose将按照下列优先级使用这些变量：

1. Compose文件
2. Shell中的环境变量
3. 环境变量的声明文件（.env）
4. Dockerfile
5. Variable is not defined

在下面的示例中，我将在`env文件`和`Compose文件`中设置相同的环境变量：

```shell
$ cat ./Docker/api/api.env
NODE_ENV=test

$ cat docker-compose.yml
version: '3'
services:
  api:
    image: 'node:6-alpine'
    env_file:
     - ./Docker/api/api.env
    environment:
     - NODE_ENV=production
```

当你运行这个容器时，Compose中声明的环境变量会优先使用：

```shell
$ docker-compose exec api node

> process.env.NODE_ENV
'production'
```

### 3.2 语法规则

- Compose期望env文件中的每一行都是向`VAR=VAL`形式的变量声明
- 如果一行以`#`开头，那么它将被视为注释从而被忽略
- 空白行会自动忽略
- Compose对引号没有特殊处理，换句话说**引号将被视为Value的一部分**。