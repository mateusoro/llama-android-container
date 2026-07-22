# ==============================================================================
# llama-android-container: Dockerfile for Qualcomm Adreno 830 GPU Inference
# ==============================================================================

FROM ubuntu:latest

# Environment variables for Qualcomm Adreno 830 GPU & Termux paths
ENV LD_LIBRARY_PATH=/vendor/lib64
ENV MODEL_PATH=/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/blobs/d93c393a9bd5139a4b5cfe24d31ef553c5a497bfb8afec178a354ecbf508f062
ENV SERVER_BIN=/data/data/com.termux/files/usr/bin/llama-server

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
CMD ["taskset", "-c", "0-5", "/data/data/com.termux/files/usr/bin/llama-server", "-m", "$MODEL_PATH", "-ngl", "99", "-c", "32768", "-np", "1", "--no-mmap", "-b", "512", "-ub", "128", "-t", "3", "-fa", "on", "--host", "0.0.0.0", "--port", "8085"]
