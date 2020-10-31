# wsl使用zsh与终端美化

> 本文参考至：https://zhuanlan.zhihu.com/p/166103184

记录如何从bash切换到zsh，如何使用oh-my-zsh对终端进行美化以及zsh一些常用插件的安装。

## 美化后的zsh

这是我修改后的终端样式：

![](../../../%E5%B7%A5%E5%85%B7%E4%BD%BF%E7%94%A8/%E5%85%B6%E5%AE%83%E5%B7%A5%E5%85%B7/images/2.png)


## 安装zsh

- 直接使用apt命令安装即可

```bash
sudo apt-get install zsh
```

- 切换为shell为zsh

```bash
chsh -s /bin/zsh
```

想了解zsh请移步至：[终极 Shell——ZSH](https://www.cnblogs.com/dhcn/p/11666845.html)

## 安装[ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)

- 使用git进行下载

```bash
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh install.sh
```

- 打开zsh的配置文件

```bash
sudo vim ~/.zshrc
```

- 选择主题为我们下载主题：[主题列表](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)

```bash
ZSH_THEME=powerlevel10k/powerlevel10k
```

- 重新加载配置文件：

```shell
source ~/.zshrc
```

## 安装字体

为了防止终端可能会出现乱码，也是因为你的电脑不支持那么多字体，所以我们需要先安装扩展字体。

推荐使用 [Meslo Nerd Font](https://link.zhihu.com/?target=https%3A//github.com/romkatv/powerlevel10k%23meslo-nerd-font-patched-for-powerlevel10k) 字体，Download these four ttf files:

- [MesloLGS NF Regular.ttf](https://link.zhihu.com/?target=https%3A//github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%2520NF%2520Regular.ttf)
- [MesloLGS NF Bold.ttf](https://link.zhihu.com/?target=https%3A//github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%2520NF%2520Bold.ttf)
- [MesloLGS NF Italic.ttf](https://link.zhihu.com/?target=https%3A//github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%2520NF%2520Italic.ttf)
- [MesloLGS NF Bold Italic.ttf](https://link.zhihu.com/?target=https%3A//github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%2520NF%2520Bold%2520Italic.ttf)

WSL配置字体其实就是配置终端的字体，点击设置会自动跳转到一个json格式的文档。

## 配置环境变量

编辑`/etc/zsh/zshrc`文件，该文件类似ubuntu系统bash环境下的bashrc文件

## 安装自动提示插件

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

1. 下载自动补全插件至`oh-my-zsh`的插件目录中  `~/.oh-my-zsh/custom/plugins`

   ```shell
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   ```

2. 编辑 `~/.zshrc`文件，注册插件:

   ```shell
   plugins=(zsh-autosuggestions)
   ```

3. 重新加载`~/.zshrc`

   ```shell
   source ~/.zshrc
   ```

安装自动补全插件可能会遇到问题：

![](../images/3.png)

解决方案：

https://github.com/zsh-users/zsh-autosuggestions/issues/557

## wsl的ls文件夹为绿色的问题

https://www.cnblogs.com/sgmder/p/13177561.html