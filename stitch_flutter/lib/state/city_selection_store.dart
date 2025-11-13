import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../pages/city_selection_page.dart';

/// 城市选择状态管理
/// 存储用户手动选择的城市信息，并持久化到数据库
class CitySelectionStore extends ChangeNotifier {
  static final CitySelectionStore _instance = CitySelectionStore._internal();
  factory CitySelectionStore() => _instance;
  CitySelectionStore._internal();

  CityInfo? _selectedCity;

  /// 获取当前选择的城市
  CityInfo? get selectedCity => _selectedCity;

  /// 设置选择的城市（保存到数据库）
  Future<void> setCity(CityInfo city) async {
    _selectedCity = city;
    notifyListeners();
    print('📍 用户选择城市: ${city.name} (${city.adcode})');
    
    // 保存到数据库
    try {
      await ApiService.updateUserProfile(city: city.adcode);
      print('✅ 城市已保存到数据库: ${city.name} (${city.adcode})');
    } catch (e) {
      print('❌ 保存城市到数据库失败: $e');
      // 即使保存失败，也保持本地状态，因为用户已经选择了
    }
  }

  /// 从数据库加载保存的城市
  Future<void> loadSavedCity() async {
    try {
      if (!ApiService.isAuthenticated) {
        print('⚠️ 用户未登录，无法加载保存的城市');
        return;
      }
      
      final profile = await ApiService.getUserProfile();
      final cityAdcode = profile['city'] as String?;
      
      if (cityAdcode != null && cityAdcode.isNotEmpty) {
        // 根据adcode查找城市信息
        final city = _findCityByAdcode(cityAdcode);
        if (city != null) {
          _selectedCity = city;
          notifyListeners();
          print('📍 从数据库加载保存的城市: ${city.name} (${city.adcode})');
        } else {
          print('⚠️ 未找到adcode对应的城市: $cityAdcode');
        }
      } else {
        print('📍 用户未在数据库中保存城市');
      }
    } catch (e) {
      print('❌ 从数据库加载城市失败: $e');
    }
  }

  /// 根据adcode查找城市信息
  CityInfo? _findCityByAdcode(String adcode) {
    // 从城市选择页面的城市列表中查找
    final cities = CitySelectionPage.getCitiesList();
    try {
      return cities.firstWhere(
        (city) => city.adcode == adcode,
      );
    } catch (e) {
      // 如果找不到，尝试根据adcode的前2位匹配省份
      final provinceCode = adcode.length >= 2 ? adcode.substring(0, 2) : '';
      if (provinceCode.isNotEmpty) {
        // 查找匹配的城市（使用adcode前缀匹配）
        for (var city in cities) {
          if (city.adcode.startsWith(provinceCode)) {
            return city;
          }
        }
      }
      print('⚠️ 未找到adcode对应的城市: $adcode');
      return null;
    }
  }

  /// 清除选择的城市（使用IP定位）
  void clearSelection() {
    _selectedCity = null;
    notifyListeners();
    print('📍 清除城市选择，将使用IP定位');
  }

  /// 检查是否有手动选择的城市
  bool get hasManualSelection => _selectedCity != null;
}

