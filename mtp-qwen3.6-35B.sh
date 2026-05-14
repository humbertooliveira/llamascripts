#!/bin/bash

# https://huggingface.co/havenoammo/Qwen3.6-35B-A3B-MTP-GGUF
# --- CONFIGURATION ---
BINARY=$HOME/llamacpp-pr22673/build/bin/llama-server
MODEL=$HOME/models/havenoammo/Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf
SPECTYPE=mtp
DRAFTMAX=3
ALIAS="qwen3.6-35B"
CTX=$((${1:-128} * 1024))

echo "Starting server from $BINARY with model $MODEL..."

echo "Cleaning up previous instances..."
pkill -f llama-server
sleep 2


CUDA_VISIBLE_DEVICES=0,1 $BINARY \
  --model $MODEL \
  --alias $ALIAS \
  --spec-type $SPECTYPE \
  --spec-draft-n-max $DRAFTMAX \
  --port 9081 \
  --host 192.168.1.15 \
  --ctx-size $CTX  \
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
  --tensor-split 0.6,0.4 \
  --ubatch-size 256 
  

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


