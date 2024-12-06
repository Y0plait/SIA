#!/bin/bash

# OS Name extraction
OS_NAME=$(awk -F'[""]' '{print $2}' <<< $(grep -w NAME= /etc/os-release))

# Color codes
RED='\033[0;31m'
GRAY='\033[90m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debugging is disabled by default
DEBUG=${DEBUG:-0}  # Default to 0 (off)

sia_print() {
    echo -e "${GREEN}[${RED}S${YELLOW}I${BLUE}A${GREEN}]${NC} "
}

# Logging functions with color
log_error() {
    echo -e "$(sia_print)${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "$(sia_print)${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "$(sia_print)${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "$(sia_print)${BLUE}[INFO]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" -eq 1 ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "$(sia_print)${PURPLE}[DEBUG]${NC} [${timestamp}] $1"
    fi
}

# Function to check if a command exists
command_exists() {
    log_debug "Checking if command '$1' exists"
    command -v "$1" &> /dev/null
}

# Determine package manager
get_package_manager() {
    local managers=("apt-get" "yum" "dnf" "brew")
    
    log_debug "Detecting package manager"
    
    for manager in "${managers[@]}"; do
        if command_exists "$manager"; then
            log_debug "Detected package manager: $manager"
            echo "$manager"
            return 0
        fi
    done
    
    log_error "No supported package manager found"
    return 1
}

# Install packages
install_packages() {
    local package_manager
    package_manager=$(get_package_manager)
    
    if [ -z "$package_manager" ]; then
        log_error "Unable to determine package manager"
        return 1
    fi

    log_debug "Starting package installation for: $*"

    case "$package_manager" in
        "apt-get")
            log_debug "Using apt-get to install packages"
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        "yum")
            log_debug "Using yum to install packages"
            sudo yum install -y "$@"
            ;;
        "dnf")
            log_debug "Using dnf to install packages"
            sudo dnf install -y "$@"
            ;;
        "brew")
            log_debug "Using brew to install packages"
            brew install "$@"
            ;;
        *)
            log_error "Unsupported package manager"
            return 1
            ;;
    esac

    local install_status=$?
    if [ $install_status -eq 0 ]; then
        log_debug "Successfully installed packages: $*"
    else
        log_error "Failed to install packages: $*"
    fi

    return $install_status
}