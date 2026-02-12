#!/bin/bash

# Script para inicializar o banco de dados
# Uso: ./scripts/init_db.sh

echo "🔧 Inicializando banco de dados..."

# Aguardar banco estar pronto
echo "⏳ Aguardando banco de dados..."
sleep 5

# Criar extensão pgvector
echo "📦 Criando extensão pgvector..."
docker-compose exec -T db psql -U petid -d petid << EOF
CREATE EXTENSION IF NOT EXISTS vector;
EOF

# Criar migrações iniciais
echo "📝 Criando migrações..."
docker-compose run --rm api alembic revision --autogenerate -m "Initial migration"

# Aplicar migrações
echo "🚀 Aplicando migrações..."
docker-compose run --rm api alembic upgrade head

echo "✅ Banco de dados inicializado com sucesso!"

