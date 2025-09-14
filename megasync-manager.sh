#!/bin/bash
# Script to start multiple instances of MEGAsync with different accounts
# DISTRO-AGNOSTIC: Compatible with Debian, Ubuntu, Fedora, and Arch Linux
#
# FEATURES:
# - Management of multiple MEGASync instances
# - Configuration of automatic startup with the system
# - Intuitive graphical interface with Zenity
# - Automatic detection of Linux distribution
# - Automatic installation of dependencies
#
# Author: https://github.com/geraldohomero
#
# Link: https://github.com/geraldohomero/megasync_multiple_instances
#
# SUPPORTED DISTRIBUTIONS:
# - Debian/Ubuntu/Mint/Pop!_OS/Zorin: apt
# - Fedora/RHEL/CentOS: dnf
# - Arch/Manjaro/EndeavourOS: pacman (AUR)
#
# RECOMMENDED NAMING:
# - Instances: MEGASync_Instance_1, MEGASync_Instance_2, MEGASync_Instance_3, etc.
# - Directories: ~/.config/MEGASync_Instance_1, ~/.config/MEGASync_Instance_2, etc.
#
# Declare an associative array with the instance names and their directories.
# Format: ["Instance Name"]="path/to/config"
#
# IMPORTANT: MEGAsync stores its configuration data in a directory.
# To use different instances, each one MUST have its own directory.
# By default, MEGAsync uses ~/.config/MEGAsync.
#
# RECOMMENDED NAMING:
# Use descriptive names like MEGASync_Instance_1, MEGASync_Instance_2, etc.
# Create copies of this directory or new directories for each instance.
# Example:
#   mkdir -p "$HOME/.config/MEGASync_Instance_1"
#   mkdir -p "$HOME/.config/MEGASync_Instance_2"
#

#
#

# === COLOR OUTPUT ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Message function with color
msg() {
    local type="$1"
    local custom="$2"
    local color="$NC"
    case "$type" in
        install_success|alias_added|copying_script|chmod_script|sourcing_alias)
            color="$GREEN" ;;
        already_installed)
            color="$YELLOW" ;;
        error|fail|fatal)
            color="$RED" ;;
    esac
    case "$type" in
        install_success) echo -e "${color}Installation complete! Use the 'mega' command to start the MEGAsync instance manager.${NC}";;
        alias_added) echo -e "${color}Alias 'mega' added to ~/.bash_aliases.${NC}";;
        already_installed) echo -e "${color}Script is already installed at ~/megasync-manager.sh.${NC}";;
        copying_script) echo -e "${color}Copying script to ~/megasync-manager.sh...${NC}";;
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

    if [ -f "$INSTALL_PATH" ]; then
        msg already_installed
    else
        msg copying_script
        # If $0 is a readable file, copy it. Otherwise, read from stdin.
        if [ -r "$0" ] && [ "$0" != "bash" ]; then
            cp "$0" "$INSTALL_PATH"
        else
            cat > "$INSTALL_PATH" <&0
        fi
        msg chmod_script
        chmod +x "$INSTALL_PATH"
    fi

    # Add alias if not present
    if ! grep -q "alias mega=" "$BASH_ALIASES" 2>/dev/null; then
        echo "$ALIAS_CMD" >> "$BASH_ALIASES"
        msg alias_added
    fi
    msg sourcing_alias
    source "$BASH_ALIASES" 2>/dev/null
    msg install_success
    exec bash
fi

declare -A ACCOUNTS=(
    ["MEGASync_Instance_1"]="$HOME/.config/MEGASync_Instance_1"
    # Add more instances here if needed
    # ["MEGASync_Instance_2"]="$HOME/.config/MEGASync_Instance_2"
    # ["MEGASync_Instance_3"]="$HOME/.config/MEGASync_Instance_3"
)
# --- END OF CONFIGURATION ---

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
    
    # Convert to lowercase for easier comparison
    DISTRO_ID=$(echo "$DISTRO_ID" | tr '[:upper:]' '[:lower:]')
    
    echo "Detected distribution: $DISTRO_NAME"
}

