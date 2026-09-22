#!/bin/bash
# Script to manage multiple instances of MEGAsync with different accounts
# DISTRO-AGNOSTIC: Compatible with Debian, Ubuntu, Fedora, and Arch Linux
#
# FEATURES:
# - Full CLI and Zenity GUI support
# - Real-time process tracking via instance PID files and /proc inspection
# - Graceful stop, start, and restart capabilities
# - Isolated configuration directories per instance
# - Autostart on boot and desktop application launcher generation
# - Visual folder picker and xdg-open integration
# - Clean, sober text interface without emojis
#
# Author: https://github.com/geraldohomero
# Link: https://github.com/geraldohomero/megasync-multiple-instances

# === COLOR OUTPUT ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Message function with color
msg() {
    local type="$1"
    local custom="$2"
    local color="$NC"
    case "$type" in
        install_success|alias_added|copying_script|chmod_script|sourcing_alias|updated_script|symlink_added)
            color="$GREEN" ;;
        already_installed)
            color="$YELLOW" ;;
        error|fail|fatal)
            color="$RED" ;;
    esac
    case "$type" in
        install_success) echo -e "${color}Installation complete! Use the 'mega' command to start the MEGAsync instance manager.${NC}";;
        alias_added) echo -e "${color}Alias 'mega' added to ~/.bash_aliases.${NC}";;
        symlink_added) echo -e "${color}Binary link created at ~/.local/bin/mega.${NC}";;
        already_installed) echo -e "${color}Script is already installed at ~/megasync-manager.sh.${NC}";;
        copying_script) echo -e "${color}Copying script to ~/megasync-manager.sh...${NC}";;
        updated_script) echo -e "${color}Updating script at ~/megasync-manager.sh...${NC}";;
        chmod_script) echo -e "${color}Setting executable permission...${NC}";;
        sourcing_alias) echo -e "${color}Reloading bash aliases...${NC}";;
        error) echo -e "${color}${custom}${NC}";;
        *) echo -e "${color}${custom}${NC}";;
    esac
}

# === INSTALL MODE ===
if [[ "$1" == "install" ]]; then
    INSTALL_PATH="$HOME/megasync-manager.sh"
    ALIAS_CMD="alias mega='bash $INSTALL_PATH'"
    BASH_ALIASES="$HOME/.bash_aliases"
    LOCAL_BIN="$HOME/.local/bin"

    if [ -f "$INSTALL_PATH" ]; then
        msg updated_script
    else
        msg copying_script
    fi

    if [ -r "$0" ] && [ "$0" != "bash" ]; then
        cp "$0" "$INSTALL_PATH"
    else
        cat > "$INSTALL_PATH" <&0
    fi
    msg chmod_script
    chmod +x "$INSTALL_PATH"

    # Add alias if not present
    if ! grep -q "alias mega=" "$BASH_ALIASES" 2>/dev/null; then
        echo "$ALIAS_CMD" >> "$BASH_ALIASES"
        msg alias_added
    fi

    # Create symlink in ~/.local/bin for system-wide user PATH support
    mkdir -p "$LOCAL_BIN"
    ln -sf "$INSTALL_PATH" "$LOCAL_BIN/mega"
    msg symlink_added

    msg sourcing_alias
    source "$BASH_ALIASES" 2>/dev/null
    msg install_success
    exit 0
fi

# Detect Linux distribution and set up package manager
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID=$ID
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO_ID=$DISTRIB_ID
        DISTRO_NAME=$DISTRIB_DESCRIPTION
    elif command -v lsb_release &> /dev/null; then
        DISTRO_ID=$(lsb_release -i | cut -d: -f2 | tr -d '[:space:]')
        DISTRO_NAME=$(lsb_release -d | cut -d: -f2 | tr -d '[:space:]')
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Distribution"
    fi
    
    DISTRO_ID=$(echo "$DISTRO_ID" | tr '[:upper:]' '[:lower:]')
}

setup_package_manager() {
    case $DISTRO_ID in
        ubuntu|debian|linuxmint|zorin|pop|elementary|kali|raspbian|mx|antix|pureos)
            PACKAGE_MANAGER="apt"
            INSTALL_CMD="sudo apt update && sudo apt install -y"
            MEGASYNC_PACKAGE="megasync"
            ZENITY_PACKAGE="zenity"
            ;;
        fedora|rhel|centos|almalinux|rocky|ol|nobara)
            PACKAGE_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            MEGASYNC_PACKAGE="megasync"
            ZENITY_PACKAGE="zenity"
            ;;
        arch|manjaro|endeavouros|garuda|arcolinux|artix)
            PACKAGE_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            MEGASYNC_PACKAGE="megasync"
            ZENITY_PACKAGE="zenity"
            ;;
        *)
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
                INSTALL_CMD="sudo apt update && sudo apt install -y"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            elif command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            elif command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                MEGASYNC_PACKAGE="megasync"
                ZENITY_PACKAGE="zenity"
            else
                PACKAGE_MANAGER="unknown"
            fi
            ;;
    esac
}

