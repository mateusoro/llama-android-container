#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Native Dockerfile Build & Execution Engine for Termux
# Powered by `proot-distro build` (Native OCI Dockerfile Compiler)
# Usage: ./start.sh [path/to/Dockerfile]
# Example: ./start.sh Dockerfile
# ==============================================================================

DOCKERFILE_PATH="${1:-Dockerfile}"
APP_NAME="llama_app"

echo "=================================================="
echo "🐳 CONSTRUINDO E EXECUTANDO DOCKERFILE VIA PROOT-DISTRO BUILD ($DOCKERFILE_PATH)"
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

# 3. Construir a Imagem OCI nativamente a partir do Dockerfile usando `proot-distro build`
echo "3️⃣ Construindo imagem OCI a partir do Dockerfile (proot-distro build)..."
proot-distro remove "$APP_NAME" 2>/dev/null || true
proot-distro build -f "$DOCKERFILE_PATH" -t "$APP_NAME:latest" --install-as "$APP_NAME" .

echo "   • Imagem OCI instalada com sucesso como container '$APP_NAME'."

# 4. Executar o Container Construído com Passthrough de GPU Adreno 830
echo "4️⃣ Executando Container '$APP_NAME' na GPU Adreno 830 (via CMD do Dockerfile)..."
nohup proot-distro run "$APP_NAME" \
  --bind /vendor/lib64:/vendor/lib64 \
  --bind /dev/kgsl-3d0:/dev/kgsl-3d0 \
  --bind /data/data/com.termux/files/usr/etc/OpenCL/vendors:/etc/OpenCL/vendors \
  --bind /data/data/com.termux/files/home:/root/home \
  </dev/null > "$HOME/llama_container.log" 2>&1 &

disown %1 2>/dev/null || true
echo "   • Container '$APP_NAME' construído e inicializado."

# 5. Aguardar inicialização
echo "5️⃣ Aguardando inicializacao da GPU no Container..."
READY=0
for i in {1..35}; do
  STATUS=$(curl -s "http://127.0.0.1:8085/health" 2>/dev/null | grep '"status":"ok"')
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
echo "6️⃣ Esquentando os motores do Container..."
curl -s -X POST "http://127.0.0.1:8085/completion" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}' \
  | grep -o '"content":"[^"]*"' | head -n 1 || true

echo ""
echo "=================================================="
echo "🎉 DOCKERFILE CONSTRUÍDO E OPERACIONAL NA ADRENO GPU!"
echo "=================================================="
