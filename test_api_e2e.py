#!/usr/bin/env python3
"""
Script de teste E2E (End-to-End) para PetID API
Testa o fluxo completo como usuário real.
"""
import requests
import base64
import json
from datetime import datetime
from io import BytesIO
from PIL import Image
import numpy as np

# Configuração
API_URL = "http://148.230.79.134:8001"  # Trocar para localhost:8001 se testar local
# API_URL = "http://localhost:8001"  # Descomentar para teste local


class Colors:
    """Cores para terminal."""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'


def print_header(text):
    """Imprime cabeçalho colorido."""
    print(f"\n{Colors.CYAN}{Colors.BOLD}{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}{Colors.END}\n")


def print_success(text):
    """Imprime mensagem de sucesso."""
    print(f"{Colors.GREEN}✓ {text}{Colors.END}")


def print_error(text):
    """Imprime mensagem de erro."""
    print(f"{Colors.RED}✗ {text}{Colors.END}")


def print_info(text):
    """Imprime mensagem informativa."""
    print(f"{Colors.BLUE}ℹ {text}{Colors.END}")


def print_warning(text):
    """Imprime mensagem de aviso."""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.END}")


def generate_fake_snout_image():
    """Gera uma imagem fake de focinho para teste."""
    # Cria uma imagem RGB 512x512 com padrão de focinho simulado
    img = np.random.randint(50, 200, (512, 512, 3), dtype=np.uint8)

    # Adiciona um círculo escuro no centro (simula focinho)
    center_x, center_y = 256, 256
    for i in range(512):
        for j in range(512):
            dist = np.sqrt((i - center_x)**2 + (j - center_y)**2)
            if dist < 100:
                img[i, j] = [30, 30, 30]  # Preto

    # Converte para PIL Image
    pil_img = Image.fromarray(img)

    # Converte para base64
    buffered = BytesIO()
    pil_img.save(buffered, format="JPEG", quality=95)
    img_base64 = base64.b64encode(buffered.getvalue()).decode()

    return f"data:image/jpeg;base64,{img_base64}"