check_and_install() {
    local cmd=$1
    local package_name=$2
    local local_paths=("$HOME/bin/$cmd" "$HOME/local/bin/$cmd" "$HOME/.local/bin/$cmd")
    
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    
    for path in "${local_paths[@]}"; do
        if [ -x "$path" ]; then
            if [ "$cmd" = "megasync" ]; then
                MEGASYNC_CMD="$path"
            elif [ "$cmd" = "zenity" ]; then
                ZENITY_CMD="$path"
            fi
            return 0
        fi
    done
    
    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        echo "ERROR: Missing dependency '$cmd'. Please install manually." >&2
        return 1
    fi

    echo "Dependency '$cmd' was not found."
    read -p "Do you want to install '$package_name' via $PACKAGE_MANAGER now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v sudo &> /dev/null; then
            eval "$INSTALL_CMD $package_name"
        else
            echo "'sudo' command not found. Run as root or install '$package_name' manually." >&2
            return 1
        fi
        
        if ! command -v "$cmd" &> /dev/null; then
            echo "Installation failed for '$package_name'." >&2
            return 1
        fi
        echo "'$package_name' installed successfully."
        return 0
    else
        echo "Installation canceled for '$cmd'." >&2
        return 1
    fi
}

# Distro setup
detect_distro
setup_package_manager

# Set executable paths
MEGASYNC_CMD=${MEGASYNC_CMD:-megasync}
ZENITY_CMD=${ZENITY_CMD:-zenity}

# Directories and Files
ACCOUNTS_FILE="${MEGASYNC_ACCOUNTS_FILE:-$HOME/.config/megasync_accounts.conf}"
AUTOSTART_DIR="${MEGASYNC_AUTOSTART_DIR:-$HOME/.config/autostart}"
DESKTOP_APPS_DIR="${MEGASYNC_DESKTOP_DIR:-$HOME/.local/share/applications}"

# Accounts storage
declare -A ACCOUNTS

