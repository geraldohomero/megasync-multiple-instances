# MEGASync Multi-Instance Manager

**Persistence**: Added instances are automatically saved

## Interface Navigation

The graphical interface is designed to be intuitive and provide full user control:

### Main Menu:
- **"Start Selected"**: Starts the marked instances
- **"Exit"**: Closes the program
- **Special options**: "Add new instance..." and "Configure automatic startup..."

### Automatic Startup Configuration:
- **"Apply"**: Saves changes and returns to main menu
- **"Back"**: Returns to main menu without saving changes
- **"Cancel"**: Closes window without making changes

### Add New Instance:
- **"Next"**: Advances to configure the path
- **"Back"**: Returns to main menu
- **"Cancel"**: Closes window

### Smart Navigation:
- "Back" buttons allow returning to previous steps
- Safe cancellation at any time
- Confirmation of important actions

## Supported Distributions for managing multiple MEGASync instances on different MEGA accounts.

## Features

- **Distro-Agnostic**: Works automatically on Debian, Ubuntu, Fedora and Arch Linux
- **Graphical Interface**: Uses Zenity for a user-friendly experience with appropriately sized windows and intuitive navigation
- **Isolated Instances**: Each instance has its own configuration directory
- **Dynamic Management**: Add new instances directly through the interface
- **Persistence**: Added instances are automatically saved
- **Automatic Startup**: Configure which instances start with the system

## Supported Distributions

The script allows configuring which MEGASync instances should start automatically when you log into the system.

### How to configure:

1. Run the script normally
2. Select "Configure automatic startup..."
3. Check/uncheck the desired instances
4. Configurations are applied immediately

### How it works:

- Creates `.desktop` files in the `~/.config/autostart/` directory
- Each instance has its own configuration file
- Works with any desktop environment that supports XDG Autostart
- Instances are isolated and use their own configuration directories

### Manage configurations:

- **Enable**: Check the instance in the configuration list
- **Disable**: Uncheck the instance in the configuration list
- **Check status**: Current status is shown in the list (Enabled/Disabled)

## Recommended Naming: Works automatically on Debian, Ubuntu, Fedora and Arch Linux
- **Graphical Interface**: Uses Zenity for a user-friendly experience
- **Isolated Instances**: Each instance has its own configuration directory
- **Dynamic Management**: Add new instances directly through the interface
- **Persistence**: Added instances are automatically saved
- **Automatic Startup**: Configure which instances start with the system

## MEGASync Multi-Instance Manager

Distro-agnostic script for managing multiple MEGASync instances on different MEGA accounts.

## Features

- **Distro-Agnostic**: Works automatically on Debian, Ubuntu, Fedora and Arch Linux
- **Graphical Interface**: Uses Zenity for a user-friendly experience
- **Isolated Instances**: Each instance has its own configuration directory
- **Dynamic Management**: Add new instances directly through the interface
- **Persistence**: Added instances are automatically saved

## Supported Distributions

| Distribution | Manager | Packages | Working? |
|--------------|---------|----------|----------|
| **Debian/Ubuntu/Mint/Pop!_OS/Zorin** | `apt` | `megasync`, `zenity` | Yes |
| **Fedora/RHEL/CentOS** | `dnf` | `megasync`, `zenity` | Yes |
| **Arch/Manjaro/EndeavourOS** | `pacman` | `megasync`, `zenity` | Not tested |


## Automatic Installation

Run the command below in the terminal to install and configure the alias automatically:

```bash
wget -O - https://raw.githubusercontent.com/geraldohomero/megasync_multiple_instances/refs/heads/main/megasync-manager.sh | bash -s install
```

After installation, just use the command:

```bash
mega
```

The script will automatically detect your distribution and install the necessary dependencies.

## Recommended Naming

- **Instances:** `MEGASync_Instance_1`, `MEGASync_Instance_2`, etc.
- **Directories:** `~/.config/MEGASync_Instance_1`, `~/.config/MEGASync_Instance_2`, etc.

## Manual Configuration

Edit the `INSTANCES` section in the script to add your instances:

```bash
declare -A CONTAS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
    # Add more instances here
)
```

## Important Notes

### Permissions
Make sure the user has permissions to:
- Execute `sudo` (for package installation)
- Create directories in `~/.config/`
- Execute graphical applications

### Isolation
Each MEGASync instance uses a separate configuration directory, ensuring complete isolation between accounts.

## Troubleshooting

### Script does not detect the distribution
If the script cannot detect your distribution, it will try to automatically detect the available package manager.

### MEGASync does not start
Check if:
- The configuration directory exists and has correct permissions
- There are no conflicts with other running instances
- Dependencies are installed correctly

### Graphical interface does not appear
Make sure that:
- You are in a graphical environment (X11 or Wayland)
- Zenity is installed
- DISPLAY environment variables are configured

### Automatic Startup
If instances are not starting automatically:

- **Check files**: `.desktop` files should be in `~/.config/autostart/`
- **Permissions**: Make sure files have execute permission
- **Desktop Environment**: Some environments may ignore corrupted `.desktop` files
- **Manual test**: Execute the `.desktop` file manually to test
- **Logs**: Check system logs for error messages

### Test command:
```bash
# List startup files
ls -la ~/.config/autostart/megasync-*

# Execute manually a .desktop file
gtk-launch ~/.config/autostart/megasync-MEGASync_Instance_1.desktop
```

## Contributions

Contributions are welcome! Feel free to:
- Report bugs
- Suggest improvements
- Add support for new distributions
- Translate to other languages

## Support

For support or questions:
- Open an issue in the repository
- Check script logs for error messages
- Make sure all dependencies are installed
