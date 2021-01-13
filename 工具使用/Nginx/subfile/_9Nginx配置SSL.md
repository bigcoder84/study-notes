# Nginx配置SSL

> 本文参考至：[Nginx 如何配置证书？ (freessl.cn)](https://blog.freessl.cn/how-to-install-cert-in-nginx/)
>
> [Nginx配置SSL报错 nginx:[emerg\] unknown directive “ssl”_程序猿杂记-CSDN博客](https://blog.csdn.net/weixin_44110998/article/details/104022583)

## 格式说明

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

## 安装证书

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

这样，配置文件已经改好了，通过：

```
$ ./sbin -s restart
```

## 问题解决

重启时可能会报如下错误：

```
nginx: [emerg] the "ssl" parameter requires ngx_http_ssl_module in /usr/local/nginx/conf/nginx.conf:37
```

这是因为我们在编译安装Nginx时没有配置`ngx_http_ssl_module`模块，我们需要重新安装一次Nginx，在解压目录中执行如下命令生成：

```shell
./configure --prefix=/Nginx --with-http_ssl_module
```

然后执行`make install`命令重新安装即可，注意此操作会覆盖目标目录，如有需要请备份原文件。安装好后重新配置nginx ssl即可。