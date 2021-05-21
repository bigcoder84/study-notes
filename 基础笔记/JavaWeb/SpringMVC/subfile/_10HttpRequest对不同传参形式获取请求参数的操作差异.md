# HttpServletRequest获取请求参数

## 一. query传参

直接通过request.getParameter()即可获取。

## 二. post请求的Form Data传参

直接通过request.getParameter()即可获取。

注意只有POST请求的`Form Data`传参，才会被`request.getParameter()`获取，如果GET请求使用`Form Data`传参时不能够被`request.getParameter()`获取到。

## 三. json body传参

只能通过`request.getInputStream`获取流转换成字符串获取body中的内容，`Form Data`传参本质上也是将数据放在Http body中的，所以通过这个方式也是能够获取到传参数据的，但是JavaEE API提供了对`Form Data`的参数获取，也就是和query传参一样，通过`request.getParameter`获取。

## 四. 总结

反映到SpringMVC框架中，query传参和form data传参的处理逻辑无任何区别，而通过json body传参则需要加上`@RequestBody`注解。