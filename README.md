# MEGASync Multi-Instance Manager

> [简体中文](https://github.com/geraldohomero/megasync-multiple-instances/blob/main/README.zh-cn.md)

A distro-agnostic script to manage multiple MEGASync instances for different MEGA accounts on Linux.

<img width="893" height="607" alt="image" src="https://github.com/user-attachments/assets/7094ccb4-204c-4380-a9d2-a4f1172dea76" />

## Features

- **Distro-agnostic:** Works on Debian, Ubuntu, Fedora, Arch Linux, and derivatives.
- **Dual-mode interface:** Full command-line interface (CLI) for automation and a clean Zenity graphical interface (GUI).
- **Real-time process tracking:** Accurate instance status (`[Running]` vs `[Stopped]`) using instance-specific PID files and `/proc` verification.
- **Live process control:** Start, stop, and restart individual or all instances with duplicate launch prevention.
- **Isolated configuration:** Each instance runs with its own isolated config directory.
- **Desktop shortcuts & Autostart:** One-click configuration for system boot autostart and application menu launchers (`.desktop`).
- **Visual directory picker:** Easily choose configuration paths with file picker dialogs.
- **Persistent storage:** Automatically stores account configurations in `~/.config/megasync_accounts.conf`.

## Installation

Run this command to install:

```bash
wget -O - https://raw.githubusercontent.com/geraldohomero/megasync-multiple-instances/refs/heads/main/megasync-manager.sh | bash -s install
```

Then use:

```bash
mega
```

The script detects your distro and can install required dependencies (`megasync`, `zenity`).

## Usage

### Graphical Interface (GUI)

Run without arguments in a graphical environment or use:

```bash
mega gui
```

The redesigned Action Hub lets you:
- **Start instances:** Select stopped instances to launch without duplicate conflicts.
- **Stop / Restart instances:** Stop or restart currently running instances.
- **Open instance folder:** Open any account's config directory in your default file manager.
- **Add / Remove accounts:** Create new instances with a visual directory picker or remove old ones.
- **Configure boot autostart:** Enable or disable automatic launch on system login.
- **Configure desktop launchers:** Create or remove application menu shortcuts.
- **View real-time status:** View a clean table with process status, PID, autostart, and launcher state.

### Command-Line Interface (CLI)

You can manage all instances directly from your terminal:

```bash
# Check status of all instances
mega status

# Start a specific instance or all instances
mega start MEGASync_Instance_1
mega start --all

# Stop a specific instance or all running instances
mega stop MEGASync_Instance_1
mega stop --all

# Restart instances
mega restart MEGASync_Instance_1
mega restart --all

# Add a new instance
mega add Account_Work ~/.config/MEGASync_Work

# Remove an instance
mega remove Account_Work

# Manage boot autostart
mega autostart enable Account_Work
mega autostart disable Account_Work

# Manage desktop application menu launcher
mega desktop-app enable Account_Work
mega desktop-app disable Account_Work

# Open instance folder in file manager
mega open Account_Work

# Display help
mega --help
```

## Configuration

Instance accounts are saved in:
```text
~/.config/megasync_accounts.conf
```

Format:
```text
Account_Name=/path/to/config/dir
```

You can add or modify accounts via the GUI, using `mega add`, or by editing this file directly.

## Troubleshooting

- Ensure graphical environment (`$DISPLAY` or `$WAYLAND_DISPLAY`) when opening the GUI. CLI commands work in headless environments.
- For auto-startup, verify `~/.config/autostart/` files.
- For desktop application launchers, verify `~/.local/share/applications/` files.

## Support

Open issues on GitHub for bugs or suggestions.
