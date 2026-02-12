# 🚀 Guia Rápido - PetID

Guia passo a passo para subir o projeto do zero na VPS Hostinger.

## ⚡ Setup Rápido (5 minutos)

### 1. Na VPS

```bash
# Conectar
ssh root@seu-ip-vps

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
apt install docker-compose -y

# Clonar/Enviar projeto
cd /root
# (Envie os arquivos do projeto aqui)
```

### 2. Configurar

```bash
cd PetID

# Ajustar senhas no docker-compose.yml (opcional, mas recomendado)
nano docker-compose.yml

# Gerar JWT_SECRET seguro
openssl rand -hex 32
# Copie o resultado e cole no docker-compose.yml na variável JWT_SECRET
```

### 3. Iniciar

```bash
# Dar permissão aos scripts
chmod +x scripts/*.sh

# Inicializar banco
./scripts/init_db.sh

# Subir serviços
./scripts/start.sh
```

### 4. Acessar

- **API Docs**: `http://seu-ip:8000/docs`
- **MinIO Console**: `http://seu-ip:9001` (user: `minio`, pass: `minio_password`)

### 5. Criar Bucket no MinIO

1. Acesse http://seu-ip:9001
2. Login: `minio` / `minio_password`
3. Crie bucket: `pet-attachments`

### 6. Testar API

1. Acesse http://seu-ip:8000/docs
2. Teste `POST /api/auth/register`
3. Teste `POST /api/auth/login`
4. Copie o token e clique em "Authorize"
5. Teste criar um pet

## 📱 Configurar App Flutter

### 1. No seu computador

```bash
cd mobile
flutter pub get
```

### 2. Ajustar URL da API

Edite `mobile/lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://seu-ip-vps:8000/api';
```

### 3. Executar

```bash
flutter run
```

## ✅ Checklist Pós-Instalação

- [ ] Serviços rodando (`docker-compose ps`)
- [ ] API respondendo (`http://seu-ip:8000/health`)
- [ ] Banco com tabelas (`docker-compose exec db psql -U petid -d petid -c "\dt"`)
- [ ] Bucket criado no MinIO
- [ ] Teste de registro/login funcionando
- [ ] App Flutter conectando na API

## 🔧 Comandos Úteis

```bash
# Ver logs
docker-compose logs -f api

# Reiniciar API
docker-compose restart api

# Backup do banco
docker-compose exec db pg_dump -U petid petid > backup.sql

# Parar tudo
docker-compose down
```

## 🆘 Problemas Comuns

**API não conecta no banco**
- Verifique se `db` está rodando: `docker-compose ps`
- Verifique logs: `docker-compose logs db`

**Erro 500 no upload**
- Crie o bucket `pet-attachments` no MinIO
- Verifique credenciais no docker-compose.yml

**App não conecta**
- Verifique IP na URL do api_service.dart
- Verifique firewall (porta 8000 aberta)
- Teste a URL no navegador primeiro

## 📚 Documentação Completa

Veja `README.md` para detalhes completos.