load_accounts() {
    ACCOUNTS=()
    local name path
    if [ -f "$ACCOUNTS_FILE" ]; then
        while IFS='=' read -r name path; do
            # Trim leading/trailing whitespace
            name="$(echo "$name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            path="$(echo "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [ -n "$name" ] && [ -n "$path" ] && [[ ! "$name" =~ ^# ]]; then
                ACCOUNTS["$name"]="$path"
            fi
        done < "$ACCOUNTS_FILE"
    fi

    # Auto-migrate legacy MEGASync_Instance_1 if directory exists but not yet in config file
    local migration_marker="$(dirname "$ACCOUNTS_FILE")/.megasync_v1_migrated"
    if [ ! -f "$migration_marker" ]; then
        if [ -d "$HOME/.config/MEGASync_Instance_1" ] && [ -z "${ACCOUNTS[MEGASync_Instance_1]}" ]; then
            ACCOUNTS["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
            save_accounts
        fi
        touch "$migration_marker" 2>/dev/null
    fi
}

save_accounts() {
    mkdir -p "$(dirname "$ACCOUNTS_FILE")"
    > "$ACCOUNTS_FILE"
    local name
    for name in "${!ACCOUNTS[@]}"; do
        echo "$name=${ACCOUNTS[$name]}" >> "$ACCOUNTS_FILE"
    done
}

# === PROCESS MANAGEMENT ===

get_pid_file() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"
    if [ -n "$config_path" ]; then
        echo "$config_path/megasync.pid"
    fi
}

get_instance_pid() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"
    [ -z "$config_path" ] && return 1

    local pid_file
    pid_file=$(get_pid_file "$instance_name")

    local cmd_base
    cmd_base="$(basename "$MEGASYNC_CMD" | tr '[:upper:]' '[:lower:]')"

    # 1. Check existing PID file
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            # Verify command line or comm belongs to megasync
            if { [ -f "/proc/$pid/cmdline" ] && grep -qai "$cmd_base" "/proc/$pid/cmdline" 2>/dev/null; } || \
               { [ -f "/proc/$pid/comm" ] && grep -qai "$cmd_base" "/proc/$pid/comm" 2>/dev/null; }; then
                echo "$pid"
                return 0
            fi
        fi
        # Stale PID file
        rm -f "$pid_file" 2>/dev/null
    fi

    # 2. Fallback: inspect /proc for processes where HOME matches instance config path
    if [ -d "$config_path" ]; then
        for env_file in /proc/[0-9]*/environ; do
            if [ -r "$env_file" ] 2>/dev/null; then
                local pid
                pid=$(basename "$(dirname "$env_file")")
                if grep -qa "HOME=$config_path" "$env_file" 2>/dev/null; then
                    if { [ -f "/proc/$pid/cmdline" ] && grep -qai "$cmd_base" "/proc/$pid/cmdline" 2>/dev/null; } || \
                       { [ -f "/proc/$pid/comm" ] && grep -qai "$cmd_base" "/proc/$pid/comm" 2>/dev/null; }; then
                        echo "$pid" > "$pid_file" 2>/dev/null
                        echo "$pid"
                        return 0
                    fi
                fi
            fi
        done
    fi

    return 1
}

is_pid_alive() {
    local pid="$1"
    [ -z "$pid" ] && return 1
    if kill -0 "$pid" 2>/dev/null; then
        # Check if zombie/defunct in /proc
        if [ -f "/proc/$pid/status" ] && grep -q "State:[[:space:]]*Z" "/proc/$pid/status" 2>/dev/null; then
            return 1
        fi
        return 0
    fi
    return 1
}

is_instance_running() {
    local instance_name="$1"
    local pid
    pid=$(get_instance_pid "$instance_name")
    [ -n "$pid" ]
}

start_instance() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"

    if [ -z "$config_path" ]; then
        echo "Error: Instance '$instance_name' is not configured." >&2
        return 1
    fi

    local current_pid
    current_pid=$(get_instance_pid "$instance_name")
    if [ -n "$current_pid" ]; then
        echo "Instance '$instance_name' is already running (PID: $current_pid)."
        return 0
    fi

    mkdir -p "$config_path"
    echo "Starting MEGAsync instance '$instance_name'..."

    # Launch instance with isolated HOME
    (
        HOME="$config_path"
        exec "$MEGASYNC_CMD" >/dev/null 2>&1
    ) &
    local new_pid=$!

    local pid_file
    pid_file=$(get_pid_file "$instance_name")
    echo "$new_pid" > "$pid_file"

    # Brief pause to verify process did not immediately crash
    sleep 0.5
    if is_pid_alive "$new_pid"; then
        echo "Instance '$instance_name' started successfully (PID: $new_pid)."
        return 0
    else
        echo "Failed to start instance '$instance_name'." >&2
        rm -f "$pid_file" 2>/dev/null
        return 1
    fi
}

stop_instance() {
    local instance_name="$1"
    local pid
    pid=$(get_instance_pid "$instance_name")

    if [ -z "$pid" ]; then
        echo "Instance '$instance_name' is not running."
        local pid_file
        pid_file=$(get_pid_file "$instance_name")
        [ -f "$pid_file" ] && rm -f "$pid_file" 2>/dev/null
        return 0
    fi

    echo "Stopping instance '$instance_name' (PID: $pid)..."
    kill -TERM "$pid" 2>/dev/null
    pkill -P "$pid" 2>/dev/null

    # Wait up to 5 seconds for graceful shutdown
    local count=0
    while is_pid_alive "$pid" && [ $count -lt 10 ]; do
        sleep 0.5
        ((count++))
    done

    # Force kill if still unresponsive
    if is_pid_alive "$pid"; then
        echo "Process $pid did not exit cleanly, sending SIGKILL..."
        kill -KILL "$pid" 2>/dev/null
        pkill -9 -P "$pid" 2>/dev/null
        sleep 0.5
    fi

    local pid_file
    pid_file=$(get_pid_file "$instance_name")
    rm -f "$pid_file" 2>/dev/null

    if ! is_pid_alive "$pid"; then
        echo "Instance '$instance_name' stopped."
        return 0
    else
        echo "Error: Failed to stop instance '$instance_name'." >&2
        return 1
    fi
}

restart_instance() {
    local instance_name="$1"
    echo "Restarting instance '$instance_name'..."
    stop_instance "$instance_name"
    sleep 1
    start_instance "$instance_name"
}

# === AUTOSTART & DESKTOP LAUNCHERS ===

is_autostart_enabled() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ]
}

create_autostart_desktop() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"
    [ -z "$config_path" ] && return 1

    mkdir -p "$AUTOSTART_DIR"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    local exec_path="$MEGASYNC_CMD"

    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=MEGASync ($instance_name)
