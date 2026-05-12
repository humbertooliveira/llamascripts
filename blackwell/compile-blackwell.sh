#!/bin/bash

# 1. Define the installation directory
INSTALL_DIR="$HOME/llamacpp-blackwell"
BUILD_DIR="$INSTALL_DIR/build"

echo "--- 🚀 Starting llama.cpp Update & Build ---"
mkdir -p $INSTALL_DIR

# 4. Clone or Update llama.cpp
echo "🔄 Pulling latest CODE..."
cd "$INSTALL_DIR"
git pull


# 5. Build with CUDA
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🛠️ Configuring build for RTX 5060 Ti (sm_120)..."
# -DGGML_CUDA_F16=ON is the key to unlocking FP8/NVFP4 support
# -DCMAKE_CUDA_ARCHITECTURES=120 explicitly targets Blackwell
cmake -B "$BUILD_DIR" \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_F16=ON \
  -DGGML_NVFP4=ON \
  -DCMAKE_CUDA_ARCHITECTURES=120 \
  -DGGML_CUDA_FA_ALL_QUANTS=ON \
  -DCMAKE_C_FLAGS="-march=native -O3" \
  -DCMAKE_CXX_FLAGS="-march=native -O3" \
  -DCMAKE_BUILD_TYPE=Release

echo "🏗️ Compiling..."
time cmake --build "$BUILD_DIR" --config Release -j $(nproc)

echo "--- ✅ Success! ---"

# Key Changes Explained
# -DGGML_CUDA_F16=ON: This is the most important change. Without this, llama.cpp defaults to 32-bit floating point for its internal math, which prevents it from using the Blackwell FP8/FP4 hardware accelerators. Enabling this is what unlocks the --cache-type-k fp8 option.

# -DCMAKE_CUDA_ARCHITECTURES=120: While native should work, explicit targeting ensures the compiler uses the 120a instruction set (the "a" stands for async), which is required for the new Blackwell Tensor Core instructions used in NVFP4.

# -DGGML_NVFP4=ON: This enables the specific matrix-multiplication kernels designed for the model you chose.

# -DGGML_CUDA_FA_ALL_QUANTS=ON: This ensures that Flash Attention works correctly across all quantization types, including your 128k context documentation tasks.