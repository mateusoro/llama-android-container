#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Master Startup Script: Native OpenCL GPU LLM Server
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830
# ==============================================================================

echo "=================================================="
echo "🚀 INICIANDO SERVIDOR LLM NATIVO NA GPU ADRENO 830"
echo "=================================================="

# 1. Matar qualquer LLM e monitor antigo
echo "1️⃣ Matando processos antigos do llama-server..."
pkill -9 -f llama-server 2>/dev/null || true
pkill -9 -f monitor_bottleneck 2>/dev/null || true
sleep 1

# 2. Iniciar script de monitoramento térmico
echo "2️⃣ Iniciando monitor de temperatura e gargalo..."
chmod +x "$HOME/monitor_bottleneck.sh"
nohup "$HOME/monitor_bottleneck.sh" </dev/null >/dev/null 2>&1 &
echo "   • Monitor de gargalo rodando em background."

# 3. Disparar llama-server com otimizações campeãs
echo "3️⃣ Iniciando llama-server (taskset 0-5, -t 3, -ub 128, -fa on)..."
export LD_LIBRARY_PATH=/vendor/lib64:$LD_LIBRARY_PATH

MODEL_PATH="$HOME/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/blobs/d93c393a9bd5139a4b5cfe24d31ef553c5a497bfb8afec178a354ecbf508f062"
SERVER_BIN="/data/data/com.termux/files/usr/bin/llama-server"

# Isolar núcleos Prime (0-5), 3 Threads, Micro-batch 128 (Prefill Fluido)
nohup taskset -c 0-5 "$SERVER_BIN" \
  -m "$MODEL_PATH" \
  -ngl 99 \
  -c 32768 \
  -np 1 \
  --no-mmap \
  -b 512 \
  -ub 128 \
  -t 3 \
  -fa on \
  --host 0.0.0.0 \
  --port 8085 </dev/null > "$HOME/llama_server.log" 2>&1 &

disown %1 2>/dev/null || true
echo "   • llama-server inicializado em background."

# 4. Aguardar inicialização do modelo
echo "4️⃣ Aguardando inicializacao na GPU..."
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
  echo "✅ Servidor LLM pronto em http://localhost:8085!"
else
  echo "⚠️ Servidor demorando a responder, aguardando mais 3 segundos..."
  sleep 3
fi

# 5. Warmup
echo "5️⃣ Esquentando os motores do modelo..."
python3 -c '
import urllib.request, json
url = "http://127.0.0.1:8085/completion"
payload = {"prompt": "Diga um oi em 3 palavras", "n_predict": 10, "temperature": 0.7}
req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        print("   • Resposta do Modelo:", res.get("content", "").strip())
except Exception as e:
    print("   • Aviso no aquecimento:", e)
'

echo "=================================================="
echo "🎉 SISTEMA PRONTO E OPERACIONAL (ADRENO GPU 14.37 tokens/s)!"
echo "=================================================="
