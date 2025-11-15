import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地缓存服务
/// 用于缓存用户信息、天气等数据，减少数据库查询
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  /// 初始化缓存服务
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== 用户信息缓存 ====================

  /// 缓存用户信息
  Future<void> cacheUserProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    await init();
    if (_prefs == null) return;

    final userKey = 'user_profile_$userId';
    final profileData = {
      'nickname': nickname ?? '',
      'avatar_url': avatarUrl ?? '',
      'cached_at': DateTime.now().toIso8601String(),
    };

    await _prefs!.setString(userKey, json.encode(profileData));
    print('✅ 已缓存用户信息: $nickname');
  }

  /// 获取缓存的用户信息
  Map<String, dynamic>? getCachedUserProfile(String userId) {
    if (_prefs == null) return null;

    final userKey = 'user_profile_$userId';
    final cachedData = _prefs!.getString(userKey);

    if (cachedData == null) return null;

    try {
      final profileData = json.decode(cachedData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(profileData['cached_at'] as String);
      final now = DateTime.now();
      
      // 缓存有效期：24小时
      if (now.difference(cachedAt).inHours > 24) {
        print('⚠️ 用户信息缓存已过期');
        _prefs!.remove(userKey);
        return null;
      }

      return {
        'nickname': profileData['nickname'] ?? '',
        'avatar_url': profileData['avatar_url'] ?? '',
      };
    } catch (e) {
      print('❌ 解析用户信息缓存失败: $e');
      _prefs!.remove(userKey);
      return null;
    }
  }

  /// 清除用户信息缓存
  Future<void> clearUserProfile(String userId) async {
    await init();
    if (_prefs == null) return;

    final userKey = 'user_profile_$userId';
    await _prefs!.remove(userKey);
    print('🗑️ 已清除用户信息缓存');
  }

  // ==================== 天气信息缓存 ====================

  /// 缓存天气信息
  Future<void> cacheWeather({
    required String cityCode,
    required Map<String, dynamic> weatherData,
  }) async {
    await init();
    if (_prefs == null) return;

    final weatherKey = 'weather_$cityCode';
    final cacheData = {
      'weather_data': weatherData,
      'cached_at': DateTime.now().toIso8601String(),
    };

    await _prefs!.setString(weatherKey, json.encode(cacheData));
    print('✅ 已缓存天气信息: $cityCode');
  }

  /// 获取缓存的天气信息
  Map<String, dynamic>? getCachedWeather(String cityCode) {
    if (_prefs == null) return null;

    final weatherKey = 'weather_$cityCode';
    final cachedData = _prefs!.getString(weatherKey);

    if (cachedData == null) return null;

    try {
      final cacheData = json.decode(cachedData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at'] as String);
      final now = DateTime.now();
      
      // 缓存有效期：1小时
      if (now.difference(cachedAt).inHours > 1) {
        print('⚠️ 天气信息缓存已过期');
        _prefs!.remove(weatherKey);
        return null;
      }

      return cacheData['weather_data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ 解析天气信息缓存失败: $e');
      _prefs!.remove(weatherKey);
      return null;
    }
  }

  /// 清除天气信息缓存
  Future<void> clearWeather(String cityCode) async {
    await init();
    if (_prefs == null) return;

    final weatherKey = 'weather_$cityCode';
    await _prefs!.remove(weatherKey);
    print('🗑️ 已清除天气信息缓存');
  }

  // ==================== 通用缓存方法 ====================

  /// 缓存任意数据
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? expiry}) async {
    await init();
    if (_prefs == null) return;

    final cacheData = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
      'expiry_hours': expiry?.inHours ?? 24,
    };

    await _prefs!.setString(key, json.encode(cacheData));
  }

  /// 获取缓存的任意数据
  Map<String, dynamic>? getCachedData(String key) {
    if (_prefs == null) return null;

    final cachedData = _prefs!.getString(key);
    if (cachedData == null) return null;

    try {
      final cacheData = json.decode(cachedData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at'] as String);
      final expiryHours = cacheData['expiry_hours'] as int? ?? 24;
      final now = DateTime.now();
      
      if (now.difference(cachedAt).inHours > expiryHours) {
        _prefs!.remove(key);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ 解析缓存数据失败: $e');
      _prefs!.remove(key);
      return null;
    }
  }

  /// 清除所有缓存
  Future<void> clearAll() async {
    await init();
    if (_prefs == null) return;

    await _prefs!.clear();
    print('🗑️ 已清除所有缓存');
  }

  /// 清除指定前缀的所有缓存
  Future<void> clearByPrefix(String prefix) async {
    await init();
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await _prefs!.remove(key);
      }
    }
    print('🗑️ 已清除前缀为 "$prefix" 的所有缓存');
  }
}

