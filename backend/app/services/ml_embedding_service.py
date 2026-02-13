"""
Serviço de geração de embeddings usando MegaDescriptor do HuggingFace.

Este serviço usa o modelo BVRA/MegaDescriptor-T-224, que é específico
para re-identificação de animais e gera embeddings de 768 dimensões.

Referências:
- Modelo: https://huggingface.co/BVRA/MegaDescriptor-T-224
- Paper: Animal Re-identification using MegaDescriptor
"""
import base64
import io
import logging
from typing import List, Tuple, Optional
from PIL import Image
import numpy as np
import torch
import torchvision.transforms as transforms
import timm
import cv2

logger = logging.getLogger(__name__)


class MLEmbeddingService:
    """
    Serviço de ML para extração de embeddings de imagens de pets.

    Usa MegaDescriptor (Swin Transformer) via timm pré-treinado para
    re-identificação de animais. O modelo gera embeddings de 768 dimensões.
    """

    # Configurações do modelo
    MODEL_NAME = "hf-hub:BVRA/MegaDescriptor-T-224"
    EMBEDDING_DIM = 768
    IMAGE_SIZE = (224, 224)

    # Thresholds de qualidade
    MIN_IMAGE_SIZE = (100, 100)
    MIN_BRIGHTNESS = 30
    MAX_BRIGHTNESS = 225
    MIN_SHARPNESS = 100  # Laplacian variance

    def __init__(self):
        """Inicializa o serviço de ML."""
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.transform = None
        self._model_loaded = False

        logger.info(f"MLEmbeddingService inicializado. Device: {self.device}")

    def _load_model(self):
        """Carrega o modelo MegaDescriptor via timm (lazy loading)."""
        if self._model_loaded:
            return

        try:
            logger.info(f"Carregando modelo {self.MODEL_NAME} via timm...")

            # Carrega modelo via timm (mais confiável para MegaDescriptor)
            self.model = timm.create_model(
                self.MODEL_NAME,
                pretrained=True,
                num_classes=0,  # Remove classification head, só features
            )

            # Move modelo para device (GPU se disponível)
            self.model = self.model.to(self.device)
            self.model.eval()  # Modo de inferência

            # Cria transform manual para pré-processamento
            # MegaDescriptor usa ImageNet normalization
            self.transform = transforms.Compose([
                transforms.Resize(self.IMAGE_SIZE),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],  # ImageNet mean
                    std=[0.229, 0.224, 0.225]     # ImageNet std
                ),
            ])

            self._model_loaded = True
            logger.info(f"Modelo carregado com sucesso via timm! Device: {self.device}")

        except Exception as e:
            logger.error(f"Erro ao carregar modelo: {e}")
            raise RuntimeError(f"Falha ao carregar modelo ML: {e}")

    def _decode_image(self, image_base64: str) -> Image.Image:
        """
        Decodifica imagem base64 para PIL Image.

        Args:
            image_base64: String base64 da imagem (com ou sem prefixo data:image/...)

        Returns:
            PIL.Image: Imagem decodificada

        Raises:
            ValueError: Se a imagem for inválida
        """
        try:
            # Remove prefixo data:image/...;base64, se existir
            if ',' in image_base64 and image_base64.startswith('data:'):
                image_base64 = image_base64.split(',', 1)[1]

            image_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(image_data))

            # Converte para RGB se necessário
            if image.mode != 'RGB':
                image = image.convert('RGB')

            return image

        except Exception as e:
            raise ValueError(f"Imagem base64 inválida: {e}")

    def _assess_image_quality(self, image: Image.Image) -> Tuple[int, List[str]]:
        """
        Avalia a qualidade da imagem para biometria.

        Verifica:
        - Resolução mínima
        - Brilho (não muito escura ou clara)
        - Nitidez (detecta blur)
        - Presença de features detectáveis

        Args:
            image: PIL Image

        Returns:
            (quality_score, issues): Score 0-100 e lista de problemas
        """
        quality_score = 100
        issues = []

        # Converte para numpy array
        img_array = np.array(image)

        # 1. Verifica resolução
        width, height = image.size
        if width < self.MIN_IMAGE_SIZE[0] or height < self.MIN_IMAGE_SIZE[1]:
            quality_score -= 30
            issues.append(f"Resolução muito baixa ({width}x{height}). Mínimo: {self.MIN_IMAGE_SIZE}")

        # 2. Verifica brilho
        gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        brightness = np.mean(gray)

        if brightness < self.MIN_BRIGHTNESS:
            quality_score -= 20
            issues.append(f"Imagem muito escura (brilho: {brightness:.1f})")
        elif brightness > self.MAX_BRIGHTNESS:
            quality_score -= 20
            issues.append(f"Imagem muito clara (brilho: {brightness:.1f})")

        # 3. Verifica nitidez (Laplacian variance)
        laplacian = cv2.Laplacian(gray, cv2.CV_64F)
        sharpness = laplacian.var()

        if sharpness < self.MIN_SHARPNESS:
            quality_score -= 25
            issues.append(f"Imagem desfocada (nitidez: {sharpness:.1f})")

        # 4. Verifica contraste
        contrast = gray.std()
        if contrast < 30:
            quality_score -= 15
            issues.append(f"Baixo contraste ({contrast:.1f})")

        # Limita score entre 0 e 100
        quality_score = max(0, min(100, quality_score))

        return quality_score, issues

    def _preprocess_image(self, image: Image.Image) -> torch.Tensor:
        """
        Pré-processa imagem para o modelo.

        Aplica:
        - Resize para tamanho esperado pelo modelo (224x224)
        - Normalização com média e std do ImageNet
        - Conversão para tensor

        Args:
            image: PIL Image

        Returns:
            torch.Tensor: Tensor pronto para o modelo (batch de 1)
        """
        # Aplica transformações
        tensor = self.transform(image)

        # Adiciona dimensão de batch
        tensor = tensor.unsqueeze(0)

        # Move para device (GPU se disponível)
        tensor = tensor.to(self.device)

        return tensor

    @torch.no_grad()
    def generate_embedding(self, image_base64: str) -> Tuple[Optional[List[float]], int, List[str]]:
        """
        Gera embedding ML real para uma imagem.

        Args:
            image_base64: Imagem em base64

        Returns:
            (embedding, quality_score, issues):
                - embedding: Lista de floats (768 dims) ou None se falhar
                - quality_score: Score de qualidade 0-100
                - issues: Lista de problemas encontrados
        """
        try:
            # Carrega modelo se necessário (lazy loading)
            self._load_model()

            # Decodifica imagem
            image = self._decode_image(image_base64)

            # Avalia qualidade
            quality_score, issues = self._assess_image_quality(image)

            if quality_score < 50:
                logger.warning(f"Qualidade baixa ({quality_score}): {issues}")
                # Ainda tenta gerar embedding, mas retorna warning

            # Pré-processa
            inputs = self._preprocess_image(image)

            # Gera embedding via timm
            # O modelo já foi configurado com num_classes=0, então retorna features
            features = self.model(inputs)

            # Extrai embedding (remove batch dimension)
            embedding = features.squeeze().cpu().numpy()

            # Normalização L2 (importante para cosine similarity)
            embedding = embedding / np.linalg.norm(embedding)

            # Converte para lista
            embedding_list = embedding.tolist()

            logger.info(f"Embedding gerado com sucesso. Qualidade: {quality_score}")

            return embedding_list, quality_score, issues

        except ValueError as e:
            logger.error(f"Erro de validação: {e}")
            return None, 0, [str(e)]
        except Exception as e:
            logger.error(f"Erro ao gerar embedding: {e}")
            return None, 0, [f"Erro interno: {str(e)}"]

    def detect_snout_region(self, image: Image.Image) -> Optional[Image.Image]:
        """
        Detecta e recorta a região do focinho (OPCIONAL - melhoria futura).

        Usa cascade classifiers do OpenCV ou modelos de detecção de objetos.
        Por enquanto, retorna a imagem completa.

        Args:
            image: PIL Image

        Returns:
            PIL.Image com região do focinho ou None se não detectar
        """
        # TODO: Implementar detecção de focinho
        # Opções:
        # 1. Haar Cascade (OpenCV) - rápido mas menos preciso
        # 2. YOLO/Faster R-CNN - mais preciso mas mais pesado
        # 3. Modelo específico de detecção de focinho

        # Por enquanto, retorna imagem completa
        return image

    def get_model_info(self) -> dict:
        """Retorna informações sobre o modelo carregado."""
        return {
            "model_name": self.MODEL_NAME,
            "embedding_dim": self.EMBEDDING_DIM,
            "device": str(self.device),
            "model_loaded": self._model_loaded,
            "image_size": self.IMAGE_SIZE
        }


# Singleton global (para evitar recarregar modelo múltiplas vezes)
_ml_service_instance = None


def get_ml_service() -> MLEmbeddingService:
    """Retorna instância singleton do serviço de ML."""
    global _ml_service_instance

    if _ml_service_instance is None:
        _ml_service_instance = MLEmbeddingService()

    return _ml_service_instance
