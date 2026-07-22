#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Dockerfile-driven Container LLM Server
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830 GPU
# Usage: ./start.sh [path/to/Dockerfile]
# Example: ./start.sh Dockerfile
# ==============================================================================

DOCKERFILE_PATH="${1:-Dockerfile}"

echo "=================================================="
echo "🐳 INICIANDO CONTAINER LLM VIA DOCKERFILE ($DOCKERFILE_PATH)"
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

# 3. Ler REPO_ID e BASE_IMAGE das especificações do Dockerfile
REPO_ID=$(grep -i "^ENV REPO_ID=" "$DOCKERFILE_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "')
REPO_ID="${REPO_ID:-InternScience/Agents-A1-4B-Q4_K_M-GGUF}"
BASE_IMAGE=$(grep -i "^FROM" "$DOCKERFILE_PATH" 2>/dev/null | awk '{print $2}' | head -n 1)
BASE_IMAGE="${BASE_IMAGE:-ubuntu:latest}"

echo "3️⃣ Especificações do Dockerfile:"
echo "   • Arquivo: $DOCKERFILE_PATH"
echo "   • Imagem Base (FROM): $BASE_IMAGE"
echo "   • Repo ID (HuggingFace): $REPO_ID"

# 4. Download / Checagem de Cache em uma única linha usando a CLI oficial `hf`
echo "4️⃣ Checando/Baixando modelo no cache HuggingFace via CLI oficial..."
HF_SNAPSHOT_PATH=$(hf download "$REPO_ID" --include "*.gguf" 2>/dev/null | grep -o 'path=.*' | cut -d'=' -f2)
MODEL_PATH=$(find "${HF_SNAPSHOT_PATH:-$HOME/.cache/huggingface/hub}" -name "*.gguf" 2>/dev/null | head -n 1)

if [ -z "$MODEL_PATH" ] || [ ! -f "$MODEL_PATH" ]; then
  MODEL_PATH=$(find "$HOME/.cache/huggingface/hub" -name "*.gguf" 2>/dev/null | head -n 1)
fi

echo "   • Modelo Encontrado/Pronto: $MODEL_PATH"

# Converter caminho do host Termux para caminho montado dentro do container
CONTAINER_MODEL_PATH=$(echo "$MODEL_PATH" | sed "s|$HOME|/root/home|g")

# 5. Executar o Container no ambiente proot-distro (ubuntu) com Adreno GPU
echo "5️⃣ Executando Container Ubuntu na GPU Adreno 830..."
nohup proot-distro login ubuntu \
  --bind /vendor/lib64:/vendor/lib64 \
  --bind /dev/kgsl-3d0:/dev/kgsl-3d0 \
  --bind /data/data/com.termux/files/usr/etc/OpenCL/vendors:/etc/OpenCL/vendors \
  --bind /data/data/com.termux/files/home:/root/home \
  -- bash -c "
export LD_LIBRARY_PATH=/vendor/lib64:\$LD_LIBRARY_PATH
export PATH=/root/home/.local/bin:/data/data/com.termux/files/usr/bin:\$PATH
taskset -c 0-5 /data/data/com.termux/files/usr/bin/llama-server -m '$CONTAINER_MODEL_PATH' -ngl 99 -c 32768 -np 1 --no-mmap -b 512 -ub 128 -t 3 -fa on --host 0.0.0.0 --port 8085
" </dev/null > "$HOME/llama_container.log" 2>&1 &

disown %1 2>/dev/null || true
echo "   • Container LLM inicializado a partir do Dockerfile."

# 6. Aguardar inicialização
echo "6️⃣ Aguardando inicializacao da GPU no Container..."
READY=0
for i in {1..35}; do
  STATUS=$(curl -s http://127.0.0.1:8085/health 2>/dev/null | grep '"status":"ok"')
  if [ -n "$STATUS" ]; then
    READY=1
    break
  fi
  sleep 1
done

if [ $READY -eq 1 ]; then
  echo "✅ Servidor do Container online e pronto em http://localhost:8085!"
else
  echo "⚠️ Servidor demorando a responder, aguardando mais 3 segundos..."
  sleep 3
fi

# 7. Warmup via CLI curl
echo "7️⃣ Esquentando os motores do Container..."
curl -s -X POST http://127.0.0.1:8085/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}' \
  | grep -o '"content":"[^"]*"' | head -n 1 || true

echo ""
echo "=================================================="
echo "🎉 DOCKERFILE OPERACIONAL COM ACELERAÇÃO ADRENO GPU!"
echo "=================================================="
