#!/bin/bash

# Script de instalação do sistema de ML para PetID
# Este script instala as dependências e configura o ambiente

set -e  # Para em caso de erro

echo "🚀 PetID - Instalação do Sistema de ML Real"
echo "============================================"
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verifica Python
echo "📦 Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 não encontrado!${NC}"
    echo "Por favor, instale Python 3.11 ou superior."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✅ Python $PYTHON_VERSION encontrado${NC}"
echo ""

# Verifica pip
echo "📦 Verificando pip..."
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip não encontrado!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ pip encontrado${NC}"
echo ""

# Instala dependências
echo "📥 Instalando dependências Python..."
echo -e "${YELLOW}Isso pode demorar alguns minutos (~2-3GB de downloads)...${NC}"
pip3 install -r requirements.txt
echo -e "${GREEN}✅ Dependências instaladas!${NC}"
echo ""

# Verifica instalação
echo "🧪 Verificando instalação..."

# Testa PyTorch
python3 -c "import torch; print('PyTorch:', torch.__version__)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PyTorch instalado${NC}"
else
    echo -e "${RED}❌ Erro ao importar PyTorch${NC}"
    exit 1
fi

# Testa Transformers
python3 -c "import transformers; print('Transformers:', transformers.__version__)" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Transformers instalado${NC}"
else
    echo -e "${RED}❌ Erro ao importar Transformers${NC}"
    exit 1
fi

# Verifica GPU
echo ""
echo "🎮 Verificando GPU..."
python3 -c "import torch; print('CUDA disponível:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')" 2>/dev/null

echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Execute a migração do banco de dados:"
echo -e "   ${YELLOW}alembic upgrade head${NC}"
echo ""
echo "2. Inicie o servidor:"
echo -e "   ${YELLOW}uvicorn app.main:app --reload${NC}"
echo ""
echo "3. Acesse a documentação:"
echo -e "   ${YELLOW}http://localhost:8000/docs${NC}"
echo ""
echo "📚 Documentação completa: ML_UPGRADE_GUIDE.md"
echo ""
echo -e "${GREEN}✅ Instalação concluída!${NC}"