Exec=env HOME="$config_path" "$exec_path"
Icon=megasync
Comment=MEGASync instance for $instance_name
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF

    chmod +x "$desktop_file"
}

remove_autostart_desktop() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ] && rm -f "$desktop_file"
}

is_desktop_app_enabled() {
    local instance_name="$1"
    local desktop_file="$DESKTOP_APPS_DIR/megasync-instance-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ]
}

create_desktop_app_desktop() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"
    [ -z "$config_path" ] && return 1

    mkdir -p "$DESKTOP_APPS_DIR"
    local desktop_file="$DESKTOP_APPS_DIR/megasync-instance-${instance_name// /_}.desktop"
    local exec_path="$MEGASYNC_CMD"

    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=MEGASync Instance ($instance_name)
Exec=env HOME="$config_path" "$exec_path"
Icon=megasync
Comment=Launch MEGASync instance for $instance_name
Terminal=false
StartupNotify=true
Categories=Network;FileTransfer;
EOF

    chmod +x "$desktop_file"
}

remove_desktop_app_desktop() {
    local instance_name="$1"
    local desktop_file="$DESKTOP_APPS_DIR/megasync-instance-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ] && rm -f "$desktop_file"
}

open_account_folder() {
    local instance_name="$1"
    local config_path="${ACCOUNTS[$instance_name]}"
    if [ -z "$config_path" ]; then
        echo "Error: Instance '$instance_name' not found." >&2
        return 1
    fi
    mkdir -p "$config_path"
    if command -v xdg-open &>/dev/null; then
        xdg-open "$config_path" >/dev/null 2>&1 &
        echo "Opened directory for '$instance_name': $config_path"
        return 0
    else
        echo "xdg-open not found. Folder path: $config_path"
        return 1
    fi
}

# === CLI COMMANDS ===

cli_help() {
    echo -e "${BOLD}MEGASync Multi-Instance Manager${NC}"
    echo ""
    echo -e "Usage: mega [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  status                            Show table with status of all instances"
    echo "  start [name | --all]              Start a specific instance or all instances"
    echo "  stop [name | --all]               Stop a specific instance or all running instances"
    echo "  restart [name | --all]            Restart a specific instance or all instances"
    echo "  add <name> [config_path]          Add a new instance (default path: ~/.config/<name>)"
    echo "  remove <name>                     Stop instance and remove its launchers and config"
    echo "  autostart <enable|disable> <name> Configure system boot autostart"
    echo "  desktop-app <enable|disable> <name> Configure desktop application launcher"
    echo "  open <name>                       Open instance folder in default file manager"
    echo "  gui                               Launch graphical Zenity interface"
    echo "  help, --help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  mega status"
    echo "  mega start MEGASync_Instance_1"
    echo "  mega start --all"
    echo "  mega stop --all"
    echo "  mega add Account_Work ~/.config/MEGASync_Work"
    echo "  mega autostart enable Account_Work"
}

cli_status() {
    load_accounts
    local name
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        echo "No MEGASync instances configured yet."
        echo "Run 'mega add <name>' or 'mega gui' to add an instance."
        return 0
    fi

    printf "%-25s %-14s %-8s %-12s %-14s %s\n" "INSTANCE" "STATUS" "PID" "AUTOSTART" "DESKTOP APP" "CONFIG PATH"
    printf "%-25s %-14s %-8s %-12s %-14s %s\n" "-------------------------" "--------------" "--------" "------------" "--------------" "---------------------------"

    for name in "${!ACCOUNTS[@]}"; do
        local pid
        pid=$(get_instance_pid "$name")
        local status_str="[Stopped]"
        local pid_str="-"
        if [ -n "$pid" ]; then
            status_str="[Running]"
            pid_str="$pid"
        fi

        local autostart_str="No"
        is_autostart_enabled "$name" && autostart_str="Yes"

        local desktop_str="No"
        is_desktop_app_enabled "$name" && desktop_str="Yes"

        printf "%-25s %-14s %-8s %-12s %-14s %s\n" "$name" "$status_str" "$pid_str" "$autostart_str" "$desktop_str" "${ACCOUNTS[$name]}"
    done
}

