# 建立 Spring Boot 项目时，当父依赖不再是 spring-boot-starter-parent 怎么办

## 问题描述

现阶段建立 Spring Boot 项目，使用 IDEA 自动创建项目时，会导入如下父依赖：

```xml
<parent>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-parent</artifactId>
	<version>2.0.6.RELEASE</version>
	<relativePath/> <!-- lookup parent from repository -->
</parent>
```

但在公司时，我们可能会需要自己公司内部的父依赖，那么就不能再依赖 `spring-boot-starter-parent`。但是若我们直接删除这个父依赖，就会报错（PS：主要是版本错误），遇到这种情况如何解决？

## 解决方式

1. 删除 `spring-boot-starter-parent` 依赖
2. 在 dependencyManagement 标签下，添加 spring-boot-dependencies 依赖，并且版本保持和原 spring-boot-starter-parent 一致。

```xml
<dependencyManagement>
		<dependencies>
			<!--
			    使用场景：当父依赖是公司内部依赖时（PS：不是spring-boot-starter-parent），需要
			这样做。
			 -->
			<!-- Spring Boot 依赖 -->
			<dependency>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-dependencies</artifactId>
				<version>2.0.6.RELEASE</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
</dependencyManagement>
```

