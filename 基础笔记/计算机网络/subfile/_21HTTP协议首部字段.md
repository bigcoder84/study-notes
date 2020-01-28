# HTTP协议首部字段

HTTP 首部字段**根据实际用途被分为**以下 4 种类型：

- 通用首部字段（**General Header Fields**）：请求报文和响应报文两方都会使用的首部。

- 请求首部字段（**Request Header Fields**）：从客户端向服务器端发送请求报文时使用的首部。补充了请求的附加内容、客户端信息、响应内容相关优先级等信息。
- 响应首部字段（**Response Header Fields**）：从服务器端向客户端返回响应报文时使用的首部。补充了响应的附加内容，也会要求客户端附加额外的内容信息。
- 实体首部字段（**Entity Header Fields**）：针对请求报文和响应报文的实体部分使用的首部。补充了资源内容更新时间等与实体有关的信息。

## 一. HTTP/1.1协议首部字段一览表

HTTP/1.1 规范定义了如下 47 种首部字段。

### 1.1 通用首部字段

![](../images/61.jpg)

### 1.2 请求首部字段

![](../images/62.jpg)

### 1.3 响应首部字段

![](../images/63.jpg)

### 1.4 实体首部字段

![](../images/64.jpg)

## 二. 非 **HTTP/1.1** 首部字段

在 HTTP 协议通信交互中使用到的首部字段，不限于 RFC2616 中定义的 47 种首部字段。还有 Cookie、Set-Cookie 和 Content-Disposition等在其他 RFC 中定义的首部字段，它们的使用频率也很高。

这些非正式的首部字段统一归纳在 RFC4229 HTTP Header Field Registrations 中。



## 三. End-to-end 首部和Hop-by-hop 首部

HTTP 首部字段将定义成缓存代理和非缓存代理的行为，分成 2 种类型:

- 端到端首部（**End-to-end Header**）：分在此类别中的首部会转发给请求 / 响应对应的最终接收目标，且必须保存在由缓存生成的响应中，另外规定它必须被转发。
- 逐跳首部（**Hop-by-hop Header**）：分在此类别中的首部只对单次转发有效，会因通过缓存或代理而不再转发。HTTP/1.1 和之后版本中，如果要使用 hop-by-hop 首部，需提供 Connection 首部字段。

下面列举了 HTTP/1.1 中的逐跳首部字段。除这 8 个首部字段之外，其他所有字段都属于端到端首部：

- Connection
- Keep-Alive
- Proxy-Authenticate
- Proxy-Authorization
- Trailer
- TE
- Transfer-Encoding
- Upgrade



## 四. HTTP/1.1 通用首部字段

### 4.1 Cache-Control

通过指定首部字段 Cache-Control 的指令，就能够控制缓存的行为

![](../images/65.jpg)

指令的参数是可选的，多个指令之间通过“,”分隔。首部字段 CacheControl 的指令可用于请求及响应时。

```shell
Cache-Control: private, max-age=0, no-cache
```

Cache-Control指令一览：指令按请求和响应分类如下所示。

**缓存请求指令**

![](../images/66.jpg)

**缓存响应指令**

![](../images/67.jpg)

Cache-Control字段详情请见：《图解HTTP》中6.3.1节（ISBN：978-7-115-35153-1）

### 4.2 Connection

Connection 首部字段具备如下两个作用：

- 控制不再转发给代理的首部字段
- 管理持久连接

#### 控制不再转发给代理的首部字段

![](../images/68.jpg)

```shell
Connection: 不再转发的首部字段名
```

在客户端发送请求和服务器返回响应内，使用 Connection 首部字段，可控制不再转发给代理的首部字段（即 Hop-by-hop 首部）。

#### 管理持久连接

![](../images/69.jpg)

HTTP/1.1 版本的默认连接都是持久连接。为此，客户端会在持久连接上连续发送请求。当服务器端想明确断开连接时，则指定Connection 首部字段的值为 Close。

```shell
Connection: close
```



![](../images/70.jpg)

**HTTP/1.1 之前的 HTTP 版本的默认连接都是非持久连接**。为此，如果想在旧版本的 HTTP 协议上维持持续连接，则需要指定Connection 首部字段的值为 Keep-Alive。

```shell
Connection: Keep-Alive
```



### 4.3 Date

首部字段 Date 表明创建 HTTP 报文的日期和时间。HTTP/1.1 协议使用在 RFC1123 中规定的日期时间的格式，如下示例：

```shell
Date: Tue, 03 Jul 2012 04:40:59 GMT
```

之前的 HTTP 协议版本中使用在 RFC850 中定义的格式，如下所示:

```shell
Date: Tue, 03-Jul-12 04:40:59 GMT
```

除此之外，还有一种格式。它与 C 标准库内的 asctime() 函数的输出格式一致:

