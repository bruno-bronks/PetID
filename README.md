# 🐾 PetID - Sistema de Identificação de Pets

Sistema completo de identificação e gerenciamento de pets com **biometria por focinho usando Machine Learning**.

## 🚀 Funcionalidades

- ✅ **Autenticação e autorização** (JWT)
- ✅ **Cadastro de pets** com fotos e informações completas
- ✅ **Prontuário médico** digital
- ✅ **Biometria por focinho** usando ML (MegaDescriptor)
- ✅ **Busca por similaridade** de focinhos
- ✅ **Vacinas e medicamentos**
- ✅ **Documentos** e anexos (S3/MinIO)
- ✅ **Auditoria** completa
- ✅ **API REST** com FastAPI

## 🧠 Machine Learning

O sistema utiliza **biometria real** para re-identificação de pets:

- **Modelo:** MegaDescriptor-T-224 (Swin Transformer)
- **Dimensões:** 768-dimensional embeddings
- **Busca:** Similaridade de cosseno com pgvector
- **Validação:** Qualidade de imagem (brilho, nitidez, contraste)
- **Performance:** ~0.2s por imagem (CPU)

## 🛠️ Tecnologias

**Backend:**
- Python 3.12
- FastAPI
- PostgreSQL + pgvector
- Redis
- MinIO (S3)
- Docker

**Machine Learning:**
- PyTorch
- Transformers (HuggingFace)
- timm
- OpenCV

## 📦 Instalação

### Requisitos
- Docker & Docker Compose
- Python 3.11+ (para desenvolvimento local)

### Setup Rápido

1. **Clone o repositório:**
```bash
git clone https://github.com/bruno-bronks/PetID.git
cd PetID
```

2. **Configure variáveis de ambiente:**
```bash
cp backend/.env.example backend/.env
# Edite o .env conforme necessário
```

3. **Inicie os containers:**
```bash
docker-compose up -d
```

4. **Execute as migrações:**
```bash
docker-compose exec api alembic upgrade head
```

5. **Acesse a API:**
- Documentação: http://localhost:8001/docs
- Healthcheck: http://localhost:8001/health

### Instalação do ML (Local)

Para desenvolvimento local com ML:

```bash
cd backend
pip install -r requirements.txt
python test_ml_installation.py
```

Consulte [ML_UPGRADE_GUIDE.md](backend/ML_UPGRADE_GUIDE.md) para mais detalhes.

## 📚 Documentação

- **API Docs:** http://localhost:8001/docs (Swagger)
- **ML Guide:** [backend/ML_UPGRADE_GUIDE.md](backend/ML_UPGRADE_GUIDE.md)
- **Migrações:** [backend/alembic/versions/](backend/alembic/versions/)

## 🧪 Testes

```bash
# Testar instalação do ML
cd backend
python test_ml_installation.py

# Testes da API (TODO)
pytest
```

## 📊 Estrutura do Projeto

```
PetID/
├── backend/
│   ├── app/
│   │   ├── api/          # Endpoints da API
│   │   ├── models/       # Modelos do banco
│   │   ├── schemas/      # Schemas Pydantic
│   │   └── services/     # Lógica de negócio + ML
│   ├── alembic/          # Migrações do banco
│   ├── requirements.txt  # Dependências Python
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

## 🔐 Segurança

- Autenticação JWT
- Bcrypt para senhas
- Sanitização de inputs
- Rate limiting (TODO)
- CORS configurável

## 📝 Licença

Este projeto é privado e proprietário.

## 👤 Autor

**Bruno Bronks**
- GitHub: [@bruno-bronks](https://github.com/bruno-bronks)

## 🤝 Contribuindo

Este é um projeto privado. Contribuições são bem-vindas mediante aprovação.

---

**Versão:** 1.0.0 (ML Real com MegaDescriptor)  
**Última atualização:** 2026-02-12
