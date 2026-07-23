#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# llama-android-container: Start llama-server + nanocoder (local LLM)
# Launches llama-server on Adreno 830 GPU, then opens nanocoder using it
# Usage: ./start-nanocoder.sh [model_path.gguf]
# ==============================================================================

MODEL_CACHE="$HOME/.cache/llama-models"
MODEL_FILE="Agents-A1-4B-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/InternScience/Agents-A1-4B-Q4_K_M-GGUF/resolve/main/Agents-A1-4B-Q4_K_M.gguf"
PORT=8085
NANOCODER_CONFIG="$HOME/.config/nanocoder/agents.config.json"

# Modelo custom via argumento
if [ -n "$1" ] && [ -f "$1" ]; then
  MODEL_PATH="$1"
  MODEL_FILE=$(basename "$1")
else
  MODEL_PATH="$MODEL_CACHE/$MODEL_FILE"
fi

echo "=================================================="
echo "🦙 llama-server + nanocoder — Adreno 830 GPU"
echo "=================================================="

# 1. Matar processos antigos
echo "1️⃣ Matando processos antigos..."
pkill -9 -f llama-server 2>/dev/null || true
pkill -9 -f monitor_bottleneck 2>/dev/null || true
sleep 1

# 2. Monitor térmico
echo "2️⃣ Monitor térmico (~/bottleneck.log)..."
chmod +x "$HOME/monitor_bottleneck.sh" 2>/dev/null || true
nohup "$HOME/monitor_bottleneck.sh" </dev/null >/dev/null 2>&1 &

# 3. Garantir modelo
mkdir -p "$MODEL_CACHE"
if [ ! -f "$MODEL_PATH" ]; then
  echo "3️⃣ 📥 Baixando modelo (~2.5 GB)..."
  curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH"
  if [ $? -ne 0 ]; then
    echo "❌ Download falhou!"
    exit 1
  fi
  echo "   ✅ Salvo: $MODEL_PATH"
else
  echo "3️⃣ ✅ Modelo em cache: $MODEL_PATH"
fi

# 4. Verificar llama-server
if ! command -v llama-server &>/dev/null; then
  echo "❌ llama-server não encontrado!"
  echo "   Instale: pkg install llama-cpp llama-cpp-backend-opencl"
  exit 1
fi

# 5. OpenCL Adreno 830
export LD_LIBRARY_PATH="/vendor/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# 6. Lançar llama-server
echo "4️⃣ Iniciando llama-server (GPU Adreno 830)..."
nohup taskset -c 0-5 llama-server \
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
  --port "$PORT" \
  </dev/null > "$HOME/llama_server.log" 2>&1 &

LLAMA_PID=$!
disown $LLAMA_PID 2>/dev/null || true
echo "   • PID: $LLAMA_PID"

# 7. Health check
echo "5️⃣ Aguardando llama-server..."
READY=0
for i in $(seq 1 60); do
  STATUS=$(curl -s "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -o '"status":"ok"')
  if [ -n "$STATUS" ]; then
    READY=1
    break
  fi
  sleep 2
done

if [ $READY -ne 1 ]; then
  echo "❌ llama-server não respondeu. Logs: cat ~/llama_server.log"
  exit 1
fi
echo "   ✅ llama-server online: http://localhost:$PORT"

# 8. Verificar nanocoder
if ! command -v nanocoder &>/dev/null; then
  echo "❌ nanocoder não encontrado!"
  echo "   Instale: npm install -g nanocoder"
  exit 1
fi

# 9. Configurar provider local no nanocoder
echo "6️⃣ Configurando nanocoder → llama-server local..."
mkdir -p "$(dirname "$NANOCODER_CONFIG")"

# Adicionar provider "local" se não existir
if [ -f "$NANOCODER_CONFIG" ]; then
  # Verificar se provider "local" já existe
  if ! python3 -c "
import json, sys
with open('$NANOCODER_CONFIG') as f:
    cfg = json.load(f)
providers = cfg.get('nanocoder', {}).get('providers', [])
sys.exit(0 if any(p.get('name') == 'local' for p in providers) else 1)
" 2>/dev/null; then
    python3 -c "
import json
with open('$NANOCODER_CONFIG') as f:
    cfg = json.load(f)
cfg.setdefault('nanocoder', {}).setdefault('providers', []).append({
    'name': 'local',
    'models': ['$MODEL_FILE'],
    'baseUrl': 'http://localhost:$PORT/v1',
    'apiKey': 'not-needed',
    'timeout': 120000
})
with open('$NANOCODER_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
"
    echo "   • Provider 'local' adicionado ao config"
  else
    echo "   • Provider 'local' já existe"
  fi
else
  # Criar config do zero
  cat > "$NANOCODER_CONFIG" << JSONEOF
{
  "nanocoder": {
    "providers": [
      {
        "name": "local",
        "models": ["$MODEL_FILE"],
        "baseUrl": "http://localhost:$PORT/v1",
        "apiKey": "not-needed",
        "timeout": 120000
      }
    ]
  }
}
JSONEOF
  echo "   • Config criada com provider 'local'"
fi

# 10. Lançar nanocoder
echo ""
echo "=================================================="
echo "🎉 Tudo pronto!"
echo "   LLM: http://localhost:$PORT (Adreno 830 GPU)"
echo "   Modelo: $MODEL_FILE"
echo "   Logs: cat ~/llama_server.log"
echo "   Parar: pkill llama-server"
echo "=================================================="
echo ""

exec nanocoder --provider local --model "$MODEL_FILE" --context-max 32k
