#!/bin/bash

# --- CONFIGURATION ---
BINARY=$HOME/llamacpp/build/bin/llama-server
MODEL=$HOME/models/freenixi/Abiray-Qwen3.6-27B-NVFP4.gguf
# MODEL=$HOME/models/libertaidai/Qwen3.6-27B-NVFP4-Q4_K_M.gguf
DRAFT_MODEL="$HOME/models/unsloth/Qwen3.5-0.8B-UD-Q8_K_XL.gguf"
SPECTYPE=ngram-mod,draft-simple
DRAFTMAX="16"
ALIAS="qwen3.6-27B"
CTX=$((${1:-128} * 1024))


CUDA_VISIBLE_DEVICES=0,1 $BINARY \
  --model $MODEL \
  --model-draft $DRAFT_MODEL \
  --alias $ALIAS \
  --port 9081 \
  --host 192.168.1.15 \
  --ctx-size $CTX \
  --spec-type $SPECTYPE \
  --spec-draft-n-max $DRAFTMAX \
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
  --log-verbosity 4 \

  # --spec-draft-ctx-size $CTX \
  # --ubatch-size 1024 \
  # --tensor-split 0.55,0.45 \  
  # --spec-type $SPECTYPE \
  # --spec-draft-n-max $DRAFTMAX \
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


