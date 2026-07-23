#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# llama-android-container: Installer
# Installs llama-server with OpenCL Adreno GPU support on Termux (no container)
# Usage: curl -fsSL https://raw.githubusercontent.com/mateusoro/llama-android-container/main/install.sh | bash
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "  _     _     _    __  E  ___  _       ___ ______ ________ ___ ___  "
echo " | |   | |   / \  |  \/  |/ _ \| \    / / |  ____|  ____|  _ \___ \ "
echo " | |   | |  / _ \ | |\/| | | | |  \  / /| | |__  | |__  | |_) |__) |"
echo " | |___| |_/ ___ \| |  | | |_| |\ \/ / | |  __| |  __| |  _ <|__ < "
echo " |_____|_____/_/   \_\_|  |_|\___/  \__/  |_|____|_|____|_| \_\___/ "
echo -e "${PURPLE}   Snapdragon 8 Elite / Adreno 830 GPU — Termux Native${NC}"
echo "===================================================================="

REPO_URL="https://github.com/mateusoro/llama-android-container.git"
INSTALL_DIR="$HOME/llama-android-container"

# 1. Pacotes base
echo -e "\n${YELLOW}[1/4] 📦 Instalando pacotes base...${NC}"
pkg update -y || true
pkg install -y git python curl fd ripgrep || true

# 2. llama-server + OpenCL backend
echo -e "\n${YELLOW}[2/4] 🦙 Instalando llama-cpp + backend OpenCL...${NC}"
pkg install -y llama-cpp llama-cpp-backend-opencl ocl-icd || true

# 3. Configurar driver OpenCL Adreno
echo -e "\n${YELLOW}[3/4] 🎮 Configurando driver OpenCL Adreno 830...${NC}"
mkdir -p "$PREFIX/etc/OpenCL/vendors"
echo "/vendor/lib64/libOpenCL_adreno.so" > "$PREFIX/etc/OpenCL/vendors/qualcomm.icd"

# 4. Clonar projeto + criar atalho global
echo -e "\n${YELLOW}[4/4] ⚙️ Configurando scripts...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --rebase || true
else
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR" || true
fi

cp -f "$INSTALL_DIR/start.sh" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/start-nanocoder.sh" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/get_thermal.py" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/monitor_bottleneck.sh" "$HOME/" 2>/dev/null || true
chmod +x "$HOME/start.sh" "$HOME/start-nanocoder.sh" "$HOME/monitor_bottleneck.sh"

cat << 'EOF' > "$PREFIX/bin/llama-container"
#!/data/data/com.termux/files/usr/bin/bash
exec "$HOME/start.sh" "$@"
EOF
chmod +x "$PREFIX/bin/llama-container"

cat << 'EOF' > "$PREFIX/bin/llama-nanocoder"
#!/data/data/com.termux/files/usr/bin/bash
exec "$HOME/start-nanocoder.sh" "$@"
EOF
chmod +x "$PREFIX/bin/llama-nanocoder"

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}🎉 INSTALAÇÃO CONCLUÍDA!${NC}"
echo -e "===================================================================="
echo -e "${CYAN}Para iniciar o servidor:${NC}"
echo -e "  ${YELLOW}llama-container${NC}"
echo -e ""
echo -e "${CYAN}Servidor + nanocoder (LLM local):${NC}"
echo -e "  ${YELLOW}llama-nanocoder${NC}"
echo -e ""
echo -e "${CYAN}Modelo personalizado:${NC}"
echo -e "  ${YELLOW}llama-container /path/to/model.gguf${NC}"
echo -e "${GREEN}====================================================================${NC}"
