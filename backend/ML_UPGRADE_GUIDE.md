# 🧠 Guia de Atualização: Biometria com ML Real

## 📋 O Que Mudou?

### ✨ Antes (Mock)
- Embeddings gerados por hash SHA-512
- 512 dimensões
- Sem validação de qualidade real
- Similaridade não confiável

### 🚀 Agora (ML Real)
- **MegaDescriptor** do HuggingFace (BVRA/MegaDescriptor-T-224)
- **768 dimensões** (Swin Transformer)
- **Validação real** de qualidade (nitidez, brilho, contraste)
- **Similaridade confiável** para re-identificação de animais
- Suporte a **GPU** (acelera 10-50x)

---

## 🛠️ Instalação

### 1. Instalar Dependências Python

```bash
cd backend
pip install -r requirements.txt
```

**Novas dependências adicionadas:**
- `transformers==4.46.3` - HuggingFace Transformers
- `torch==2.5.1` - PyTorch (CPU ou GPU)
- `torchvision==0.20.1` - Utilitários de visão
- `timm==1.0.11` - PyTorch Image Models
- `Pillow==10.4.0` - Processamento de imagem
- `opencv-python==4.10.0.84` - OpenCV

**Tamanho total:** ~2-3GB (PyTorch + modelo)

### 2. Executar Migração do Banco

```bash
# Opção 1: Via Docker
docker-compose exec api alembic upgrade head

# Opção 2: Local
cd backend
alembic upgrade head
```

**⚠️ IMPORTANTE:** Esta migração irá **APAGAR** todos os embeddings existentes,
pois a dimensão mudou de 512 para 768. Usuários precisarão re-registrar
a biometria dos pets.

### 3. (Opcional) Configurar GPU

Se você tem GPU NVIDIA com CUDA:

```bash
# Instala PyTorch com suporte CUDA
pip install torch==2.5.1+cu121 torchvision==0.20.1+cu121 --index-url https://download.pytorch.org/whl/cu121
```

O serviço detecta automaticamente se GPU está disponível.

---

## 🧪 Testes

### Teste 1: Verificar Instalação

```bash
cd backend
python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
python -c "import transformers; print('Transformers:', transformers.__version__)"
```

**Saída esperada:**
```
PyTorch: 2.5.1
CUDA: True  # ou False se não tiver GPU
Transformers: 4.46.3
```

### Teste 2: Testar Serviço de ML

Crie um arquivo `test_ml.py`:

```python
from app.services.ml_embedding_service import get_ml_service
import base64

# Carrega serviço
ml_service = get_ml_service()

# Info do modelo
info = ml_service.get_model_info()
print("Modelo:", info)

# Testa com imagem (exemplo com imagem fake)
# Substitua por uma imagem real de pet
with open("test_dog.jpg", "rb") as f:
    image_data = f.read()
    image_base64 = base64.b64encode(image_data).decode()

embedding, quality, issues = ml_service.generate_embedding(image_base64)

print(f"Embedding gerado: {len(embedding)} dimensões")
print(f"Qualidade: {quality}/100")
print(f"Issues: {issues}")
```

Execute:
```bash
python test_ml.py
```

### Teste 3: Testar via API

```bash
# 1. Inicie o servidor
uvicorn app.main:app --reload

# 2. Acesse Swagger
open http://localhost:8000/docs

# 3. Teste endpoint POST /api/v1/biometry/register
# Use uma imagem real de pet em base64
```

---

## 📊 Performance

### Primeiro Carregamento
- **Tempo:** ~10-30 segundos
- **Motivo:** Baixa modelo do HuggingFace (~400MB)
- **Cache:** Modelo fica em cache (~/.cache/huggingface/)

### Inferência (por imagem)
| Hardware | Tempo |
|----------|-------|
| **CPU** | 0.5 - 2 segundos |
| **GPU (NVIDIA)** | 0.05 - 0.2 segundos |

### Memória
| Componente | RAM necessária |
|------------|----------------|
| Modelo | ~800MB |
| Por requisição | ~50MB |
| **Total recomendado** | **2GB RAM** |

---

## 🔧 Configuração Avançada

### Ajustar Thresholds de Qualidade

Edite `ml_embedding_service.py`:

