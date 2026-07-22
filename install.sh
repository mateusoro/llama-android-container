#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# llama-android-container: One-Line Installer Script
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830 GPU on Termux
# Usage: curl -fsSL https://raw.githubusercontent.com/mateusoro/llama-android-container/main/install.sh | bash
# ==============================================================================

# Cores para Saída Terminal Estilizada
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "  _     _     _    __  E  ___  _       ___ ______ ________ ___ ___  "
echo " | |   | |   / \  |  \/  |/ _ \| \    / / |  ____|  ____|  _ \___ \ "
echo " | |   | |  / _ \ | |\/| | | | |  \  / /| | |__  | |__  | |_) |__) |"
echo " | |___| |_/ ___ \| |  | | |_| |\ \/ / | |  __| |  __| |  _ <|__ < "
echo " |_____|_____/_/   \_\_|  |_|\___/  \__/  |_|____|_|____|_| \_\___/ "
echo -e "${PURPLE}   High-Performance Snapdragon 8 Elite / Adreno 830 GPU Container${NC}"
echo "===================================================================="

REPO_URL="https://github.com/mateusoro/llama-android-container.git"
INSTALL_DIR="$HOME/llama-android-container"

# 1. Instalar pacotes base do Termux
echo -e "\n${YELLOW}[1/6] 📦 Instalando pacotes base e ferramentas container...${NC}"
pkg update -y || true
pkg install -y git python curl clinfo proot proot-distro fd ripgrep || true

# 2. Clonar ou atualizar o repositório no celular
echo -e "\n${YELLOW}[2/6] 🔄 Clonando/Atualizando repositório do projeto em ${INSTALL_DIR}...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --rebase || true
else
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR" || true
fi

# 3. Instalar e preparar o udocker
echo -e "\n${YELLOW}[3/6] 🐳 Instalando e configurando udocker (Rootless Engine)...${NC}"
pip install --upgrade udocker || true
udocker install || true
udocker pull --platform=linux/arm64 ubuntu:latest || true
udocker create --name=llm_dockerfile_container ubuntu:latest || true

# 4. Configurar o ICD de Vendor do OpenCL da Adreno 830 GPU
echo -e "\n${YELLOW}[4/6] 🎮 Configurando driver OpenCL da GPU Adreno 830...${NC}"
mkdir -p /data/data/com.termux/files/usr/etc/OpenCL/vendors
echo "/vendor/lib64/libOpenCL_adreno.so" > /data/data/com.termux/files/usr/etc/OpenCL/vendors/qualcomm.icd

# 5. Garantir container Ubuntu do proot-distro
echo -e "\n${YELLOW}[5/6] 🐧 Configurando ambiente Ubuntu (proot-distro)...${NC}"
proot-distro install ubuntu || true

# 6. Copiar scripts e criar comando global no Termux
echo -e "\n${YELLOW}[6/6] ⚙️ Criando atalho global 'llama-container' em \$PREFIX/bin...${NC}"
cp -f "$INSTALL_DIR/get_thermal.py" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/monitor_bottleneck.sh" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/start.sh" "$HOME/" 2>/dev/null || true
cp -f "$INSTALL_DIR/Dockerfile" "$HOME/" 2>/dev/null || true

chmod +x "$HOME/monitor_bottleneck.sh" "$HOME/start.sh"

# Criar executável global no PATH do Termux (/data/data/com.termux/files/usr/bin/llama-container)
cat << 'EOF' > /data/data/com.termux/files/usr/bin/llama-container
#!/data/data/com.termux/files/usr/bin/bash
exec "$HOME/start.sh" "$@"
EOF
chmod +x /data/data/com.termux/files/usr/bin/llama-container

# Checar/Baixar modelo de pesos em background se necessario
MODEL_URL="https://huggingface.co/InternScience/Agents-A1-4B-Q4_K_M-GGUF/resolve/main/Agents-A1-4B-Q4_K_M.gguf"
CACHE_DIR="$HOME/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF/snapshots/default"
MODEL_PATH="$CACHE_DIR/Agents-A1-4B-Q4_K_M.gguf"

EXISTING_MODEL=$(find "$HOME/.cache/huggingface/hub" -name "*.gguf" 2>/dev/null | head -n 1)
if [ -z "$EXISTING_MODEL" ]; then
  echo -e "\n${YELLOW}📥 Baixando pesos do modelo de IA do HuggingFace...${NC}"
  mkdir -p "$CACHE_DIR"
  curl -L --progress-bar "$MODEL_URL" -o "$MODEL_PATH" || true
else
  echo -e "\n${GREEN}✅ Pesos do modelo encontrados em cache!${NC}"
fi

echo -e "\n${GREEN}====================================================================${NC}"
echo -e "${GREEN}🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo -e "===================================================================="
echo -e "${CYAN}Para iniciar o servidor a qualquer momento, digite no terminal:${NC}"
echo -e "  ${YELLOW}llama-container${NC}"
echo -e "ou"
echo -e "  ${YELLOW}./start.sh Dockerfile${NC}"
echo -e "${GREEN}====================================================================${NC}"
