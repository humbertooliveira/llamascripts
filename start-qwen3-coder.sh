#!/bin/bash

# --- CONFIGURATION ---
BINARY="$HOME/.llamacpp/code/build/bin/llama-server"
MODELS_DIR="$HOME/.llamacpp/models"

# --- CLEANUP ---
echo "🧹 Cleaning up previous instances..."
# pkill -9 llama-server
sudo fuser -k 11003/tcp
sleep 2

# --- 1. START CODING MODEL (Port 11003) ---
# Distributed across GPU 0 and 1
echo "🚀 Launching Qwen3 Coder on Dual GPUs..."
CUDA_VISIBLE_DEVICES=1,0 $BINARY \
  --model "$MODELS_DIR/Qwen3-Coder-30B-A3B-Instruct-Q4_0.gguf" \
  --alias "Qwen3-Coder:30B" \
  --port 11003 \
  --ctx-size 160000 \
  --n-gpu-layers 99 \
  --split-mode layer \
  --flash-attn on \
  --ubatch-size 4096 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --context-shift \
  --parallel 1 \
  --jinja \
  --metrics