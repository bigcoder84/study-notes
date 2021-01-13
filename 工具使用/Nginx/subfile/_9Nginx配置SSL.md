# Nginx配置SSL

> 本文参考至：
>
> [Nginx 如何配置证书？ (freessl.cn)](https://blog.freessl.cn/how-to-install-cert-in-nginx/)
>
> [Nginx配置SSL报错 nginx:[emerg\] unknown directive “ssl”_程序猿杂记-CSDN博客](https://blog.csdn.net/weixin_44110998/article/details/104022583)
>
> https://www.myfreax.com/redirect-http-to-https-in-nginx/
>
> https://segmentfault.com/a/1190000022532940

## 一. 格式说明

首先 Nginx 使用的证书是 `.pem` 格式的。什么是 `.pem` 格式，就是以 `-----BEGIN xxx-----` 开头的文件，如：

```
-----BEGIN CERTIFICATE-----
MIID6jCCAtKgAwIBAgIBFDANBgkqhkiG9w0BAQsFADB7MQswCQYDVQQGEwJDTjER
MA8GA1UECAwIU2hhbmdoYWkxDzANBgNVBAoMBmRlZXB6ejEPMA0GA1UECwwGZGVl
cHp6MRMwEQYDVQQDDApkZWVwenouY29tMSIwIAYJKoZIhvcNAQkBFhNkZWVwenou
... ...
-----END CERTIFICATE-----
```

当然现在 openssl 新版签发的证书，在 `-----BEGIN xxx-----` 之前还有一段信息，我们这里就不举例了。

所以，当我们从证书服务商那里下载证书的时候需要注意证书的格式问题。选择 `Nginx` 或 `SLB` 进行下载。

拿到证书后，你可能有如下文件：

```
example.com.crt
example.com.key
```

`example.com.key` 就是你的私钥文件，千万不要泄漏给别人哦。

`example.com.crt` 是你的证书文件，也有可能是证书链文件。用文本编辑器打开，你可能会看到两张上面提到的内容，它的内容是 `站点证书+CA中间证书`。我们需要的就是这样的证书链文件。如果不是，请联系证书服务商或到 [这里](https://myssl.com/chain_download.html) 补全证书链。

## 二. 安装证书

首先，我们需要将我们的证书和私钥上传的服务器的指定路径，假设为 `/path/to/` 目录。

然后，编辑你的 Nginx 的 web 服务器的配置文件。在文件内添加如下：

```
server {  
    # 监听 ssl 443 端口
    listen 443 ssl;
    server_name example.com;

    # 开启 ssl
    ssl on;
    # 指定 ssl 证书路径
    ssl_certificate /path/to/example.com.crt;
    # 指定私钥文件路径
    ssl_certificate_key /path/to/example.com.key;
}
```

这样，配置文件已经改好了，通过下列命令重启：

```
$ ./sbin -s stop & ./sbin/nginx
```

## 三. ssl配置报错问题解决

重启时可能会报如下错误：

```
nginx: [emerg] the "ssl" parameter requires ngx_http_ssl_module in /usr/local/nginx/conf/nginx.conf:37
```

这是因为我们在编译安装Nginx时没有配置`ngx_http_ssl_module`模块，我们需要重新安装一次Nginx，在解压目录中执行如下命令生成：

```shell
./configure --prefix=/Nginx --with-http_ssl_module
```

然后执行`make install`命令重新安装即可，注意此操作会覆盖目标目录，如有需要请备份原文件。安装好后重新配置nginx ssl即可。

## 四. 默认重定向至HTTPS

下列两种方式是将HTTP重定向至HTTPS，安装自己情况进行选择

### 将每个站点的HTTP重定向到HTTPS

要将单个网站重定向到HTTPS，请打开域配置文件并进行以下更改：

```bash
server {
    listen 80;
    listen [::]:80;
    server_name myfreax.com www.myfreax.com;
    return 301 https://myfreax.com$request_uri;
}
```

让我们逐行细分代码：

- `listen 80`-服务器块将侦听端口80上指定域的传入连接。
- `server_name myfreax.com www.myfreax.com` -指定服务器块的域名。确保将其替换为您的域名。
- `return 301 https://myfreax.com$request_uri` -将流量重定向到网站的HTTPS版本。 `$request_uri`变量是包含参数的完整原始请求URI。

通常，您还希望将站点的HTTPS www版本重定向到非www或反之。推荐的重定向方法是为www和非www版本创建一个单独的服务器块。

例如，要将HTTPS www请求重定向到非www，请使用以下配置：

```bash
server {
    listen 80;
    listen [::]:80;
    server_name myfreax.com www.myfreax.com;
    return 301 https://myfreax.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.myfreax.com;

    # . . . other code

    return 301 https://myfreax.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name myfreax.com;

    # . . . other code
}
```

### 将所有站点重定向到HTTPS

如果服务器上托管的所有网站都配置为使用HTTPS，并且您不想为每个网站创建单独的HTTP服务器块，则可以创建一个通用的HTTP服务器块。该块会将所有HTTP请求重定向到适当的HTTPS块。

要创建一个通用的HTTP块，它将访问者重定向到站点的HTTPS版本，请打开Nginx配置文件并进行以下更改：

```bash
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name _;
	return 301 https://$host$request_uri;
}
```

让我们逐行分析代码：

- `listen 80 default_server`-将此服务器块设置为所有不匹配域的默认（全部捕获）块。
- `server_name _` -`_`是一个无效域名，从未与任何真实域名匹配。
- `return 301 https://$host$request_uri` -使用状态代码301（永久移动）将流量重定向到相应的HTTPS服务器块。 `$host`变量保存请求的域名。

例如，如果访问者在浏览器中打开`http://example.com/page2`，则Nginx会将请求重定向到`https://example.com/page2`。

如果可能，最好在每个域的基础上创建重定向，而不是从全局HTTP到HTTPS重定向。