# 🚀 Deploy do PetID na VPS Hostinger

Guia completo para fazer deploy do sistema PetID na VPS da Hostinger.

**VPS IP:** 148.230.79.134

## 📋 Pré-requisitos

- Acesso SSH à VPS
- Domínio configurado (opcional, para SSL)
- Chave SSH ou senha de acesso

## 🔧 1. Conectar na VPS

```bash
ssh root@148.230.79.134
# OU
ssh usuario@148.230.79.134
```

## 📦 2. Instalar Dependências

### 2.1 Atualizar o Sistema

```bash
apt update && apt upgrade -y
```

### 2.2 Instalar Docker

```bash
# Remover versões antigas (se existirem)
apt remove docker docker-engine docker.io containerd runc

# Instalar dependências
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar repositório Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Verificar instalação
docker --version
```

### 2.3 Instalar Docker Compose

```bash
# Baixar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Dar permissão de execução
chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker-compose --version
```

### 2.4 Instalar Git (se não tiver)

```bash
apt install -y git
```

## 📂 3. Clonar o Repositório

```bash
# Criar diretório para aplicações
mkdir -p /var/www
cd /var/www

# Clonar o repositório
git clone https://github.com/bruno-bronks/PetID.git
cd PetID
```

## ⚙️ 4. Configurar Variáveis de Ambiente

```bash
# Criar arquivo .env de produção
cd /var/www/PetID/backend
cp .env.example .env

# Editar o .env com nano
nano .env
```

### Configurações Recomendadas para Produção:

```bash
# Database
DATABASE_URL=postgresql+psycopg://petid:SENHA_SEGURA_AQUI@db:5432/petid

# JWT - IMPORTANTE: Gerar segredo forte
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRES_MINUTES=10080

# S3/MinIO
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=minio
S3_SECRET_KEY=SENHA_MINIO_SEGURA
S3_BUCKET=pet-attachments
S3_REGION=us-east-1

# Debug - DESATIVAR em produção
DEBUG=false
```

### Gerar Senhas Seguras:

```bash
# Gerar senha para PostgreSQL
openssl rand -base64 32

# Gerar JWT Secret
openssl rand -hex 32

# Gerar senha para MinIO
openssl rand -base64 32
```

## 🐳 5. Configurar Docker Compose para Produção

Editar o `docker-compose.yml` para produção:

```bash
nano docker-compose.yml
```

### Mudanças importantes:

1. **Trocar portas expostas** (não expor DB, Redis, MinIO):

```yaml
services:
  db:
    # REMOVER a linha ports: para não expor o PostgreSQL
    # ports:
    #   - "5432:5432"

  redis:
    # REMOVER a linha ports: para não expor o Redis
    # ports:
    #   - "6379:6379"

  minio:
    # REMOVER ou trocar portas do MinIO
    ports:
      - "127.0.0.1:9000:9000"  # Só acesso local
      - "127.0.0.1:9001:9001"  # Console admin só local

  api:
    # Porta da API - OK expor
    ports:
      - "8001:8000"

  nginx:
    ports:
      - "80:80"
      - "443:443"
```

2. **Usar senhas do .env**:

```yaml
services:
  db:
    environment:
      POSTGRES_DB: petid
      POSTGRES_USER: petid
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # Do .env
```

## 🚀 6. Iniciar os Containers

```bash
cd /var/www/PetID

# Iniciar containers
docker-compose up -d

# Verificar logs
docker-compose logs -f

# Verificar status
docker-compose ps
```

## 🗄️ 7. Executar Migrações do Banco

```bash
# Executar migrations
docker-compose exec api alembic upgrade head

# Verificar se deu certo
docker-compose logs api
```

## 🔥 8. Configurar Firewall (UFW)

```bash
# Habilitar UFW
ufw enable

# Permitir SSH (IMPORTANTE: fazer isso ANTES de habilitar)
ufw allow 22/tcp

# Permitir HTTP e HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Permitir porta da API (se necessário)
ufw allow 8001/tcp

# Verificar regras
ufw status
```

## 🌐 9. Configurar NGINX como Reverse Proxy

### 9.1 Criar configuração do NGINX

```bash
# Criar arquivo de configuração
nano /var/www/PetID/nginx/nginx.conf
```