cli_start() {
    load_accounts
    local target="$1"
    local name

    if [ -z "$target" ]; then
        echo "Error: Specify an instance name or --all." >&2
        return 1
    fi

    if [ "$target" = "--all" ]; then
        if [ ${#ACCOUNTS[@]} -eq 0 ]; then
            echo "No instances configured."
            return 0
        fi
        for name in "${!ACCOUNTS[@]}"; do
            start_instance "$name"
        done
        return 0
    fi

    if [ -z "${ACCOUNTS[$target]}" ]; then
        echo "Error: Instance '$target' not found." >&2
        return 1
    fi

    start_instance "$target"
}

cli_stop() {
    load_accounts
    local target="$1"
    local name

    if [ -z "$target" ]; then
        echo "Error: Specify an instance name or --all." >&2
        return 1
    fi

    if [ "$target" = "--all" ]; then
        if [ ${#ACCOUNTS[@]} -eq 0 ]; then
            echo "No instances configured."
            return 0
        fi
        for name in "${!ACCOUNTS[@]}"; do
            if is_instance_running "$name"; then
                stop_instance "$name"
            fi
        done
        return 0
    fi

    if [ -z "${ACCOUNTS[$target]}" ]; then
        echo "Error: Instance '$target' not found." >&2
        return 1
    fi

    stop_instance "$target"
}

cli_restart() {
    load_accounts
    local target="$1"
    local name

    if [ -z "$target" ]; then
        echo "Error: Specify an instance name or --all." >&2
        return 1
    fi

    if [ "$target" = "--all" ]; then
        for name in "${!ACCOUNTS[@]}"; do
            restart_instance "$name"
        done
        return 0
    fi

    if [ -z "${ACCOUNTS[$target]}" ]; then
        echo "Error: Instance '$target' not found." >&2
        return 1
    fi

    restart_instance "$target"
}

cli_add() {
    load_accounts
    local name="$1"
    local path="$2"

    if [ -z "$name" ]; then
        echo "Error: Instance name is required. Usage: mega add <name> [config_path]" >&2
        return 1
    fi

    if [ -n "${ACCOUNTS[$name]}" ]; then
        echo "Error: Instance '$name' already exists." >&2
        return 1
    fi

    if [ -z "$path" ]; then
        path="$HOME/.config/$name"
    fi

    mkdir -p "$path"
    ACCOUNTS["$name"]="$path"
    save_accounts
    echo "Instance '$name' added with configuration path: $path"
}

cli_remove() {
    load_accounts
    local name="$1"

    if [ -z "$name" ]; then
        echo "Error: Instance name is required. Usage: mega remove <name>" >&2
        return 1
    fi

    if [ -z "${ACCOUNTS[$name]}" ]; then
        echo "Error: Instance '$name' not found." >&2
        return 1
    fi

    stop_instance "$name"
    remove_autostart_desktop "$name"
    remove_desktop_app_desktop "$name"

    unset ACCOUNTS["$name"]
    save_accounts
    echo "Instance '$name' removed successfully."
}

cli_autostart() {
    load_accounts
    local action="$1"
    local name="$2"

    if [ -z "$action" ] || [ -z "$name" ]; then
        echo "Usage: mega autostart <enable|disable> <name>" >&2
        return 1
    fi

    if [ -z "${ACCOUNTS[$name]}" ]; then
        echo "Error: Instance '$name' not found." >&2
        return 1
    fi

    case "$action" in
        enable)
            create_autostart_desktop "$name"
            echo "Autostart enabled for '$name'."
            ;;
        disable)
            remove_autostart_desktop "$name"
            echo "Autostart disabled for '$name'."
            ;;
        *)
            echo "Error: Unknown action '$action'. Use 'enable' or 'disable'." >&2
            return 1
            ;;
    esac
}

cli_desktop_app() {
    load_accounts
    local action="$1"
    local name="$2"

    if [ -z "$action" ] || [ -z "$name" ]; then
        echo "Usage: mega desktop-app <enable|disable> <name>" >&2
        return 1
    fi

    if [ -z "${ACCOUNTS[$name]}" ]; then
        echo "Error: Instance '$name' not found." >&2
        return 1
    fi

    case "$action" in
        enable)
            create_desktop_app_desktop "$name"
            echo "Desktop launcher enabled for '$name'."
            ;;
        disable)
            remove_desktop_app_desktop "$name"
            echo "Desktop launcher disabled for '$name'."
            ;;
        *)
            echo "Error: Unknown action '$action'. Use 'enable' or 'disable'." >&2
            return 1
            ;;
    esac
}

# === ZENITY GUI IMPLEMENTATION ===

gui_notify() {
    local message="$1"
    local timeout="${2:-3}"
    "$ZENITY_CMD" --notification --text="$message" --timeout="$timeout" 2>/dev/null &
}

