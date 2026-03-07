#!/bin/bash

# --- CONFIGURATION ---
BINARY="$HOME/.llamacpp/code/build/bin/llama-server"
MODELS_DIR="$HOME/.llamacpp/models"

# Default values
DEFAULT_CTX_SIZE=32768
DEFAULT_MODEL="Qwen_Qwen3.5-9B-Q6_K.gguf"
DEFAULT_PORT=11001

# Parse command line arguments
CTX_SIZE=$DEFAULT_CTX_SIZE
MODEL_NAME=$DEFAULT_MODEL
PORT=$DEFAULT_PORT

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--ctx-size)
            CTX_SIZE="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_NAME="$2"
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
            echo "  -m, --model MODEL    Set model name (default: $DEFAULT_MODEL)"
            echo "  -p, --port PORT      Set port (default: $DEFAULT_PORT)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 -c 128000         # Use 128k context with default model"
            echo "  $0 -m model.gguf -c 262144  # Custom model and context size"
            echo "  $0                  # Use default settings"
            echo "  $0 -c 128000 -p 12001  # Custom context and port"
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
sudo fuser -k "$PORT/tcp" 2>/dev/null || true
sleep 2

# --- START CODING MODEL ---
# Using only GPU 1 as requested
echo "🚀 Launching $MODEL_NAME with $CTX_SIZE context size on GPU 1..."
CUDA_VISIBLE_DEVICES=1 $BINARY \
  --model "$MODELS_DIR/$MODEL_NAME" \
  --alias "$MODEL_NAME" \
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