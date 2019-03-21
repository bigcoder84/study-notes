## SpringMVC多后缀名拦截细节

​	在搭建SpringMVC项目时，通常我们在web.xml配置前端控制器，在配置前端控制器时很多时候会选择 “后缀名拦截”，例如：`*.html`它可以实现网页的伪静态化。

```xml
<servlet-mapping>
    <servlet-name>blog-portal-web</servlet-name>
    <url-pattern>*.html</url-pattern>
</servlet-mapping>
```

​	但是在很多情况下，一个项目只使用*.html拦截是不够的，因为在大多数POST请求中使用*.html是不合适的，所以我们需要配置第二个“后缀名拦截”，方法很简单，只需要添加一个`<url-pattern>`即可：

```xml
<servlet-mapping>
    <servlet-name>blog-portal-web</servlet-name>
    <url-pattern>*.html</url-pattern>
    <url-pattern>*.action</url-pattern>
</servlet-mapping>
```

​	这样我们就能实现两个后缀名都拦截的效果了。但是有很多处理器（Controller类中的方法）很多时候就只需要处理其中某一个后缀的结尾，例如：我们在访问图片验证码的jsp时，总不能写成`xxx.html`的请求吧，写成`xxx.action`比较合适。<font color="red">**如果我们需要指定处理器处理的请求后缀，只需要在配置映射时指定即可**：</font>

​	例如：`@RequestMapping(“validatecode.action”)`修饰指定处理器即可，此时如果试图采用`validatecode.html`来访问，前端控制器虽然可以拦截请求，但是处理器映射器，是找不到`validatecode.html`的处理器的，只有`valiedatecode.action`的处理器。

​      <font color="red">**如果我们想两个后缀名的请求都拦截，那又该如何解决呢？只需要在写映射路径时，不带上后缀名即可**</font>。例如：`@RequestMapping(“validatecode”)`，这样两种后缀名的请求都会处理。

