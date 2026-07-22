#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# llama-android-container: Installation Script
# Optimized for Qualcomm Snapdragon 8 Elite / Adreno 830 GPU on Termux
# ==============================================================================

set -e

echo "=================================================="
echo "🚀 INSTALANDO DEPENDÊNCIAS DO LLAMA-ANDROID-CONTAINER"
echo "=================================================="

# 1. Atualizar repositórios e instalar pacotes base do Termux
echo "1️⃣ Instalando pacotes base e ferramentas OpenCL/Container..."
pkg update -y || true
pkg install -y python git curl clinfo proot proot-distro fd ripgrep || true

# 2. Instalar udocker via pip
echo "2️⃣ Instalando e configurando udocker..."
pip install --upgrade udocker || true
udocker install || true

# 3. Configurar ICD de Vendor do OpenCL da Qualcomm (Adreno 830)
echo "3️⃣ Configurando driver OpenCL da Adreno GPU (/vendor/lib64/libOpenCL_adreno.so)..."
mkdir -p /data/data/com.termux/files/usr/etc/OpenCL/vendors
echo "/vendor/lib64/libOpenCL_adreno.so" > /data/data/com.termux/files/usr/etc/OpenCL/vendors/qualcomm.icd

# 4. Baixar imagem base Linux ARM64 para o udocker
echo "4️⃣ Baixando imagem base Linux ARM64 no udocker..."
udocker pull --platform=linux/arm64 ubuntu:latest || true
udocker create --name=llm_agent ubuntu:latest || true

# 5. Instalar ambiente proot-distro Ubuntu
echo "5️⃣ Garantindo ambiente proot-distro Ubuntu..."
proot-distro install ubuntu || true

# 6. Copiar scripts para o diretório $HOME e dar permissão de execução
echo "6️⃣ Copiando scripts de controle para $HOME..."
cp -f get_thermal.py "$HOME/" 2>/dev/null || true
cp -f monitor_bottleneck.sh "$HOME/" 2>/dev/null || true
cp -f start.sh "$HOME/" 2>/dev/null || true
cp -f start_udocker.sh "$HOME/" 2>/dev/null || true

chmod +x "$HOME/monitor_bottleneck.sh" "$HOME/start.sh" "$HOME/start_udocker.sh"

echo "=================================================="
echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "Para iniciar o servidor nativo:  ./start.sh"
echo "Para iniciar via udocker:        ./start_udocker.sh llm_agent"
echo "=================================================="
