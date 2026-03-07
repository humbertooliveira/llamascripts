#!/bin/bash

# Improved llama.cpp Update & Build Script
# This script provides enhanced functionality and error handling for building llama.cpp with CUDA support

# Configuration
INSTALL_DIR="$HOME/.llamacpp/code"
BUILD_DIR="$INSTALL_DIR/build"
CUDA_ARCH="120a"  # Default CUDA architecture
BUILD_TYPE="Release"  # Default build type
THREADS=$(nproc)  # Default to number of CPU cores

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if a package is installed
package_installed() {
    dpkg -l | grep -q "$1" 2>/dev/null
}

# Function to validate CUDA installation
validate_cuda() {
    if ! command_exists nvcc; then
        log_error "CUDA Toolkit not found. Please install CUDA Toolkit 12.8 or higher."
        return 1
    fi
    
    # Check CUDA version
    local cuda_version=$(nvcc --version | grep "Cuda compilation tools" | awk '{print $6}')
    log_info "CUDA version: $cuda_version"
    
    return 0
}

# Function to check available disk space
check_disk_space() {
    local required_space="2G"  # Adjust as needed
    local available_space=$(df "$INSTALL_DIR" | awk 'NR==2 {print $4}')
    
    # Convert to MB for comparison
    if [ "$available_space" -lt 2048 ]; then
        log_warning "Low disk space available: ${available_space}KB"
        return 1
    fi
    
    return 0
}

# Function to validate build directory
validate_build_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        log_info "Creating installation directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR" || {
            log_error "Failed to create installation directory"
            return 1
        }
    fi
    
    return 0
}

# Function to check if we're on Ubuntu 24.04
check_os() {
    if ! command_exists lsb_release; then
        log_warning "Cannot determine OS version. Proceeding with assumption."
        return 0
    fi
    
    local os_version=$(lsb_release -rs)
    if [[ "$os_version" != "24.04" ]]; then
        log_warning "This script is optimized for Ubuntu 24.04. Current version: $os_version"
    fi
    
    return 0
}

# Function to install CUDA Toolkit if needed
install_cuda_toolkit() {
    log_info "Checking CUDA Toolkit installation..."
    
    if ! command_exists nvcc; then
        log_info "CUDA Toolkit not found. Installing official NVIDIA repo..."
        
        # Download and install CUDA keyring
        local keyring_file="cuda-keyring_1.1-1_all.deb"
        if ! wget -O "$keyring_file" "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb"; then
            log_error "Failed to download CUDA keyring"
            return 1
        fi
        
        # Verify checksum (basic verification)
        if ! dpkg -i "$keyring_file"; then
            log_error "Failed to install CUDA keyring"
            rm -f "$keyring_file"
            return 1
        fi
        
        rm -f "$keyring_file"
        
        # Update package list
        if ! sudo apt update; then
            log_error "Failed to update package list"
            return 1
        fi
        
        # Install CUDA toolkit and dependencies
        log_info "Installing CUDA Toolkit 12.8 and dependencies..."
        if ! sudo apt install -y cuda-toolkit-12-8 build-essential cmake git git-lfs libcurl4-openssl-dev; then
            log_error "Failed to install CUDA Toolkit and dependencies"
            return 1
        fi
        
        log_success "CUDA Toolkit installed successfully"
    else
        log_info "CUDA Toolkit found. Skipping installation."
    fi
    
    return 0
}

# Function to setup environment variables
setup_environment() {
    log_info "Setting up CUDA environment variables..."
    
    export CUDA_HOME=/usr/local/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    export CUDAToolkit_ROOT=$CUDA_HOME
    
    # Verify environment variables are set
    if [ -z "$CUDA_HOME" ] || [ -z "$PATH" ] || [ -z "$LD_LIBRARY_PATH" ]; then
        log_error "Failed to set CUDA environment variables"
        return 1
    fi
    
    log_success "CUDA environment variables set"
    return 0
}

