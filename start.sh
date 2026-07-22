#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Containerized OpenCL GPU LLM Server
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830 (100% Container Mode)
# ==============================================================================

CONTAINER_NAME="${1:-llm_agent}"

echo "=================================================="
echo "🐳 INICIANDO SERVIDOR LLM NO CONTAINER ($CONTAINER_NAME + ADRENO 830 GPU)"
echo "=================================================="

# 1. Matar qualquer LLM e monitor antigo para garantir ambiente limpo
echo "1️⃣ Matando processos antigos..."
pkill -9 -f llama-server 2>/dev/null || true
pkill -9 -f monitor_bottleneck 2>/dev/null || true
pkill -9 -f proot-distro 2>/dev/null || true
sleep 1

# 2. Iniciar script de monitoramento térmico
echo "2️⃣ Iniciando monitor de temperatura (logs em ~/bottleneck.log)..."
chmod +x "$HOME/monitor_bottleneck.sh"
nohup "$HOME/monitor_bottleneck.sh" </dev/null >/dev/null 2>&1 &
echo "   • Monitor de gargalo rodando em background."

# 3. Disparar llama-server EXCLUSIVAMENTE DENTRO do Container com GPU Passthrough
echo "3️⃣ Iniciando llama-server DENTRO do Container na GPU Adreno 830..."

if command -v udocker >/dev/null 2>&1 && udocker ps | grep -q "$CONTAINER_NAME"; then
  echo "   • Modo de Execucao: Container udocker ($CONTAINER_NAME)"
  nohup taskset -c 0-5 udocker run \
    -v /vendor/lib64:/vendor/lib64 \
    -v /dev/kgsl-3d0:/dev/kgsl-3d0 \
    -v /data/data/com.termux/files/usr/etc/OpenCL/vendors:/etc/OpenCL/vendors \
    -v /data/data/com.termux/files/home:/root/home \
    -e LD_LIBRARY_PATH=/vendor/lib64 \
    "$CONTAINER_NAME" \
    /data/data/com.termux/files/usr/bin/llama-server \
      -m /root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/blobs/d93c393a9bd5139a4b5cfe24d31ef553c5a497bfb8afec178a354ecbf508f062 \
      -ngl 99 -c 32768 -np 1 --no-mmap -b 512 -ub 128 -t 3 -fa on --host 0.0.0.0 --port 8085 </dev/null > "$HOME/llama_container.log" 2>&1 &
else
  echo "   • Modo de Execucao: Container proot-distro (ubuntu)"
  nohup proot-distro login ubuntu \
    --bind /vendor/lib64:/vendor/lib64 \
    --bind /dev/kgsl-3d0:/dev/kgsl-3d0 \
    --bind /data/data/com.termux/files/usr/etc/OpenCL/vendors:/etc/OpenCL/vendors \
    --bind /data/data/com.termux/files/home:/root/home \
    -- bash -c '
  export LD_LIBRARY_PATH=/vendor/lib64:$LD_LIBRARY_PATH
  export PATH=/root/home/.local/bin:/data/data/com.termux/files/usr/bin:$PATH
  MODEL_PATH="/root/home/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/blobs/d93c393a9bd5139a4b5cfe24d31ef553c5a497bfb8afec178a354ecbf508f062"
  taskset -c 0-5 /data/data/com.termux/files/usr/bin/llama-server -m "$MODEL_PATH" -ngl 99 -c 32768 -np 1 --no-mmap -b 512 -ub 128 -t 3 -fa on --host 0.0.0.0 --port 8085
  ' </dev/null > "$HOME/llama_container.log" 2>&1 &
fi

disown %1 2>/dev/null || true
echo "   • Container LLM inicializado com sucesso."

# 4. Aguardar inicialização
echo "4️⃣ Aguardando inicializacao do Container na GPU..."
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

# 5. Warmup
echo "5️⃣ Esquentando os motores do Container..."
python3 -c '
import urllib.request, json
url = "http://127.0.0.1:8085/completion"
payload = {"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}
req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        print("   • Resposta do Container:", res.get("content", "").strip())
except Exception as e:
    print("   • Aviso no aquecimento:", e)
'

echo "=================================================="
echo "🎉 CONTAINER LLM OPERACIONAL COM ACELERAÇÃO ADRENO GPU!"
echo "=================================================="
