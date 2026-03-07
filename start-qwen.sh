#!/bin/bash

# --- CONFIGURATION ---
BINARY="$HOME/.llamacpp/code/build/bin/llama-server"
MODELS_DIR="$HOME/.llamacpp/models"

# Default context size
DEFAULT_CTX_SIZE=32768

# Parse command line arguments
CTX_SIZE=$DEFAULT_CTX_SIZE
PORT=11001

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--ctx-size)
            CTX_SIZE="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -c, --ctx-size N     Set context size (default: $DEFAULT_CTX_SIZE)"
            echo "  -p, --port PORT      Set port (default: 11001)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 -c 128000         # Use 128k context"
            echo "  $0 -c 262144         # Use 256k context"
            echo "  $0                  # Use default 32k context"
            echo "  $0 -c 128000 -p 12001  # Custom port and context"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# --- CLEANUP ---
echo "🧹 Cleaning up previous instances..."
pkill -9 llama-server
sleep 2

# --- START CODING MODEL (Port 11001) ---
# Using only GPU 1 as requested
echo "🚀 Launching Qwen 3.5 Model with $CTX_SIZE context size on GPU 1..."
CUDA_VISIBLE_DEVICES=1 $BINARY \
  --model "$MODELS_DIR/Qwen_Qwen3.5-9B-Q6_K.gguf" \
  --alias "Qwen3:9B" \
  --port "$PORT" \
  --ctx-size "$CTX_SIZE" \
  --n-gpu-layers 99 \
  --split-mode none \
  --flash-attn on \
  --ubatch-size 4096 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --context-shift \
  --parallel 1 \
  --jinja

echo "✅ Model is starting. Check logs for VRAM distribution details."