# Set up commands and packages based on the distribution
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
            MEGASYNC_PACKAGE="megasync"  # Official MEGA repository package
            ZENITY_PACKAGE="zenity"
            ;;
        *)
            echo "Unrecognized distribution: $DISTRO_NAME"
            echo "Trying to detect package manager automatically..."
            
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
                echo "ERROR: Could not detect a known package manager."
                echo "Please install manually: megasync and zenity"
                exit 1
            fi
            ;;
    esac
    
    echo "Package manager: $PACKAGE_MANAGER"
}

# 1. Check and install dependencies (distro-agnostic)
# The script automatically detects your Linux distribution and uses the
# appropriate package manager (apt, dnf, pacman)
check_and_install() {
    local cmd=$1
    local package_name=$2
    local local_paths=("$HOME/bin/$cmd" "$HOME/local/bin/$cmd" "$HOME/.local/bin/$cmd")
    
    # First, check if it's in the PATH
    if command -v "$cmd" &> /dev/null; then
        echo "'$cmd' found in PATH."
        return 0
    fi
    
    # Check common local paths
    for path in "${local_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "'$cmd' found at: $path"
            # Set global variable for the path
            if [ "$cmd" = "megasync" ]; then
                MEGASYNC_CMD="$path"
            elif [ "$cmd" = "zenity" ]; then
                ZENITY_CMD="$path"
            fi
            return 0
        fi
    done
    
    # If not found, offer to install
    echo "The dependency '$cmd' was not found in the PATH or common local paths."
    read -p "Do you want to install it via $PACKAGE_MANAGER now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing '$package_name'... Please enter your password if prompted."
        
        # Special warnings for some distributions
        case $DISTRO_ID in
            # No special warnings needed for supported distributions
        esac
        
        if command -v sudo &> /dev/null; then
            eval "$INSTALL_CMD $package_name"
        else
            echo "'sudo' command not found. Run as root or install '$package_name' manually."
            echo "Suggested command: $INSTALL_CMD $package_name"
            exit 1
        fi
        
        if ! command -v "$cmd" &> /dev/null; then
            echo "Installation failed. Check the package name or install '$package_name' manually."
            echo "Suggested command: $INSTALL_CMD $package_name"
            exit 1
        fi
        echo "'$package_name' installed successfully."
    else
        echo "Installation canceled. The script cannot continue without '$cmd'."
        echo "Install manually: $INSTALL_CMD $package_name"
        exit 1
    fi
}

# Detect distribution and configure
detect_distro
setup_package_manager

echo "=== MEGASync Multi-Instance Manager ==="
echo "Distribution: $DISTRO_NAME"
echo "Manager: $PACKAGE_MANAGER"
echo "========================================"
echo ""

# Check for required dependencies
check_and_install "megasync" "$MEGASYNC_PACKAGE"
check_and_install "zenity" "$ZENITY_PACKAGE"

# Set default commands if not defined
MEGASYNC_CMD=${MEGASYNC_CMD:-megasync}
ZENITY_CMD=${ZENITY_CMD:-zenity}

# File to save dynamically added instances
ACCOUNTS_FILE="$HOME/.config/megasync_accounts.conf"

# Directory for autostart files
AUTOSTART_DIR="$HOME/.config/autostart"

# Load saved instances if the file exists
if [ -f "$ACCOUNTS_FILE" ]; then
    while IFS='=' read -r name path; do
        if [ -n "$name" ] && [ -n "$path" ]; then
            ACCOUNTS["$name"]="$path"
        fi
    done < "$ACCOUNTS_FILE"
fi

# Function to check if an instance is configured for autostart
is_autostart_enabled() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ]
}

