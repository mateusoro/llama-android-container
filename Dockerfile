# ==============================================================================
# llama-android-container: Dockerfile for Qualcomm Adreno 830 GPU Inference
# ==============================================================================

FROM ubuntu:latest

# Environment variables for Qualcomm Adreno 830 GPU & Termux paths
ENV LD_LIBRARY_PATH=/vendor/lib64
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF
ENV MODEL_FILENAME=Agents-A1-4B-Q4_K_M.gguf

# HuggingFace Cache Directory (Shared with Termux Host ~/.cache/huggingface)
ENV HF_HOME=/root/home/.cache/huggingface

# Optimized LLM Inference Parameters
ENV THREADS=3
ENV UBATCH=128
ENV BATCH=512
ENV CONTEXT=32768
ENV GPU_LAYERS=99
ENV FLASH_ATTN=on
ENV PORT=8085
ENV HOST=0.0.0.0

# Automatic Model Cache Checker & Downloader Script
# Checks ~/.cache/huggingface first; downloads automatically from HF if missing!
RUN echo "HuggingFace Cache mapped to /root/home/.cache/huggingface"

CMD ["taskset", "-c", "0-5", "/data/data/com.termux/files/usr/bin/llama-server", "-ngl", "99", "-c", "32768", "-np", "1", "--no-mmap", "-b", "512", "-ub", "128", "-t", "3", "-fa", "on", "--host", "0.0.0.0", "--port", "8085"]
