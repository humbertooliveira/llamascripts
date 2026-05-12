"""# Deep Dive: Optimizing Blackwell (RTX 50-Series) for Local LLMs

This document summarizes the technical discussions regarding the optimization of **NVIDIA Blackwell (SM 120)** hardware, specifically the **RTX 5060 Ti 16GB Dual Setup**, for high-context coding tasks using `llama.cpp` and Qwen 3.6 27B.

---

## 1. Why Blackwell Needs Specific Build Options
While `llama.cpp` is designed to be cross-platform, the **RTX 50-series (Blackwell)** introduces architectural shifts that "default" or "native" build flags often miss.

### A. The SM 120 Architecture
Default builds often target older Streaming Multiprocessor (SM) versions (like SM 80 for Ampere or SM 89 for Ada). Blackwell uses **SM 120**. 
* **The Issue:** If you use `native`, the compiler might fallback to generic CUDA kernels if the detection logic hasn't been updated for the very latest hardware.
* **The Fix:** Explicitly setting `-DCMAKE_CUDA_ARCHITECTURES=120` ensures the compiler uses Blackwell-specific instructions, such as **Asynchronous Transaction Commands**, which improve data movement between the GPUs.

### B. Unlocking NVFP4 & FP8 Hardware Acceleration
Blackwell's "Superpower" is native support for **4-bit Floating Point (NVFP4)** and **8-bit Floating Point (FP8)** math.
* **Standard GGUF:** Uses integer math (Q4_K, etc.). While fast, it doesn't use the specialized Blackwell Tensor Core paths.
* **Build Flag:** `-DGGML_CUDA_F16=ON`. In `llama.cpp`, this flag is the gatekeeper. It forces the internal GGML math to stay in half-precision, which allows the Blackwell Tensor Cores to engage their high-speed FP8/FP4 hardware units. Without this, the system may default to slower FP32 accumulation.

---

## 2. Model Selection: NVFP4 vs. Regular GGUF
For your dual 5060 Ti setup, **NVFP4** is the superior choice for coding.

| Feature | Regular GGUF (e.g., Q4_K_M) | NVFP4 GGUF |
| :--- | :--- | :--- |
| **Math Type** | Integer-based | Floating Point-based |
| **Hardware Path** | Generic CUDA Kernels | Blackwell Tensor Cores |
| **Logic Density** | Standard | High (Better for code syntax) |
| **Efficiency** | Good for all GPUs | Optimized for 50-series |

**Recommendation:** Use the **Abiray/Freenixi** version. It preserves the architecture's output tensors more effectively than the LibertAID version, leading to fewer "hallucinated" syntax errors in long code files.

---

## 3. High Context (128k) & VRAM Budgeting
You have **32GB total VRAM**. Running a **27B model** at 128k context is a "tight fit" that requires specific KV cache quantization.

### The Hybrid Advantage
**Qwen 3.6 27B** uses a hybrid architecture (Gated DeltaNet + Gated Attention). 
* **Linear Scaling:** Only a portion of the model's layers scale linearly with context length. 
* **VRAM Savings:** This allows a 128k context to fit into ~4-8GB (depending on quantization), whereas older architectures would require 20GB+ for the same context window.

### Recommended KV Cache Settings
* **FP8 (`--cache-type-k fp8`):** Use this now that you have the optimized build. It provides the best stability for CUDA 13.2 and maintains the highest accuracy for reading multiple files.
* **Q8_0 (`--cache-type-k q8_0`):** Use this if you encounter any FP8 kernel bugs. It is very stable and nearly as accurate.

---

## 4. Hardware Bottlenecks: B550 & PCIe 3.0
Your **Ryzen 5700G** and **B550** motherboard create a specific bottleneck:
1.  **PCIe Lane Splitting:** On B550, the second GPU usually runs through the chipset at **PCIe 3.0 x4**. 
2.  **P2P Communication:** When `llama.cpp` splits the model across two GPUs, they must exchange data. Because your second slot is restricted, you will see a "Prompt Processing" (ingest) speed that is slower than a high-end X670/X870 setup.
3.  **The Solution:** This only affects the *start* of the chat. Once the 128k context is loaded into VRAM, the generation speed (Tokens per Second) will be full Blackwell speed.

---

## 5. The Optimized Build Command
To ensure all the above features are active, your build script should utilize these flags:

```bash
cmake -B build \\
  -DGGML_CUDA=ON \\
  -DGGML_CUDA_F16=ON \\
  -DGGML_NVFP4=ON \\
  -DCMAKE_CUDA_ARCHITECTURES=120 \\
  -DGGML_CUDA_FA_ALL_QUANTS=ON \\
  -DCMAKE_BUILD_TYPE=Release
```


## 6. Final Launch Strategy for Pi Agent
```bash
./llama-server -m Qwen3.6-27B-Abiray-NVFP4.gguf \
  --n-gpu-layers 999 \
  --ctx-size 131072 \
  --cache-type-k fp8 \
  --cache-type-v fp8 \
  --flash-attn \
  --batch-size 1024
```

Using fp8 cache ensures you have ~6-8GB of VRAM headroom to prevent OOM crashes during long documentation writes.

## 7. Final Launch Strategy (Stabilized for B550)
To run 128k context reliably while documentation is generated over a slower PCIe bus:[cite: 1]

```bash
./llama-server -m Qwen3.6-27B-Abiray-NVFP4.gguf \
  --n-gpu-layers 999 \
  --ctx-size 131072 \
  --cache-type-k fp8 \
  --cache-type-v fp8 \
  --flash-attn \
  --n-ga-n 4 \
  --grp-attn-n 4 \
  --batch-size 1024
```
Note: The --n-ga flags help stabilize the math and prevent "context-shift" slowdowns caused by the PCIe 3.0 x4 bottleneck on the second 5060 Ti slot.