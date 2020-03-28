# SpringMVC拦截器配置

## 一. SpringMVC拦截器

```java
public class Interceptor implements HandlerInterceptor{
    private Logger logger = LoggerFactory.getLogger(Interceptor.class);

    public void afterCompletion(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, Exception arg3)
            throws Exception {
        // TODO Auto-generated method stub

    }

    public void postHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, ModelAndView arg3)
            throws Exception {
        // TODO Auto-generated method stub

    }

    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object arg2) throws Exception {
        String flag = null;
        flag = request.getParameter("auth");
        if(StringUtils.isEmpty(flag) || !flag.equals("php")){
            /*logger.error("error-auth:{}", flag);
            response.getWriter().append("error-auth");
            return false;*/
        } else {
            logger.info("通过校验！");
            return true;
        }
        return true;
    }
}
```

**向SpringBoot注册拦截器**：

```java
@Configuration
public class MyWebAppConfigurer implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new Interceptor()).addPathPatterns("/**");
    }
}
```



## 二. Servlet过滤器

```java
/*
 * 如果是一个过滤器,在MyFilter类上加上@WebFilter(filterName = "myFilter",urlPatterns = {"/*"}) ,入口类加上@ServletComponentScan即可
 */
public class MyFilter implements Filter{
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {

    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        System.out.println(request.getParameter("name"));
        HttpServletRequest hrequest = (HttpServletRequest)request;
        HttpServletResponseWrapper wrapper = new HttpServletResponseWrapper((HttpServletResponse) response);
        if(hrequest.getRequestURI().indexOf("/index") != -1 ||
                hrequest.getRequestURI().indexOf("/asd") != -1 ||
                hrequest.getRequestURI().indexOf("/online") != -1 ||
                hrequest.getRequestURI().indexOf("/login") != -1
                ) {
            chain.doFilter(request, response);
        }else {
//            wrapper.sendRedirect("/login");
            chain.doFilter(request, response);
        }
    }

    @Override
    public void destroy() {

    }
}
```

**SpringBoot项目配置过滤器**：

```java
@Configuration
public class MyWebAppConfigurer implements WebMvcConfigurer {
    /**
     * 注册过滤器
     * @return
     */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    @Bean
    public FilterRegistrationBean filterRegist() {
        FilterRegistrationBean frBean = new FilterRegistrationBean();
        frBean.setFilter(new MyFilter());
//        frBean.setOrder(1);//多个过滤器时指定过滤器的执行顺序
        frBean.addUrlPatterns("/*");
        System.out.println("filter");
        return frBean;
    }
}
```





## 三. Servlet监听器

```java
/**
 * @date: 2019/4/1
 * @description:  ServletRequestListener、 HttpSessionListener 、ServletContextListener ......
 * 可直接在MyListener类上使用@WebListener注解,入口类加上@ServletComponentScan即可
 */
public class MyListener implements HttpSessionListener {
    private Logger logger = LoggerFactory.getLogger(this.getClass());//用户this.getClass(), 粘贴不容易出错
    public static int online = 0;

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        online ++;
        logger.info("online在线人数为：" + online);
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {

    }
}
```

**SpringBoot项目配置监听器**：

```java
@Configuration
public class MyWebAppConfigurer implements WebMvcConfigurer {
    /**
     * 注册监听器
     * @return
     */
    @SuppressWarnings({ "rawtypes", "unchecked" })
    @Bean
    public ServletListenerRegistrationBean listenerRegist() {
        ServletListenerRegistrationBean srb = new ServletListenerRegistrationBean();
        srb.setListener(new MyListener());
        System.out.println("listener");
        return srb;
    }
}
```

