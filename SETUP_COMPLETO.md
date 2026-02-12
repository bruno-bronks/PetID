# 📖 Guia de Setup Completo - PetID

Este guia te leva passo a passo desde o zero até ter o PetID rodando na VPS Hostinger.

## 📋 Pré-requisitos

- **VPS Linux** (Ubuntu 20.04+ ou Debian 11+)
  - Mínimo: 2 vCPU, 4GB RAM, 20GB disco
  - Recomendado: 4 vCPU, 8GB RAM, 50GB disco
- **Acesso root ou sudo**
- **Domínio** (opcional para MVP, mas recomendado)

---

## 🎯 Passo 1: Preparar a VPS

### 1.1 Conectar na VPS

```bash
ssh root@seu-ip-vps
```

Substitua `seu-ip-vps` pelo IP da sua VPS Hostinger.

### 1.2 Atualizar Sistema

```bash
apt update
apt upgrade -y
```

### 1.3 Instalar Ferramentas Básicas

```bash
apt install -y curl wget git nano ufw
```

### 1.4 Instalar Docker

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Adicionar usuário ao grupo docker (se necessário)
usermod -aG docker $USER

# Instalar Docker Compose
apt install -y docker-compose

# Verificar instalação
docker --version
docker-compose --version
```

Você deve ver algo como:
```
Docker version 24.x.x
docker-compose version 1.29.x
```

### 1.5 Configurar Firewall (Recomendado)

```bash
# Permitir SSH
ufw allow 22/tcp

# Permitir HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Ativar firewall
ufw --force enable

# Verificar status
ufw status
```

---

## 📦 Passo 2: Enviar Projeto para VPS

### Opção A: Via Git (Recomendado)

```bash
# No seu computador local
cd /caminho/do/projeto
git init
git add .
git commit -m "Initial commit"

# Na VPS
cd /root
git clone https://github.com/seu-usuario/petid.git
# OU crie um repositório privado e clone
```

### Opção B: Via SCP (Upload Direto)

No seu computador local (Windows PowerShell ou Linux/Mac):

```bash
# Windows PowerShell
scp -r C:\Users\user\Documents\Bruno\Projetos\PetID root@seu-ip-vps:/root/

# Linux/Mac
scp -r ~/PetID root@seu-ip-vps:/root/
```

### Opção C: Via WinSCP (Windows - Interface Gráfica)

1. Baixe WinSCP: https://winscp.net/
2. Conecte na VPS
3. Arraste a pasta PetID para `/root/`

### 2.1 Verificar Arquivos na VPS

```bash
cd /root/PetID
ls -la
```

Você deve ver:
- `backend/`
- `mobile/`
- `docker-compose.yml`
- `README.md`

---

## ⚙️ Passo 3: Configurar o Projeto

### 3.1 Entrar no Diretório

```bash
cd /root/PetID
```

### 3.2 Gerar JWT Secret Seguro

```bash
openssl rand -hex 32
```

Copie o resultado (será algo como: `a1b2c3d4e5f6...`)

### 3.3 Editar docker-compose.yml

```bash
nano docker-compose.yml
```

Localize a seção `api` -> `environment` -> `JWT_SECRET` e substitua:

```yaml
JWT_SECRET: "COLE_O_RESULTADO_DO_COMANDO_AQUI"
```

**⚠️ IMPORTANTE**: Use um valor único e seguro. Não compartilhe!

### 3.4 (Opcional) Alterar Senhas Padrão

Por segurança, altere as senhas no `docker-compose.yml`:

```yaml
# Banco de dados
POSTGRES_PASSWORD: "SUA_SENHA_SEGURA_AQUI"

