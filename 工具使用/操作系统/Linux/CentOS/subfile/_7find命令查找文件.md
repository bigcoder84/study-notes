# Linux 命令之 find：查找文件

在 Linux 命令中，`find`用于在指定目录下查找文件。任何位于参数之前的字符串都将被视为欲查找的目录名，其支持按名称查找、按正则表达式查找、按文件大小查找、按文件权限查找等多种查询方式。如果在使用该命令时，不设置任何参数，则`find`命令将在当前目录下查找子目录与文件，并且将查找到的子目录和文件全部进行显示。

- 语法：`find [dir] [选项]`

### 常用选项列表

| 选项                   | 含义                                                         |
| ---------------------- | :----------------------------------------------------------- |
| `-perm <权限数值>`     | 查找符合指定的权限数值的文件或目录                           |
| `-type <文件类型>`     | 只寻找符合指定的文件类型的文件                               |
| `-name <范本样式>`     | 指定字符串作为寻找文件或目录的范本样式                       |
| `-expty`               | 寻找文件大小为 0 Byte 的文件，或目录下没有任何子目录或文件的空目录 |
| `-ls`                  | 假设`find`指令的回传值为`ture`，就将文件或目录名称列出到标准输出 |
| `-maxdepth <目录层级>` | 设置最大目录层级                                             |
| `-mindepth <目录层级>` | 设置最小目录层级                                             |
| `-exec <执行指令>`     | 假设`find`指令的回传值为`true`，就执行该指令                 |
| `-ok <执行指令>`       | 此参数的效果和指定`-exec`类似，但在执行指令之前会先询问用户，若回答`y`或`Y`，则放弃执行命令 |

### 示例

- **示例 1**：在`/testLinux`目录下查找以`.txt`结尾的文件名

```
// 需要书写完整的路径
find /tmp/cg/testLinux -name "*.txt"
```
- **示例 2**：组合查找文件名以`file1`开头（与、或、非）`file2`开头的文件

```
/**
 * 组合查找语法：
 * -a        与（取交集）
 * -o        或（取并集）
 * -not      非（同 ！）
 * !         非（同 not）
 */

find . -name "file1*" -a -name "file2*"
find . -name "file1*" -o -name "file2*"
find . -name "file1*" -not -name "file2*"
find . -name "file1*" ! -name "file2*"
```

- **示例 3**：根据文件类型进行搜索

```
/**
 * 查找当前目录及所有子目录下的普通文件
 */

find . -type f
```

- **示例 4**：基于目录深度进行搜索

```
/**
 * 限制最大深度为 3
 */

find . -maxdepth 3 -type f

/**
 * 限制最大深度为 2
 */

find . -maxdepth 2 -type f
```

- **示例 5**：基于文件权限进行搜索

```
/**
 * 搜索权限为 777 的文件
 */

find . -type f -perm 777

/**
 * 搜索 .txt 格式且权限不为 777 的文件
 */

find . -type f -name "*.txt" ! -perm 777
```

- **示例 6**：借助`-exec`命令，将当前目录及子目录下所有`.txt`格式的文件以`File:文件名`的形式打印出来

```
find . -type f -name "*.txt" -exec printf "File: %s\n" {} \;
```

- **示例 7**：借助`-exec`命令，将当前目录及子目录下所有 3 天前的`.txt`格式的文件复制一份到`old`目录

```
find . -type f -mtime +3 -name "*.txt" -exec cp {} old \;
```

-------


### 文件类型参数列表

| 文件类型参数 | 含义     |
| ------------ | :------- |
| `f`          | 普通文件 |
| `l`          | 符号连接 |
| `d`          | 目录     |
| `c`          | 字符设备 |
| `b`          | 块设备   |
| `s`          | 套接字   |
| `p`          | Fifo     |


### 文件大小单元列表


| 文件大小单元 | 含义           |
| ------------ | :------------- |
| `b`          | 块（512 字节） |
| `c`          | 字节           |
| `w`          | 字（2 字节）   |
| `k`          | 千字节         |
| `M`          | 兆字节         |
| `G`          | 吉字节         |

### 选项列表

