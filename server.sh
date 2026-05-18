#!/bin/bash

# llama.cpp router-mode launcher
# Serves multiple models behind a single OpenAI-compatible API endpoint.
# Model definitions live in models.ini (see that file for per-model overrides).

BINARY=$HOME/llamacpp/build/bin/llama-server
PRESET="$(cd "$(dirname "$0")" && pwd)/models.ini"
HOST=192.168.1.15
PORT=9081

LOG_DIR="$(cd "$(dirname "$0")" && pwd)/.logs"
LOG_FILE="$LOG_DIR/server-$(date +%Y%m%d).log"

# ── Helpers ──────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Launch llama-server in router mode using models.ini"
  echo ""
  echo "Options:"
  echo "  --host HOST    Bind address  (default: $HOST)"
  echo "  --port PORT    Port number   (default: $PORT)"
  echo "  --help         Show this help"
}

# ── Parse optional args ──────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# ── Pre-flight checks ────────────────────────────────────────────────────────

[[ -x "$BINARY" ]]   || die "Binary not found or not executable: $BINARY"
[[ -f "$PRESET" ]]   || die "Preset file not found: $PRESET"
mkdir -p "$LOG_DIR"

# ── Log header ───────────────────────────────────────────────────────────────

{
  echo ""
  echo "=================================================="
  echo "  SERVER START: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  Host: $HOST  Port: $PORT  Preset: $PRESET"
  echo "=================================================="
} >> "$LOG_FILE"

echo "Starting llama.cpp router on $HOST:$PORT (preset: $PRESET)"
echo "Log: $LOG_FILE"

# ── Launch ───────────────────────────────────────────────────────────────────

CUDA_VISIBLE_DEVICES=0,1 "$BINARY" \
  --models-preset "$PRESET" \
  --host "$HOST" \
  --port "$PORT" \
  --metrics \
  2>&1 | tee -a "$LOG_FILE"
