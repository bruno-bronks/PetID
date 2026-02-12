#!/bin/bash
# Script para corrigir e continuar o deploy na VPS
# Execute este script na VPS: bash fix_vps.sh

echo "========================================="
echo "  Corrigindo repositórios e continuando deploy"
echo "========================================="
echo ""

# 1. Remover repositório problemático do Monarx
echo "[1/8] Removendo repositório problemático..."
rm -f /etc/apt/sources.list.d/monarx.list 2>/dev/null || true
echo "✓ Repositório removido"
echo ""

# 2. Atualizar lista de pacotes
echo "[2/8] Atualizando lista de pacotes..."
apt-get update -qq
echo "✓ Lista atualizada"
echo ""

# 3. Verificar Docker
echo "[3/8] Verificando Docker..."
docker --version
echo "✓ Docker instalado"
echo ""

# 4. Verificar Docker Compose
echo "[4/8] Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
docker-compose --version
echo "✓ Docker Compose instalado"
echo ""

# 5. Clonar repositório (se não existir)
echo "[5/8] Clonando/Atualizando repositório..."
if [ -d "/var/www/PetID" ]; then
    echo "Diretório existe. Atualizando..."
    cd /var/www/PetID
    git pull origin main
else
    echo "Clonando repositório..."
    mkdir -p /var/www
    cd /var/www
    git clone https://github.com/bruno-bronks/PetID.git
fi
echo "✓ Repositório pronto"
echo ""

# 6. Gerar senhas seguras
echo "[6/8] Gerando senhas seguras..."
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -hex 32)
MINIO_PASSWORD=$(openssl rand -base64 32)

echo ""
echo "========================================="
echo "  SENHAS GERADAS - SALVE EM LOCAL SEGURO!"
echo "========================================="
echo "DB_PASSWORD=$DB_PASSWORD"
echo "JWT_SECRET=$JWT_SECRET"
echo "MINIO_PASSWORD=$MINIO_PASSWORD"
echo "========================================="
echo ""

# 7. Criar arquivo .env
echo "[7/8] Configurando variáveis de ambiente..."
cd /var/www/PetID/backend
cat > .env << EOF
DATABASE_URL=postgresql+psycopg://petid:$DB_PASSWORD@db:5432/petid
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_MINUTES=10080
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=minio
S3_SECRET_KEY=$MINIO_PASSWORD
S3_BUCKET=pet-attachments
S3_REGION=us-east-1
DEBUG=false
EOF
echo "✓ .env criado"
echo ""

# 8. Atualizar docker-compose.yml com senhas
echo "[8/8] Atualizando docker-compose.yml..."
cd /var/www/PetID
sed -i "s/POSTGRES_PASSWORD: petid_password/POSTGRES_PASSWORD: $DB_PASSWORD/g" docker-compose.yml
sed -i "s/MINIO_ROOT_PASSWORD: minio_password/MINIO_ROOT_PASSWORD: $MINIO_PASSWORD/g" docker-compose.yml
echo "✓ docker-compose.yml atualizado"
echo ""

echo "========================================="
echo "  PRÓXIMOS PASSOS"
echo "========================================="
echo ""
echo "Execute os seguintes comandos:"
echo ""
echo "1. Configurar firewall:"
echo "   ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw allow 8001/tcp"
echo "   ufw --force enable"
echo ""
echo "2. Iniciar containers:"
echo "   cd /var/www/PetID"
echo "   docker-compose up -d"
echo ""
echo "3. Executar migrações:"
echo "   docker-compose exec api alembic upgrade head"
echo ""
echo "4. Verificar:"
echo "   docker-compose ps"
echo "   curl http://localhost:8001/health"
echo ""
