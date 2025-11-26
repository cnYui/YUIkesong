import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// 高德天气API服务
class WeatherService {
  static String get _apiKey => ApiConfig.amapApiKey;
  static const String _baseUrl = 'https://restapi.amap.com/v3/weather/weatherInfo';

  /// 获取实时天气
  /// [cityCode] 城市编码（adcode）
  static Future<WeatherInfo?> getRealTimeWeather(String cityCode) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey&city=$cityCode&extensions=base&output=JSON');
      
      print('🌤️ 请求天气API: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('🌤️ 天气API响应: $data');
        
        if (data['status'] == '1' && data['lives'] != null && data['lives'].isNotEmpty) {
          return WeatherInfo.fromJson(data['lives'][0]);
        } else {
          print('❌ 天气API返回错误: ${data['info']}');
          return null;
        }
      } else {
        print('❌ 天气API请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 获取天气信息异常: $e');
      return null;
    }
  }

  /// 获取预报天气（未来几天）
  static Future<WeatherForecast?> getForecastWeather(String cityCode) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey&city=$cityCode&extensions=all&output=JSON');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == '1' && data['forecasts'] != null && data['forecasts'].isNotEmpty) {
          return WeatherForecast.fromJson(data['forecasts'][0]);
        }
      }
      return null;
    } catch (e) {
      print('❌ 获取天气预报异常: $e');
      return null;
    }
  }
}

/// 实时天气信息
class WeatherInfo {
  final String province;      // 省份
  final String city;          // 城市
  final String adcode;        // 区域编码
  final String weather;       // 天气现象（汉字）
  final String temperature;   // 实时气温
  final String windDirection; // 风向
  final String windPower;     // 风力
  final String humidity;      // 湿度
  final String reportTime;    // 数据发布时间

  WeatherInfo({
    required this.province,
    required this.city,
    required this.adcode,
    required this.weather,
    required this.temperature,
    required this.windDirection,
    required this.windPower,
    required this.humidity,
    required this.reportTime,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      adcode: json['adcode'] ?? '',
      weather: json['weather'] ?? '',
      temperature: json['temperature']?.toString() ?? '0',
      windDirection: json['winddirection'] ?? '',
      windPower: json['windpower'] ?? '',
      humidity: json['humidity']?.toString() ?? '0',
      reportTime: json['reporttime'] ?? '',
    );
  }

  /// 根据天气描述获取天气类型
  WeatherType get weatherType {
    if (weather.contains('晴')) return WeatherType.sunny;
    if (weather.contains('云') || weather.contains('阴')) return WeatherType.cloudy;
    if (weather.contains('雨')) return WeatherType.rainy;
    if (weather.contains('雪')) return WeatherType.snowy;
    if (weather.contains('雾') || weather.contains('霾')) return WeatherType.foggy;
    return WeatherType.cloudy;
  }
}

/// 天气预报信息
class WeatherForecast {
  final String city;
  final List<DayForecast> forecasts;

  WeatherForecast({
    required this.city,
    required this.forecasts,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final casts = json['casts'] as List? ?? [];
    return WeatherForecast(
      city: json['city'] ?? '',
      forecasts: casts.map((e) => DayForecast.fromJson(e)).toList(),
    );
  }
}

/// 单日预报
class DayForecast {
  final String date;
  final String week;
  final String dayWeather;
  final String nightWeather;
  final String dayTemp;
  final String nightTemp;

  DayForecast({
    required this.date,
    required this.week,
    required this.dayWeather,
    required this.nightWeather,
    required this.dayTemp,
    required this.nightTemp,
  });

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    return DayForecast(
      date: json['date'] ?? '',
      week: json['week'] ?? '',
      dayWeather: json['dayweather'] ?? '',
      nightWeather: json['nightweather'] ?? '',
      dayTemp: json['daytemp']?.toString() ?? '0',
      nightTemp: json['nighttemp']?.toString() ?? '0',
    );
  }
}

/// 天气类型枚举
enum WeatherType {
  sunny,   // 晴天
  cloudy,  // 多云/阴天
  rainy,   // 雨天
  snowy,   // 雪天
  foggy,   // 雾/霾
}

