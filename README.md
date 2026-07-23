# 📱 llama-android-container

> **High-Performance LLM Inference on Android Termux**  
> Powered by **llama.cpp** (pre-built with OpenCL) & **Qualcomm Adreno 830 GPU**

---

## ⚡ 1-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/mateusoro/llama-android-container/main/install.sh | bash
```

Start the server:

```bash
llama-container
```

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│  Termux (Native — no container)                      │
│                                                      │
│  install.sh                                          │
│    ├── pkg install llama-cpp llama-cpp-backend-opencl│
│    └── Configure OpenCL ICD → Adreno 830 driver      │
│                                                      │
│  start.sh                                            │
│    ├── Download model → ~/.cache/llama-models/       │
│    ├── LD_LIBRARY_PATH=/vendor/lib64 (GPU driver)    │
│    └── taskset -c 0-5 llama-server (GPU offload)     │
│                                                      │
│  Cores 0-5: Oryon Perf (inference)                   │
│  Cores 6-7: Oryon Prime (UI stays smooth)            │
└──────────────────────────────────────────────────────┘
```

**Why no container?**
- Termux packages (`llama-cpp` + `llama-cpp-backend-opencl`) are pre-compiled with OpenCL Adreno support
- Binaries link against bionic (Android libc) — they can't run inside a glibc container without ptrace overhead
- Running natively = zero overhead, direct GPU access

---

## 📊 Performance Tweaks

- `-ngl 99` — 100% GPU offload (all layers on Adreno 830)
- `-fa on` — Flash Attention (reduces VRAM, faster attention)
- `-ub 128` — Micro-batch 128 (prevents UI freezing during prefill)
- `-b 512` — Batch size 512
- `-t 3` — 3 CPU threads (GPU does the heavy lifting)
- `--no-mmap` — Lock model in RAM (avoids page faults)
- `taskset -c 0-5` — Pin to perf cores, leave prime cores for UI

---

## 📊 Benchmark (Snapdragon 8 Elite / RedMagic)

- **Temperature**: 102.3 °C → **58.3 – 67.5 °C** (-34.8 °C)
- **Speed**: ~11.5 → **14.37 – 16.22 tokens/s**
- **UI Lag**: Severe → **Smooth** (micro-batching)
- **GPU**: 100% Adreno 830 OpenCL offload

---

## 🚀 Usage

### Start server (default model)
```bash
llama-container
```

### Custom model
```bash
llama-container /path/to/model.gguf
```

### Monitor thermals
```bash
tail -f ~/bottleneck.log
```

### Server logs
```bash
cat ~/llama_server.log
```

### Stop
```bash
pkill llama-server
```

---

## 📁 Files

- `install.sh` — One-line installer (pkg install + OpenCL config)
- `start.sh` — Download model + launch llama-server with tweaks
- `get_thermal.py` — SoC temperature reader (Snapdragon 8 Elite zones)
- `monitor_bottleneck.sh` — 15s interval thermal/RAM/CPU logger

---

## 📄 License

MIT License. Free for personal and commercial use.