```shell
Date: Tue Jul 03 04:40:59 2012
```



### 4.4 Pragma

Pragma 是 HTTP/1.1 之前版本的历史遗留字段，仅作为与 HTTP/1.0的向后兼容而定义。

规范定义的形式唯一，如下所示:

```shell
Pragma: no-cache
```

该首部字段属于通用首部字段，但只用在客户端发送的请求中。客户端会要求所有的中间服务器不返回缓存的资源。

![](../images/71.jpg)

所有的中间服务器如果都能以 HTTP/1.1 为基准，那直接采用 CacheControl: no-cache 指定缓存的处理方式是最为理想的。但要整体掌握全部中间服务器使用的 HTTP 协议版本却是不现实的。因此，发送的请求会同时含有下面两个首部字段。

```shell
Cache-Control: no-cache
Pragma: no-cache
```

### 4.5 Trailer

![](../images/72.jpg)

首部字段 Trailer 会事先说明在报文主体后记录了哪些首部字段。该首部字段可应用在 HTTP/1.1 版本分块传输编码时。

```shell
HTTP/1.1 200 OK
Date: Tue, 03 Jul 2012 04:40:56 GMT
Content-Type: text/html
...
Transfer-Encoding: chunked
Trailer: Expires
...(报文主体)...
0
Expires: Tue, 28 Sep 2004 23:59:59 GMT
```

以上用例中，指定首部字段 Trailer 的值为 Expires，在报文主体之后（分块长度 0 之后）出现了首部字段 Expires。

### 4.6 Transfer-Encoding

![](../images/73.jpg)

首部字段 Transfer-Encoding 规定了传输报文主体（请求体和响应体）时采用的编码方式。

HTTP/1.1 的传输编码方式仅对分块传输编码有效：

```shell
HTTP/1.1 200 OK
Date: Tue, 03 Jul 2012 04:40:56 GMT
Cache-Control: public, max-age=604800
Content-Type: text/javascript; charset=utf-8
Expires: Tue, 10 Jul 2012 04:40:56 GMT
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Encoding: gzip
Transfer-Encoding: chunked
Connection: keep-alive

cf0 ←16进制(10进制为3312)

...3312字节分块数据...

392 ←16进制(10进制为914)

...914字节分块数据...

0
```

以上用例中，正如在首部字段 Transfer-Encoding 中指定的那样，有效使用分块传输编码，且分别被分成 3312 字节和 914 字节大小的分块数据。

### 4.7 Upgrade

首部字段 Upgrade 用于检测 HTTP 协议及其他协议是否可使用更高的版本进行通信，其参数值可以用来指定一个完全不同的通信协议。

![](../images/74.jpg)

上图用例中，首部字段 Upgrade 指定的值为 TLS/1.0。请注意此处两个字段首部字段的对应关系，Connection 的值被指定为 Upgrade。Upgrade 首部字段产生作用的 Upgrade 对象仅限于客户端和邻接服务器之间。因此，**使用首部字段 Upgrade 时，还需要额外指定Connection:Upgrade**。

**对于附有首部字段 Upgrade 的请求，服务器可用 101 SwitchingProtocols 状态码作为响应返回**。

### 4.8 Via

使用首部字段 Via 是为了追踪客户端与服务器之间的请求和响应报文的传输路径。

报文经过代理或网关时，会先在首部字段 Via 中附加该服务器的信息，然后再进行转发。这个做法和 traceroute 及电子邮件的 Received首部的工作机制很类似。

首部字段 Via 不仅用于追踪报文的转发，还可避免请求回环的发生所以必须在经过代理时附加该首部字段内容。

![](../images/75.jpg)

上图用例中，在经过代理服务器 A 时，Via 首部附加了“1.0gw.hackr.jp (Squid/3.1)”这样的字符串值。行头的 1.0 是指接收请求的服务器上应用的 HTTP 协议版本。接下来经过代理服务器 B 时亦是如此，在 Via 首部附加服务器信息，也可增加 1 个新的 Via 首部写入服务器信息。

Via 首部是为了追踪传输路径，所以经常会和 TRACE 方法一起使用。比如，代理服务器接收到由 TRACE 方法发送过来的请求（其中Max-Forwards: 0）时，代理服务器就不能再转发该请求了。这种情况下，代理服务器会将自身的信息附加到 Via 首部后，返回该请求的响应。

### 4.9 Warning

HTTP/1.1 的 Warning 首部是从 HTTP/1.0 的响应首部（Retry-After）演变过来的。该首部通常会告知用户一些与缓存相关的问题的警告。

```shell
Warning: 113 gw.hackr.jp:8080 "Heuristic expiration" Tue, 03
```

Warning 首部的格式如下。最后的日期时间部分可省略。

```shell
Warning: [警告码][警告的主机:端口号]“[警告内容]”([日期时间])
```

