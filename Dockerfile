# ==============================================================================
# llama-android-container: Dockerfile for Qualcomm Adreno 830 GPU Inference
# ==============================================================================

FROM ubuntu:latest

# Single HuggingFace Repository ID Variable (e.g. InternScience/Agents-A1-4B-Q4_K_M-GGUF or InternScience/Agents-A1-4B-Q8_0-GGUF)
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF

# Environment & Hardware Configurations
ENV LD_LIBRARY_PATH=/vendor/lib64
ENV THREADS=3
ENV UBATCH=128
ENV BATCH=512
ENV CONTEXT=32768
ENV GPU_LAYERS=99
ENV FLASH_ATTN=on
ENV PORT=8085
ENV HOST=0.0.0.0

# Single-line official HF CLI download & cache check (reuses cache if present, downloads if missing)
RUN hf download $REPO_ID --include "*.gguf"

# Execution Command
CMD ["taskset", "-c", "0-5", "/data/data/com.termux/files/usr/bin/llama-server", "-ngl", "99", "-c", "32768", "-np", "1", "--no-mmap", "-b", "512", "-ub", "128", "-t", "3", "-fa", "on", "--host", "0.0.0.0", "--port", "8085"]
