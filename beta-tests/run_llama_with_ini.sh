#!/bin/bash

# --- CONFIGURATION ---
BINARY="$HOME/.llamacpp/code/build/bin/llama-server"
MODELS_DIR="$HOME/.llamacpp/models"
CONFIG_INI="$HOME/llamacpp/models.ini"

# --- CLEANUP ---
echo "🧹 Cleaning up previous instances..."
sudo fuser -k 11001/tcp
sudo fuser -k 11002/tcp
# pkill -9 llama-server
# # Wait a second for VRAM to clear
 sleep 2

# --- 1. START CODING MODEL (Port 11001) ---
# We use the explicit model path to bypass the 'Router Mode' bug
echo "🚀 Launching Qwen 9B Coder (128k Context) on Port 1434..."
CUDA_VISIBLE_DEVICES=1 $BINARY \
  -m "$MODELS_DIR/Qwen_Qwen3.5-9B-Q6_K.gguf" \
  --models-preset "$CONFIG_INI" \
  --port 11001 \
  --parallel 1 \
  --split-mode none \
  --alias Qwen3:9B & 

# --- 2. START EMBEDDING MODEL (Port 11002) ---
echo "🛰️  Launching mxbai-embed-large-v1-f16.gguf on Port 11002..."
CUDA_VISIBLE_DEVICES=1 $BINARY \
  -m "$MODELS_DIR/mxbai-embed-large-v1-f16.gguf" \
  --models-preset "$CONFIG_INI" \
  --port 11002 \
  --embedding \
  --parallel 1 \
  --alias embedding-model &

echo "--- ✅ Servers are running! ---"
echo "Roo Code Chat: http://localhost:11001"
echo "Roo Code Index: http://localhost:11002"