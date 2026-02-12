"""Upgrade embedding dimension from 512 to 768 for MegaDescriptor

Revision ID: 001_ml_upgrade
Revises:
Create Date: 2026-02-12

Atualiza a dimensão do embedding de 512 para 768 dimensões para usar
o modelo MegaDescriptor do HuggingFace.

IMPORTANTE: Esta migração irá APAGAR todos os embeddings existentes,
pois a dimensão é incompatível. Os usuários precisarão re-registrar
a biometria de seus pets.
"""
from alembic import op
import sqlalchemy as sa
from pgvector.sqlalchemy import Vector

# revision identifiers, used by Alembic.
revision = '001_ml_upgrade'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    """
    Atualiza a coluna embedding de Vector(512) para Vector(768).

    Como não é possível converter embeddings de 512 para 768 dimensões,
    esta migração remove todos os embeddings existentes.
    """
    # Habilita extensão pgvector (se ainda não estiver)
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    # Verifica se a tabela existe
    conn = op.get_bind()
    inspector = sa.inspect(conn)

    if 'snout_biometries' in inspector.get_table_names():
        # Tabela existe - atualizar dimensão
        # 1. Remove índice existente (se existir)
        op.execute("DROP INDEX IF EXISTS ix_snout_biometries_embedding")

        # 2. Remove coluna antiga
        op.drop_column('snout_biometries', 'embedding')

        # 3. Adiciona coluna nova com 768 dimensões
        op.add_column(
            'snout_biometries',
            sa.Column('embedding', Vector(768), nullable=False)
        )
    else:
        # Tabela não existe - criar do zero (sem FK por enquanto)
        op.create_table(
            'snout_biometries',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('pet_id', sa.Integer(), nullable=False),
            sa.Column('embedding', Vector(768), nullable=False),
            sa.Column('quality_score', sa.Integer(), nullable=True),
            sa.Column('is_active', sa.Boolean(), nullable=True, default=True),
            sa.Column('created_at', sa.DateTime(), nullable=True),
            sa.Column('updated_at', sa.DateTime(), nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_snout_biometries_id'), 'snout_biometries', ['id'], unique=False)
        op.create_index(op.f('ix_snout_biometries_pet_id'), 'snout_biometries', ['pet_id'], unique=True)

        # Adiciona FK apenas se a tabela pets existir
        if 'pets' in inspector.get_table_names():
            op.create_foreign_key(
                'fk_snout_biometries_pet_id',
                'snout_biometries', 'pets',
                ['pet_id'], ['id'],
                ondelete='CASCADE'
            )

    # 4. Recria índice IVFFlat para busca vetorial eficiente
    op.execute("""
        CREATE INDEX ix_snout_biometries_embedding
        ON snout_biometries
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 100)
    """)

    print("✅ Embedding atualizado para 768 dimensões (MegaDescriptor)")
    print("⚠️  AVISO: Todos os embeddings anteriores foram removidos.")
    print("   Usuários precisarão re-registrar a biometria dos pets.")


def downgrade():
    """
    Reverte para Vector(512).

    AVISO: Isso também remove todos os embeddings.
    """
    # 1. Remove índice (se existir)
    op.execute("DROP INDEX IF EXISTS ix_snout_biometries_embedding")

    # 2. Remove coluna de 768 dims
    op.drop_column('snout_biometries', 'embedding')

    # 3. Adiciona coluna de 512 dims
    op.add_column(
        'snout_biometries',
        sa.Column('embedding', Vector(512), nullable=False)
    )

    # 4. Recria índice
    op.execute("""
        CREATE INDEX ix_snout_biometries_embedding
        ON snout_biometries
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 100)
    """)

    print("⚠️  Revertido para 512 dimensões. Embeddings removidos.")
