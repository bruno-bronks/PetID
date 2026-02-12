from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql+psycopg://petid:petid_password@db:5432/petid"
    
    # JWT
    JWT_SECRET: str = "troque-por-um-segredo-longo-e-aleatorio-em-producao"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRES_MINUTES: int = 30  # 30 minutos
    JWT_REFRESH_TOKEN_EXPIRES_DAYS: int = 7  # 7 dias
    JWT_EXPIRES_MINUTES: int = 30  # Compatibilidade
    
    # S3/MinIO
    S3_ENDPOINT: str = "http://minio:9000"
    S3_ACCESS_KEY: str = "minio"
    S3_SECRET_KEY: str = "minio_password"
    S3_BUCKET: str = "pet-attachments"
    S3_REGION: str = "us-east-1"
    S3_USE_SSL: bool = False
    
    # App
    APP_NAME: str = "PetID"
    DEBUG: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

