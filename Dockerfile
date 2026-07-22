# ==============================================================================
# llama-android-container: Dockerfile Specification
# Single Source of Truth for Model, Environment & Inference Parameters
# ==============================================================================

FROM ubuntu:latest

# 1. HuggingFace Repository ID (e.g. InternScience/Agents-A1-4B-Q4_K_M-GGUF or InternScience/Agents-A1-4B-Q8_0-GGUF)
ENV REPO_ID=InternScience/Agents-A1-4B-Q4_K_M-GGUF

# 2. Hardware & OpenCL Adreno 830 GPU Driver Path
ENV LD_LIBRARY_PATH=/vendor/lib64

# 3. LLM Inference Parameters (Loaded integrally by start.sh / llama-container)
ENV CONTEXT=32768
ENV THREADS=3
ENV UBATCH=128
ENV BATCH=512
ENV GPU_LAYERS=99
ENV FLASH_ATTN=on
ENV PORT=8085
ENV HOST=0.0.0.0

# 4. Single-line official HuggingFace CLI download & cache check
RUN hf download $REPO_ID --include "*.gguf"
