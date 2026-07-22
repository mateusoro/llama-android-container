# ==============================================================================
# llama-android-container: Dockerfile for Qualcomm Adreno 830 GPU Inference
# ==============================================================================

FROM ubuntu:latest

# Environment variables for Qualcomm Adreno 830 GPU & Termux paths
ENV LD_LIBRARY_PATH=/vendor/lib64
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF
ENV MODEL_FILENAME=Agents-A1-4B-Q4_K_M.gguf
ENV MODEL_URL=https://huggingface.co/InternScience/Agents-A1-4B-Q4_K_M-GGUF/resolve/main/Agents-A1-4B-Q4_K_M.gguf

# HuggingFace Cache Directory (Shared with Host ~/.cache/huggingface)
ENV HF_HOME=/root/home/.cache/huggingface
ENV MODEL_CACHE_DIR=/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default
ENV MODEL_PATH=/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default/Agents-A1-4B-Q4_K_M.gguf

# Pure CLI Model Cache Checker & Downloader (curl / bash CLI)
RUN mkdir -p $MODEL_CACHE_DIR && \
    if [ ! -f "$MODEL_PATH" ]; then \
        echo "📥 [CLI] Baixando modelo do HuggingFace via curl..." && \
        curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH"; \
    else \
        echo "✅ [CLI] Modelo encontrado em cache ($MODEL_PATH)! Skipped download."; \
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

# Execution Command
CMD ["taskset", "-c", "0-5", "/data/data/com.termux/files/usr/bin/llama-server", "-m", "/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default/Agents-A1-4B-Q4_K_M.gguf", "-ngl", "99", "-c", "32768", "-np", "1", "--no-mmap", "-b", "512", "-ub", "128", "-t", "3", "-fa", "on", "--host", "0.0.0.0", "--port", "8085"]
