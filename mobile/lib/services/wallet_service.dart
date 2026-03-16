import 'dart:convert';
import 'package:flutter/foundation.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  /// Gera um payload JSON que representa o cartão de identificação do pet
  /// para ser usado por integradores de Wallet (Apple PKPass ou Google Pay passes)
  Future<String> generatePetPassJson(Map<String, dynamic> pet) async {
    try {
      // Estrutura básica de um "Event Ticket" ou "Generic Pass" simplificado
      final passData = {
        "passTypeIdentifier": "pass.com.petid.identification",
        "formatVersion": 1,
        "organizationName": "PetID",
        "description": "Cartão de Identificação de ${pet['name']}",
        "logoText": "PetID Identification",
        "foregroundColor": "rgb(255, 255, 255)",
        "backgroundColor": "rgb(124, 58, 237)", // Purple
        "generic": {
          "primaryFields": [
            {
              "key": "pet_name",
              "label": "PET",
              "value": pet['name'] ?? 'N/A'
            }
          ],
          "secondaryFields": [
            {
              "key": "breed",
              "label": "RAÇA",
              "value": pet['breed'] ?? 'SRD'
            },
            {
              "key": "owner",
              "label": "TUTOR",
              "value": pet['owner_name'] ?? 'Identificado no App'
            }
          ],
          "auxiliaryFields": [
            {
              "key": "id",
              "label": "PET ID",
              "value": "#${pet['id']}"
            },
            {
              "key": "microchip",
              "label": "MICROCHIP",
              "value": pet['microchip'] ?? '—'
            }
          ],
          "backFields": [
            {
              "key": "info",
              "label": "SOBRE O PETID",
              "value": "Este cartão é gerado digitalmente pelo PetID. Acesse o app para ver o prontuário completo."
            }
          ]
        },
        "barcode": {
          "format": "PKBarcodeFormatQR",
          "message": "https://petid.app/p/${pet['id']}",
          "messageEncoding": "iso-8859-1"
        }
      };

      return jsonEncode(passData);
    } catch (e) {
      debugPrint('Erro ao gerar dados do Wallet: $e');
      return '';
    }
  }

  /// No futuro, esta função enviará o JSON para um backend que assina o arquivo .pkpass
  /// ou usará um plugin nativo para adicionar ao Google Wallet.
  Future<bool> addToWallet(Map<String, dynamic> pet) async {
    final json = await generatePetPassJson(pet);
    if (json.isEmpty) return false;
    
    // Simulação de exportação
    debugPrint('Simulando exportação para Wallet de: ${pet['name']}');
    // Em uma implementação real usaríamos:
    // https://pub.dev/packages/apple_native_passbook (para iOS)
    // Pass2U ou integração direta via API do Google Wallet (para Android)
    
    return true;
  }
}
