import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// 城市选择状态管理
/// 存储用户手动选择的城市信息
class CitySelectionStore extends ChangeNotifier {
  static final CitySelectionStore _instance = CitySelectionStore._internal();
  factory CitySelectionStore() => _instance;
  CitySelectionStore._internal();

  CityInfo? _selectedCity;

  /// 获取当前选择的城市
  CityInfo? get selectedCity => _selectedCity;

  /// 设置选择的城市
  void setCity(CityInfo city) {
    _selectedCity = city;
    notifyListeners();
    print('📍 用户选择城市: ${city.name} (${city.adcode})');
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

