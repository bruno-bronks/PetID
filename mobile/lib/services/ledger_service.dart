import 'dart:convert';
import 'package:crypto/crypto.dart';

class LedgerService {
  static final LedgerService _instance = LedgerService._internal();
  factory LedgerService() => _instance;
  LedgerService._internal();

  /// Gera um hash SHA-256 para um registro médico simulando um registro em blockchain.
  String generateMedicalHash({
    required int petId,
    required String recordType,
    required String data,
    required DateTime timestamp,
  }) {
    final payload = '$petId|$recordType|$data|${timestamp.toIso8601String()}';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Retorna um "Certificado de Autenticidade" visual para o registro.
  String getValidationSeal(String hash) {
    return 'BLOCKCHAIN-VERIFIED | HASH: ${hash.substring(0, 8).toUpperCase()}...';
  }
}
