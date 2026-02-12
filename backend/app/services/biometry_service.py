import base64
import hashlib
import logging
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.models.snout_biometry import SnoutBiometry
from app.models.pet import Pet
from app.models.user import User
from app.services.ml_embedding_service import get_ml_service

logger = logging.getLogger(__name__)


class BiometryService:
    """
    Serviço de biometria por focinho usando ML REAL.

    Usa MegaDescriptor (BVRA/MegaDescriptor-T-224) do HuggingFace para
    gerar embeddings de 768 dimensões específicos para re-identificação
    de animais.

    Features:
    - Embeddings ML reais (não mais mock)
    - Validação de qualidade de imagem
    - Busca por similaridade usando pgvector
    - Suporte a GPU (se disponível)
    """

    EMBEDDING_DIM = 768  # Dimensão do MegaDescriptor

    def __init__(self, db: Session):
        self.db = db
        self.ml_service = get_ml_service()
    
    def _generate_embedding(self, image_base64: str) -> Tuple[Optional[List[float]], int, List[str]]:
        """
        Gera embedding ML REAL usando MegaDescriptor.

        Args:
            image_base64: Imagem em base64

        Returns:
            (embedding, quality_score, issues):
                - embedding: Lista de 768 floats ou None se falhar
                - quality_score: Score 0-100
                - issues: Lista de problemas detectados
        """
        return self.ml_service.generate_embedding(image_base64)
    
    def register_snout(
        self,
        pet_id: int,
        image_base64: str,
        owner_id: int
    ) -> Tuple[Optional[SnoutBiometry], str]:
        """
        Registra a biometria do focinho de um pet usando ML REAL.

        Args:
            pet_id: ID do pet
            image_base64: Imagem do focinho em base64
            owner_id: ID do dono

        Returns:
            (SnoutBiometry, message) se sucesso
            (None, error_message) se falha
        """
        # Verifica se o pet existe e pertence ao usuário
        pet = self.db.query(Pet).filter(
            Pet.id == pet_id,
            Pet.owner_id == owner_id
        ).first()

        if not pet:
            return None, "Pet não encontrado ou você não tem permissão"

        # Gera embedding usando ML real
        embedding, quality, issues = self._generate_embedding(image_base64)

        if embedding is None:
            error_msg = "Erro ao processar imagem: " + "; ".join(issues)
            logger.error(error_msg)
            return None, error_msg

        # Verifica qualidade mínima
        if quality < 50:
            issues_text = "\n- ".join(issues) if issues else "Qualidade insuficiente"
            return None, f"Qualidade da imagem muito baixa ({quality}/100).\n\nProblemas detectados:\n- {issues_text}\n\nDicas:\n- Use boa iluminação\n- Foque no focinho do pet\n- Evite fotos desfocadas"

        logger.info(f"Embedding gerado para pet {pet_id}. Qualidade: {quality}")

        # Verifica se já existe biometria
        existing = self.db.query(SnoutBiometry).filter(
            SnoutBiometry.pet_id == pet_id
        ).first()

        message_suffix = f"Qualidade: {quality}/100"
        if issues:
            message_suffix += f"\nAvisos: {', '.join(issues)}"

        if existing:
            # Atualiza existente
            existing.embedding = embedding
            existing.quality_score = quality
            existing.is_active = True
            self.db.commit()
            self.db.refresh(existing)
            return existing, f"Biometria atualizada com sucesso! {message_suffix}"

        # Cria nova
        biometry = SnoutBiometry(
            pet_id=pet_id,
            embedding=embedding,
            quality_score=quality,
            is_active=True
        )

        self.db.add(biometry)
        self.db.commit()
        self.db.refresh(biometry)

        return biometry, f"Biometria registrada com sucesso! {message_suffix}"
    
    def search_by_snout(
        self,
        image_base64: str,
        threshold: float = 0.80,  # Reduzido para 0.80 (ML real é mais preciso)
        max_results: int = 5
    ) -> List[dict]:
        """
        Busca pets por similaridade do focinho usando ML REAL.

        Args:
            image_base64: Imagem para buscar
            threshold: Threshold de similaridade (0-1). Default: 0.80
            max_results: Máximo de resultados

        Returns:
            Lista de dicts com pet_id, similarity, e dados do pet
        """
        # Gera embedding da imagem de busca usando ML
        query_embedding, quality, issues = self._generate_embedding(image_base64)

        if query_embedding is None:
            logger.error(f"Erro ao gerar embedding de busca: {issues}")
            return []

        if quality < 50:
            logger.warning(f"Qualidade baixa na busca ({quality}): {issues}")
            # Ainda tenta buscar, mas avisa no log
        
        # Busca por similaridade de cosseno usando pgvector
        # Quanto menor a distância, maior a similaridade
        # cosine distance = 1 - cosine_similarity
        query = text("""
            SELECT 
                sb.pet_id,
                sb.quality_score,
                1 - (sb.embedding <=> :embedding) as similarity,
                p.name as pet_name,
                p.species,
                p.breed,
                p.photo_url,
                u.full_name as owner_name,
                u.phone as owner_phone
            FROM snout_biometries sb
            JOIN pets p ON p.id = sb.pet_id
            JOIN users u ON u.id = p.owner_id
            WHERE sb.is_active = true
            AND 1 - (sb.embedding <=> :embedding) >= :threshold
            ORDER BY similarity DESC
            LIMIT :max_results
        """)
        
        # Converte embedding para string no formato pgvector
        embedding_str = "[" + ",".join(str(x) for x in query_embedding) + "]"
        
        results = self.db.execute(
            query,
            {
                "embedding": embedding_str,
                "threshold": threshold,
                "max_results": max_results
            }
        ).fetchall()
        
        # Mascara telefone para privacidade
        def mask_phone(phone: str) -> str:
            if not phone or len(phone) < 4:
                return "****"
            return phone[:2] + "*" * (len(phone) - 4) + phone[-2:]
        
        return [
            {
                "pet_id": row.pet_id,
                "pet_name": row.pet_name,
                "species": row.species,
                "breed": row.breed,
                "owner_name": row.owner_name,
                "owner_phone": mask_phone(row.owner_phone) if row.owner_phone else None,
                "similarity": round(row.similarity, 4),
                "has_contact_permission": True  # TODO: Verificar permissões
            }
            for row in results
        ]
    
    def delete_biometry(self, pet_id: int, owner_id: int) -> bool:
        """Remove a biometria de um pet"""
        biometry = self.db.query(SnoutBiometry).join(Pet).filter(
            SnoutBiometry.pet_id == pet_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not biometry:
            return False
        
        self.db.delete(biometry)
        self.db.commit()
        return True

