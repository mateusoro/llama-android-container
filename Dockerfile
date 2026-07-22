# ==============================================================================
# llama-android-container: Dockerfile Specification
# Single Source of Truth for Model, Environment & Inference Parameters
# ==============================================================================

FROM ubuntu:latest

# 1. Single HuggingFace Repository ID Variable
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF

# 2. Hardware & OpenCL Adreno 830 GPU Driver Path
ENV LD_LIBRARY_PATH=/vendor/lib64

# 3. LLM Inference Parameters
ENV CONTEXT=32768
ENV THREADS=3
ENV UBATCH=128
ENV BATCH=512
ENV GPU_LAYERS=99
ENV FLASH_ATTN=on
ENV PORT=8085
ENV HOST=0.0.0.0

# 4. Build-time setup inside container
RUN apt-get update && apt-get install -y curl ca-certificates

# 5. Runtime Execution Engine (Triggered by proot-distro run)
CMD sh -c 'export PATH=/root/home/.local/bin:/data/data/com.termux/files/usr/bin:$PATH && \
    MODEL_PATH=$(find /root/home/.cache/huggingface/hub -name "*.gguf" 2>/dev/null | head -n 1) && \
    exec taskset -c 0-5 /data/data/com.termux/files/usr/bin/llama-server \
      -m "$MODEL_PATH" -ngl $GPU_LAYERS -c $CONTEXT -np 1 --no-mmap \
      -b $BATCH -ub $UBATCH -t $THREADS -fa $FLASH_ATTN \
      --host $HOST --port $PORT'
