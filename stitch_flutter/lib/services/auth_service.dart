import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _nickname;

  bool get isAuthenticated => _isAuthenticated;
  String? get nickname => _nickname;

  void login(String token) {
    ApiService.setToken(token);
    _isAuthenticated = true;
    // 登录成功后获取用户信息
    _loadUserProfile();
    notifyListeners();
  }

  void logout() {
    ApiService.clearToken();
    _isAuthenticated = false;
    _nickname = null;
    notifyListeners();
  }

  void checkAuthStatus() {
    _isAuthenticated = ApiService.isAuthenticated;
    if (_isAuthenticated) {
      _loadUserProfile();
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    if (!_isAuthenticated) return;
    
    try {
      final profile = await ApiService.getUserProfile();
      _nickname = profile['nickname'];
      notifyListeners();
    } catch (e) {
      print('获取用户资料失败: $e');
      // 如果获取失败，使用默认值
      _nickname = '用户';
      notifyListeners();
    }
  }
}