### 9.2 Configuração NGINX:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream api_backend {
        server api:8000;
    }

    # Redirecionar HTTP para HTTPS (depois de configurar SSL)
    server {
        listen 80;
        server_name petid.seudominio.com;  # Trocar pelo seu domínio

        # Temporariamente, permitir HTTP para testar
        location / {
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Aumentar timeout para ML (embeddings podem demorar)
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    # HTTPS (configurar depois de obter certificado SSL)
    # server {
    #     listen 443 ssl http2;
    #     server_name petid.seudominio.com;
    #
    #     ssl_certificate /etc/letsencrypt/live/petid.seudominio.com/fullchain.pem;
    #     ssl_certificate_key /etc/letsencrypt/live/petid.seudominio.com/privkey.pem;
    #
    #     location / {
    #         proxy_pass http://api_backend;
    #         proxy_set_header Host $host;
    #         proxy_set_header X-Real-IP $remote_addr;
    #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #         proxy_set_header X-Forwarded-Proto $scheme;
    #     }
    # }
}
```

### 9.3 Reiniciar NGINX:

```bash
docker-compose restart nginx
```

## 🔒 10. Configurar SSL com Let's Encrypt (Opcional)

### 10.1 Instalar Certbot:

```bash
apt install -y certbot python3-certbot-nginx
```

### 10.2 Obter Certificado:

```bash
# Parar NGINX temporariamente
docker-compose stop nginx

# Obter certificado
certbot certonly --standalone -d petid.seudominio.com

# Reiniciar NGINX
docker-compose start nginx
```

### 10.3 Auto-renovação:

```bash
# Testar renovação
certbot renew --dry-run

# Renovação automática já está configurada via cron
```

## 📊 11. Verificar se está Funcionando

```bash
# Verificar containers
docker-compose ps

# Verificar logs
docker-compose logs -f api

# Testar API localmente
curl http://localhost:8001/health

# Testar API externamente
curl http://148.230.79.134:8001/health

# Verificar se NGINX está respondendo
curl http://148.230.79.134/health
```

## 🔄 12. Comandos Úteis

### Atualizar o código:

```bash
cd /var/www/PetID
git pull origin main
docker-compose down
docker-compose up -d --build
docker-compose exec api alembic upgrade head
```

### Ver logs:

```bash
# Logs de todos os containers
docker-compose logs -f

# Logs só da API
docker-compose logs -f api

# Logs do banco
docker-compose logs -f db
```

### Reiniciar containers:

```bash
# Reiniciar tudo
docker-compose restart

# Reiniciar só a API
docker-compose restart api
```

### Backup do banco:

```bash
# Backup
docker-compose exec db pg_dump -U petid petid > backup_$(date +%Y%m%d).sql

# Restaurar
docker-compose exec -T db psql -U petid petid < backup_20260212.sql
```

### Limpar volumes (CUIDADO - apaga dados):

```bash
docker-compose down -v  # Remove volumes
```

## 🎯 13. Acessar a Aplicação

Após configurar tudo:

- **API Docs:** http://148.230.79.134/docs
- **API Health:** http://148.230.79.134/health
- **MinIO Console:** http://148.230.79.134:9001 (só se expor a porta)

Com domínio configurado:
- **API Docs:** https://petid.seudominio.com/docs
- **API Health:** https://petid.seudominio.com/health

## 🐛 Troubleshooting

### Container não inicia:

```bash
docker-compose logs api
docker-compose logs db
```

### Erro de permissão:

```bash
# Dar permissão aos volumes
chown -R 1000:1000 /var/www/PetID
```

### Porta já em uso:

```bash
# Ver o que está usando a porta 8001
netstat -tulpn | grep 8001

# Matar processo se necessário
kill -9 <PID>
```

### Banco não conecta:

```bash
# Entrar no container do banco
docker-compose exec db psql -U petid

# Verificar se extensão pgvector está ativa
\dx
```

### ML não funciona:

```bash
# Verificar se as dependências ML foram instaladas
docker-compose exec api pip list | grep torch
docker-compose exec api pip list | grep transformers

# Testar ML
docker-compose exec api python test_ml_installation.py
```

## 📝 Notas Importantes

1. **Senhas:** Troque TODAS as senhas padrão
2. **Firewall:** Configure o UFW antes de expor a VPS
3. **Backup:** Configure backup automático do banco
4. **Monitoramento:** Configure logs e alertas
5. **ML Performance:** O modelo ML roda melhor com GPU, mas funciona em CPU (~0.5-2s por imagem)

## 🔐 Segurança

- Não exponha portas desnecessárias (DB, Redis)
- Use SSL em produção
- Configure rate limiting
- Mantenha o sistema atualizado
- Use senhas fortes
- Configure backup automático

---

**Última atualização:** 2026-02-12
