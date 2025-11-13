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
  /// API文档: https://lbs.amap.com/api/webservice/guide/api/ipconfig
  /// 
  /// 注意：如果返回空数组，可能的原因：
  /// - 局域网IP（内网地址，如 192.168.x.x, 10.x.x.x）
  /// - 使用了代理/VPN，导致IP无法识别
  /// - 国外IP地址（高德仅支持国内IP定位）
  /// - IP地址格式非法
  static Future<CityInfo> getCityByIP() async {
    try {
      final url = Uri.parse('https://restapi.amap.com/v3/ip?key=$_apiKey&output=JSON');
      
      print('📍 请求IP定位API: $url');
      print('   说明：如果不传ip参数，API会使用请求来源的IP地址');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('📍 IP定位API响应: $data');
        
        // 检查status（可能是字符串"1"或整数1）
        final status = data['status'];
        final isSuccess = status == '1' || status == 1;
        
        if (isSuccess) {
          // 安全地提取字符串字段（处理可能是数组的情况）
          String? getStringValue(dynamic value) {
            if (value == null) return null;
            if (value is String && value.isNotEmpty) return value;
            if (value is List && value.isEmpty) return null;
            // 如果是数组但非空，尝试取第一个元素
            if (value is List && value.isNotEmpty) {
              final first = value[0];
              if (first is String) return first;
            }
            return null;
          }
          
          final province = getStringValue(data['province']);
          final city = getStringValue(data['city']);
          final adcode = getStringValue(data['adcode']);
          
          // 如果adcode有效，使用返回的城市信息
          if (adcode != null && adcode.isNotEmpty) {
            final cityName = city ?? province ?? '北京市';
            print('📍 解析成功: 城市=$cityName, adcode=$adcode');
            return CityInfo(
              name: cityName,
              adcode: adcode,
            );
          } else {
            // 详细说明失败原因
            print('⚠️ IP定位失败 - 返回的adcode为空或无效');
            print('   可能原因：');
            print('   1. 当前IP为局域网IP（内网地址）');
            print('   2. 使用了代理/VPN，IP地址无法识别');
            print('   3. IP地址为国外地址（高德仅支持国内IP定位）');
            print('   4. IP地址格式非法');
            print('   解决方案：将使用默认城市（北京）获取天气信息');
          }
        } else {
          print('⚠️ IP定位API返回失败: ${data['info']}');
        }
      } else {
        print('❌ IP定位API请求失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ IP定位异常: $e');
    }
    
    // 如果失败，返回默认城市
    print('📍 使用默认城市: 北京市 (110000)');
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

