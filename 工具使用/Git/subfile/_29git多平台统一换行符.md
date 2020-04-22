# Git 多平台统一换行符

最近工作使用 `sourceTree` 的时候经常发现，尽管只是很小的代码改动，但是在文件 diff 的区域莫名的多了很多空格，即使选择忽略空格，一项项提交仍有很大几率报错，很是烦恼。最初的想法是通过脚本去除掉空格，但经过一番努力依然没有彻底解决问题。

偶然的，通过对同事提交的文件使用命令行执行diff的时候，发现存在大量的 `^M` 符号，考虑到同事使用的是 windows 系统，终于意识到很有可能是换行符的问题。经过排查终于发现在 sublime 中设置了 line Endings 为 windows (CRLF)，而作为主力开发的 IDEA 设置为 LF。最终导致了项目换行符混乱。剩余内容为着力于解决问题。

## 背景

首先在不同操作系统中，换行符并不统一，Linux 系统中使用 `0x0A（LF）`, windows 系统中使用 `0x0D0A（CRLF）`, 而 MAC OS 系统起初使用`0x0D（CR）` 后来和 Linux 系统保持一致。而 git 默认采用 Linux 的换行符（当然这一点并不奇怪）。

git 为了解决不同平台换行符不一致的问题，在 windows 操作系统中默认在检出代码时将 LF 转换为 CRLF,而在提交的时候再转换为 LF，但是看似完美的解决方案在中文环境中却失效了。

## 解决方案

### 设置 git 全局参数

git 中有三个参数于换行符有关：

- `eol`: 设置工作目录中文件的换行符，有三个值 `lf`, `crlf` 和 `native`（默认，同操作系统）
- `autocrlf`:
  - `true` 表示检出是转换CRLF, 提交时转换为 LF
  - `input` 表示检出是不转换，提交时转换为 LF
  - `false` 表示不做转换
- `safecrlf`：
  - `true` 表示不允许提交时包含不同换行符
  - `warn` 则只在有不同换行符时警告
  - `false` 则允许提价时有不同换行符存在

配置方法：

```shell
#统一换行符为 lf
git config --global core.eol lf
#将自动转换关闭,避免转换失败不能不同进行提交
git config --global core.autocrlf false
#禁止混用 lf 和 crlf 两种换行符
git config --global core.safecrlf true
```

### 增加配置文件` .gitattributes`

虽然通过设置了 git 全局参数解决了问题，但是作为团队协作的话，并不能保证所有人都正确配好了。git 提供了`.gitattributes`文件解决了这个问题。在项目根目录新建`.gitattributes`文件，添加一下内容：

```shell
# Set the default behavior, in case people don't have core.autocrlf set.
* text eol=lf
```

通过这种方式避免有人没有设置` core.autocrlf`参数，并且将该文件加入版本控制中。

另外根据需要` .gitattributes `文件可以在项目不同目录中创建，而一些非文本文件可以设置为二进制文件，不用考虑换行符问题。

