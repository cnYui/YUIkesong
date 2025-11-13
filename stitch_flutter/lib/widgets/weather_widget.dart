import 'package:flutter/material.dart';
import 'package:stitch_flutter/services/weather_service.dart';
import 'package:stitch_flutter/services/location_service.dart';
import 'package:stitch_flutter/services/auth_service.dart';
import 'package:stitch_flutter/state/city_selection_store.dart';
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
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadWeather();
  }

  /// 检查登录状态并加载天气
  void _checkAuthAndLoadWeather() {
    final authService = AuthService();
    
    // 如果已登录，直接加载天气
    if (authService.isAuthenticated) {
      _loadWeather();
      return;
    }

    // 如果未登录，监听登录状态变化
    authService.addListener(_onAuthChanged);
    
    // 首次检查时，如果未登录，显示未登录状态
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 登录状态变化回调
  void _onAuthChanged() {
    final authService = AuthService();
    
    if (authService.isAuthenticated && _weatherInfo == null) {
      // 用户刚登录，开始加载天气
      _loadWeather();
    } else if (!authService.isAuthenticated) {
      // 用户登出，清空天气信息
      if (mounted) {
        setState(() {
          _weatherInfo = null;
          _cityInfo = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadWeather();
    // 监听城市选择变化
    CitySelectionStore().addListener(_onCityChanged);
  }

  @override
  void dispose() {
    // 移除所有监听器
    AuthService().removeListener(_onAuthChanged);
    CitySelectionStore().removeListener(_onCityChanged);
    super.dispose();
  }

  /// 城市选择变化回调
  void _onCityChanged() {
    // 如果用户选择了新城市，重新加载天气
    if (AuthService().isAuthenticated) {
      _loadWeather();
    }
  }

  /// 加载天气数据（仅在登录后调用）
  Future<void> _loadWeather() async {
    // 再次检查登录状态
    if (!AuthService().isAuthenticated) {
      print('⚠️ 用户未登录，跳过天气加载');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 1. 获取用户城市（优先使用手动选择的城市）
      final cityStore = CitySelectionStore();
      CityInfo city;
      
      if (cityStore.hasManualSelection) {
        // 使用用户手动选择的城市
        city = cityStore.selectedCity!;
        print('📍 使用用户选择的城市: ${city.name} (${city.adcode})');
      } else {
        // 使用IP定位
        city = await LocationService.getCityByIP();
        print('📍 使用IP定位的城市: ${city.name} (${city.adcode})');
      }

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
    // 使用 AnimatedBuilder 监听登录状态变化
    return AnimatedBuilder(
      animation: AuthService(),
      builder: (context, _) {
        // 检查登录状态
        final isAuthenticated = AuthService().isAuthenticated;
        
        // 如果未登录，显示占位符
        if (!isAuthenticated) {
          return _buildPlaceholder();
        }

        // 如果正在加载
        if (_isLoading) {
          return _buildLoading();
        }

        // 如果加载失败
        if (_weatherInfo == null) {
          return _buildError();
        }

        // 显示天气信息
        return _buildWeatherDisplay();
      },
    );
  }

  /// 构建未登录占位符
  Widget _buildPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: widget.iconSize * 0.5,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            '登录后查看天气',
            style: widget.textStyle?.copyWith(
              color: Colors.grey[500],
            ) ?? TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
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
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadWeather();
    // 监听城市选择变化
    CitySelectionStore().addListener(_onCityChanged);
  }

  void _checkAuthAndLoadWeather() {
    final authService = AuthService();
    
    if (authService.isAuthenticated) {
      _loadWeather();
      return;
    }

    authService.addListener(_onAuthChanged);
    
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAuthChanged() {
    final authService = AuthService();
    
    if (authService.isAuthenticated && _weatherInfo == null) {
      _loadWeather();
    } else if (!authService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _weatherInfo = null;
          _isLoading = false;
        });
      }
    }
  }

  void _onCityChanged() {
    if (AuthService().isAuthenticated) {
      _loadWeather();
    }
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    CitySelectionStore().removeListener(_onCityChanged);
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (!AuthService().isAuthenticated) {
      return;
    }

    try {
      // 优先使用用户手动选择的城市
      final cityStore = CitySelectionStore();
      CityInfo city;
      
      if (cityStore.hasManualSelection) {
        city = cityStore.selectedCity!;
      } else {
        city = await LocationService.getCityByIP();
      }
      
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
    // 使用 AnimatedBuilder 监听登录状态变化
    return AnimatedBuilder(
      animation: AuthService(),
      builder: (context, _) {
        final isAuthenticated = AuthService().isAuthenticated;
        
        if (!isAuthenticated) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(
              Icons.location_off,
              size: widget.size * 0.4,
              color: Colors.grey[400],
            ),
          );
        }

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
      },
    );
  }
}

