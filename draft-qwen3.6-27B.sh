#!/bin/bash

# --- CONFIGURATION ---
BINARY=${1:-"$HOME/llamacpp"}/build/bin/llama-server
MODEL=${2:-"$HOME/models/unsloth/Qwen3.6-27B-UD-Q4_K_XL.gguf"}
DRAFT_MODEL="$HOME/models/unsloth/Qwen3.5-0.8B-UD-Q8_K_XL.gguf"
# DRAFT_MODEL="$HOME/models/qwen/qwen2.5-0.5b-instruct-q8_0.gguf"
#DRAFT_MODEL="$HOME/models/qwen/qwen2.5-coder-0.5b-instruct-q8_0.gguf" # o coder teve uma aceptance rate menor
SPECTYPE=${3:-"ngram-mod"}
DRAFTMAX=${4:-"16"}
ALIAS="qwen3.6-27B"

echo "Starting server from $BINARY with model $MODEL..."

echo "Cleaning up previous instances..."
pkill -f llama-server
sleep 2


CUDA_VISIBLE_DEVICES=0,1 $BINARY \
  --model $MODEL \
  --model-draft $DRAFT_MODEL \
  --alias $ALIAS \
  --spec-type $SPECTYPE \
  --spec-draft-n-max $DRAFTMAX \
  --port 9081 \
  --host 192.168.1.15 \
  --ctx-size 131072  \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --gpu-layers 99 \
  --flash-attn on \
  --parallel 1 \
  --temp 0.6  \
  --top-p 0.95  \
  --top-k 20  \
  --min-p 0.00 \
  --presence-penalty 0.0 \
  --repeat-penalty 1.0 \
  --cache-ram -1 \
  --jinja \
  --kv-unified \
  --no-context-shift \
  --metrics \
  

  # --sleep-idle-seconds 60 \
  # --ctx-size 262144 \
  # --ctx-size 217088 \
  # --ctx-size 194560 \
  # --ctx-size 163840 \
  # --split-mode layer
  # --tensor-split 12,16 \
  # --batch-size 4096 \
  # --batch-size 2048 \
  # --batch-size 1024 \
  # --ubatch-size 1024 \
  # --ubatch-size 512 \
  # --ubatch-size 256 \


