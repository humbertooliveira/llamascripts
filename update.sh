#!/bin/bash

# 1. Define the installation directory
INSTALL_DIR="$HOME/llamacpp"
BUILD_DIR="$INSTALL_DIR/build"

echo "--- 🚀 Starting llama.cpp Update & Build ---"

# 4. Clone or Update llama.cpp
echo "🔄 Pulling latest CODE..."
cd "$INSTALL_DIR"
git pull


# 5. Build with CUDA
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🛠️ Configuring build with CUDA..."
cmake -B "$BUILD_DIR" \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES=native \
  -DCMAKE_BUILD_TYPE=Release \

echo "🏗️ Compiling..."
time cmake --build "$BUILD_DIR" --config Release -j $(nproc)

echo "--- ✅ Success! ---"