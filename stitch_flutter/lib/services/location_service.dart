import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 位置服务 - 获取用户城市信息
class LocationService {
  static String get _apiKey => ApiConfig.amapApiKey;
  
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

  /// 获取所有省份列表
  /// 使用高德地图行政区划API，获取省级行政区
  static Future<List<ProvinceInfo>> getProvinces() async {
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/config/district?key=$_apiKey&keywords=中国&subdistrict=1&extensions=base&output=JSON'
      );
      
      print('📍 请求省份列表API: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == '1' && data['districts'] != null) {
          final districts = data['districts'] as List;
          if (districts.isNotEmpty) {
            // 第一层是中国，第二层是省份
            final china = districts[0];
            final provinces = china['districts'] as List? ?? [];
            
            return provinces.map((p) => ProvinceInfo(
              name: p['name'] ?? '',
              adcode: p['adcode'] ?? '',
            )).toList();
          }
        }
      }
    } catch (e) {
      print('❌ 获取省份列表异常: $e');
    }
    
    // 如果失败，返回常用省份列表
    return _getDefaultProvinces();
  }

  /// 根据省份获取城市列表
  /// [provinceAdcode] 省份编码
  static Future<List<CityInfo>> getCitiesByProvince(String provinceAdcode) async {
    try {
      final url = Uri.parse(
        'https://restapi.amap.com/v3/config/district?key=$_apiKey&keywords=$provinceAdcode&subdistrict=1&extensions=base&output=JSON'
      );
      
      print('📍 请求城市列表API: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == '1' && data['districts'] != null) {
          final districts = data['districts'] as List;
          if (districts.isNotEmpty) {
            // 第一层是省份，第二层是城市
            final province = districts[0];
            final cities = province['districts'] as List? ?? [];
            
            return cities.map((c) => CityInfo(
              name: c['name'] ?? '',
              adcode: c['adcode'] ?? '',
            )).toList();
          }
        }
      }
    } catch (e) {
      print('❌ 获取城市列表异常: $e');
    }
    
    return [];
  }

  /// 获取默认省份列表（常用省份）
  static List<ProvinceInfo> _getDefaultProvinces() {
    return [
      ProvinceInfo(name: '北京市', adcode: '110000'),
      ProvinceInfo(name: '天津市', adcode: '120000'),
      ProvinceInfo(name: '河北省', adcode: '130000'),
      ProvinceInfo(name: '山西省', adcode: '140000'),
      ProvinceInfo(name: '内蒙古自治区', adcode: '150000'),
      ProvinceInfo(name: '辽宁省', adcode: '210000'),
      ProvinceInfo(name: '吉林省', adcode: '220000'),
      ProvinceInfo(name: '黑龙江省', adcode: '230000'),
      ProvinceInfo(name: '上海市', adcode: '310000'),
      ProvinceInfo(name: '江苏省', adcode: '320000'),
      ProvinceInfo(name: '浙江省', adcode: '330000'),
      ProvinceInfo(name: '安徽省', adcode: '340000'),
      ProvinceInfo(name: '福建省', adcode: '350000'),
      ProvinceInfo(name: '江西省', adcode: '360000'),
      ProvinceInfo(name: '山东省', adcode: '370000'),
      ProvinceInfo(name: '河南省', adcode: '410000'),
      ProvinceInfo(name: '湖北省', adcode: '420000'),
      ProvinceInfo(name: '湖南省', adcode: '430000'),
      ProvinceInfo(name: '广东省', adcode: '440000'),
      ProvinceInfo(name: '广西壮族自治区', adcode: '450000'),
      ProvinceInfo(name: '海南省', adcode: '460000'),
      ProvinceInfo(name: '重庆市', adcode: '500000'),
      ProvinceInfo(name: '四川省', adcode: '510000'),
      ProvinceInfo(name: '贵州省', adcode: '520000'),
      ProvinceInfo(name: '云南省', adcode: '530000'),
      ProvinceInfo(name: '西藏自治区', adcode: '540000'),
      ProvinceInfo(name: '陕西省', adcode: '610000'),
      ProvinceInfo(name: '甘肃省', adcode: '620000'),
      ProvinceInfo(name: '青海省', adcode: '630000'),
      ProvinceInfo(name: '宁夏回族自治区', adcode: '640000'),
      ProvinceInfo(name: '新疆维吾尔自治区', adcode: '650000'),
    ];
  }
}

/// 省份信息
class ProvinceInfo {
  final String name;   // 省份名称
  final String adcode; // 省份编码

  ProvinceInfo({
    required this.name,
    required this.adcode,
  });

  @override
  String toString() => '$name ($adcode)';
}

/// 城市信息
class CityInfo {
  final String name;   // 城市名称
  final String adcode; // 城市编码

  const CityInfo({
    required this.name,
    required this.adcode,
  });

  @override
  String toString() => '$name ($adcode)';
}

