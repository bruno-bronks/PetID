#!/usr/bin/env python3
"""
Teste de biometria com imagem REAL de focinho de pet.
Baixe uma foto de focinho de cachorro/gato e teste!
"""
import requests
import base64
import sys
import os


API_URL = "http://148.230.79.134:8001"
# API_URL = "http://localhost:8001"  # Para teste local


def image_to_base64(image_path):
    """Converte imagem para base64."""
    with open(image_path, "rb") as img_file:
        img_data = img_file.read()
        img_base64 = base64.b64encode(img_data).decode()
        return f"data:image/jpeg;base64,{img_base64}"


def register_biometry(token, pet_id, image_path):
    """Registra biometria com imagem real."""
    print(f"\n📸 Processando imagem: {image_path}")
    print("⏳ Gerando embedding com ML (pode demorar ~2-5s)...\n")

    snout_image = image_to_base64(image_path)

    data = {
        "pet_id": pet_id,
        "image_base64": snout_image
    }

    headers = {"Authorization": f"Bearer {token}"}

    response = requests.post(
        f"{API_URL}/api/v1/biometry/register",
        json=data,
        headers=headers,
        timeout=120
    )

    if response.status_code == 201:
        result = response.json()
        print("✅ Biometria registrada com sucesso!")
        print(f"   ID: {result.get('id')}")
        print(f"   Qualidade: {result.get('quality_score')}/100")

        if result.get('quality_score', 0) < 50:
            print(f"\n⚠️  Qualidade baixa! Dicas:")
            print("   - Use foto com boa iluminação")
            print("   - Focinho centralizado e em foco")
            print("   - Sem reflexos ou sombras fortes")
        else:
            print(f"\n🎉 Ótima qualidade de imagem!")

        return result
    else:
        print(f"❌ Erro: {response.status_code}")
        print(f"   {response.text}")
        return None


def identify_pet(token, image_path):
    """Identifica pet por biometria."""
    print(f"\n🔍 Identificando pet pela imagem: {image_path}")
    print("⏳ Processando com ML...\n")

    snout_image = image_to_base64(image_path)

    data = {
        "image_base64": snout_image,
        "threshold": 0.85,
        "max_results": 5
    }
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.post(
        f"{API_URL}/api/v1/biometry/search",
        json=data,
        headers=headers,
        timeout=60
    )

    if response.status_code == 200:
        result = response.json()

        if result.get("found"):
            print("✅ Pet identificado!")
            pet_result = result.get("results", [])[0] if result.get("results") else None
            if pet_result:
                print(f"   Pet ID: {pet_result.get('pet_id')}")
                print(f"   Nome: {pet_result.get('pet_name')}")
                print(f"   Similaridade: {pet_result.get('similarity', 0):.2%}")

                # Threshold padrão é 0.85 (85%)
                if pet_result.get('similarity', 0) > 0.95:
                    print(f"\n🎯 Confiança MUITO ALTA!")
                elif pet_result.get('similarity', 0) > 0.85:
                    print(f"\n✓ Confiança alta")
                else:
                    print(f"\n⚠️  Confiança média")

            return result
        else:
            print("❌ Nenhum pet identificado")
            print("   Similaridade muito baixa ou nenhuma biometria cadastrada")
            return None
    else:
        print(f"❌ Erro: {response.status_code}")
        print(f"   {response.text}")
        return None


def main():
    if len(sys.argv) < 2:
        print("\n" + "="*60)
        print("  TESTE DE BIOMETRIA COM IMAGEM REAL")
        print("="*60)
        print("\nUSO:")
        print(f"  python {sys.argv[0]} <caminho_da_imagem>\n")
        print("EXEMPLOS:")
        print(f"  # Registrar biometria")
        print(f"  python {sys.argv[0]} foto_focinho.jpg\n")
        print(f"  # Identificar pet")
        print(f"  python {sys.argv[0]} foto_focinho_2.jpg\n")
        print("DICAS:")
        print("  - Baixe fotos de focinhos de pets da internet")
        print("  - Tire fotos do focinho do seu pet")
        print("  - Use imagens com boa iluminação e foco")
        print("  - Focinho deve estar centralizado\n")
        return 1

    image_path = sys.argv[1]

    if not os.path.exists(image_path):
        print(f"❌ Arquivo não encontrado: {image_path}")
        return 1

    print("\n" + "="*60)
    print("  TESTE DE BIOMETRIA COM IMAGEM REAL")
    print("="*60)

    # Você precisa ter TOKEN e PET_ID
    # Execute test_api_e2e.py primeiro para criar usuário e pet

    print("\n⚠️  IMPORTANTE:")
    print("1. Execute 'python test_api_e2e.py' primeiro para criar usuário e pet")
    print("2. Ou faça login manualmente e forneça TOKEN e PET_ID\n")

    token = input("Digite seu token (access_token): ").strip()
    if not token:
        print("❌ Token não fornecido")
        return 1

    print("\nO que você quer fazer?")
    print("1. Registrar nova biometria")
    print("2. Identificar pet existente")

    choice = input("\nEscolha (1 ou 2): ").strip()

    if choice == "1":
        pet_id = input("Digite o ID do pet: ").strip()
        if not pet_id.isdigit():
            print("❌ ID do pet inválido")
            return 1

        register_biometry(token, int(pet_id), image_path)

    elif choice == "2":
        identify_pet(token, image_path)

    else:
        print("❌ Opção inválida")
        return 1

    print("\n✅ Teste concluído!\n")
    return 0


if __name__ == "__main__":
    try:
        exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Teste interrompido pelo usuário.\n")
        exit(1)
    except Exception as e:
        print(f"\n❌ Erro: {e}\n")
        exit(1)
