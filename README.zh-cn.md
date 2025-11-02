# MEGASync 多实例管理器

一个与发行版无关的脚本，用于管理不同 MEGA 帐户的多个 MEGASync 实例。

<img width="959" height="762" alt="image" src="https://github.com/user-attachments/assets/4d423bb1-6dc0-42c9-9815-56c188e8dad2" />

## 功能

  - 适用于 Debian、Ubuntu、Fedora 和 Arch Linux
  - 使用 Zenity 的图形界面
  - 具有独立配置目录的隔离实例
  - 动态添加实例
  - 持久化实例存储

## 安装

运行此命令进行安装：

```bash
wget -O - https://raw.githubusercontent.com/geraldohomero/megasync-multiple-instances/refs/heads/main/megasync-manager.sh | bash -s install
```

然后使用：

```bash
mega
```

该脚本会检测您的发行版并安装依赖项（`megasync`、`zenity`）。

## 使用方法

  - 运行 `mega` 打开管理器。
  - 选择要启动的实例或添加新实例。
  - 配置实例的自动启动。

## 配置

编辑脚本的 `CONTAS` 数组以手动添加实例：

```bash
declare -A CONTAS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
)
```

## 故障排除

  - 确保有图形环境和相应权限。
  - 检查配置目录是否存在。
  - 对于自动启动，请验证 `~/.config/autostart/` 目录下的文件。

## 支持

如有错误或建议，请在 GitHub 上提交 issue。

如需支持或有任何疑问：

  - 在仓库中提交 issue
  - 查看脚本日志以获取错误信息
  - 确保所有依赖项均已安装