gui_start_instances() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Start Instances" --text="No instances configured yet. Please add an instance first." --width=450 --height=120
        return 0
    fi

    local name inst
    local options=()
    for name in "${!ACCOUNTS[@]}"; do
        local pid
        pid=$(get_instance_pid "$name")
        if [ -n "$pid" ]; then
            options+=(FALSE "$name" "[Running (PID: $pid)]")
        else
            options+=(TRUE "$name" "[Stopped]")
        fi
    done

    local selected
    selected=$("$ZENITY_CMD" --list \
        --title="Start MEGASync Instances" \
        --text="Select the instances you want to start:\n(Instances already running will be skipped)" \
        --checklist \
        --column="Select" \
        --column="Instance" \
        --column="Current Status" \
        --width=650 --height=450 \
        --ok-label="Start Selected" \
        --cancel-label="Back" \
        "${options[@]}" \
        --separator="|")

    [ $? -ne 0 ] && return 0
    [ -z "$selected" ] && return 0

    IFS='|' read -ra selected_arr <<< "$selected"
    local started_count=0
    for inst in "${selected_arr[@]}"; do
        if ! is_instance_running "$inst"; then
            start_instance "$inst"
            ((started_count++))
        fi
    done

    gui_notify "$started_count instance(s) started." 3
}

gui_stop_restart_instances() {
    load_accounts
    local name inst
    local running_instances=()
    for name in "${!ACCOUNTS[@]}"; do
        local pid
        pid=$(get_instance_pid "$name")
        if [ -n "$pid" ]; then
            running_instances+=(FALSE "$name" "$pid")
        fi
    done

    if [ ${#running_instances[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Stop / Restart" --text="No MEGASync instances are currently running." --width=450 --height=120
        return 0
    fi

    local selected
    selected=$("$ZENITY_CMD" --list \
        --title="Stop / Restart Instances" \
        --text="Select running instances to manage:" \
        --checklist \
        --column="Select" \
        --column="Instance" \
        --column="PID" \
        --width=600 --height=400 \
        --extra-button="Restart Selected" \
        --ok-label="Stop Selected" \
        --cancel-label="Back" \
        "${running_instances[@]}" \
        --separator="|")

    local exit_code=$?
    [ $exit_code -eq 1 ] && return 0 # Back pressed
    [ -z "$selected" ] && return 0

    IFS='|' read -ra selected_arr <<< "$selected"

    # Check if extra button "Restart Selected" was pressed (exit code 1 or extra button label)
    if [ "$selected" = "Restart Selected" ] || [ $exit_code -eq 100 ]; then
        for inst in "${selected_arr[@]}"; do
            restart_instance "$inst"
        done
        gui_notify "Selected instance(s) restarted." 3
    else
        for inst in "${selected_arr[@]}"; do
            stop_instance "$inst"
        done
        gui_notify "Selected instance(s) stopped." 3
    fi
}

gui_add_account() {
    load_accounts

    # Find next default instance number
    local num=1
    while [ -n "${ACCOUNTS[MEGASync_Instance_$num]}" ]; do
        ((num++))
    done
    local default_name="MEGASync_Instance_$num"

    local account_name
    account_name=$("$ZENITY_CMD" --entry \
        --title="Add New Account" \
        --text="Enter a name for the new account:" \
        --entry-text="$default_name" \
        --width=500 --height=150 \
        --ok-label="Next" \
        --cancel-label="Cancel")

    [ $? -ne 0 ] || [ -z "$account_name" ] && return 0

    if [ -n "${ACCOUNTS[$account_name]}" ]; then
        "$ZENITY_CMD" --error --title="Error" --text="An account named '$account_name' already exists." --width=420 --height=120
        return 0
    fi

    local default_path="$HOME/.config/$account_name"
    local config_path="$default_path"

    while true; do
        local choice
        choice=$("$ZENITY_CMD" --entry \
            --title="Configuration Directory" \
            --text="Configuration path for '$account_name':\n(Press Next to accept default, or click Browse to choose a folder)" \
            --entry-text="$config_path" \
            --extra-button="Browse..." \
            --width=600 --height=170 \
            --ok-label="Next" \
            --cancel-label="Cancel")
        local ret=$?

        if [ $ret -ne 0 ]; then
            if [ "$choice" = "Browse..." ]; then
                local chosen_dir
                chosen_dir=$("$ZENITY_CMD" --file-selection \
                    --directory \
                    --title="Select Directory for $account_name" \
                    --filename="$HOME/")
                if [ $? -eq 0 ] && [ -n "$chosen_dir" ]; then
                    config_path="$chosen_dir"
                fi
                continue
            fi
            return 0
        fi

        config_path="$choice"
        [ -n "$config_path" ] && break
    done

    mkdir -p "$config_path"
    ACCOUNTS["$account_name"]="$config_path"
    save_accounts

    # Prompt for desktop launcher
    if "$ZENITY_CMD" --question --title="Desktop Launcher" --text="Create a desktop launcher for '$account_name' in your applications menu?" --width=500 --height=130; then
        create_desktop_app_desktop "$account_name"
    fi

    # Prompt for autostart
    if "$ZENITY_CMD" --question --title="Autostart" --text="Enable autostart on system boot for '$account_name'?" --width=500 --height=130; then
        create_autostart_desktop "$account_name"
    fi

    "$ZENITY_CMD" --info --title="Success" --text="Account '$account_name' added successfully!" --width=420 --height=120
}

gui_remove_account() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Remove Account" --text="No accounts to remove." --width=400 --height=120
        return 0
    fi

    local name
    local options=()
    for name in "${!ACCOUNTS[@]}"; do
        options+=("$name")
    done

    local target
    target=$("$ZENITY_CMD" --list \
        --title="Remove MEGASync Account" \
        --text="Select the account you want to remove:\n(Note: This will not delete your local sync files)" \
        --radiolist \
        --column="" \
        --column="Account" \
        --width=550 --height=400 \
        --ok-label="Remove" \
        --cancel-label="Back" \
        FALSE "${options[0]}" \
        "${options[@]:1}")

    [ $? -ne 0 ] || [ -z "$target" ] && return 0

    if "$ZENITY_CMD" --question --title="Confirm Removal" --text="Are you sure you want to remove '$target'?\n\nThis will stop the instance and remove its shortcuts." --width=500 --height=150; then
        cli_remove "$target"
        "$ZENITY_CMD" --info --title="Success" --text="Account '$target' removed successfully." --width=400 --height=120
    fi
}

gui_open_folder() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Open Folder" --text="No accounts configured." --width=400 --height=120
        return 0
    fi

    local name
    local options=()
    for name in "${!ACCOUNTS[@]}"; do
        options+=("$name" "${ACCOUNTS[$name]}")
    done

    local target
    target=$("$ZENITY_CMD" --list \
        --title="Open Account Folder" \
        --text="Select an account to open its configuration folder in your file manager:" \
        --column="Account" \
        --column="Directory" \
        --width=650 --height=400 \
        --ok-label="Open" \
        --cancel-label="Back" \
        "${options[@]}")

    [ $? -ne 0 ] || [ -z "$target" ] && return 0

    open_account_folder "$target"
}

