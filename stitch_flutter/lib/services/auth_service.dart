import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _nickname;
  String? _avatarUrl;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;

  void login(String token, {String? userId}) {
    ApiService.setToken(token);
    _isAuthenticated = true;
    _userId = userId;
    
    // 先尝试从缓存加载用户信息（立即显示）
    _loadUserProfileFromCache();
    
    // 然后从服务器获取最新信息（后台更新）
    _loadUserProfile();
    notifyListeners();
  }

  void logout() {
    ApiService.clearToken();
    _isAuthenticated = false;
    _nickname = null;
    _avatarUrl = null;
    
    // 清除缓存
    if (_userId != null) {
      CacheService().clearUserProfile(_userId!);
    }
    _userId = null;
    notifyListeners();
  }

  void checkAuthStatus() {
    _isAuthenticated = ApiService.isAuthenticated;
    if (_isAuthenticated) {
      // 先加载缓存
      _loadUserProfileFromCache();
      // 然后更新
      _loadUserProfile();
      notifyListeners();
    }
  }

  /// 从缓存加载用户信息（快速显示）
  void _loadUserProfileFromCache() {
    if (_userId == null) return;
    
    final cachedProfile = CacheService().getCachedUserProfile(_userId!);
    if (cachedProfile != null) {
      _nickname = cachedProfile['nickname'] as String?;
      _avatarUrl = cachedProfile['avatar_url'] as String?;
      print('✅ 从缓存加载用户信息: $_nickname');
      notifyListeners();
    }
  }

  /// 从服务器加载用户信息（后台更新）
  Future<void> _loadUserProfile() async {
    if (!_isAuthenticated) return;
    
    try {
      final profile = await ApiService.getUserProfile();
      _nickname = profile['nickname'];
      _avatarUrl = profile['avatar_url'];
      
      // 保存到缓存
      if (_userId != null) {
        await CacheService().cacheUserProfile(
          userId: _userId!,
          nickname: _nickname,
          avatarUrl: _avatarUrl,
        );
      }
      
      notifyListeners();
    } catch (e) {
      print('获取用户资料失败: $e');
      // 如果获取失败且缓存也没有，使用默认值
      if (_nickname == null) {
        _nickname = '用户';
        notifyListeners();
      }
    }
  }

  /// 设置用户ID（用于缓存）
  void setUserId(String userId) {
    _userId = userId;
    _loadUserProfileFromCache();
    _loadUserProfile();
  }
}