HTTP/1.1 中定义了 7 种警告。警告码对应的警告内容仅推荐参考。另外，警告码具备扩展性，今后有可能追加新的警告码。

**HTTP/1.1 警告码**

![](../images/76.jpg)





## 五. 请求首部字段

请求首部字段是从客户端往服务器端发送请求报文中所使用的字段，用于补充请求的附加信息、客户端信息、对响应内容相关的优先级等内容。

### 5.1 Accept

![](../images/77.jpg)

```shell
Accept: text/html,application/xhtml+xml,application/xml;q=0.2
```

Accept 首部字段可通知服务器，用户代理能够处理的媒体类型及媒体类型的相对优先级。可使用 type/subtype 这种形式，一次指定多种媒体类型。

下面我们试举几个媒体类型的例子:

- 文本文件
  - text/html, text/plain, text/css ...
  - application/xhtml+xml, application/xml ...
- 图片文件
  - image/jpeg, image/gif, image/png ...
- 视频文件
  - video/mpeg, video/quicktime ...
- 应用程序使用的二进制文件
  - application/octet-stream, application/zip ...

比如，如果浏览器不支持 PNG 图片的显示，那 Accept 就不指定image/png，而指定可处理的 image/gif 和 image/jpeg 等图片类型。

若想要给显示的媒体类型增加优先级，则使用 q= 来额外表示权重值1，用分号（;）进行分隔。权重值 q 的范围是 0~1（可精确到小数点后 3 位），且 1 为最大值。不指定权重 q 值时，默认权重为 q=1.0。

> 1 原文是“品質係数”。在 RFC2616 定义中，此处的 q 是指 qvalue，即 qualityfactor。直译的话就是质量数，但经过综合考虑理解记忆的便利性后，似乎采用权重值更为稳妥。——译者注

当服务器提供多种内容时，将会首先返回权重值最高的媒体类型。

### 5.2 Accept-Charset

![](../images/78.jpg)

```shell
Accept-Charset: iso-8859-5, unicode-1-1;q=0.8
```

Accept-Charset 首部字段可用来通知服务器用户代理支持的字符集字符集的相对优先顺序。另外，可一次性指定多种字符集。与首部字段 Accept 相同的是可用权重 q 值来表示相对优先级。

该首部字段应用于内容协商机制的服务器驱动协商

### 5.3 Accept-Encoding

![](../images/79.jpg)

```shell
Accept-Encoding: gzip, deflate
```

Accept-Encoding 首部字段用来告知服务器用户代理支持的内容编码及内容编码的优先级顺序。可一次性指定多种内容编码。

下面试举出几个内容编码的例子:

- gzip：由文件压缩程序 gzip（GNU zip）生成的编码格式（RFC1952），采用 Lempel-Ziv 算法（LZ77）及 32 位循环冗余校验（Cyclic Redundancy Check，通称 CRC）。
- compress：由 UNIX 文件压缩程序 compress 生成的编码格式，采用 LempelZiv-Welch 算法（LZW）。
- deflate：组合使用 zlib 格式（RFC1950）及由 deflate 压缩算法（RFC1951）生成的编码格式。
- identity：不执行压缩或不会变化的默认编码格式

采用权重 q 值来表示相对优先级，这点与首部字段 Accept 相同。另外，也可使用星号（*）作为通配符，指定任意的编码格式。

### 5.4 Accept-Language

![](../images/80.jpg)

```shell
Accept-Language: zh-cn,zh;q=0.7,en-us,en;q=0.3
```

首部字段 Accept-Language 用来告知服务器用户代理能够处理的自然语言集（指中文或英文等），以及自然语言集的相对优先级。可一次指定多种自然语言集。

和 Accept 首部字段一样，按权重值 q 来表示相对优先级。在上述图例中，客户端在服务器有中文版资源的情况下，会请求其返回中文版对应的响应，没有中文版时，则请求返回英文版响应。

### 5.5 Authorization

![](../images/81.jpg)

```shell
Authorization: Basic dWVub3NlbjpwYXNzd29yZA==
```

首部字段 Authorization 是用来告知服务器，用户代理的认证信息（证书值）。通常，想要通过服务器认证的用户代理会在接收到返回的401 状态码响应后，把首部字段 Authorization 加入请求中。共用缓存在接收到含有 Authorization 首部字段的请求时的操作处理会略有差异。

有关 HTTP 访问认证及 Authorization 首部字段，稍后的章节还会详细说明。另外，读者也可参阅 RFC2616。

### 5.6 Expect

![](../images/82.jpg)

```shell
Expect: 100-continue
```

客户端使用首部字段 Expect 来告知服务器，期望出现的某种特定行为。因服务器无法理解客户端的期望作出回应而发生错误时，会返回状态码 417 Expectation Failed。

