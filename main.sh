#!/bin/bash

# Clear the screen and print ASCII logo
clear
cat << 'END'
   _____ _______                _____ __                               _ __           ____
  / ___//  _/   |              / ___// /_________  ____ _____ ___     (_/ /_   ____ _/ / /
  \__ \ / // /| |    ______    \__ \/ __/ ___/ _ \/ __ `/ __ `__ \   / / __/  / __ `/ / / 
 ___/ _/ // ___ |   /_____/   ___/ / /_/ /  /  __/ /_/ / / / / / /  / / /_   / /_/ / / /  
/____/___/_/  |_|            /____/\__/_/   \___/\__,_/_/ /_/ /_/  /_/\__/   \__,_/_/_/                                                                                         
END

# Determine the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source the utils script
# Use the full path to ensure it works from any directory
source "$SCRIPT_DIR/utils.sh"

# Enable/Disable debugging
export DEBUG=0

# Source the docker installation script
source "$SCRIPT_DIR/docker-installation.sh"
source "$SCRIPT_DIR/compose-templating.sh"

# Main script
main() {
    log_debug "Starting main script execution"
    log_debug "Script directory: $SCRIPT_DIR"
    log_debug "Current user: $USER"
    log_debug "Operating System: $OS_NAME"

    # Prerequisite checks
    local tools_to_check=("bash" "curl" "grep" "awk" "sed" "git")
    local missing_tools=()

    log_debug "Checking required tools: ${tools_to_check[*]}"

    for tool in "${tools_to_check[@]}"; do
        if ! command_exists "$tool"; then
            log_debug "Tool '$tool' not found"
            missing_tools+=("$tool")
        else
            log_debug "Tool '$tool' is available"
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_debug "Prompting user about tool installation"
        read -p "$(sia_print)Would you like to install these tools? (y/n): " install_choice
        
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            log_debug "User chose to install missing tools"
            if ! install_packages "${missing_tools[@]}"; then
                log_error "Failed to install missing tools"
                log_debug "Tool installation process failed"
                exit 1
            fi
        else
            log_error "Tool installation cancelled. Cannot proceed."
            log_debug "User declined tool installation"
            exit 1
        fi
    fi

    # Prompt for Docker installation
    log_debug "Prompting for Docker installation"
    read -p "$(sia_print)Do you want to install Docker? (y/n): " docker_choice
    
    if [[ "$docker_choice" =~ ^[Yy]$ ]]; then
        log_debug "User chose to install Docker"
        if install_docker; then
            log_success "Docker installation completed successfully"
            log_debug "Docker installation process completed"
        else
            log_error "Docker installation failed"
            log_debug "Docker installation process failed"
            exit 1
        fi
    else
        log_warning "Docker installation cancelled"
        log_debug "User declined Docker installation"
        exit 0
    fi

    log_debug "Main script execution completed successfully"
}

# Run the main function
main