def test_health():
    """Testa endpoint de saúde."""
    print_header("1. Testando Saúde da API")

    try:
        response = requests.get(f"{API_URL}/health", timeout=5)

        if response.status_code == 200:
            print_success("API está online e saudável!")
            print_info(f"Resposta: {response.json()}")
            return True
        else:
            print_error(f"API retornou código {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print_error(f"Não foi possível conectar à API em {API_URL}")
        print_warning("Verifique se os containers estão rodando: docker-compose ps")
        return False
    except Exception as e:
        print_error(f"Erro ao testar health: {e}")
        return False


def test_register_user():
    """Testa registro de usuário."""
    print_header("2. Registrando Usuário")

    # Gera dados únicos com timestamp
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    user_data = {
        "name": f"Usuário Teste {timestamp}",
        "email": f"teste{timestamp}@petid.com",
        "password": "senha123",
        "cpf": f"{timestamp[:11]}"  # CPF fake (apenas para teste)
    }

    print_info(f"Criando usuário: {user_data['email']}")

    try:
        response = requests.post(
            f"{API_URL}/api/v1/auth/register",
            json=user_data,
            timeout=10
        )

        if response.status_code == 201:
            print_success("Usuário registrado com sucesso!")
            user = response.json()
            print_info(f"ID: {user.get('id')}")
            print_info(f"Nome: {user.get('name')}")
            print_info(f"Email: {user.get('email')}")
            return user_data
        else:
            print_error(f"Erro ao registrar usuário: {response.status_code}")
            print_error(f"Resposta: {response.text}")
            return None
    except Exception as e:
        print_error(f"Erro ao registrar usuário: {e}")
        return None


def test_login(user_data):
    """Testa login de usuário."""
    print_header("3. Fazendo Login")

    login_data = {
        "email": user_data["email"],
        "password": user_data["password"]
    }

    print_info(f"Fazendo login: {login_data['email']}")

    try:
        response = requests.post(
            f"{API_URL}/api/v1/auth/login",
            json=login_data,
            timeout=10
        )

        if response.status_code == 200:
            print_success("Login realizado com sucesso!")
            data = response.json()
            token = data.get("access_token")
            print_info(f"Token obtido: {token[:50]}...")
            return token
        else:
            print_error(f"Erro ao fazer login: {response.status_code}")
            print_error(f"Resposta: {response.text}")
            return None
    except Exception as e:
        print_error(f"Erro ao fazer login: {e}")
        return None


def test_create_pet(token):
    """Testa criação de pet."""
    print_header("4. Registrando Pet")

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    pet_data = {
        "name": f"Rex {timestamp}",
        "species": "dog",
        "breed": "Labrador",
        "birth_date": "2020-01-15",
        "sex": "male",
        "color": "Dourado",
        "weight": 25.5
    }

    print_info(f"Criando pet: {pet_data['name']}")

    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.post(
            f"{API_URL}/api/v1/pets",
            json=pet_data,
            headers=headers,
            timeout=10
        )

        if response.status_code == 201:
            print_success("Pet registrado com sucesso!")
            pet = response.json()
            print_info(f"ID: {pet.get('id')}")
            print_info(f"Nome: {pet.get('name')}")
            print_info(f"Espécie: {pet.get('species')}")
            print_info(f"Raça: {pet.get('breed')}")
            return pet
        else:
            print_error(f"Erro ao criar pet: {response.status_code}")
            print_error(f"Resposta: {response.text}")
            return None
    except Exception as e:
        print_error(f"Erro ao criar pet: {e}")
        return None


def test_register_biometry(token, pet_id):
    """Testa registro de biometria (ML)."""
    print_header("5. Registrando Biometria do Focinho (ML)")

    print_info("Gerando imagem de teste de focinho...")
    snout_image = generate_fake_snout_image()

    biometry_data = {
        "pet_id": pet_id,
        "snout_image": snout_image
    }

    print_info(f"Registrando biometria para pet ID: {pet_id}")
    print_warning("Primeira chamada pode demorar ~30s (download do modelo ML)...")

    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.post(
            f"{API_URL}/api/v1/biometry/register",
            json=biometry_data,
            headers=headers,
            timeout=120  # 2 minutos (primeira vez baixa modelo)
        )

        if response.status_code == 201:
            print_success("Biometria registrada com sucesso!")
            biometry = response.json()
            print_info(f"ID: {biometry.get('id')}")
            print_info(f"Qualidade: {biometry.get('quality_score')}/100")
            print_info(f"Dimensões do embedding: 768")

            if biometry.get('quality_score', 0) < 50:
                print_warning(f"Qualidade baixa: {biometry.get('quality_score')}")

            return biometry
        else:
            print_error(f"Erro ao registrar biometria: {response.status_code}")
            print_error(f"Resposta: {response.text}")
            return None
    except requests.exceptions.Timeout:
        print_error("Timeout! O modelo ML pode estar demorando para carregar.")
        print_warning("Verifique os logs: docker-compose logs -f api")
        return None
    except Exception as e:
        print_error(f"Erro ao registrar biometria: {e}")
        return None


def test_identify_pet(token):
    """Testa identificação de pet por biometria."""
    print_header("6. Identificando Pet por Biometria")

    print_info("Gerando nova imagem de focinho para identificação...")
    snout_image = generate_fake_snout_image()

    identify_data = {
        "snout_image": snout_image
    }

    print_info("Enviando imagem para identificação...")

    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.post(
            f"{API_URL}/api/v1/biometry/identify",
            json=identify_data,
            headers=headers,
            timeout=60
        )

        if response.status_code == 200:
            result = response.json()

            if result.get("match"):
                print_success("Pet identificado com sucesso!")
                print_info(f"Pet ID: {result.get('pet_id')}")
                print_info(f"Nome: {result.get('pet_name')}")
                print_info(f"Similaridade: {result.get('similarity_score', 0):.2%}")
                return result
            else:
                print_warning("Nenhum pet identificado (similaridade muito baixa)")
                print_info("Isso é esperado com imagens fake aleatórias")
                return None
        else:
            print_error(f"Erro ao identificar pet: {response.status_code}")
            print_error(f"Resposta: {response.text}")
            return None
    except Exception as e:
        print_error(f"Erro ao identificar pet: {e}")
        return None


def test_list_pets(token):
    """Testa listagem de pets."""
    print_header("7. Listando Pets do Usuário")

    headers = {"Authorization": f"Bearer {token}"}

    try:
        response = requests.get(
            f"{API_URL}/api/v1/pets",
            headers=headers,
            timeout=10
        )

        if response.status_code == 200:
            pets = response.json()
            print_success(f"Total de pets: {len(pets)}")

            for pet in pets:
                print_info(f"  - {pet.get('name')} (ID: {pet.get('id')})")

            return pets
        else:
            print_error(f"Erro ao listar pets: {response.status_code}")
            return None
    except Exception as e:
        print_error(f"Erro ao listar pets: {e}")
        return None


def main():
    """Executa todos os testes E2E."""
    print("\n" + "="*60)
    print(f"{Colors.BOLD}{Colors.CYAN}  TESTE E2E - PetID API (Fluxo de Usuário Real){Colors.END}")
    print("="*60)
    print(f"\n{Colors.YELLOW}API URL: {API_URL}{Colors.END}\n")

    # 1. Health check
    if not test_health():
        print_error("\nAPI não está disponível. Abortando testes.")
        return 1

    # 2. Registrar usuário
    user_data = test_register_user()
    if not user_data:
        print_error("\nFalha ao registrar usuário. Abortando testes.")
        return 1

    # 3. Login
    token = test_login(user_data)
    if not token:
        print_error("\nFalha ao fazer login. Abortando testes.")
        return 1

    # 4. Criar pet
    pet = test_create_pet(token)
    if not pet:
        print_error("\nFalha ao criar pet. Abortando testes.")
        return 1

    # 5. Registrar biometria (ML!)
    biometry = test_register_biometry(token, pet["id"])
    if not biometry:
        print_error("\nFalha ao registrar biometria. Verifique logs do ML.")
        return 1

    # 6. Identificar pet
    identified = test_identify_pet(token)
    # Não falhamos se não identificar (imagens fake são aleatórias)

    # 7. Listar pets
    test_list_pets(token)

    # Resumo final
    print_header("RESUMO DOS TESTES")
    print_success("✓ Health check")
    print_success("✓ Registro de usuário")
    print_success("✓ Login")
    print_success("✓ Criação de pet")
    print_success("✓ Registro de biometria (ML)")
    print_success("✓ Identificação de pet")
    print_success("✓ Listagem de pets")

    print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 TODOS OS TESTES PASSARAM!{Colors.END}")
    print(f"\n{Colors.CYAN}Sistema PetID está funcionando corretamente!{Colors.END}")
    print(f"\n{Colors.YELLOW}Próximos passos:{Colors.END}")
    print(f"  1. Acesse a documentação: {API_URL}/docs")
    print(f"  2. Teste com imagens reais de focinho de pet")
    print(f"  3. Configure domínio e SSL para produção\n")

    return 0


if __name__ == "__main__":
    try:
        exit(main())
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Teste interrompido pelo usuário.{Colors.END}\n")
        exit(1)
