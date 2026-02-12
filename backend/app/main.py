from fastapi import FastAPI, APIRouter, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api import routes_auth, routes_pets, routes_records, routes_attachments, routes_audit, routes_biometry, routes_vaccines, routes_public, routes_veterinarians, routes_medications, routes_documents
from app.core.config import settings
from collections import defaultdict
import time

app = FastAPI(
    title="PetID API",
    description="API para gerenciamento de prontuários de pets com biometria por focinho",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS - Configure conforme necessário
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # No MVP, depois restrinja para domínios específicos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Rate Limiting simples (em produção use Redis)
class RateLimiter:
    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.requests = defaultdict(list)
    
    def is_allowed(self, client_ip: str) -> bool:
        now = time.time()
        minute_ago = now - 60
        
        # Remove requisições antigas
        self.requests[client_ip] = [
            req_time for req_time in self.requests[client_ip]
            if req_time > minute_ago
        ]
        
        # Verifica limite
        if len(self.requests[client_ip]) >= self.requests_per_minute:
            return False
        
        self.requests[client_ip].append(now)
        return True


rate_limiter = RateLimiter(requests_per_minute=100)


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Middleware de rate limiting"""
    # Pega IP real (considerando proxy)
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        client_ip = request.client.host if request.client else "unknown"
    
    # Ignora rate limit para health check
    if request.url.path in ["/health", "/docs", "/openapi.json", "/redoc"]:
        return await call_next(request)
    
    if not rate_limiter.is_allowed(client_ip):
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Muitas requisições. Tente novamente em alguns segundos."},
        )
    
    return await call_next(request)

# Router versionado (v1)
api_v1_router = APIRouter(prefix="/api/v1")

# Incluir rotas no router v1
api_v1_router.include_router(routes_auth.router, prefix="/auth", tags=["Autenticação"])
api_v1_router.include_router(routes_pets.router, prefix="/pets", tags=["Pets"])
api_v1_router.include_router(routes_records.router, prefix="/pets", tags=["Prontuário"])
api_v1_router.include_router(routes_attachments.router, prefix="/records", tags=["Anexos"])
api_v1_router.include_router(routes_audit.router, prefix="/audit", tags=["Auditoria"])
api_v1_router.include_router(routes_biometry.router, prefix="/biometry", tags=["Biometria"])
api_v1_router.include_router(routes_vaccines.router, prefix="/vaccines", tags=["Vacinas"])
api_v1_router.include_router(routes_public.router, prefix="/public", tags=["Público"])
api_v1_router.include_router(routes_veterinarians.router, prefix="/pets", tags=["Veterinários"])
api_v1_router.include_router(routes_medications.router, prefix="/pets", tags=["Medicamentos"])
api_v1_router.include_router(routes_documents.router, prefix="/pets", tags=["Documentos"])

# Incluir router versionado no app
app.include_router(api_v1_router)

# Manter rotas legadas (sem /v1) para compatibilidade
# Remova após migração completa para v1
legacy_router = APIRouter(prefix="/api", deprecated=True)
legacy_router.include_router(routes_auth.router, prefix="/auth", tags=["[Legacy] Auth"])
legacy_router.include_router(routes_pets.router, prefix="/pets", tags=["[Legacy] Pets"])
legacy_router.include_router(routes_records.router, prefix="/pets", tags=["[Legacy] Prontuário"])
legacy_router.include_router(routes_attachments.router, prefix="/records", tags=["[Legacy] Anexos"])
app.include_router(legacy_router)


@app.get("/", tags=["Root"])
async def root():
    """Informações da API"""
    return {
        "message": "PetID API",
        "version": "1.0.0",
        "docs": "/docs",
        "api_v1": "/api/v1",
    }


@app.get("/health", tags=["Health"])
async def health():
    """Health check da API"""
    return {"status": "ok", "version": "1.0.0"}

