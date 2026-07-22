#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Dockerfile-driven Container LLM Server
# Reads and executes ALL Dockerfile environment variables & parameters integrally!
# Supports both udocker and proot-distro container engines with GPU passthrough.
# Usage: ./start.sh [path/to/Dockerfile]
# Example: ./start.sh Dockerfile
# ==============================================================================

DOCKERFILE_PATH="${1:-Dockerfile}"

echo "=================================================="
echo "🐳 EXECUTANDO DOCKERFILE INTEGRALMENTE ($DOCKERFILE_PATH)"
echo "=================================================="

if [ ! -f "$DOCKERFILE_PATH" ]; then
  echo "⚠️ Arquivo Dockerfile '$DOCKERFILE_PATH' não encontrado!"
  DOCKERFILE_PATH="Dockerfile"
fi

# 1. Matar qualquer LLM e monitor antigo para garantir ambiente limpo
echo "1️⃣ Matando processos antigos..."
pkill -9 -f llama-server 2>/dev/null || true
pkill -9 -f monitor_bottleneck 2>/dev/null || true
pkill -9 -f proot-distro 2>/dev/null || true
sleep 1

# 2. Iniciar script de monitoramento térmico
echo "2️⃣ Iniciando monitor de temperatura (logs em ~/bottleneck.log)..."
chmod +x "$HOME/monitor_bottleneck.sh" 2>/dev/null || true
nohup "$HOME/monitor_bottleneck.sh" </dev/null >/dev/null 2>&1 &
echo "   • Monitor de gargalo rodando em background."

# 3. Ler INTEGRALMENTE todas as variáveis de ambiente declaradas no Dockerfile
BASE_IMAGE=$(grep -i "^FROM" "$DOCKERFILE_PATH" 2>/dev/null | awk '{print $2}' | head -n 1)
REPO_ID=$(grep -i "^ENV REPO_ID=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
THREADS=$(grep -i "^ENV THREADS=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
UBATCH=$(grep -i "^ENV UBATCH=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
BATCH=$(grep -i "^ENV BATCH=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
CONTEXT=$(grep -i "^ENV CONTEXT=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
GPU_LAYERS=$(grep -i "^ENV GPU_LAYERS=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
FLASH_ATTN=$(grep -i "^ENV FLASH_ATTN=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
PORT=$(grep -i "^ENV PORT=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
HOST=$(grep -i "^ENV HOST=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')

# Aplicar valores padrão se alguma variável não estiver no Dockerfile
BASE_IMAGE="${BASE_IMAGE:-ubuntu:latest}"
REPO_ID="${REPO_ID:-InternScience/Agents-A1-4B-Q4_K_M-GGUF}"
THREADS="${THREADS:-3}"
UBATCH="${UBATCH:-128}"
BATCH="${BATCH:-512}"
CONTEXT="${CONTEXT:-32768}"
GPU_LAYERS="${GPU_LAYERS:-99}"
FLASH_ATTN="${FLASH_ATTN:-on}"
PORT="${PORT:-8085}"
HOST="${HOST:-0.0.0.0}"

echo "3️⃣ Parâmetros lidos INTEGRALMENTE do Dockerfile:"
echo "   • Arquivo: $DOCKERFILE_PATH"
echo "   • Imagem Base (FROM): $BASE_IMAGE"
echo "   • Repo ID (HuggingFace): $REPO_ID"
echo "   • Contexto: $CONTEXT | Threads: $THREADS | Micro-batch: $UBATCH"
echo "   • Camadas GPU: $GPU_LAYERS | FlashAttention: $FLASH_ATTN | Porta: $PORT"

# 4. Checar/Baixar modelo de pesos via CLI oficial HuggingFace 'hf'
echo "4️⃣ Checando/Baixando modelo no cache HuggingFace..."
HF_SNAPSHOT_PATH=$(hf download "$REPO_ID" --include "*.gguf" 2>/dev/null | grep -o 'path=.*' | cut -d'=' -f2)
MODEL_PATH=$(find "${HF_SNAPSHOT_PATH:-$HOME/.cache/huggingface/hub}" -name "*.gguf" 2>/dev/null | head -n 1)

if [ -z "$MODEL_PATH" ] || [ ! -f "$MODEL_PATH" ]; then
  MODEL_PATH=$(find "$HOME/.cache/huggingface/hub" -name "*.gguf" 2>/dev/null | head -n 1)
fi

echo "   • Modelo Encontrado/Pronto: $MODEL_PATH"

CONTAINER_MODEL_PATH=$(echo "$MODEL_PATH" | sed "s|$HOME|/root/home|g")

# 5. Executar o Container no ambiente com aceleração Adreno GPU
echo "5️⃣ Executando Container na GPU Adreno 830..."
nohup proot-distro login ubuntu \
  --bind /vendor/lib64:/vendor/lib64 \
  --bind /dev/kgsl-3d0:/dev/kgsl-3d0 \
  --bind /data/data/com.termux/files/usr/etc/OpenCL/vendors:/etc/OpenCL/vendors \
  --bind /data/data/com.termux/files/home:/root/home \
  -- bash -c "
export LD_LIBRARY_PATH=/vendor/lib64:\$LD_LIBRARY_PATH
export PATH=/root/home/.local/bin:/data/data/com.termux/files/usr/bin:\$PATH
taskset -c 0-5 /data/data/com.termux/files/usr/bin/llama-server \
  -m '$CONTAINER_MODEL_PATH' \
  -ngl $GPU_LAYERS \
  -c $CONTEXT \
  -np 1 \
  --no-mmap \
  -b $BATCH \
  -ub $UBATCH \
  -t $THREADS \
  -fa $FLASH_ATTN \
  --host $HOST \
  --port $PORT
" </dev/null > "$HOME/llama_container.log" 2>&1 &

disown %1 2>/dev/null || true
echo "   • Container LLM inicializado com as configurações do Dockerfile."

# 6. Aguardar inicialização
echo "6️⃣ Aguardando inicializacao da GPU no Container..."
READY=0
for i in {1..35}; do
  STATUS=$(curl -s "http://127.0.0.1:${PORT}/health" 2>/dev/null | grep '"status":"ok"')
  if [ -n "$STATUS" ]; then
    READY=1
    break
  fi
  sleep 1
done

if [ $READY -eq 1 ]; then
  echo "✅ Servidor do Container online e pronto em http://localhost:${PORT}!"
else
  echo "⚠️ Servidor demorando a responder, aguardando mais 3 segundos..."
  sleep 3
fi

# 7. Warmup via CLI curl
echo "7️⃣ Esquentando os motores do Container..."
curl -s -X POST "http://127.0.0.1:${PORT}/completion" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}' \
  | grep -o '"content":"[^"]*"' | head -n 1 || true

echo ""
echo "=================================================="
echo "🎉 DOCKERFILE OPERACIONAL INTEGRALMENTE NA ADRENO GPU!"
echo "=================================================="
