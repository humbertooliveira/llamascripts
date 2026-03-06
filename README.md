# Llama.cpp CUDA Setup

Local LLM inference server configuration using the [llama.cpp](https://github.com/ggml-org/llama.cpp) library, optimized for NVIDIA GPUs.

## Overview

This workspace provides scripts and configuration for running large language models locally with CUDA acceleration. The setup supports multiple models simultaneously for different purposes including LLM inference and embedding generation.

## Files

| File | Purpose |
|------|---------|
| [`models.ini`](models.ini) | Configuration file with model settings (context size, GPU allocation, cache types) |
| [`run_llama.sh`](run_llama.sh) | Simple launcher for llama-server on port 11434 |
| [`update_llama.sh`](update_llama.sh) | Build script: installs CUDA Toolkit 12.8, clones llama.cpp, builds with CUDA support |
| [`startqwen128.sh`](startqwen128.sh) | Starts Qwen 9B (128k context) + embedding model on GPU 1 |
| [`startqwen256.sh`](startqwen256.sh) | Starts Qwen 9B (256k context) using dual GPUs (0+1) with flash attention |

## Key Configuration

- **Model**: Qwen3.5-9B-Q6_K.gguf (quantized coding LLM)
- **Embedding Model**: mxbai-embed-large-v1-f16.gguf
- **GPU Target**: CUDA architecture `120a` (Ampere - RTX 30xx/A100)
- **Context Sizes**: 128k and 256k options
- **Optimizations**: Flash attention, q8_0 cache, layer splitting

## Models Configuration

### Qwen3.5-9B-Q6_K.gguf
- **Alias**: `qwen3:9b`
- **Context Size**: 131072 (128k)
- **Device**: cuda1 (GPU 1)
- **Split Mode**: none (100% on GPU)
- **Cache Type**: q8_0 for K and V caches

### mxbai-embed-large-v1-f16.gguf
- **Alias**: `embedding-model`
- **Context Size**: 1024
- **Device**: cuda1 (GPU 1)
- **Embedding Mode**: enabled

## Usage

### Build with CUDA
```bash
./update_llama.sh
```

This script will:
1. Install CUDA Toolkit 12.8 for Ubuntu 24.04 (if not present)
2. Clone or update the llama.cpp repository
3. Build with CUDA support (`GGML_CUDA=ON`)
4. Target GPU architecture `120a` (Ampere)

### Start Server

#### Simple Mode
```bash
./run_llama.sh
```
Starts llama-server on port 11434 with both models enabled.

#### Specific Configurations

**128k Context (Single GPU)**
```bash
./startqwen128.sh
```
- Port 11001: Qwen 9B with 128k context on GPU 1
- Port 11002: Embedding model on GPU 1

**256k Context (Dual GPU)**
```bash
./startqwen256.sh
```
- Port 11001: Qwen 9B with 256k context using GPUs 0+1
- Flash attention enabled
- Layer splitting across GPUs

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 11434 | Main API | Standard llama-server port |
| 11001 | Qwen 9B | Coding model inference |
| 11002 | Embeddings | Vector embedding generation |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Scripts                         │
├─────────────────────────────────────────────────────────┤
│  update_llama.sh  │  run_llama.sh  │ startqwen*.sh     │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   llama.cpp Binary                      │
│              (CUDA-accelerated)                         │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Port 11434  │  │  Port 11001  │  │  Port 11002  │
│   Main API   │  │   Qwen 9B    │  │ Embeddings   │
└──────────────┘  └──────────────┘  └──────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│                    Models                               │
├─────────────────────────────────────────────────────────┤
│  Qwen3.5-9B-Q6_K.gguf  │  mxbai-embed-large-v1-f16.gguf │
└─────────────────────────────────────────────────────────┘
```

## Environment Variables

The scripts set the following environment variables:

```bash
CUDA_VISIBLE_DEVICES=0,1  # Specify which GPUs to use
CUDA_HOME=/usr/local/cuda # CUDA toolkit path
LD_LIBRARY_PATH           # Add CUDA libraries to path
```

## Requirements

- **OS**: Ubuntu 24.04 (tested)
- **GPU**: NVIDIA Ampere architecture (RTX 30xx, A100, etc.)
- **CUDA**: Toolkit 12.8
- **Memory**: Sufficient VRAM for model loading
  - Qwen 9B Q6_K: ~6-7 GB VRAM
  - mxbai-embed-large: ~2-3 GB VRAM

## Integration

The setup is designed for **Roo Code Chat** integration:
- Main API: http://localhost:11434
- Coding Model: http://localhost:11001
- Embeddings: http://localhost:11002

## Troubleshooting

### CUDA Not Found
```bash
# Check if CUDA is installed
nvcc --version

# If not installed, run:
./update_llama.sh
```

### Port Already in Use
The scripts include cleanup commands to kill existing processes:
```bash
sudo fuser -k 11001/tcp
sudo fuser -k 11002/tcp
```

### VRAM Issues
- Use `startqwen256.sh` for dual-GPU distribution
- Reduce context size in `models.ini` if needed
- Use lower quantization (Q4_K instead of Q6_K)

## License

This setup uses the llama.cpp library which is licensed under MIT. Model files are subject to their respective licenses.
