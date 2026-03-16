import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class PetDocument {
  final int id;
  final int petId;
  final String title;
  final String documentType;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final int? fileSize;
  final DateTime? documentDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetDocument({
    required this.id,
    required this.petId,
    required this.title,
    required this.documentType,
    this.description,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    this.fileSize,
    this.documentDate,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetDocument.fromJson(Map<String, dynamic> json) {
    return PetDocument(
      id: json['id'],
      petId: json['pet_id'],
      title: json['title'],
      documentType: json['document_type'],
      description: json['description'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      documentDate: json['document_date'] != null ? DateTime.parse(json['document_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get documentTypeLabel {
    switch (documentType) {
      case 'vaccination_card': return 'Carteira de Vacinação';
      case 'health_certificate': return 'Atestado de Saúde';
      case 'exam': return 'Exame';
      case 'prescription': return 'Receita';
      case 'other': return 'Outro';
      default: return documentType;
    }
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => fileType?.startsWith('image/') ?? false;
  bool get isPdf => fileType == 'application/pdf';
  
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
  
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }
}

class DocumentService {
  final _api = ApiService();

  Future<List<PetDocument>> listDocuments(int petId, {String? documentType}) async {
    String url = '/pets/$petId/documents';
    if (documentType != null) {
      url += '?document_type=$documentType';
    }
    final response = await _api.get(url);
    return (response as List).map((d) => PetDocument.fromJson(d)).toList();
  }

  Future<PetDocument> uploadDocument({
    required int petId,
    required String filePath,
    required String title,
    required String documentType,
    String? description,
    DateTime? documentDate,
    DateTime? expiryDate,
  }) async {
    final token = await _api.getAccessToken();
    final uri = Uri.parse('${_api.baseUrlValue}/pets/$petId/documents');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['title'] = title;
    request.fields['document_type'] = documentType;
    if (description != null) request.fields['description'] = description;
    if (documentDate != null) request.fields['document_date'] = documentDate.toIso8601String();
    if (expiryDate != null) request.fields['expiry_date'] = expiryDate.toIso8601String();
    
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      return PetDocument.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao fazer upload: ${response.body}');
    }
  }

  Future<String> getDownloadUrl(int petId, int documentId) async {
    final response = await _api.get('/pets/$petId/documents/$documentId/download');
    return response['download_url'];
  }

  Future<void> deleteDocument(int petId, int documentId) async {
    await _api.delete('/pets/$petId/documents/$documentId');
  }
}