# Function to create .desktop file for autostart
create_autostart_desktop() {
    local instance_name="$1"
    local config_path="$2"
    
    mkdir -p "$AUTOSTART_DIR"
    
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    local exec_path=""
    
    # Determine the executable path
    if [ -n "$MEGASYNC_CMD" ]; then
        exec_path="$MEGASYNC_CMD"
    else
        exec_path="megasync"
    fi
    
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

# Function to remove .desktop file for autostart
remove_autostart_desktop() {
    local instance_name="$1"
    local desktop_file="$AUTOSTART_DIR/megasync-${instance_name// /_}.desktop"
    [ -f "$desktop_file" ] && rm "$desktop_file"
}

# Function to configure autostart
configure_autostart() {
    local title="Configure Autostart"
    
    # Build list of instances with current status
    local autostart_options=""
    for instance_name in "${!ACCOUNTS[@]}"; do
        if is_autostart_enabled "$instance_name"; then
            autostart_options+="TRUE \"$instance_name (Enabled)\" "
        else
            autostart_options+="FALSE \"$instance_name (Disabled)\" "
        fi
    done
    
    # Remove trailing space
    autostart_options=${autostart_options% }
    
    # Show configuration dialog
    local selections
    selections=$(eval "$ZENITY_CMD --list \
                        --title=\"$title\" \
                        --text=\"Select the instances that should start automatically with the system:\n\n• Check the instances you want to enable\n• Uncheck those you want to disable\n• Click 'Back' to return to the main menu\" \
                        --checklist \
                        --column=\"Enable\" \
                        --column=\"Instance\" \
                        --width=650 --height=500 \
                        --extra-button=\"Back\" \
                        --ok-label=\"Apply\" \
                        --cancel-label=\"Cancel\" \
                        $autostart_options \
                        --separator=\"|\"")
    
    local exit_code=$?
    
    # Check if the user clicked "Back" or canceled
    if [ $exit_code -eq 1 ]; then
        # User clicked "Back" - return to the main menu
        return 0
    elif [ $exit_code -ne 0 ]; then
        # User canceled or closed the window
        return 1
    fi
    
    # Process selections
    IFS='|' read -ra selected_instances <<< "$selections"
    
    # Extract only the instance names (remove "(Enabled)" and "(Disabled)")
    local instances_to_enable=()
    for selection in "${selected_instances[@]}"; do
        # Remove suffixes and extract instance name
        local instance_name=$(echo "$selection" | sed 's/ (Enabled)//' | sed 's/ (Disabled)//')
        instances_to_enable+=("$instance_name")
    done
    
    # Update autostart configuration
    local changes_made=false
    for instance_name in "${!ACCOUNTS[@]}"; do
        local should_enable=false
        
        # Check if this instance should be enabled
        for enabled_instance in "${instances_to_enable[@]}"; do
            if [ "$enabled_instance" = "$instance_name" ]; then
                should_enable=true
                break
            fi
        done
        
        if $should_enable; then
            if ! is_autostart_enabled "$instance_name"; then
                create_autostart_desktop "$instance_name" "${ACCOUNTS[$instance_name]}"
                changes_made=true
                echo "Autostart ENABLED for: $instance_name"
            fi
        else
            if is_autostart_enabled "$instance_name"; then
                remove_autostart_desktop "$instance_name"
                changes_made=true
                echo "Autostart DISABLED for: $instance_name"
            fi
        fi
    done
    
    if $changes_made; then
        $ZENITY_CMD --info --text="Autostart configuration updated successfully!" --width=500 --height=100
    else
        $ZENITY_CMD --info --text="No changes were made to the configuration." --width=500 --height=100
    fi
}

# Function to add a new instance
add_account() {
    # Calculate the next number for MEGASync_Instance
    account_number=1
    while [ "${ACCOUNTS[MEGASync_Instance_$account_number]}" ]; do
        ((account_number++))
    done
    
    # Default account name
    default_name="MEGASync_Instance_$account_number"
    
    # Dialog for account name
    account_name=$($ZENITY_CMD --entry \
                    --title="Add New MEGASync Account" \
                    --text="Enter the name for the new account:\n\n• Leave blank or click 'Back' to cancel" \
                    --entry-text="$default_name" \
                    --width=500 --height=180 \
                    --extra-button="Back" \
                    --ok-label="Next" \
                    --cancel-label="Cancel")
    
    local exit_code=$?
    
    # Check if the user clicked "Back" or canceled
    if [ $exit_code -eq 1 ] || [ $exit_code -ne 0 ] && [ -z "$account_name" ]; then
        return 1
    fi
    
    # Check if it already exists
    if [ "${ACCOUNTS[$account_name]}" ]; then
        $ZENITY_CMD --error --text="An instance with that name already exists!" --width=400 --height=100
        return 1
    fi
    
    # Default path based on account name
    default_path="$HOME/.config/MEGASync_Instance_$account_number"
    
    # Dialog for config path
    config_path=$($ZENITY_CMD --entry \
                        --title="Configuration Path" \
                        --text="Enter the path for the configuration directory:\n\n• Click 'Back' to return and change the name\n• Leave blank to cancel" \
                        --entry-text="$default_path" \
                        --width=600 --height=180 \
                        --extra-button="Back" \
                        --ok-label="Create Instance" \
                        --cancel-label="Cancel")
    
    local exit_code=$?
    
    # Check if the user clicked "Back" or canceled
    if [ $exit_code -eq 1 ]; then
        # User clicked "Back" - return to change the name
        add_account
        return $?
    elif [ $exit_code -ne 0 ] || [ -z "$config_path" ]; then
        return 1
    fi
    
    # Add to the array
    ACCOUNTS["$account_name"]="$config_path"
    
    # Save to the file
    echo "$account_name=$config_path" >> "$ACCOUNTS_FILE"
    
    $ZENITY_CMD --info --text="Instance '$account_name' added successfully!" --width=400 --height=100
    return 0
}

# Function to remove an instance
remove_instance() {
    local title="Remove MEGASync Instance"
    
    # Build list of instances for removal
    local remove_options=""
    for instance_name in "${!ACCOUNTS[@]}"; do
        remove_options+="\"$instance_name\" "
    done
    
    # Remove trailing space
    remove_options=${remove_options% }
    
    # Show selection dialog
    local instance_to_remove
    instance_to_remove=$(eval "$ZENITY_CMD --list \
                                --title=\"$title\" \
                                --text=\"Select the instance you want to remove:\n\n• Removal is permanent and cannot be undone.\n• The configuration directory will NOT be deleted.\n• Click 'Back' to return to the main menu\" \
                                --radiolist \
                                --column=\"\" \
                                --column=\"Instance\" \
                                --width=650 --height=500 \
                                --extra-button=\"Back\" \
                                --ok-label=\"Remove\" \
                                --cancel-label=\"Cancel\" \
                                $remove_options \
                                --separator=\"|\"")
    
    local exit_code=$?
    
    # Check if the user clicked "Back" or canceled
    if [ $exit_code -eq 1 ] || [ -z "$instance_to_remove" ]; then
        return 1
    fi
    
    # Confirm removal
    if ! $ZENITY_CMD --question --text="Are you sure you want to remove the instance '$instance_to_remove'?\n\nThis action will remove the instance from the list and disable autostart, but will not delete the configuration files." --width=500 --height=150; then
        return 1
    fi
    
    # Stop the instance if it's running
    pkill -f "HOME=${ACCOUNTS[$instance_to_remove]} $MEGASYNC_CMD"
    
    # Remove from autostart
    remove_autostart_desktop "$instance_to_remove"
    
    # Remove from the array
    unset ACCOUNTS["$instance_to_remove"]
    
    # Update the configuration file
    > "$ACCOUNTS_FILE" # Clear the file
    for account_name in "${!ACCOUNTS[@]}"; do
        echo "$account_name=${ACCOUNTS[$account_name]}" >> "$ACCOUNTS_FILE"
    done
    
    $ZENITY_CMD --info --text="Instance '$instance_to_remove' removed successfully!" --width=400 --height=100
    return 0
}

# 2. Build the arguments for the zenity dialog
zenity_args=()
for account_name in "${!ACCOUNTS[@]}"; do
    zenity_args+=(FALSE "$account_name")
done
# Add option to add a new instance
zenity_args+=(FALSE "Add new instance...")
# Add option to remove an instance
zenity_args+=(FALSE "Remove instance...")
# Add option to configure autostart
zenity_args+=(FALSE "Configure autostart...")

# Main loop for account selection
while true; do
    # 3. Display the checklist dialog to the user
    choices=$($ZENITY_CMD --list \
                    --title="MEGASync Instance Manager" \
                    --text="Which MEGASync instances do you want to start?\n\nSelect 'Add new instance...' to create a new instance.\nSelect 'Configure autostart...' to manage startup with the system.\n\n• Use 'OK' to start the selected instances\n• Use 'Cancel' to exit the program" \
                    --checklist \
                    --column="Select" --column="Instance" \
                    --width=650 --height=500 \
                    --ok-label="Ok" \
                    --cancel-label="Exit" \
                    "${zenity_args[@]}" \
                    --separator="|")

    # Check if the user canceled
    if [ $? -ne 0 ]; then
        echo "No instance selected. Exiting."
        exit 0
    fi

    # 4. Process the choices
    IFS='|' read -ra selected_accounts <<< "$choices"

    # Check if "Add new instance" or "Remove instance" was selected
    add_selected=false
    remove_selected=false
    configure_autostart_selected=false
    
    for account in "${selected_accounts[@]}"; do
        if [ "$account" = "Add new instance..." ]; then
            add_selected=true
        elif [ "$account" = "Remove instance..." ]; then
            remove_selected=true
        elif [ "$account" = "Configure autostart..." ]; then
            configure_autostart_selected=true
        fi
    done

    if [ "$configure_autostart_selected" = true ]; then
        # Remove "Configure autostart" from the list of selected
        selected_accounts=("${selected_accounts[@]/Configure autostart...}")
        
        # Configure autostart
        if configure_autostart; then
            # Rebuild the list with the new instance
            zenity_args=()
            for account_name in "${!ACCOUNTS[@]}"; do
                zenity_args+=(FALSE "$account_name")
            done
            zenity_args+=(FALSE "Add new instance...")
            zenity_args+=(FALSE "Remove instance...")
            zenity_args+=(FALSE "Configure autostart...")
            continue  # Go back to the loop to show the updated list
        fi
    fi

    if [ "$add_selected" = true ]; then
        # Remove "Add new instance" from the list of selected
        selected_accounts=("${selected_accounts[@]/Add new instance...}")
        
        # Add new account
        if add_account; then
            # Rebuild the list with the new instance
            zenity_args=()
            for account_name in "${!ACCOUNTS[@]}"; do
                zenity_args+=(FALSE "$account_name")
            done
            zenity_args+=(FALSE "Add new instance...")
            zenity_args+=(FALSE "Remove instance...")
            zenity_args+=(FALSE "Configure autostart...")
            continue  # Go back to the loop to show the updated list
        fi
    fi

    if [ "$remove_selected" = true ]; then
        # Remove "Remove instance" from the list of selected
        selected_accounts=("${selected_accounts[@]/Remove instance...}")
        
        # Remove instance
        if remove_instance; then
            # Rebuild the list
            zenity_args=()
            for account_name in "${!ACCOUNTS[@]}"; do
                zenity_args+=(FALSE "$account_name")
            done
            zenity_args+=(FALSE "Add new instance...")
            zenity_args+=(FALSE "Remove instance...")
            zenity_args+=(FALSE "Configure autostart...")
            continue  # Go back to the loop to show the updated list
        fi
    fi

    # If no accounts are selected (only "Add new account" was removed)
    if [ ${#selected_accounts[@]} -eq 0 ]; then
        continue
    fi

    # Proceed with the selected accounts
    break
done

# 5. Start MEGAsync for each selected instance
for account in "${selected_accounts[@]}"; do
    config_path="${ACCOUNTS[$account]}"
    
    if [ -n "$config_path" ]; then
        echo "Starting MEGAsync for instance: $account"
        
        # Create the configuration directory if it doesn't exist
        mkdir -p "$config_path"
        
        # Start MEGAsync in the background, setting the HOME variable
        # so that it uses the correct configuration directory.
        # This is the recommended way to isolate instances.
        (HOME="$config_path" "$MEGASYNC_CMD" &)
        
        $ZENITY_CMD --notification --text="MEGASync '$account' started." --timeout=3
    else
        $ZENITY_CMD --error --text="Configuration not found for instance: $account" --width=500 --height=100
    fi
done

echo "Process completed."
