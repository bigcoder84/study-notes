## 使用MySQL数据库为什么永远不要UTF-8编码

​	最近我遇到了一个bug，我试着通过Rails在以“utf8”编码的MariaDB中保存一个UTF-8字符串，然后出现了一个离奇的错误：

> Incorrect string value:‘\xF0\x9F\x98\x83 <…’ for column ‘summary’ at row 1

​	我用的是UTF-8编码的客户端，服务器也是UTF-8编码的，数据库也是，就连要保存的这个字符串“ <…”也是合法的UTF-8。

​	**MySQL的“utf8”实际上不是真正的UTF-8**

​	MySQL中的UTF-8只支持每个字符最多三个字节，而真正的UTF-8是每个字符最多四个字节。MySQL一直没有修复这个bug，他们在2010年发布了一个叫作“utf8mb4”的字符集，绕过了这个问题。

简单概括如下：

- MySQL的“utf8mb4”是真正的“UTF-8”。
- MySQL的“utf8”是一种“专属的编码”，它能够编码的Unicode字符并不多。

[阅读原文](<https://mp.weixin.qq.com/s?__biz=MzU2MTI4MjI0MQ==&mid=2247486185&idx=1&sn=16a843ae0b6dc13c0aa6eed0f9e193ac&chksm=fc7a6747cb0dee51475ec22a53fa20f03eb48de66fa6976d00d285140f5dd10311c64e33fda8&xtrack=1&scene=90&subscene=93&sessionid=1556353235&clicktime=1556364023&ascene=56&devicetype=android-28&version=27000436&nettype=WIFI&abtest_cookie=BQABAAgACgALABIAEwAGAJ6GHgAjlx4AW5keAMGZHgDUmR4A3JkeAAAA&lang=zh_CN&pass_ticket=1zMwHINqsyefX%2B%2F8nJ1xjhcipdKft1gxqHZVHHGN5n%2FURo%2F84R00FClxAujiq6AO&wx_header=1>)