gui_configure_autostart() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Autostart" --text="No accounts configured." --width=400 --height=120
        return 0
    fi

    local name sel
    local options=()
    for name in "${!ACCOUNTS[@]}"; do
        if is_autostart_enabled "$name"; then
            options+=(TRUE "$name" "[Enabled]")
        else
            options+=(FALSE "$name" "[Disabled]")
        fi
    done

    local selected
    selected=$("$ZENITY_CMD" --list \
        --title="Configure Boot Autostart" \
        --text="Select instances that should start automatically on system login:\n- Check to enable\n- Uncheck to disable" \
        --checklist \
        --column="Autostart" \
        --column="Instance" \
        --column="Status" \
        --width=600 --height=450 \
        --extra-button="Disable All" \
        --ok-label="Apply" \
        --cancel-label="Back" \
        "${options[@]}" \
        --separator="|")

    local exit_code=$?
    if [ "$selected" = "Disable All" ]; then
        for name in "${!ACCOUNTS[@]}"; do
            remove_autostart_desktop "$name"
        done
        "$ZENITY_CMD" --info --title="Autostart" --text="All autostart entries have been disabled." --width=450 --height=120
        return 0
    fi

    [ $exit_code -ne 0 ] && return 0

    IFS='|' read -ra selected_arr <<< "$selected"
    for name in "${!ACCOUNTS[@]}"; do
        local should_enable=false
        for sel in "${selected_arr[@]}"; do
            if [ "$sel" = "$name" ]; then
                should_enable=true
                break
            fi
        done

        if $should_enable; then
            create_autostart_desktop "$name"
        else
            remove_autostart_desktop "$name"
        fi
    done

    "$ZENITY_CMD" --info --title="Autostart" --text="Autostart configuration updated successfully." --width=450 --height=120
}

