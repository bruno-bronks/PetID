"""
Script de teste para validar a instalação do sistema de ML.

Testa:
1. Importação de dependências
2. Carregamento do modelo MegaDescriptor
3. Geração de embeddings
4. Validação de qualidade de imagem

Execute: python test_ml_installation.py
"""
import sys
import time
from io import BytesIO
import base64

def print_header(text):
    """Imprime cabeçalho formatado."""
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60)


def test_imports():
    """Testa importação das dependências."""
    print_header("Teste 1: Importação de Dependências")

    dependencies = {
        "torch": "PyTorch",
        "torchvision": "TorchVision",
        "transformers": "HuggingFace Transformers",
        "PIL": "Pillow",
        "cv2": "OpenCV",
        "numpy": "NumPy"
    }

    all_ok = True
    for module_name, display_name in dependencies.items():
        try:
            module = __import__(module_name)
            version = getattr(module, "__version__", "N/A")
            print(f"[OK] {display_name:25} v{version}")
        except ImportError as e:
            print(f"[ERRO] {display_name:25} ERRO: {e}")
            all_ok = False

    return all_ok


def test_torch_device():
    """Testa disponibilidade de GPU."""
    print_header("Teste 2: Device (CPU/GPU)")

    import torch

    print(f"PyTorch version: {torch.__version__}")
    print(f"CUDA disponível: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        print(f"CUDA version: {torch.version.cuda}")
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
        print("[OK] GPU detectada! Inferência será 10-50x mais rápida.")
    else:
        print("[AVISO]  GPU não detectada. Usando CPU.")
        print("   Inferência será mais lenta (~0.5-2s por imagem).")

    return True


def test_model_loading():
    """Testa carregamento do modelo MegaDescriptor."""
    print_header("Teste 3: Carregamento do Modelo")

    try:
        from app.services.ml_embedding_service import get_ml_service

        print("[DOWNLOAD] Carregando MegaDescriptor do HuggingFace...")
        print("   (Primeira vez pode demorar ~30s para baixar ~400MB)")

        start_time = time.time()
        ml_service = get_ml_service()

        # Força carregamento
        ml_service._load_model()

        load_time = time.time() - start_time

        print(f"[OK] Modelo carregado em {load_time:.2f} segundos")

        # Info do modelo
        info = ml_service.get_model_info()
        print("\nInformações do modelo:")
        for key, value in info.items():
            print(f"  {key}: {value}")

        return True

    except Exception as e:
        print(f"[ERRO] Erro ao carregar modelo: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_embedding_generation():
    """Testa geração de embeddings com imagem fake."""
    print_header("Teste 4: Geração de Embeddings")

    try:
        from app.services.ml_embedding_service import get_ml_service
        from PIL import Image
        import numpy as np

        ml_service = get_ml_service()

        # Cria imagem fake (colorida, 512x512)
        print("[IMG] Gerando imagem de teste (512x512 RGB)...")
        fake_image = Image.fromarray(
            np.random.randint(0, 255, (512, 512, 3), dtype=np.uint8)
        )

        # Converte para base64
        buffered = BytesIO()
        fake_image.save(buffered, format="JPEG")
        image_base64 = base64.b64encode(buffered.getvalue()).decode()

        print("[ML] Gerando embedding...")
        start_time = time.time()

        embedding, quality, issues = ml_service.generate_embedding(image_base64)

        inference_time = time.time() - start_time

        if embedding is None:
            print(f"[ERRO] Falha ao gerar embedding: {issues}")
            return False

        print(f"[OK] Embedding gerado em {inference_time:.3f} segundos")
        print(f"   Dimensões: {len(embedding)}")
        print(f"   Qualidade: {quality}/100")

        if issues:
            print(f"   Avisos: {', '.join(issues)}")

        # Valida embedding
        assert len(embedding) == 768, f"Dimensão esperada: 768, obtida: {len(embedding)}"
        assert all(isinstance(x, float) for x in embedding), "Embedding deve conter floats"

        # Verifica normalização L2
        import math
        magnitude = math.sqrt(sum(x**2 for x in embedding))
        assert abs(magnitude - 1.0) < 0.01, f"Embedding deve ser normalizado (L2=1), obtido: {magnitude}"

        print("[OK] Embedding válido (768 dims, normalizado L2)")

        return True

    except Exception as e:
        print(f"[ERRO] Erro ao gerar embedding: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_quality_assessment():
    """Testa avaliação de qualidade de imagem."""
    print_header("Teste 5: Avaliação de Qualidade")

    try:
        from app.services.ml_embedding_service import get_ml_service
        from PIL import Image
        import numpy as np

        ml_service = get_ml_service()

        test_cases = [
            ("Imagem boa (512x512)", np.random.randint(100, 150, (512, 512, 3), dtype=np.uint8)),
            ("Imagem pequena (50x50)", np.random.randint(100, 150, (50, 50, 3), dtype=np.uint8)),
            ("Imagem escura", np.random.randint(0, 30, (512, 512, 3), dtype=np.uint8)),
            ("Imagem clara", np.random.randint(220, 255, (512, 512, 3), dtype=np.uint8)),
        ]

        for name, img_array in test_cases:
            img = Image.fromarray(img_array)
            buffered = BytesIO()
            img.save(buffered, format="JPEG")
            image_base64 = base64.b64encode(buffered.getvalue()).decode()

            embedding, quality, issues = ml_service.generate_embedding(image_base64)

            status = "[OK]" if quality >= 50 else "[AVISO]"
            print(f"{status} {name:20} - Qualidade: {quality}/100")

            if issues:
                for issue in issues:
                    print(f"     - {issue}")

        return True

    except Exception as e:
        print(f"[ERRO] Erro no teste de qualidade: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Executa todos os testes."""
    print("\n" + "=" * 60)
    print("  TESTE DE INSTALAÇÃO DO SISTEMA DE ML - PetID")
    print("=" * 60)

    tests = [
        ("Importação de Dependências", test_imports),
        ("Device (CPU/GPU)", test_torch_device),
        ("Carregamento do Modelo", test_model_loading),
        ("Geração de Embeddings", test_embedding_generation),
        ("Avaliação de Qualidade", test_quality_assessment),
    ]

    results = []
    for name, test_func in tests:
        try:
            success = test_func()
            results.append((name, success))
        except Exception as e:
            print(f"\n[ERRO] Erro inesperado no teste '{name}': {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))

    # Resumo
    print_header("RESUMO DOS TESTES")
    total = len(results)
    passed = sum(1 for _, success in results if success)

    for name, success in results:
        status = "[OK] PASSOU" if success else "[ERRO] FALHOU"
        print(f"{status:12} - {name}")

    print(f"\nResultado: {passed}/{total} testes passaram")

    if passed == total:
        print("\n[SUCESSO] SUCESSO! Sistema de ML está funcionando perfeitamente!")
        print("\n[INFO] Próximos passos:")
        print("   1. Execute: alembic upgrade head")
        print("   2. Inicie o servidor: uvicorn app.main:app --reload")
        print("   3. Teste a API em: http://localhost:8000/docs")
        return 0
    else:
        print("\n[AVISO]  Alguns testes falharam. Verifique os erros acima.")
        print("\n[DOCS] Consulte ML_UPGRADE_GUIDE.md para troubleshooting.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
