# PetID Mobile App

Aplicativo Flutter para gerenciamento de prontuários de pets.

## Configuração

1. Instale o Flutter: https://flutter.dev/docs/get-started/install

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure a URL da API em `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://SEU_IP_OU_DOMINIO/api';
```

4. Execute o app:
```bash
flutter run
```

## Próximos passos

- Implementar tela de cadastro de pet
- Implementar tela de detalhes do pet
- Implementar tela de prontuário (timeline)
- Implementar upload de anexos
- Implementar captura de focinho (câmera)

