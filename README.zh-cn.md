# MEGASync 多实例管理器

> [English](https://github.com/geraldohomero/megasync-multiple-instances/blob/main/README.md)

一个与发行版无关的 Linux 脚本，用于管理不同 MEGA 帐户的多个 MEGASync 实例。

<img width="893" height="607" alt="image" src="https://github.com/user-attachments/assets/7094ccb4-204c-4380-a9d2-a4f1172dea76" />

## 功能

- **发行版无关：** 适用于 Debian、Ubuntu、Fedora、Arch Linux 及其衍生版。
- **双模式支持：** 包含用于自动化的完整命令行界面（CLI）和直观的 Zenity 图形界面（GUI）。
- **实时进程跟踪：** 通过各实例专用的 PID 文件与 `/proc` 检查，准确显示状态（`[Running]` / `[Stopped]`）。
- **动态进程控制：** 支持启动、停止和重启单个或所有实例，并具有防重复启动保护。
- **独立配置目录：** 每个实例运行在其独立的配置目录中。
- **开机自启与桌面启动器：** 一键配置系统开机自启和应用程序菜单启动器（`.desktop`）。
- **可视化目录选择器：** 在图形界面中方便地浏览并选择配置目录。
- **持久化配置存储：** 自动将实例账户保存在 `~/.config/megasync_accounts.conf` 中。

## 安装

运行此命令进行安装：

```bash
wget -O - https://raw.githubusercontent.com/geraldohomero/megasync-multiple-instances/refs/heads/main/megasync-manager.sh | bash -s install
```

然后使用：

```bash
mega
```

该脚本会检测您的发行版并可自动安装所需依赖项（`megasync`、`zenity`）。

## 使用方法

### 图形界面 (GUI)

在图形环境中直接运行或使用：

```bash
mega gui
```

全新的操作中心提供：
- **启动实例：** 选择已停止的实例进行启动，避免进程冲突。
- **停止 / 重启实例：** 快速停止或重启当前运行中的实例。
- **打开实例文件夹：** 在默认文件管理器中打开任何实例的配置目录。
- **添加 / 删除账户：** 通过可视化文件夹选择器添加新实例或删除旧实例。
- **配置开机自启：** 启用或禁用系统登录时的自动启动。
- **配置桌面启动器：** 创建或移除应用程序菜单快捷方式。
- **查看实时状态：** 查看清晰的状态表格，包括进程状态、PID、自启动和启动器状态。

### 命令行界面 (CLI)

您也可以直接在终端中管理所有实例：

```bash
# 查看所有实例的实时状态
mega status

# 启动指定实例或所有实例
mega start MEGASync_Instance_1
mega start --all

# 停止指定实例或所有正在运行的实例
mega stop MEGASync_Instance_1
mega stop --all

# 重启实例
mega restart MEGASync_Instance_1
mega restart --all

# 添加新实例
mega add Account_Work ~/.config/MEGASync_Work

# 删除实例
mega remove Account_Work

# 管理开机自启
mega autostart enable Account_Work
mega autostart disable Account_Work

# 管理应用程序菜单启动器
mega desktop-app enable Account_Work
mega desktop-app disable Account_Work

# 在文件管理器中打开实例目录
mega open Account_Work

# 显示帮助信息
mega --help
```

## 配置

实例账户保存在：
```text
~/.config/megasync_accounts.conf
```

格式：
```text
Account_Name=/path/to/config/dir
```

您可以通过 GUI 添加、使用 `mega add` 添加，或直接编辑此文件。

## 故障排除

- 打开 GUI 时需确保存在图形环境（`$DISPLAY` 或 `$WAYLAND_DISPLAY`）。CLI 命令可在无图形环境（Headless/SSH）下工作。
- 对于自动启动，请检查 `~/.config/autostart/` 目录中的文件。
- 对于桌面快捷方式，请检查 `~/.local/share/applications/` 目录中的文件。

## 支持

如有错误或建议，请在 GitHub 上提交 issue。
