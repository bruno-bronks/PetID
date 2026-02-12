# Script de instalação do sistema de ML para PetID (Windows PowerShell)
# Este script instala as dependências e configura o ambiente

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  PetID - Instalacao do Sistema de ML Real" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Verifica Python
Write-Host "[PYTHON] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] $pythonVersion encontrado" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Python nao encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale Python 3.11 ou superior." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verifica pip
Write-Host "[PIP] Verificando pip..." -ForegroundColor Yellow
try {
    pip --version 2>&1 | Out-Null
    Write-Host "[OK] pip encontrado" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] pip nao encontrado!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Instala dependências
Write-Host "[INSTALL] Instalando dependencias Python..." -ForegroundColor Yellow
Write-Host "[INSTALL] Isso pode demorar alguns minutos (~2-3GB de downloads)..." -ForegroundColor Yellow
Write-Host ""

try {
    pip install -r requirements.txt
    Write-Host "[OK] Dependencias instaladas!" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Erro ao instalar dependencias!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verifica instalação
Write-Host "[TEST] Verificando instalacao..." -ForegroundColor Yellow

# Testa PyTorch
try {
    $torchVersion = python -c 'import torch; print(\"PyTorch:\", torch.__version__)' 2>&1
    Write-Host "[OK] $torchVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Erro ao importar PyTorch" -ForegroundColor Red
    exit 1
}

# Testa Transformers
try {
    $transformersVersion = python -c 'import transformers; print(\"Transformers:\", transformers.__version__)' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERRO] Erro ao importar Transformers:" -ForegroundColor Red
        Write-Host $transformersVersion -ForegroundColor Red
        Write-Host "" -ForegroundColor Yellow
        Write-Host "[DICA] Isso pode ser um problema temporario. Tente executar:" -ForegroundColor Yellow
        Write-Host "  python test_ml_installation.py" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "[OK] $transformersVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Erro ao importar Transformers: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verifica GPU
Write-Host ""
Write-Host "[GPU] Verificando GPU..." -ForegroundColor Yellow
try {
    python -c 'import torch; print(\"CUDA disponivel:\", torch.cuda.is_available()); print(\"Device:\", torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"CPU\")'
} catch {
    Write-Host "[AVISO] Erro ao verificar GPU (continuando com CPU)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Proximos Passos" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Execute a migracao do banco de dados:" -ForegroundColor White
Write-Host "   alembic upgrade head" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Inicie o servidor:" -ForegroundColor White
Write-Host "   uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Acesse a documentacao:" -ForegroundColor White
Write-Host "   http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "[DOCS] Documentacao completa: ML_UPGRADE_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] Instalacao concluida!" -ForegroundColor Green
Write-Host ""
Write-Host "[DICA] Se encontrar erros, consulte ML_UPGRADE_GUIDE.md" -ForegroundColor Yellow
