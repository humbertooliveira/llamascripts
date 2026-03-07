#!/bin/bash

# --- CONFIGURATION ---
BINARY="$HOME/.llamacpp/code/build/bin/llama-server"
MODELS_DIR="$HOME/.llamacpp/models"

# --- CLEANUP ---
echo "🧹 Cleaning up previous instances..."
pkill -9 llama-server
sleep 2

# --- 1. START CODING MODEL (Port 11001) ---
# Distributed across GPU 0 and 1 | 131072 |
echo "🚀 Launching Qwen 9B Coder (256k Context, Q8 Cache) on Dual GPUs..."
CUDA_VISIBLE_DEVICES=1 $BINARY \
  --model "$MODELS_DIR/Qwen_Qwen3.5-9B-Q6_K.gguf" \
  --alias "Qwen3:9B" \
  --port 11001 \
  --ctx-size 262144 \
  --n-gpu-layers 99 \
  --split-mode layer \
  --flash-attn on \
  --ubatch-size 4096 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --context-shift \
  --parallel 1 \
  --jinja 

# --- 2. START EMBEDDING MODEL (Port 11002) ---
# Strictly on GPU 0 to avoid fragmenting GPU 1
# echo "🛰️  Launching mxbai-embed-large-v1-f16.gguf on Port 11002..."
# CUDA_VISIBLE_DEVICES=0 $BINARY \
#   --model "$MODELS_DIR/mxbai-embed-large-v1-f16.gguf" \
#   --alias "embedding-model" \
#   --port 11002 \
#   --ctx-size 1024 \
#   --n-gpu-layers 99 \
#   --embedding \
#   --split-mode none &

# echo "✅ Model is starting. Check logs for VRAM distribution details."