gui_configure_desktop_apps() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Desktop Launchers" --text="No accounts configured." --width=400 --height=120
        return 0
    fi

    local name sel
    local options=()
    for name in "${!ACCOUNTS[@]}"; do
        if is_desktop_app_enabled "$name"; then
            options+=(TRUE "$name" "[Enabled]")
        else
            options+=(FALSE "$name" "[Disabled]")
        fi
    done

    local selected
    selected=$("$ZENITY_CMD" --list \
        --title="Configure Desktop Launchers" \
        --text="Select instances that should have desktop / application menu shortcuts:\n- Check to create launcher\n- Uncheck to remove launcher" \
        --checklist \
        --column="Launcher" \
        --column="Instance" \
        --column="Status" \
        --width=600 --height=450 \
        --ok-label="Apply" \
        --cancel-label="Back" \
        "${options[@]}" \
        --separator="|")

    [ $? -ne 0 ] && return 0

    IFS='|' read -ra selected_arr <<< "$selected"
    for name in "${!ACCOUNTS[@]}"; do
        local should_enable=false
        for sel in "${selected_arr[@]}"; do
            if [ "$sel" = "$name" ]; then
                should_enable=true
                break
            fi
        done

        if $should_enable; then
            create_desktop_app_desktop "$name"
        else
            remove_desktop_app_desktop "$name"
        fi
    done

    "$ZENITY_CMD" --info --title="Desktop Launchers" --text="Desktop launcher configuration updated successfully." --width=450 --height=120
}

gui_show_status() {
    load_accounts
    if [ ${#ACCOUNTS[@]} -eq 0 ]; then
        "$ZENITY_CMD" --info --title="Status" --text="No accounts configured." --width=400 --height=120
        return 0
    fi

    local name
    local rows=()
    for name in "${!ACCOUNTS[@]}"; do
        local pid
        pid=$(get_instance_pid "$name")
        local status_str="[Stopped]"
        local pid_str="-"
        if [ -n "$pid" ]; then
            status_str="[Running]"
            pid_str="$pid"
        fi

        local autostart_str="No"
        is_autostart_enabled "$name" && autostart_str="Yes"

        local desktop_str="No"
        is_desktop_app_enabled "$name" && desktop_str="Yes"

        rows+=("$name" "$status_str" "$pid_str" "$autostart_str" "$desktop_str")
    done

    "$ZENITY_CMD" --list \
        --title="MEGASync Real-Time Status" \
        --text="Current system state for all configured instances:" \
        --column="Instance" \
        --column="Process Status" \
        --column="PID" \
        --column="Boot Autostart" \
        --column="Desktop Launcher" \
        --width=750 --height=420 \
        --ok-label="Close" \
        "${rows[@]}"
}

gui_main_menu() {
    check_and_install "zenity" "$ZENITY_PACKAGE" || return 1

    while true; do
        load_accounts
        local action
        action=$("$ZENITY_CMD" --list \
            --title="MEGASync Multi-Instance Manager" \
            --text="Choose an action:" \
            --column="Option" \
            --column="Description" \
            --width=620 --height=450 \
            --ok-label="Select" \
            --cancel-label="Exit" \
            "start" "Start instances" \
            "stop" "Stop or restart running instances" \
            "open" "Open instance folder in file manager" \
            "add" "Add a new account" \
            "remove" "Remove an account" \
            "autostart" "Configure boot autostart" \
            "desktop" "Configure desktop application launchers" \
            "status" "View real-time status table" \
            "exit" "Exit program")

        [ $? -ne 0 ] || [ -z "$action" ] || [ "$action" = "exit" ] && break

        case "$action" in
            start) gui_start_instances ;;
            stop) gui_stop_restart_instances ;;
            open) gui_open_folder ;;
            add) gui_add_account ;;
            remove) gui_remove_account ;;
            autostart) gui_configure_autostart ;;
            desktop) gui_configure_desktop_apps ;;
            status) gui_show_status ;;
        esac
    done
}

# === MAIN DISPATCHER ===

load_accounts

case "$1" in
    status)
        cli_status
        ;;
    start)
        shift
        cli_start "$@"
        ;;
    stop)
        shift
        cli_stop "$@"
        ;;
    restart)
        shift
        cli_restart "$@"
        ;;
    add)
        shift
        cli_add "$@"
        ;;
    remove)
        shift
        cli_remove "$@"
        ;;
    autostart)
        shift
        cli_autostart "$@"
        ;;
    desktop-app)
        shift
        cli_desktop_app "$@"
        ;;
    open)
        shift
        cli_open "$@"
        ;;
    gui)
        gui_main_menu
        ;;
    help|--help|-h)
        cli_help
        ;;
    "")
        # No arguments: if display is available, launch GUI; else show status and help
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            gui_main_menu
        else
            cli_status
            echo ""
            cli_help
        fi
        ;;
    *)
        echo "Error: Unknown command '$1'." >&2
        echo "Run 'mega --help' for usage instructions." >&2
        exit 1
        ;;
esac
