# 📱 llama-android-container

> **High-Performance LLM Containerization & Thermal Optimization for Android Termux**  
> Optimized specifically for **Qualcomm Snapdragon 8 Elite** (Oryon CPU) and **Adreno 830 GPU** (OpenCL Acceleration).

---

## ⚡ Overview & Key Discoveries

Running local Large Language Models (LLMs) on mobile hardware often suffers from **thermal throttling**, **UI stutter/freezing during prompt prefill**, and **VRAM sync deadlocks**. 

This repository provides an end-to-end containerized setup (`udocker` / `proot-distro`) that solves these mobile bottlenecks, achieving **14.37 to 16.22 tokens/second** generation speed while dropping CPU Prime core temperatures by **~35 °C**.

```mermaid
graph TD
    A["Android OS / Termux Host"] --> B["udocker / proot-distro Container"]
    B --> C["llama-server Engine"]
    C -->|"/vendor/lib64/libOpenCL_adreno.so"| D["Adreno 830 GPU (100% Offload)"]
    C -->|"taskset -c 0-5"| E["Oryon Performance Cores (0-5)"]
    F["Android System UI"] -->|Unblocked| G["Oryon Prime Cores (6-7)"]
```

---

## 📊 Benchmark Summary

| Metric | Stock / Default Settings | Optimized `llama-android-container` |
| :--- | :--- | :--- |
| **CPU Temperature** | **102.3 °C** 🛑 (Thermal Throttling) | **58.3 °C – 67.5 °C** 🧊 (**-34.8 °C Drop!**) |
| **Generation Speed** | ~11.5 tokens/s | **14.37 – 16.22 tokens/s** 🏆 (Peak Performance) |
| **Prefill UI Lag** | Severe UI Freezing | **Smooth & Fluid** (`-ub 128` Micro-batching) |
| **GPU Acceleration** | 100% Adreno 830 Offload | **100% OpenCL Passthrough via Container** |
| **RAM Usage** | ~3.2 GB | ~550 MB – 1.2 GB |

---

## 🛠️ Key Technical Optimizations

> [!NOTE]
> **1. CPU Core Pinning (`taskset -c 0-5`)**  
> The Snapdragon 8 Elite features 2 ultra-hot Prime cores and 6 Performance cores. By hard-pinning `llama-server` to cores `0-5`, we isolate the Prime cores for Android system UI rendering and eliminate thermal throttling.

> [!TIP]
> **2. Micro-Batching (`-ub 128`)**  
> Default logical batch sizes (`-ub 512`) monopolize the GPU command queue for 500ms+ per kernel submission, causing UI frame drops. Slicing prefill into 128-token micro-batches yields the GPU queue back to the Android display compositor between iterations.

> [!IMPORTANT]
> **3. Flash Attention (`-fa on`) & Standard KV Cache (`f16`)**  
> Pass `-fa on` for FlashAttention 2 acceleration. **Do NOT quantize KV cache** (`-ctk q4_0 -ctv q4_0`) on Adreno OpenCL drivers, as quantized KV cache causes `SET_ROWS` sync kernel crashes.

---

## 🚀 Quick Start Guide

### 1. Installation

Clone this repository and run the automated installer:

```bash
git clone https://github.com/mateusoro/llama-android-container.git
cd llama-android-container
chmod +x install.sh
./install.sh
```

The installer automatically:
- Installs `python`, `clinfo`, `proot-distro`, and `udocker`
- Configures Qualcomm OpenCL vendor ICD (`/data/data/com.termux/files/usr/etc/OpenCL/vendors/qualcomm.icd`)
- Prepares base ARM64 Linux container environments

---

### 2. Running the Server

#### Option A: Native Termux Mode
```bash
./start.sh
```

#### Option B: Container Mode (`udocker` / `proot-distro`)
```bash
./start_udocker.sh llm_agent
```

Both startup scripts:
1. Terminate old server instances to prevent OOM memory kills
2. Launch real-time 15s thermal logger (`~/bottleneck.log`)
3. Execute `llama-server` on port `8085` with GPU OpenCL passthrough
4. Perform an automatic health check and warmup request

---

## 🌡️ Real-Time Bottleneck & Thermal Monitoring

Monitor temperatures, CPU load, and RAM usage live:

```bash
tail -f ~/bottleneck.log
```

Example Log Output:
```text
==================================================
⏱️ TIMESTAMP: 2026-07-22 08:55:05
--------------------------------------------------
🌡️ TEMPERATURAS DO SNAPDRAGON 8 ELITE / REDMAGIC:
  • CPU Prime Core 0 (cpu-1-0-1) : 56.7 °C
  • CPU Prime Core 1 (cpu-1-1-1) : 61.4 °C
  • CPU Perf Cores (cpuss-1-1)   : 57.1 °C
  • GPU Adreno 830 (gpuss-4)     : 56.0 °C
  • Bateria (battery)             : 48.0 °C
--------------------------------------------------
🧠 MEMÓRIA (RAM / ZRAM):
               total        used        free
Mem:           11161        5057        1224
==================================================
```

---

## 📄 License

Distributed under the MIT License. Free for personal and commercial use.
