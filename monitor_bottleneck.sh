#!/data/data/com.termux/files/usr/bin/bash
# Script ultra-completo de monitoramento de temperatura e memória a cada 15s

LOG_FILE="$HOME/bottleneck.log"
echo "=== INICIANDO MONITOR DE GARGALO E TEMPERATURA [$(date '+%Y-%m-%d %H:%M:%S')] ===" > "$LOG_FILE"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "==================================================" >> "$LOG_FILE"
    echo "⏱️ TIMESTAMP: $TIMESTAMP" >> "$LOG_FILE"
    echo "--------------------------------------------------" >> "$LOG_FILE"
    
    # 🌡️ TEMPERATURAS DETALHADAS (CPU PRIME, PERF, GPU, BATERIA, CHASSI)
    echo "🌡️ TEMPERATURAS DO SNAPDRAGON 8 ELITE / REDMAGIC:" >> "$LOG_FILE"
    python3 "$HOME/get_thermal.py" >> "$LOG_FILE" 2>/dev/null || true

    echo "--------------------------------------------------" >> "$LOG_FILE"

    # MEMÓRIA RAM & SWAP/ZRAM
    echo "🧠 MEMÓRIA (RAM / ZRAM):" >> "$LOG_FILE"
    free -m | awk 'NR==1 || NR==2 || NR==3' >> "$LOG_FILE"
    
    echo "--------------------------------------------------" >> "$LOG_FILE"

    # TOP PROCESSOS POR CPU E MEMÓRIA
    echo "🔥 TOP 3 PROCESSOS POR CPU:" >> "$LOG_FILE"
    ps aux --sort=-%cpu | head -n 4 | tail -n 3 | awk '{print "  PID:", $2, "| CPU%:", $3, "| MEM%:", $4, "| CMD:", $11, $12, $13}' >> "$LOG_FILE"
    
    echo "🐘 TOP 3 PROCESSOS POR MEMÓRIA (RSS):" >> "$LOG_FILE"
    ps aux --sort=-rss | head -n 4 | tail -n 3 | awk '{print "  PID:", $2, "| RSS(MB):", int($6/1024), "| CMD:", $11, $12, $13}' >> "$LOG_FILE"
    
    echo "==================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    sleep 15
done