客户端可以利用该首部字段，写明所期望的扩展。虽然 HTTP/1.1 规范只定义了 100-continue（状态码 100 Continue 之意）。

等待状态码 100 响应的客户端在发生请求时，需要指定 Expect:100-continue。

### 5.7 Host

![](../images/83.jpg)

虚拟主机运行在同一个 **IP** 上，因此使用首部字段 **Host** 加以区分

```shell
Host: www.hackr.jp
```

首部字段 Host 会告知服务器，请求的资源所处的互联网主机名和端口号。**Host 首部字段在 HTTP/1.1 规范内是唯一一个必须被包含在请求内的首部字段**。

首部字段 Host 和以单台服务器分配多个域名的虚拟主机的工作机制有很密切的关联，这是首部字段 Host 必须存在的意义。

请求被发送至服务器时，请求中的主机名会用 IP 地址直接替换解决。但如果这时，相同的 IP 地址下部署运行着多个域名，那么服务器就会无法理解究竟是哪个域名对应的请求。因此，就需要使用首部字段 Host 来明确指出请求的主机名。若服务器未设定主机名，那直接发送一个空值即可。如下所示。

```shell
Host:
```

### 5.8 If-Match

详见《图解HTTP》中**6.4.9** 节（ISBN：978-7-115-35153-1）

### 5.9  If-Modified-Since

详见《图解HTTP》中**6.4.10**节（ISBN：978-7-115-35153-1）

### 5.10 If-None-Match

详见《图解HTTP》中**6.4.11**节（ISBN：978-7-115-35153-1）

### 5.11 If-Range

详见《图解HTTP》中**6.4.12**节（ISBN：978-7-115-35153-1）

### 5.12 If-Unmodified-Since

详见《图解HTTP》中**6.4.13**节（ISBN：978-7-115-35153-1）

### 5.13 Max-Forwards

![](../images/84.jpg)

```shell
Max-Forwards: 10
```

通过 TRACE 方法或 OPTIONS 方法，发送包含首部字段 Max-Forwards 的请求时，该字段以十进制整数形式指定可经过的服务器最大数目。服务器在往下一个服务器转发请求之前，Max-Forwards 的值减 1 后重新赋值。当服务器接收到 Max-Forwards 值为 0 的请求时，则不再进行转发，而是直接返回响应。

使用 HTTP 协议通信时，请求可能会经过代理等多台服务器。途中，如果代理服务器由于某些原因导致请求转发失败，客户端也就等不到服务器返回的响应了。对此，我们无从可知。

可以灵活使用首部字段 Max-Forwards，针对以上问题产生的原因展开调查。由于当 Max-Forwards 字段值为 0 时，服务器就会立即返回响应，由此我们至少可以对以那台服务器为终点的传输路径的通信状况有所把握。

![](../images/85.jpg)

![](../images/86.jpg)

### 5.14 Proxy-Authorization

```shell
Proxy-Authorization: Basic dGlwOjkpNLAGfFY5
```

接收到从代理服务器发来的认证质询时，客户端会发送包含首部字段Proxy-Authorization 的请求，以告知服务器认证所需要的信息。

这个行为是与客户端和服务器之间的 HTTP 访问认证相类似的，不同之处在于，认证行为发生在客户端与代理之间。客户端与服务器之间的认证，使用首部字段 Authorization 可起到相同作用。有关 HTTP 访问认证，后面的章节会作详尽阐述。

### 5.15 Range

```shell
Range: bytes=5001-10000
```

对于只需获取部分资源的范围请求，包含首部字段 Range 即可告知服务器资源的指定范围。上面的示例表示请求获取从第 5001 字节至第10000 字节的资源。

接收到附带 Range 首部字段请求的服务器，会在处理请求之后返回状态码为 206 Partial Content 的响应。无法处理该范围请求时，则会返回状态码 200 OK 的响应及全部资源。

### 5.16 Referer

![](../images/87.jpg)

```shell
Referer: http://www.hackr.jp/index.htm
```

首部字段 Referer 会告知服务器请求的原始资源的 URI。

客户端一般都会发送 Referer 首部字段给服务器。但当直接在浏览器的地址栏输入 URI，或出于安全性的考虑时，也可以不发送该首部字段。

因为原始资源的 URI 中的查询字符串可能含有 ID 和密码等保密信息，要是写进 Referer 转发给其他服务器，则有可能导致保密信息的泄露。

另外，Referer 的正确的拼写应该是 Referrer，但不知为何，大家一直沿用这个错误的拼写

### 5.17 User-Agent

**User-Agent** 用于传达浏览器的种类。

首部字段 User-Agent 会将创建请求的浏览器和用户代理名称等信息传达给服务器。由网络爬虫发起请求时，有可能会在字段内添加爬虫作者的电子邮件地址。此外，如果请求经过代理，那么中间也很可能被添加上代理服务器的名称。



## 六. 响应首部字段