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

## usar no máximo o cuda 13.0 para não ter o bug com os modelos MOE, conforme sloth
# https://www.reddit.com/r/unsloth/comments/1sgl0wh/do_not_use_cuda_132_to_run_models/
# precisa instalar o gcc 13:
# sudo apt update && sudo apt install -y gcc-13 g++-13
# -DGGML_CUDA_F16=ON \

echo "🛠️ Configuring build with CUDA..."

export PATH=/usr/local/cuda-13.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

cmake -B "$BUILD_DIR" \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_F16=ON \
  -DCMAKE_CUDA_ARCHITECTURES=120 \
  -DGGML_NATIVE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=gcc-13 \
  -DCMAKE_CXX_COMPILER=g++-13 \
  -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/gcc-13 \
  -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler"

echo "🏗️ Compiling..."
time cmake --build "$BUILD_DIR" --config Release -j $(nproc)

echo "--- ✅ Success! ---"



  # -DCMAKE_C_COMPILER=gcc-14 \
  # -DCMAKE_CXX_COMPILER=g++-14 \
  # -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/gcc-14 \
  # -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-12.8 \