```python
class MLEmbeddingService:
    # Thresholds de qualidade
    MIN_IMAGE_SIZE = (100, 100)  # Aumentar para exigir mais resolução
    MIN_BRIGHTNESS = 30          # Diminuir se muitas fotos escuras
    MAX_BRIGHTNESS = 225         # Aumentar se muitas fotos claras
    MIN_SHARPNESS = 100          # Aumentar para exigir mais nitidez
```

### Ajustar Threshold de Similaridade

No `biometry_service.py`, o threshold padrão é `0.80` (80% de similaridade).

Para busca mais rígida:
```python
threshold = 0.90  # Apenas matches muito similares
```

Para busca mais flexível:
```python
threshold = 0.70  # Aceita matches menos similares
```

---

## 🐛 Troubleshooting

### Erro: "No module named 'torch'"
```bash
pip install torch==2.5.1
```

### Erro: "Model not found"
O modelo está sendo baixado do HuggingFace. Aguarde alguns minutos.

Se falhar, baixe manualmente:
```python
from transformers import AutoModel
model = AutoModel.from_pretrained("BVRA/MegaDescriptor-T-224")
```

### Erro: "CUDA out of memory"
GPU com pouca memória. Use CPU:
```python
# Em ml_embedding_service.py
self.device = torch.device("cpu")  # Força CPU
```

### Performance Lenta (CPU)
- **Normal:** 0.5-2s por imagem no CPU
- **Melhorar:**
  - Use GPU (10-50x mais rápido)
  - Implemente cache de embeddings
  - Use batch processing para múltiplas imagens

### Qualidade sempre baixa
- Verifique iluminação das fotos
- Use fotos de alta resolução (min 224x224)
- Foque no focinho do pet
- Evite fotos desfocadas

---

## 📚 Documentação

### API Endpoints

#### POST /api/v1/biometry/register
Registra biometria de um pet.

**Request:**
```json
{
  "pet_id": 1,
  "image_base64": "base64_encoded_image..."
}
```

**Response:**
```json
{
  "id": 1,
  "pet_id": 1,
  "quality_score": 85,
  "is_active": true,
  "created_at": "2026-02-12T10:00:00Z"
}
```

#### POST /api/v1/biometry/search
Busca pets por similaridade.

**Request:**
```json
{
  "image_base64": "base64_encoded_image...",
  "threshold": 0.80,
  "max_results": 5
}
```

**Response:**
```json
{
  "found": true,
  "results": [
    {
      "pet_id": 1,
      "pet_name": "Rex",
      "species": "dog",
      "breed": "Golden Retriever",
      "similarity": 0.9234,
      "owner_name": "Bruno",
      "owner_phone": "11****5678"
    }
  ],
  "message": "Encontrado(s) 1 pet(s) com similaridade acima de 80%"
}
```

---

## 🔮 Melhorias Futuras

### Fase 2 (Curto Prazo)
- [ ] Cache de embeddings em Redis
- [ ] Batch processing para múltiplas imagens
- [ ] Detecção automática da região do focinho
- [ ] API assíncrona (background jobs)

### Fase 3 (Médio Prazo)
- [ ] Fine-tuning do modelo com fotos dos usuários
- [ ] Suporte a múltiplos focinhos por pet
- [ ] Histórico de mudanças (focinho do filhote vs adulto)
- [ ] Qualidade adaptativa (aprende o que funciona melhor)

### Fase 4 (Longo Prazo)
- [ ] Modelo edge (rodar no mobile)
- [ ] Reconhecimento em tempo real (vídeo)
- [ ] Integração com outras biometrias (pelagem, iris)

---

## 📞 Suporte

**Problemas?** Abra uma issue ou consulte:
- [HuggingFace Model Card](https://huggingface.co/BVRA/MegaDescriptor-T-224)
- [PyTorch Documentation](https://pytorch.org/docs/)
- [Transformers Documentation](https://huggingface.co/docs/transformers/)

**Logs úteis:**
```bash
# Ver logs do backend
docker-compose logs -f api

# Ver logs do Python
tail -f backend/app.log
```

---

**Atualizado em:** 2026-02-12
**Versão:** 1.0.0 (ML Real com MegaDescriptor)
