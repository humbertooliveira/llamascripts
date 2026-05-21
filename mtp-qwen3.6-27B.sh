#!/bin/bash

BINARY=$HOME/llamacpp/build/bin/llama-server
# MODEL=$HOME/models/havenoammo/Qwen3.6-27B-MTP-UD-Q5_K_XL.gguf
# MODEL=$HOME/models/unsloth/Qwen3.6-27B-MTP-UD-Q4_K_XL.gguf
MODEL=/home/humberto/models/unsloth/mtp/Qwen3.6-27B-UD-Q5_K_XL.gguf
SPECTYPE=draft-mtp
DRAFTMAX=3
ALIAS="qwen3.6-27B"
CTX=$((${1:-128} * 1024))

# 1. Get the script name without path or extension
SCRIPT_BASE="${0##*/}"
SCRIPT_NAME="${SCRIPT_BASE%.*}"

# 2. Define the log file (date-only keeps all of today's tests in one file)
LOG_FILE=/home/humberto/llamascripts/.logs/"${SCRIPT_NAME}-$(date +%Y%m%d).log"

# 3. Print a clean visual separator with the exact restart time
echo -e "\n==================================================" >> "$LOG_FILE"
echo "  SERVER RESTART: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo -e "==================================================\n" >> "$LOG_FILE"

# LOG_PATH=/home/humberto/llamascripts/.logs/$LOG_FILE

echo "Starting server from $BINARY with model $MODEL..."
echo "Saving log to $LOG_FILE"


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
  --no-mmproj \
  --log-verbosity 4 \
  --tensor-split 0.55,0.45 \
  --log-colors off \
  --batch-size 512 \
  --ubatch-size 512 \
  --chat-template-kwargs '{"preserve_thinking": true}' \
  2>&1 | tee -a $LOG_FILE
  

  # --ubatch-size 256 
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


