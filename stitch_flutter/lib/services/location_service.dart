import 'dart:convert';
import 'package:http/http.dart' as http;

/// 位置服务 - 获取用户城市信息
class LocationService {
  static const String _apiKey = '1beb15f42b6dd9b5381b05ce51d81bd2';
  
  /// 获取默认城市（北京）
  /// 注意：在Web环境中，地理定位可能受限，这里提供一个后备方案
  static CityInfo getDefaultCity() {
    return CityInfo(
      name: '北京市',
      adcode: '110000',
    );
  }

  /// 通过IP获取城市信息（高德IP定位API）
  /// 这个API可以在Web环境中使用，不需要权限
  static Future<CityInfo> getCityByIP() async {
    try {
      final url = Uri.parse('https://restapi.amap.com/v3/ip?key=$_apiKey&output=JSON');
      
      print('📍 请求IP定位API: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('📍 IP定位API响应: $data');
        
        if (data['status'] == '1' && data['adcode'] != null) {
          return CityInfo(
            name: data['city'] ?? data['province'] ?? '北京市',
            adcode: data['adcode'],
          );
        }
      }
    } catch (e) {
      print('❌ IP定位异常: $e');
    }
    
    // 如果失败，返回默认城市
    return getDefaultCity();
  }

  /// 搜索城市获取adcode
  /// [keyword] 城市名称关键词
  static Future<List<CityInfo>> searchCity(String keyword) async {
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/config/district?key=$_apiKey&keywords=$keyword&subdistrict=0&output=JSON'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == '1' && data['districts'] != null) {
          final districts = data['districts'] as List;
          return districts.map((d) => CityInfo(
            name: d['name'] ?? '',
            adcode: d['adcode'] ?? '',
          )).toList();
        }
      }
    } catch (e) {
      print('❌ 搜索城市异常: $e');
    }
    
    return [];
  }

  /// 获取常用城市列表
  static List<CityInfo> getPopularCities() {
    return [
      CityInfo(name: '北京市', adcode: '110000'),
      CityInfo(name: '上海市', adcode: '310000'),
      CityInfo(name: '广州市', adcode: '440100'),
      CityInfo(name: '深圳市', adcode: '440300'),
      CityInfo(name: '杭州市', adcode: '330100'),
      CityInfo(name: '成都市', adcode: '510100'),
      CityInfo(name: '武汉市', adcode: '420100'),
      CityInfo(name: '西安市', adcode: '610100'),
    ];
  }
}

/// 城市信息
class CityInfo {
  final String name;   // 城市名称
  final String adcode; // 城市编码

  CityInfo({
    required this.name,
    required this.adcode,
  });

  @override
  String toString() => '$name ($adcode)';
}