| 选项                             | 含义                                                         |
| -------------------------------- | :----------------------------------------------------------- |
| `-amin <分钟>`                   | 查找在指定时间曾被存取过的文件或目录，单位以分钟计算         |
| `-atime <24小时数>`              | 查找在指定时间曾被存取过的文件或目录，单位以 24 小时计算     |
| `-cmin <分钟>`                   | 查找在指定时间之时被更改过的文件或目录                       |
| `-ctime <24小时数>`              | 查找在指定时间之时被更改的文件或目录，单位以 24 小时计算     |
| `-anewer <参考文件或目录>`       | 查找其存取时间较指定文件或目录的存取时间更接近现在的文件或目录 |
| `-cnewer <参考文件或目录>`       | 查找其更改时间较指定文件或目录的更改时间更接近现在的文件或目录 |
| `-daystart`                      | 从本日开始计算时间                                           |
| `-depth`                         | 从指定目录下最深层的子目录开始查找                           |
| `-expty`                         | 寻找文件大小为 0 Byte 的文件，或目录下没有任何子目录或文件的空目录 |
| `-exec <执行指令>`               | 假设`find`指令的回传值为`true`，就执行该指令                 |
| `-false`                         | 将`find`指令的回传值皆设为`false`                            |
| `-fls <列表文件>`                | 此参数的效果和指定`-ls`参数类似，但会把结果保存为指定的列表文件 |
| `-follow`                        | 排除符号连接                                                 |
| `-fprint <列表文件>`             | 此参数的效果和指定`-print`参数类似，但会把结果保存成指定的列表文件 |
| `-fprint0 <列表文件>`            | 此参数的效果和指定`-print0`参数类似，但会把结果保存成指定的列表文件 |
| `-fprintf <列表文件> <输出格式>` | 此参数的效果和指定`-printf`参数类似，但会把结果保存成指定的列表文件 |
| `-fstype <文件系统类型>`         | 只寻找该文件系统类型下的文件或目录                           |
| `-gid <群组识别码>`              | 查找符合指定群组识别码的文件或目录                           |
| `-group <群组名称>`              | 查找符合指定群组名称的文件或目录                             |
| `-help`或`——help`                | 在线帮助                                                     |
| `-name <范本样式>`               | 指定字符串作为寻找文件或目录的范本样式                       |
| `-iname <范本样式>`              | 此参数的效果和指定`-name`参数类似，但忽略字符大小写的差别    |
| `-ilname <范本样式>`             | 此参数的效果和指定`-lname`参数类似，但忽略字符大小写的差别   |
| `-inum <inode编号>`              | 查找符合指定的`inode`编号的文件或目录                        |
| `-path <范本样式>`               | 指定字符串作为寻找目录的范本样式                             |
| `-ipath <范本样式>`              | 此参数的效果和指定`-path`参数类似，但忽略字符大小写的差别    |
| `-iregex <范本样式>`             | 此参数的效果和指定`-regexe`参数类似，但忽略字符大小写的差别  |
| `-links <连接数目>`              | 查找符合指定的硬连接数目的文件或目录                         |
| `-ls`                            | 假设`find`指令的回传值为`ture`，就将文件或目录名称列出到标准输出 |
| `-maxdepth <目录层级>`           | 设置最大目录层级                                             |
| `-mindepth <目录层级>`           | 设置最小目录层级                                             |
| `-mmin <分钟>`                   | 查找在指定时间曾被更改过的文件或目录，单位以分钟计算         |
| `-mount`                         | 此参数的效果和指定`-xdev`相同                                |
| `-mtime <24小时数>`              | 查找在指定时间曾被更改过的文件或目录，单位以 24 小时计算     |
| `-newer <参考文件或目录>`        | 查找其更改时间较指定文件或目录的更改时间更接近现在的文件或目录 |
| `-nogroup`                       | 找出不属于本地主机群组识别码的文件或目录                     |
| `-noleaf`                        | 不去考虑目录至少需拥有两个硬连接存在                         |
| `-nouser`                        | 找出不属于本地主机用户识别码的文件或目录                     |
| `-ok <执行指令>`                 | 此参数的效果和指定`-exec`类似，但在执行指令之前会先询问用户，若回答`y`或`Y`，则放弃执行命令 |
| `-perm <权限数值>`               | 查找符合指定的权限数值的文件或目录                           |
| `-print`                         | 假设`find`指令的回传值为`ture`，就将文件或目录名称列出到标准输出，格式为每列一个名称，每个名称前皆有`./`字符串 |
| `-print0`                        | 假设`find`指令的回传值为`ture`，就将文件或目录名称列出到标准输出，格式为全部的名称皆在同一行 |
| `-printf <输出格式>`             | 假设`find`指令的回传值为`ture`，就将文件或目录名称列出到标准输出，格式可以自行指定 |
| `-prune`                         | 不寻找字符串作为寻找文件或目录的范本样式                     |
| `-regex <范本样式>`              | 指定字符串作为寻找文件或目录的范本样式                       |
| `-size <文件大小>`               | 查找符合指定的文件大小的文件                                 |
| `-true`                          | 将`find`指令的回传值皆设为`true`                             |
| `-type <文件类型>`               | 只寻找符合指定的文件类型的文件                               |
| `-uid <用户识别码>`              | 查找符合指定的用户识别码的文件或目录                         |
| `-used <日数>`                   | 查找文件或目录被更改之后在指定时间曾被存取过的文件或目录，单位以日计算 |
| `-user <拥有者名称>`             | 查找符和指定的拥有者名称的文件或目录                         |
| `-version`或`——version`          | 显示版本信息                                                 |
| `-xdev`                          | 将范围局限在先行的文件系统中                                 |
| `-xtype <文件类型>`              | 此参数的效果和指定`-type`参数类似，差别在于它针对符号连接检查 |
