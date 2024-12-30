#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Version
VERSION="0.2.0"
PLUGIN_NAME="moosefs/docker-volume-moosefs:${VERSION}"

# Function to print step
print_step() {
    echo -e "${YELLOW}[*] $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}[-] $1${NC}"
    exit 1
}

# Clean previous build
print_step "Cleaning previous build..."
rm -rf plugin/rootfs *.deb *.rpm docker-volume-moosefs obj
print_success "Clean completed"

# Clean existing plugin if it exists
print_step "Checking for existing plugin..."
if docker plugin inspect ${PLUGIN_NAME} >/dev/null 2>&1; then
    print_step "Disabling existing plugin..."
    docker plugin disable ${PLUGIN_NAME} >/dev/null 2>&1
    print_step "Removing existing plugin..."
    docker plugin rm ${PLUGIN_NAME} >/dev/null 2>&1
fi
print_success "Plugin cleanup completed"

# Build Go binary
print_step "Building Go binary..."
go build || print_error "Go build failed"
print_success "Binary built successfully"

# Create plugin
print_step "Creating Docker plugin..."
mkdir -p plugin/rootfs || print_error "Failed to create plugin directory"

# Build Docker image
print_step "Building Docker image..."
docker build -t moosefs-plugin-build -f plugin/Dockerfile . || print_error "Docker build failed"

print_step "Creating temporary container..."
docker create --name tmp moosefs-plugin-build || print_error "Failed to create temporary container"

print_step "Extracting rootfs..."
docker export tmp | tar -x -C plugin/rootfs || print_error "Failed to extract rootfs"

print_step "Cleaning up temporary container..."
docker rm -vf tmp
docker rmi moosefs-plugin-build

# Create and enable plugin
print_step "Creating Docker plugin..."
docker plugin create ${PLUGIN_NAME} plugin || print_error "Failed to create plugin"

print_step "Enabling Docker plugin..."
docker plugin enable ${PLUGIN_NAME} || print_error "Failed to enable plugin"

print_success "Build completed successfully!"
echo -e "${GREEN}Plugin ${PLUGIN_NAME} is now ready to use${NC}"
echo -e "${YELLOW}You can create a volume with:${NC}"
echo -e "docker volume create -d ${PLUGIN_NAME} --name test_volume"
