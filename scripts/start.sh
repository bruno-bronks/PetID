#!/bin/bash

# Script para iniciar todos os serviços
# Uso: ./scripts/start.sh

echo "🚀 Iniciando serviços PetID..."

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose não encontrado. Instale primeiro."
    exit 1
fi

# Subir serviços
echo "📦 Subindo containers..."
docker-compose up -d

# Aguardar serviços estarem prontos
echo "⏳ Aguardando serviços..."
sleep 10

# Verificar status
echo "📊 Status dos serviços:"
docker-compose ps

echo ""
echo "✅ Serviços iniciados!"
echo ""
echo "📱 Acesse:"
echo "   - API: http://localhost:8000"
echo "   - Docs: http://localhost:8000/docs"
echo "   - MinIO: http://localhost:9001 (user: minio, pass: minio_password)"
echo ""

