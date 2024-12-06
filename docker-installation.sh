#!/bin/bash

# Functions to install and check Docker

# Function to verify Docker installation
verify_docker_installation() {
    log_info "Verifying Docker installation..."

    # Check if Docker daemon is running
    if ! sudo systemctl is-active --quiet docker; then
        log_error "Docker daemon is not running"
        read -p "Do you want to enable it ? (y/n): " docker_daemon_choice
        if [[ "$docker_daemon_choice" =~ ^[Yy]$ ]]; then
            if ! sudo systemctl enable --now docker 2>/dev/null; then
                log_error "Unable to active Docker daemon"
            fi
            log_info "Docker daemon activated"
        fi
        return 1
    fi

    # Check Docker version
    if ! docker version &> /dev/null; then
        log_error "Unable to run Docker command"
        return 1
    fi

    # Verify Docker info
    local docker_info
    docker_info=$(docker info 2>/dev/null)
    if [ $? -ne 0 ]; then
        log_error "Failed to retrieve Docker system information"
        return 1
    fi

    # Check Docker Compose installation
    if ! command_exists docker compose; then
        log_warning "Docker Compose not found. A problem must have occured during the install process..."
        exit 1
    fi

    # Run a simple test container
    log_info "Running Docker hello-world container..."
    if ! sudo docker run --rm hello-world &> /dev/null; then
        log_error "Failed to run test container"
        return 1
    fi

    # Additional Docker Compose test
    log_info "Creating a simple Docker Compose test file..."
    local test_compose_file="/tmp/docker-compose-test.yml"
    cat << EOF > "$test_compose_file"
version: '3'
services:
  test:
    image: alpine
    command: echo "Docker Compose is working!"
EOF

    if ! docker-compose -f "$test_compose_file" up --exit-code-from test &> /dev/null; then
        log_error "Docker Compose test failed"
        rm "$test_compose_file"
        return 1
    fi

    if ! docker compose -f "$test_compose_file" down -v &> /dev/null; then
        log_warning "Unable to delete composed containers"
        rm "$test_compose_file"
    fi

    rm "$test_compose_file"

    # If all checks pass
    log_success "Docker and Docker Compose installed and verified successfully!"
    return 0
}

# Download function with fallback
download_docker_script() {
    local primary_url="https://get.docker.com"
    local secondary_url="https://test.docker.com"
    local output_file="${1:-get-docker.sh}"

    # Try primary URL with curl
    if command_exists curl; then
        log_info "Attempting to download Docker installation script from $primary_url"
        if curl -fsSL "$primary_url" -o "$output_file"; then
            log_success "Successfully downloaded Docker installation script"
            return 0
        fi
    fi

    # Try secondary URL with curl
    if command_exists curl; then
        log_warning "Primary download failed. Attempting secondary URL $secondary_url"
        if curl -fsSL "$secondary_url" -o "$output_file"; then
            log_success "Successfully downloaded Docker installation script from secondary URL"
            return 0
        fi
    fi

    # Fallback to wget if curl fails
    if command_exists wget; then
        log_warning "Curl download failed. Attempting download with wget"
        if wget -q "$primary_url" -O "$output_file"; then
            log_success "Successfully downloaded Docker installation script with wget"
            return 0
        fi

        # Try secondary URL with wget
        if wget -q "$secondary_url" -O "$output_file"; then
            log_success "Successfully downloaded Docker installation script from secondary URL with wget"
            return 0
        fi
    fi

    log_error "Failed to download Docker installation script from both URLs. Exiting ..."
    return 1
}

# Main installation function
install_docker() {
    # Download and install Docker
    if ! download_docker_script; then
        log_error "Docker script download failed"
        return 1
    fi

    # Verify script download
    if [ ! -s get-docker.sh ]; then
        log_error "Downloaded script is empty"
        return 1
    fi

    # Install Docker
    log_info "Running Docker installation script..."
    if ! sudo sh get-docker.sh; then
        return 1
    fi

    # Post-installation steps
    log_info "Configuring Docker user group..."
    sudo usermod -aG docker "$USER"

    # Clean up installation script
    rm -f get-docker.sh

    # Verify installation
    if ! verify_docker_installation; then
        return 1
    fi

    log_warning "You may need to log out and log back in for group changes to take effect"
    return 0
}