# Function to clone or update llama.cpp repository
setup_repository() {
    log_info "Setting up llama.cpp repository..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log_info "Cloning llama.cpp repository..."
        if ! git clone https://github.com/ggml-org/llama.cpp "$INSTALL_DIR"; then
            log_error "Failed to clone llama.cpp repository"
            return 1
        fi
    else
        log_info "Repository exists. Pulling latest changes..."
        cd "$INSTALL_DIR" || {
            log_error "Failed to change directory to $INSTALL_DIR"
            return 1
        }
        
        if ! git pull; then
            log_error "Failed to pull latest changes"
            return 1
        fi
    fi
    
    cd "$INSTALL_DIR" || {
        log_error "Failed to change directory to $INSTALL_DIR"
        return 1
    }
    
    log_success "Repository setup complete"
    return 0
}

# Function to build llama.cpp
build_llama_cpp() {
    log_info "Starting build process..."
    
    # Clean previous build
    log_info "Cleaning previous build..."
    rm -rf "$BUILD_DIR" || {
        log_warning "Failed to remove previous build directory"
    }
    
    mkdir -p "$BUILD_DIR" || {
        log_error "Failed to create build directory"
        return 1
    }
    
    # Configure build with CMake
    log_info "Configuring build with CUDA..."
    if ! cmake -B "$BUILD_DIR" \
        -DGGML_CUDA=ON \
        -DGGML_NATIVE=OFF \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCH" \
        -DCMAKE_CXX_FLAGS="-O3" \
        -DCMAKE_C_FLAGS="-O3"; then
        log_error "CMake configuration failed"
        return 1
    fi
    
    # Compile with parallel jobs
    log_info "Compiling with $THREADS threads..."
    if ! cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$THREADS"; then
        log_error "Build failed"
        return 1
    fi
    
    log_success "Build completed successfully"
    return 0
}

# Function to validate build
validate_build() {
    log_info "Validating build..."
    
    if [ ! -f "$BUILD_DIR/bin/llama-server" ]; then
        log_error "Build validation failed: llama-server binary not found"
        return 1
    fi
    
    log_success "Build validation successful"
    return 0
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -a, --arch ARCH         Set CUDA architecture (default: 120a)"
    echo "  -t, --type TYPE         Set build type (Release/Debug, default: Release)"
    echo "  -j, --jobs N            Set number of parallel jobs (default: number of CPUs)"
    echo "  -v, --verbose           Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run with default settings"
    echo "  $0 -a 110a -t Debug     # Build with different architecture and debug type"
    echo "  $0 -j 8                 # Build with 8 parallel jobs"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--arch)
            CUDA_ARCH="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -j|--jobs)
            THREADS="$2"
            shift 2
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution flow
main() {
    log_info "--- 🚀 Starting Improved llama.cpp Update & Build ---"
    
    # Check OS compatibility
    if ! check_os; then
        log_warning "OS compatibility check failed, continuing anyway"
    fi
    
    # Check disk space
    if ! check_disk_space; then
        log_warning "Low disk space detected"
    fi
    
    # Validate build directory
    if ! validate_build_dir; then
        log_error "Failed to validate build directory"
        exit 1
    fi
    
    # Install CUDA Toolkit if needed
    if ! install_cuda_toolkit; then
        log_error "Failed to install CUDA Toolkit"
        exit 1
    fi
    
    # Validate CUDA installation
    if ! validate_cuda; then
        log_error "CUDA validation failed"
        exit 1
    fi
    
    # Setup environment
    if ! setup_environment; then
        log_error "Failed to setup environment"
        exit 1
    fi
    
    # Setup repository
    if ! setup_repository; then
        log_error "Failed to setup repository"
        exit 1
    fi
    
    # Build llama.cpp
    if ! build_llama_cpp; then
        log_error "Build process failed"
        exit 1
    fi
    
    # Validate build
    if ! validate_build; then
        log_error "Build validation failed"
        exit 1
    fi
    
    log_success "--- ✅ Success! llama.cpp built with CUDA support ---"
    log_info "Binary location: $BUILD_DIR/bin/llama-server"
}

# Run main function
main "$@"