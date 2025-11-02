# MEGASync Multi-Instance Manager

> [简体中文](https://github.com/geraldohomero/megasync-multiple-instances/blob/main/README.zh-cn.md)

A distro-agnostic script to manage multiple MEGASync instances for different MEGA accounts.

<img width="959" height="762" alt="image" src="https://github.com/user-attachments/assets/4d423bb1-6dc0-42c9-9815-56c188e8dad2" />

## Features

- Works on Debian, Ubuntu, Fedora, and Arch Linux
- Graphical interface with Zenity
- Isolated instances with separate config directories
- Add instances dynamically
- Persistent instance storage

## Installation

Run this command to install:

```bash
wget -O - https://raw.githubusercontent.com/geraldohomero/megasync-multiple-instances/refs/heads/main/megasync-manager.sh | bash -s install
```

Then use:

```bash
mega
```

The script detects your distro and installs dependencies (`megasync`, `zenity`).

## Usage

- Run `mega` to open the manager.
- Select instances to start or add new ones.
- Configure auto-startup for instances.

## Configuration

Edit the script's `ACCOUNTS` array to add instances manually:

```bash
declare -A ACCOUNTS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
)
```

## Troubleshooting

- Ensure graphical environment and permissions.
- Check config directories exist.
- For auto-startup, verify `~/.config/autostart/` files.

## Support

Open issues on GitHub for bugs or suggestions.

For support or questions:
- Open an issue in the repository
- Check script logs for error messages
- Make sure all dependencies are installed
