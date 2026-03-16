import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}

class OfflineException extends ApiException {
  OfflineException() : super('Ação Indisponível Offline. Conecte-se à internet para enviar dados.');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Sessão expirada. Faça login novamente.', 401);
}

class ApiService {
  // Configure com o IP/domínio da sua VPS
  // Para emulador Android use 10.0.2.2, para iOS use localhost
  // static const String baseUrl = 'http://10.0.2.2:8001/api/v1'; // Emulador
  static const String baseUrl = 'https://148.230.79.134/api/v1'; // VPS Produção (HTTPS)
  
  // Callback para quando o token expirar e não puder ser renovado
  Function? onSessionExpired;
  
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  
  Future<String?> _getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString('access_token');
  }
  
  // Método público para obter o token (usado pelo DocumentService)
  Future<String?> getAccessToken() async => _getAccessToken();
  
  // Getter para acessar a baseUrl
  String get baseUrlValue => baseUrl;
  
  /// Converte um caminho relativo em uma URL completa
  String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Remove /api/v1 do final da baseUrl para obter a raiz do servidor
    final rootUrl = baseUrl.replaceAll('/api/v1', '');
    return '$rootUrl${path.startsWith('/') ? '' : '/'}$path';
  }
  
  Future<String?> _getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString('refresh_token');
  }
  
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await _prefs;
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }
  
  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  /// Tenta renovar o access token usando o refresh token
  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final url = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(
          data['access_token'],
          data['refresh_token'],
        );
        return true;
      }
    } catch (e) {
      // Falha ao renovar token
    }
    
    return false;
  }
  
  /// Executa uma requisição com retry automático em caso de token expirado
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    
    // Se receber 401, tenta renovar o token e refaz a requisição
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await request();
      } else {
        // Não conseguiu renovar - NÃO limpa tokens automaticamente
        // O usuário pode tentar novamente
        throw UnauthorizedException();
      }
    }
    
    return response;
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }
    
    String message = 'Erro ao processar requisição';
    try {
      final error = json.decode(response.body);
      message = error['detail'] ?? message;
    } catch (_) {}
    
    throw ApiException(message, response.statusCode);
  }
  
  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult is List) {
       return connectivityResult.any((r) => r != ConnectivityResult.none);
    }
    return connectivityResult != ConnectivityResult.none;
  }

  Future<dynamic> get(String endpoint) async {
    final isOnline = await _isOnline();
    
    if (!isOnline) {
      // Offline: Tenta buscar do cache NoSQL local
      final cachedData = CacheService().get(endpoint);
      if (cachedData != null) {
        print('⏳ [OFFLINE CACHE HIT]: $endpoint');
        return cachedData;
      }
      throw ApiException('Sem conexão com a internet e nenhum cache local disponível.');
    }
    
    // Online: Faz requisição ao backend
    final response = await _executeWithRetry(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      return http.get(url, headers: headers);
    });
    
    final parsedData = _handleResponse(response);
    
    // Salva cópia fresca no Cache NoSQL invisivelmente
    if (parsedData != null) {
      await CacheService().save(endpoint, parsedData);
    }
    
    return parsedData;
  }
  
  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool includeAuth = true}) async {
    if (!await _isOnline()) throw OfflineException();
    
    final response = await _executeWithRetry(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      return http.post(url, headers: headers, body: json.encode(data));
    });
    
    return _handleResponse(response);
  }
  
  /// POST com form-data (para OAuth2)
  Future<dynamic> postForm(String endpoint, Map<String, String> data) async {
    if (!await _isOnline()) throw OfflineException();
    
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(url, body: data).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Falha na conexão: $e');
    }
  }
  
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    if (!await _isOnline()) throw OfflineException();
    
    final response = await _executeWithRetry(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      return http.patch(url, headers: headers, body: json.encode(data));
    });
    
    return _handleResponse(response);
  }
  
  Future<void> delete(String endpoint) async {
    if (!await _isOnline()) throw OfflineException();
    
    final response = await _executeWithRetry(() async {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      return http.delete(url, headers: headers);
    });
    
    if (response.statusCode >= 400) {
      _handleResponse(response);
    }
  }
  
  Future<dynamic> uploadFile(String endpoint, String filePath, String fieldName) async {
    if (!await _isOnline()) throw OfflineException();
    
    final token = await _getAccessToken();
    final url = Uri.parse('$baseUrl$endpoint');
    
    final request = http.MultipartRequest('POST', url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    // Se 401, tenta renovar e refazer
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final newToken = await _getAccessToken();
        final newRequest = http.MultipartRequest('POST', url);
        newRequest.headers['Authorization'] = 'Bearer $newToken';
        newRequest.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
        
        final newStreamedResponse = await newRequest.send();
        final newResponse = await http.Response.fromStream(newStreamedResponse);
        return _handleResponse(newResponse);
      } else {
        await clearTokens();
        onSessionExpired?.call();
        throw UnauthorizedException();
      }
    }
    
    return _handleResponse(response);
  }
}
