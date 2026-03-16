import 'api_service.dart';

class AttachmentService {
  final ApiService _api = ApiService();
  
  /// Lista anexos de um registro médico
  Future<List<dynamic>> listAttachments(int recordId) async {
    final response = await _api.get('/records/$recordId/attachments');
    return response as List<dynamic>;
  }
  
  /// Obtém detalhes de um anexo com URL de download
  Future<Map<String, dynamic>> getAttachment(int recordId, int attachmentId) async {
    final response = await _api.get('/records/$recordId/attachments/$attachmentId');
    return response;
  }
  
  /// Faz upload de um anexo
  Future<Map<String, dynamic>> uploadAttachment(int recordId, String filePath) async {
    final response = await _api.uploadFile(
      '/records/$recordId/attachments',
      filePath,
      'file',
    );
    return response;
  }
  
  /// Deleta um anexo
  Future<void> deleteAttachment(int recordId, int attachmentId) async {
    await _api.delete('/records/$recordId/attachments/$attachmentId');
  }
  
  /// Retorna a URL de download direto (redireciona para presigned URL)
  String getDownloadUrl(int recordId, int attachmentId) {
    return '${ApiService.baseUrl}/records/$recordId/attachments/$attachmentId/download';
  }
}

