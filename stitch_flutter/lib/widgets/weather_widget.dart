import 'package:flutter/material.dart';
import 'package:stitch_flutter/services/weather_service.dart';
import 'package:stitch_flutter/services/location_service.dart';
import 'package:stitch_flutter/widgets/weather_icons.dart';

/// 天气显示组件
/// 动态获取并显示天气信息
class WeatherWidget extends StatefulWidget {
  final bool showCityName; // 是否显示城市名称
  final double iconSize;   // 图标大小
  final TextStyle? textStyle; // 文字样式

  const WeatherWidget({
    super.key,
    this.showCityName = true,
    this.iconSize = 48.0,
    this.textStyle,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherInfo? _weatherInfo;
  CityInfo? _cityInfo;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  /// 加载天气数据
  Future<void> _loadWeather() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 1. 获取用户城市
      final city = await LocationService.getCityByIP();
      print('📍 当前城市: ${city.name} (${city.adcode})');

      // 2. 获取天气信息
      final weather = await WeatherService.getRealTimeWeather(city.adcode);

      if (mounted) {
        setState(() {
          _cityInfo = city;
          _weatherInfo = weather;
          _isLoading = false;
          if (weather == null) {
            _errorMessage = '获取天气失败';
          }
        });
      }
    } catch (e) {
      print('❌ 加载天气异常: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '网络错误';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_weatherInfo == null) {
      return _buildError();
    }

    return _buildWeatherDisplay();
  }

  /// 构建加载状态
  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.textStyle?.color ?? Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '加载中...',
            style: widget.textStyle ?? const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: widget.iconSize * 0.4,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            _errorMessage.isEmpty ? '天气信息不可用' : _errorMessage,
            style: widget.textStyle ?? const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 构建天气显示
  Widget _buildWeatherDisplay() {
    final weather = _weatherInfo!;
    final defaultTextStyle = widget.textStyle ?? 
      const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500);

    return GestureDetector(
      onTap: _loadWeather, // 点击刷新天气
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 天气图标
            WeatherIcon(
              type: weather.weatherType,
              size: widget.iconSize,
            ),
            
            const SizedBox(width: 12),
            
            // 天气信息
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 城市名 + 天气
                if (widget.showCityName && _cityInfo != null)
                  Text(
                    '${_cityInfo!.name} · ${weather.weather}',
                    style: defaultTextStyle,
                  ),
                if (!widget.showCityName)
                  Text(
                    weather.weather,
                    style: defaultTextStyle,
                  ),
                
                const SizedBox(height: 2),
                
                // 温度
                Text(
                  '${weather.temperature}°C',
                  style: defaultTextStyle.copyWith(
                    fontSize: (defaultTextStyle.fontSize ?? 14) * 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 简洁版天气组件（仅图标和温度）
class CompactWeatherWidget extends StatefulWidget {
  final double size;
  
  const CompactWeatherWidget({
    super.key,
    this.size = 80.0,
  });

  @override
  State<CompactWeatherWidget> createState() => _CompactWeatherWidgetState();
}

class _CompactWeatherWidgetState extends State<CompactWeatherWidget> {
  WeatherInfo? _weatherInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final city = await LocationService.getCityByIP();
      final weather = await WeatherService.getRealTimeWeather(city.adcode);

      if (mounted) {
        setState(() {
          _weatherInfo = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _weatherInfo == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WeatherIcon(
          type: _weatherInfo!.weatherType,
          size: widget.size * 0.6,
        ),
        const SizedBox(height: 4),
        Text(
          '${_weatherInfo!.temperature}°',
          style: TextStyle(
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _weatherInfo!.weather,
          style: TextStyle(
            fontSize: widget.size * 0.15,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

