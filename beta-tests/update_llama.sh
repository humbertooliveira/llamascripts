#!/bin/bash

# 1. Define the installation directory
INSTALL_DIR="$HOME/.llamacpp/code"
BUILD_DIR="$INSTALL_DIR/build"

echo "--- 🚀 Starting llama.cpp Update & Build ---"

# 2. Install Official NVIDIA Repository (for Ubuntu 24.04)
if ! command -v nvcc &> /dev/null; then
    echo "📦 CUDA Toolkit not found. Installing official NVIDIA repo..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt update
    # Installing only the toolkit to avoid conflicts with Windows drivers
    sudo apt install -y cuda-toolkit-12-8 build-essential cmake git git-lfs libcurl4-openssl-dev
else
    echo "✅ nvcc found. Skipping toolkit installation."
fi

# 3. CRITICAL: Export CUDA Paths for this session
# This tells CMake exactly where to find the compiler and libraries
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
export CUDAToolkit_ROOT=$CUDA_HOME

# 4. Clone or Update llama.cpp
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📂 Cloning llama.cpp..."
    git clone https://github.com/ggml-org/llama.cpp "$INSTALL_DIR"
    cd "$INSTALL_DIR"
else
    echo "🔄 Repository exists. Pulling latest..."
    cd "$INSTALL_DIR"
    git pull
fi

# 5. Build with CUDA
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🛠️ Configuring build with CUDA..."
cmake -B "$BUILD_DIR" \
  -DGGML_CUDA=ON \
  -DGGML_NATIVE=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_ARCHITECTURES=120a

echo "🏗️ Compiling..."
cmake --build "$BUILD_DIR" --config Release -j $(nproc)

echo "--- ✅ Success! ---"