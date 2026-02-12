# 🔥 Configuração do Firebase para PetID

## Passo 1: Criar Projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Clique em **"Adicionar projeto"**
3. Nome do projeto: `PetID`
4. Desative Google Analytics (opcional)
5. Clique em **"Criar projeto"**

## Passo 2: Adicionar App Android

1. No painel do projeto, clique em **"Android"** (ícone do robô)
2. Preencha os dados:
   - **Nome do pacote Android**: `pet.petapet.petid`
   - **Apelido do app**: PetID
   - **Certificado SHA-1**: (opcional para teste, necessário para produção)
3. Clique em **"Registrar app"**

## Passo 3: Baixar google-services.json

1. Clique em **"Baixar google-services.json"**
2. Mova o arquivo para:
   ```
   mobile/android/app/google-services.json
   ```

## Passo 4: Configurar Cloud Messaging

1. No menu lateral, vá em **"Engage > Messaging"**
2. Clique em **"Criar sua primeira campanha"** (apenas para testar)
3. Anote a **Server Key** (para o backend enviar notificações)

## Passo 5: Testar

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

---

## Estrutura Final

```
mobile/
├── android/
│   └── app/
│       └── google-services.json  ← ADICIONE AQUI
├── lib/
│   └── services/
│       └── notification_service.dart
└── pubspec.yaml
```

## Verificar Funcionamento

No app, acesse **Configurações > Notificações** e clique em **"Testar Notificação"**.

---

## Backend: Enviar Notificações (Opcional)

Para enviar notificações do backend, adicione ao servidor:

### 1. Instalar dependência Python:
```bash
pip install firebase-admin
```

### 2. Baixar chave do serviço:
- Firebase Console > Configurações do projeto > Contas de serviço
- Gerar nova chave privada
- Salvar como `firebase-admin-key.json`

### 3. Código Python para enviar:
```python
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate("firebase-admin-key.json")
firebase_admin.initialize_app(cred)

def send_vaccine_reminder(token: str, pet_name: str, vaccine_name: str, days: int):
    message = messaging.Message(
        notification=messaging.Notification(
            title="💉 Lembrete de Vacina",
            body=f"{pet_name} precisa tomar {vaccine_name} em {days} dias!",
        ),
        token=token,
    )
    response = messaging.send(message)
    print(f"Notificação enviada: {response}")
```

---

## Troubleshooting

### Erro: "google-services.json not found"
- Verifique se o arquivo está em `android/app/google-services.json`

### Erro: "Firebase not initialized"
- Execute `flutter clean && flutter pub get`

### Notificações não aparecem
- Verifique permissões no celular
- Teste com `adb logcat | grep Firebase`