# MinIO
MINIO_ROOT_PASSWORD: "SUA_SENHA_SEGURA_AQUI"
```

**Salve**: `Ctrl+O`, `Enter`, `Ctrl+X`

---

## 🚀 Passo 4: Inicializar Banco de Dados

### 4.1 Dar Permissão aos Scripts

```bash
chmod +x scripts/*.sh
```

### 4.2 Executar Script de Inicialização

```bash
./scripts/init_db.sh
```

Este script vai:
1. Aguardar o banco ficar pronto
2. Criar extensão pgvector
3. Gerar migrações iniciais
4. Aplicar migrações

Se der erro, execute manualmente:

```bash
# Criar extensão
docker-compose exec -T db psql -U petid -d petid -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Criar migrações
docker-compose run --rm api alembic revision --autogenerate -m "Initial migration"

# Aplicar
docker-compose run --rm api alembic upgrade head
```

---

## 🎬 Passo 5: Iniciar Serviços

### 5.1 Subir Todos os Serviços

```bash
./scripts/start.sh
```

Ou manualmente:

```bash
docker-compose up -d
```

### 5.2 Verificar Status

```bash
docker-compose ps
```

Todos devem estar com status `Up`:
- ✅ `petid_db`
- ✅ `petid_redis`
- ✅ `petid_minio`
- ✅ `petid_api`
- ✅ `petid_nginx`

### 5.3 Ver Logs (se necessário)

```bash
docker-compose logs -f api
```

Pressione `Ctrl+C` para sair.

---

## 🗄️ Passo 6: Configurar MinIO (Storage)

### 6.1 Acessar Console MinIO

Abra no navegador:
```
http://seu-ip-vps:9001
```

### 6.2 Fazer Login

- **User**: `minio`
- **Password**: `minio_password` (ou a senha que você configurou)

### 6.3 Criar Bucket

1. Clique em **"Buckets"** no menu lateral
2. Clique em **"Create Bucket"**
3. Nome: `pet-attachments`
4. Deixe todas as opções padrão
5. Clique em **"Create Bucket"**

✅ Pronto! O bucket está criado.

---

## ✅ Passo 7: Testar a API

### 7.1 Acessar Documentação Swagger

Abra no navegador:
```
http://seu-ip-vps:8000/docs
```

### 7.2 Criar Primeiro Usuário

1. Na página do Swagger, encontre `POST /api/auth/register`
2. Clique em **"Try it out"**
3. Preencha:
```json
{
  "email": "teste@exemplo.com",
  "password": "senha123",
  "full_name": "Nome Teste",
  "phone": "+5511999999999"
}
```
4. Clique em **"Execute"**
5. Você deve ver resposta `201` com os dados do usuário criado

### 7.3 Fazer Login

1. Encontre `POST /api/auth/login`
2. Clique em **"Try it out"**
3. Preencha:
```json
{
  "email": "teste@exemplo.com",
  "password": "senha123"
}
```
4. Clique em **"Execute"**
5. Copie o `access_token` da resposta

### 7.4 Autenticar no Swagger

1. No topo da página, clique no botão **"Authorize"** (🔓)
2. No campo "Value", cole: `Bearer SEU_ACCESS_TOKEN_AQUI`
3. Clique em **"Authorize"** e depois **"Close"**

Agora você pode testar endpoints que requerem autenticação!

### 7.5 Criar um Pet de Teste

1. Encontre `POST /api/pets`
2. Clique em **"Try it out"**
3. Preencha:
```json
{
  "name": "Rex",
  "species": "dog",
  "breed": "Labrador",
  "sex": "male",
  "birth_date": "2020-01-15",
  "weight": "25kg",
  "is_castrated": true
}
```
4. Clique em **"Execute"**
5. ✅ Pet criado com sucesso!

---

## 📱 Passo 8: Configurar App Flutter

### 8.1 No Seu Computador Local

```bash
# Navegar para o app
cd mobile

# Instalar dependências
flutter pub get
```

### 8.2 Configurar URL da API

Edite `mobile/lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://SEU-IP-VPS:8000/api';
```

Substitua `SEU-IP-VPS` pelo IP da sua VPS.

**Para produção com HTTPS:**
```dart
static const String baseUrl = 'https://seu-dominio.com/api';
```

### 8.3 Executar no Android

```bash
flutter run
```

Ou abra no Android Studio e execute.

### 8.4 Testar Login no App

1. Abra o app
2. Faça cadastro ou login
3. Você deve ver a tela "Meus Pets"

---

## 🔒 Passo 9: Configurar HTTPS (Opcional mas Recomendado)

### 9.1 Ter Domínio Apontado

No painel da Hostinger, configure:
- **Tipo**: A
- **Nome**: @ (ou www)
- **Valor**: IP da VPS
- **TTL**: 3600

Aguarde propagação (pode levar até 24h, geralmente < 1h).

### 9.2 Instalar Certbot

```bash
apt install -y certbot python3-certbot-nginx
```

### 9.3 Obter Certificado SSL

```bash
certbot --nginx -d seu-dominio.com -d www.seu-dominio.com
```

Siga as instruções:
- Email: seu email
- Concorde com termos
- Configure redirecionamento HTTP → HTTPS

### 9.4 Atualizar Nginx

Edite `nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name seu-dominio.com www.seu-dominio.com;

    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    # ... resto da configuração
}
```

### 9.5 Reiniciar Nginx

```bash
docker-compose restart nginx
```

### 9.6 Atualizar App Flutter

Atualize `mobile/lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://seu-dominio.com/api';
```

---

## 📊 Passo 10: Verificar Tudo

### Checklist Final

- [ ] Todos os containers rodando (`docker-compose ps`)
- [ ] API respondendo (`http://seu-ip:8000/health`)
- [ ] Swagger acessível (`http://seu-ip:8000/docs`)
- [ ] MinIO funcionando (`http://seu-ip:9001`)
- [ ] Bucket `pet-attachments` criado
- [ ] Teste de registro/login OK
- [ ] Teste de criação de pet OK
- [ ] App Flutter conectando na API
- [ ] HTTPS configurado (se aplicável)

---

## 🛠️ Comandos Úteis

### Ver Logs

```bash
# Todos os serviços
docker-compose logs -f

# Apenas API
docker-compose logs -f api

# Últimas 100 linhas
docker-compose logs --tail=100 api
```

### Reiniciar Serviço

```bash
docker-compose restart api
```

### Parar Tudo

```bash
docker-compose down
```

### Subir Novamente

```bash
docker-compose up -d
```

### Backup do Banco

```bash
docker-compose exec db pg_dump -U petid petid > backup_$(date +%Y%m%d).sql
```

### Restaurar Backup

```bash
docker-compose exec -T db psql -U petid petid < backup_20240101.sql
```

### Acessar Banco de Dados

```bash
docker-compose exec db psql -U petid -d petid
```

### Ver Tabelas

```bash
docker-compose exec db psql -U petid -d petid -c "\dt"
```

---

## 🐛 Troubleshooting

### API não inicia

```bash
# Ver logs
docker-compose logs api

# Verificar se banco está rodando
docker-compose ps db

# Reiniciar
docker-compose restart api
```

### Erro de conexão com banco

```bash
# Verificar variável DATABASE_URL
docker-compose exec api env | grep DATABASE_URL

# Testar conexão
docker-compose exec api python -c "from app.db.session import engine; engine.connect()"
```

### Erro 500 no upload

- Verifique se o bucket `pet-attachments` existe no MinIO
- Verifique credenciais no docker-compose.yml
- Verifique logs: `docker-compose logs api`

### App não conecta na API

1. Verifique IP/URL no `api_service.dart`
2. Teste a URL no navegador: `http://seu-ip:8000/health`
3. Verifique firewall: `ufw status`
4. Verifique se porta 8000 está aberta

### Erro de migração

```bash
# Resetar migrações (CUIDADO: apaga dados)
docker-compose down -v
docker-compose up -d db
sleep 5
./scripts/init_db.sh
```

---

## 📚 Próximos Passos

1. ✅ **MVP Prontuário**: Backend e app básico funcionando
2. 🔄 **Cadastro de Pet**: Implementar tela no Flutter
3. 🔄 **Prontuário Timeline**: Listar e adicionar registros
4. 🔄 **Upload de Anexos**: Funcionalidade completa
5. 🔄 **Biometria**: Captura e identificação por focinho

---

## 🎉 Parabéns!

Seu PetID está rodando! 🚀

- Backend: ✅
- Banco de dados: ✅
- Storage: ✅
- App Flutter: ✅

Agora você pode continuar desenvolvendo as funcionalidades do app!

---

**Dúvidas?** Consulte:
- `README.md` - Documentação completa
- `GUIA_RAPIDO.md` - Guia resumido
- Swagger UI: `http://seu-ip:8000/docs`

