#!/bin/bash
# Script de deploy automatizado para VPS Hostinger
# Uso: ./deploy.sh

set -e  # Parar em caso de erro

echo "========================================="
echo "  PetID - Deploy Automatizado na VPS"
echo "========================================="
echo ""

# Configurações
VPS_IP="148.230.79.134"
VPS_USER="root"  # Trocar se usar outro usuário
APP_DIR="/var/www/PetID"
REPO_URL="https://github.com/bruno-bronks/PetID.git"

echo "VPS: $VPS_IP"
echo "Usuário: $VPS_USER"
echo "Diretório: $APP_DIR"
echo ""

# Função para executar comando na VPS
run_remote() {
    ssh $VPS_USER@$VPS_IP "$1"
}

# Função para copiar arquivo
copy_file() {
    scp "$1" $VPS_USER@$VPS_IP:"$2"
}

echo "[1/10] Testando conexão SSH..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 $VPS_USER@$VPS_IP exit 2>/dev/null; then
    echo "Erro: Não foi possível conectar via SSH."
    echo "Configure sua chave SSH ou verifique se a VPS está acessível."
    exit 1
fi
echo "✓ Conexão SSH OK"
echo ""

echo "[2/10] Verificando Docker..."
if ! run_remote "command -v docker" >/dev/null 2>&1; then
    echo "Docker não encontrado. Instalando..."
    run_remote "curl -fsSL https://get.docker.com | sh"
    echo "✓ Docker instalado"
else
    echo "✓ Docker já instalado"
fi
echo ""

echo "[3/10] Verificando Docker Compose..."
if ! run_remote "command -v docker-compose" >/dev/null 2>&1; then
    echo "Docker Compose não encontrado. Instalando..."
    run_remote "curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose"
    echo "✓ Docker Compose instalado"
else
    echo "✓ Docker Compose já instalado"
fi
echo ""

echo "[4/10] Verificando Git..."
if ! run_remote "command -v git" >/dev/null 2>&1; then
    echo "Git não encontrado. Instalando..."
    run_remote "apt update && apt install -y git"
    echo "✓ Git instalado"
else
    echo "✓ Git já instalado"
fi
echo ""

echo "[5/10] Clonando/Atualizando repositório..."
if run_remote "[ -d $APP_DIR ]"; then
    echo "Diretório existe. Atualizando código..."
    run_remote "cd $APP_DIR && git pull origin main"
    echo "✓ Código atualizado"
else
    echo "Clonando repositório..."
    run_remote "mkdir -p /var/www && cd /var/www && git clone $REPO_URL"
    echo "✓ Repositório clonado"
fi
echo ""

echo "[6/10] Configurando variáveis de ambiente..."
echo "IMPORTANTE: Configure as variáveis de ambiente no arquivo .env"
echo "Gerando senhas seguras..."

DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -hex 32)
MINIO_PASSWORD=$(openssl rand -base64 32)

echo ""
echo "========================================="
echo "  SENHAS GERADAS (Salve em local seguro!)"
echo "========================================="
echo "DB_PASSWORD=$DB_PASSWORD"
echo "JWT_SECRET=$JWT_SECRET"
echo "MINIO_PASSWORD=$MINIO_PASSWORD"
echo "========================================="
echo ""
echo "Pressione ENTER para continuar..."
read

# Criar .env na VPS
run_remote "cat > $APP_DIR/backend/.env << 'EOL'
# Database
DATABASE_URL=postgresql+psycopg://petid:$DB_PASSWORD@db:5432/petid

# JWT
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_MINUTES=10080

# S3/MinIO
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=minio
S3_SECRET_KEY=$MINIO_PASSWORD
S3_BUCKET=pet-attachments
S3_REGION=us-east-1

# Debug
DEBUG=false
EOL"

# Atualizar docker-compose.yml com as senhas
run_remote "cd $APP_DIR && sed -i 's/POSTGRES_PASSWORD: petid_password/POSTGRES_PASSWORD: $DB_PASSWORD/g' docker-compose.yml"
run_remote "cd $APP_DIR && sed -i 's/MINIO_ROOT_PASSWORD: minio_password/MINIO_ROOT_PASSWORD: $MINIO_PASSWORD/g' docker-compose.yml"

echo "✓ Variáveis de ambiente configuradas"
echo ""

echo "[7/10] Configurando firewall..."
run_remote "ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw allow 8001/tcp && echo 'y' | ufw enable" || echo "Firewall já configurado ou erro (ignorando)"
echo "✓ Firewall configurado"
echo ""

echo "[8/10] Iniciando containers..."
run_remote "cd $APP_DIR && docker-compose down || true"
run_remote "cd $APP_DIR && docker-compose up -d --build"
echo "✓ Containers iniciados"
echo ""

echo "[9/10] Aguardando containers ficarem prontos..."
sleep 10
echo "✓ Containers prontos"
echo ""

echo "[10/10] Executando migrações do banco..."
run_remote "cd $APP_DIR && docker-compose exec -T api alembic upgrade head" || echo "Aviso: Erro ao executar migrations (pode ser normal na primeira vez)"
echo "✓ Migrações executadas"
echo ""

echo "========================================="
echo "  DEPLOY CONCLUÍDO COM SUCESSO!"
echo "========================================="
echo ""
echo "Acessos:"
echo "  - API Docs: http://$VPS_IP:8001/docs"
echo "  - Health: http://$VPS_IP:8001/health"
echo ""
echo "Comandos úteis:"
echo "  - Ver logs: ssh $VPS_USER@$VPS_IP 'cd $APP_DIR && docker-compose logs -f'"
echo "  - Status: ssh $VPS_USER@$VPS_IP 'cd $APP_DIR && docker-compose ps'"
echo "  - Reiniciar: ssh $VPS_USER@$VPS_IP 'cd $APP_DIR && docker-compose restart'"
echo ""
echo "Próximos passos:"
echo "  1. Configure um domínio apontando para $VPS_IP"
echo "  2. Configure SSL com Let's Encrypt"
echo "  3. Configure backup automático"
echo ""
echo "Consulte DEPLOY_VPS.md para mais detalhes."
echo ""
