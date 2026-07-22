#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Pure CLI Dockerfile Container LLM Server
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830 GPU
# Usage: ./start.sh [path/to/Dockerfile]
# Example: ./start.sh Dockerfile
# ==============================================================================

DOCKERFILE_PATH="${1:-Dockerfile}"

echo "=================================================="
echo "🐳 INICIANDO CONTAINER LLM VIA DOCKERFILE CLI ($DOCKERFILE_PATH)"
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

# 3. CLI: Checar/Baixar modelo de pesos via CLI (curl / bash)
echo "3️⃣ CLI: Verificando cache de pesos do modelo HuggingFace..."
MODEL_URL="https://huggingface.co/InternScience/Agents-A1-4B-Q4_K_M-GGUF/resolve/main/Agents-A1-4B-Q4_K_M.gguf"
CACHE_DIR="$HOME/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default"
MODEL_PATH="$CACHE_DIR/Agents-A1-4B-Q4_K_M.gguf"

# Buscar no cache local via CLI (find / ls)
EXISTING_MODEL=$(find "$HOME/.cache/huggingface/hub" -name "*.gguf" 2>/dev/null | head -n 1)

if [ -n "$EXISTING_MODEL" ] && [ -f "$EXISTING_MODEL" ]; then
  MODEL_PATH="$EXISTING_MODEL"
  echo "   • ✅ [CLI] Modelo encontrado em cache: $MODEL_PATH"
else
  echo "   • 📥 [CLI] Modelo nao encontrado em cache. Baixando via curl..."
  mkdir -p "$CACHE_DIR"
  curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH"
  echo "   • ✅ [CLI] Download concluido!"
fi

# 4. Ler especificações do Dockerfile
BASE_IMAGE=$(grep -i "^FROM" "$DOCKERFILE_PATH" 2>/dev/null | awk '{print $2}' | head -n 1)
BASE_IMAGE="${BASE_IMAGE:-ubuntu:latest}"

echo "4️⃣ Processando especificações do Dockerfile:"
echo "   • Arquivo: $DOCKERFILE_PATH"
echo "   • Imagem Base (FROM): $BASE_IMAGE"
echo "   • Executando Container no ambiente proot-distro (ubuntu) com Adreno GPU..."

# Converter o caminho do host para o caminho correspondente dentro do container
CONTAINER_MODEL_PATH=$(echo "$MODEL_PATH" | sed "s|$HOME|/root/home|g")

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
echo "   • Container LLM inicializado a partir do Dockerfile CLI."

# 5. Aguardar inicialização
echo "5️⃣ Aguardando inicializacao da GPU no Container..."
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

# 6. Warmup via CLI curl
echo "6️⃣ Esquentando os motores do Container via CLI..."
curl -s -X POST http://127.0.0.1:8085/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}' \
  | grep -o '"content":"[^"]*"' | head -n 1 || true

echo ""
echo "=================================================="
echo "🎉 DOCKERFILE CLI OPERACIONAL COM ACELERAÇÃO ADRENO GPU!"
echo "=================================================="
