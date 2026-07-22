# 📱 llama-android-container

> **High-Performance Dockerfile-driven LLM Containerization & Thermal Optimization for Android Termux**  
> Optimized specifically for **Qualcomm Snapdragon 8 Elite** (Oryon CPU) and **Adreno 830 GPU** (OpenCL Acceleration).

---

## ⚡ 1-Line Installation (Modern One-Liner)

Install everything automatically on Termux with a single command (no repository cloning required):

```bash
curl -fsSL https://raw.githubusercontent.com/mateusoro/llama-android-container/main/install.sh | bash
```

After installation completes, start the server anywhere by typing:

```bash
llama-container
```

---

## ⚡ Overview & Key Discoveries

Running local Large Language Models (LLMs) on mobile hardware often suffers from **thermal throttling**, **UI stutter/freezing during prompt prefill**, and **VRAM sync deadlocks**. 

This repository provides a **Dockerfile-driven containerized environment** (`udocker` / `proot-distro`) that parses standard `Dockerfile` parameters and executes them with GPU passthrough, achieving **14.37 to 16.22 tokens/second** generation speed while dropping CPU Prime core temperatures by **~35 °C**.

```mermaid
graph TD
    A["Dockerfile Specification"] --> B["start.sh / llama-container Entrypoint"]
    B --> C["udocker / proot-distro Container Engine"]
    C --> D["llama-server Engine (Inside Container)"]
    D -->|"/vendor/lib64/libOpenCL_adreno.so"| E["Adreno 830 GPU (100% Offload)"]
    D -->|"taskset -c 0-5"| F["Oryon Performance Cores (0-5)"]
    G["Android System UI"] -->|Unblocked| H["Oryon Prime Cores (6-7)"]
```

---

## 📄 Dockerfile Specification

The container is fully specified via standard `Dockerfile` syntax:

```dockerfile
FROM ubuntu:latest

ENV LD_LIBRARY_PATH=/vendor/lib64
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF
ENV MODEL_FILENAME=Agents-A1-4B-Q4_K_M.gguf

# HuggingFace Cache Directory (Shared with Host ~/.cache/huggingface)
ENV HF_HOME=/root/home/.cache/huggingface
ENV MODEL_PATH=/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default/Agents-A1-4B-Q4_K_M.gguf

# Pure CLI Model Cache Checker & Downloader (curl / bash CLI)
RUN mkdir -p $MODEL_CACHE_DIR && \
    if [ ! -f "$MODEL_PATH" ]; then \
        echo "📥 [CLI] Downloading model from HuggingFace via curl..." && \
        curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH"; \
    else \
        echo "✅ [CLI] Model found in cache! Skipped download."; \
    fi

# Optimized LLM Inference Parameters
ENV THREADS=3
ENV UBATCH=128
ENV BATCH=512
ENV CONTEXT=32768
ENV GPU_LAYERS=99
ENV FLASH_ATTN=on
ENV PORT=8085
ENV HOST=0.0.0.0
```

---

## 📊 Benchmark Summary

| Metric | Stock / Default Settings | Dockerfile Container Mode (`llama-android-container`) |
| :--- | :--- | :--- |
| **CPU Temperature** | **102.3 °C** 🛑 (Thermal Throttling) | **58.3 °C – 67.5 °C** 🧊 (**-34.8 °C Drop!**) |
| **Generation Speed** | ~11.5 tokens/s | **14.37 – 16.22 tokens/s** 🏆 (Peak Performance) |
| **Prefill UI Lag** | Severe UI Freezing | **Smooth & Fluid** (`-ub 128` Micro-batching) |
| **GPU Acceleration** | 100% Adreno 830 Offload | **100% OpenCL Passthrough via Container** |
| **Workflow Interface** | Unprotected / Native | **100% Driven by `Dockerfile` Specification** |

---

## 🚀 Quick Start & Usage

### 1. Start Server via Default Dockerfile
```bash
llama-container
```

### 2. Start Server via Custom Dockerfile
```bash
llama-container meu_modelo.Dockerfile
```
or
```bash
./start.sh /caminho/para/meu_modelo.Dockerfile
```

The startup script automatically:
1. Parses the base image (`FROM`) and parameters from the target `Dockerfile`
2. Checks/downloads model weights from HuggingFace via pure CLI (reusing local cache if present)
3. Terminates old server instances to prevent OOM memory kills
4. Launches real-time 15s thermal logger (`~/bottleneck.log`)
5. Executes `llama-server` **inside the GPU-accelerated container** on port `8085`
6. Performs an automatic health check and warmup request

---

## 🌡️ Real-Time Bottleneck & Thermal Monitoring

Monitor temperatures, CPU load, and RAM usage live:

```bash
tail -f ~/bottleneck.log
```

---

## 📄 License

Distributed under the MIT License. Free for personal and commercial use.
