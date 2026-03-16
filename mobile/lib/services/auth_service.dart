import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  
  AuthService() {
    // Configura callback para sessão expirada
    _api.onSessionExpired = _handleSessionExpired;
  }
  
  void _handleSessionExpired() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    notifyListeners();
  }
  
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    
    if (_accessToken != null) {
      try {
        final user = await _api.get('/auth/me');
        _currentUser = user;
        notifyListeners();
        return true;
      } catch (e) {
        await logout();
        return false;
      }
    }
    
    return false;
  }
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // OAuth2 espera form-data com 'username' (não 'email')
      final response = await _api.postForm('/auth/login', {
        'username': email,
        'password': password,
      });
      
      _accessToken = response['access_token'];
      _refreshToken = response['refresh_token'];
      
      // Salva tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      
      // Login bem-sucedido! Não precisa buscar /auth/me agora
      // Os dados do usuário serão carregados quando necessário
      _currentUser = {'email': email};
      
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _api.post('/auth/register', {
        'email': email,
        'password': password,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      }, includeAuth: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateProfile({String? fullName, String? phone}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    
    if (data.isEmpty) return;
    
    final response = await _api.patch('/auth/me', data);
    _currentUser = response;
    notifyListeners();
  }
  
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    notifyListeners();
  }
}
