import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stitch_flutter/services/weather_service.dart';
import 'package:stitch_flutter/services/location_service.dart';
import 'package:stitch_flutter/services/auth_service.dart';
import 'package:stitch_flutter/services/api_service.dart';
import 'package:stitch_flutter/services/cache_service.dart';
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
  DateTime? _lastWeatherUpdate; // 上次更新天气的时间
  Timer? _refreshTimer; // 定时刷新计时器
  
  // 天气缓存有效期（1小时）
  static const Duration _weatherCacheDuration = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadWeather();
    // 监听城市选择变化
    CitySelectionStore().addListener(_onCityChanged);
    // 启动定时刷新（每小时检查一次）
    _startAutoRefresh();
  }

  /// 检查登录状态并加载天气
  void _checkAuthAndLoadWeather() {
    final authService = AuthService();
    
    // 如果已登录，从数据库加载保存的城市，然后加载天气
    if (authService.isAuthenticated) {
      _loadWeatherFromDatabase();
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

  /// 从数据库加载保存的城市，然后加载天气
  Future<void> _loadWeatherFromDatabase() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 1. 从数据库加载保存的城市
      await CitySelectionStore().loadSavedCity();
      
      // 2. 检查是否有保存的城市
      final cityStore = CitySelectionStore();
      if (cityStore.hasManualSelection) {
        // 有保存的城市，先尝试加载缓存的天气
        print('📍 从数据库加载到保存的城市: ${cityStore.selectedCity!.name}');
        
        // 先尝试从数据库获取缓存的天气
        final cachedWeather = await _loadCachedWeather();
        if (cachedWeather != null) {
          print('✅ 使用缓存的天气数据');
          // 先显示缓存的天气
          if (mounted) {
            setState(() {
              _cityInfo = cityStore.selectedCity!;
              _weatherInfo = cachedWeather;
              _isLoading = false;
            });
          }
          
          // 记录为已更新（使用缓存也算）
          _lastWeatherUpdate = DateTime.now();
        }
        
        // 只有在需要刷新时才调用API（超过1小时或者没有缓存）
        if (_shouldRefreshWeather()) {
          print('⏰ 天气缓存已过期，刷新中...');
          await _loadWeather(forceRefresh: false);
        } else {
          print('✅ 天气缓存仍然有效，跳过API调用');
        }
      } else {
        // 没有保存的城市，显示默认天气
        print('📍 数据库中没有保存的城市，显示默认天气');
        _loadDefaultWeather();
      }
    } catch (e) {
      print('❌ 从数据库加载城市失败: $e');
      // 如果加载失败，显示默认天气
      _loadDefaultWeather();
    }
  }

  /// 从缓存加载天气（优先本地缓存，其次数据库）
  Future<WeatherInfo?> _loadCachedWeather() async {
    final cityStore = CitySelectionStore();
    if (!cityStore.hasManualSelection) return null;
    
    final cityCode = cityStore.selectedCity!.adcode;
    
    // 1. 先尝试从本地缓存（shared_preferences）加载
    final localCache = CacheService().getCachedWeather(cityCode);
    if (localCache != null) {
      print('✅ 从本地缓存加载天气');
      return WeatherInfo(
        province: localCache['province'] ?? '',
        city: localCache['city'] ?? '',
        adcode: localCache['adcode'] ?? '',
        weather: localCache['weather'] ?? '',
        temperature: localCache['temperature'] ?? '',
        windDirection: localCache['windDirection'] ?? '',
        windPower: localCache['windPower'] ?? '',
        humidity: localCache['humidity'] ?? '',
        reportTime: localCache['reportTime'] ?? '',
      );
    }
    
    // 2. 如果本地缓存没有，尝试从数据库加载
    try {
      final cachedData = await ApiService.getWeatherCache();
      if (cachedData != null) {
        print('✅ 从数据库缓存加载天气');
        // 同时保存到本地缓存
        await CacheService().cacheWeather(
          cityCode: cityCode,
          weatherData: cachedData,
        );
        return WeatherInfo(
          province: cachedData['province'] ?? '',
          city: cachedData['city'] ?? '',
          adcode: cachedData['adcode'] ?? '',
          weather: cachedData['weather'] ?? '',
          temperature: cachedData['temperature'] ?? '',
          windDirection: cachedData['windDirection'] ?? '',
          windPower: cachedData['windPower'] ?? '',
          humidity: cachedData['humidity'] ?? '',
          reportTime: cachedData['reportTime'] ?? '',
        );
      }
    } catch (e) {
      print('❌ 加载数据库缓存天气失败: $e');
    }
    return null;
  }

  /// 加载默认天气（北京，晴）
  void _loadDefaultWeather() {
    if (mounted) {
      setState(() {
        _cityInfo = LocationService.getDefaultCity();
        _weatherInfo = WeatherInfo(
          province: '北京',
          city: '北京市',
          adcode: '110000',
          weather: '晴',
          temperature: '20',
          windDirection: '无风',
          windPower: '≤3',
          humidity: '50',
          reportTime: DateTime.now().toString(),
        );
        _isLoading = false;
      });
    }
  }

  /// 登录状态变化回调
  void _onAuthChanged() {
    final authService = AuthService();
    
    if (authService.isAuthenticated && _weatherInfo == null) {
      // 用户刚登录，从数据库加载保存的城市并获取天气
      _loadWeatherFromDatabase();
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
  void dispose() {
    // 停止定时器
    _refreshTimer?.cancel();
    // 移除所有监听器
    AuthService().removeListener(_onAuthChanged);
    CitySelectionStore().removeListener(_onCityChanged);
    super.dispose();
  }

  /// 启动自动刷新（每小时检查一次）
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_weatherCacheDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // 只有在已登录且有城市选择的情况下才刷新
      if (AuthService().isAuthenticated && CitySelectionStore().hasManualSelection) {
        print('⏰ 定时刷新天气（每小时）');
        _loadWeather(forceRefresh: true);
      }
    });
  }

  /// 检查是否需要刷新天气（超过1小时）
  bool _shouldRefreshWeather() {
    if (_lastWeatherUpdate == null) return true;
    final elapsed = DateTime.now().difference(_lastWeatherUpdate!);
    return elapsed >= _weatherCacheDuration;
  }

  /// 城市选择变化回调
  void _onCityChanged() {
    // 如果用户选择了新城市，立即调用API获取真实天气（强制刷新）
    if (AuthService().isAuthenticated) {
      final cityStore = CitySelectionStore();
      // 只有在用户手动选择城市时才调用API
      if (cityStore.hasManualSelection) {
        print('🌍 用户更改了城市，立即刷新天气');
        _loadWeather(forceRefresh: true);
      } else {
        // 如果用户清除了选择，恢复默认天气
        _loadDefaultWeather();
      }
    }
  }

  /// 加载天气数据（仅在用户手动选择城市后调用）
  /// [forceRefresh] 是否强制刷新（忽略缓存时间限制）
  Future<void> _loadWeather({bool forceRefresh = false}) async {
    // 再次检查登录状态
    if (!AuthService().isAuthenticated) {
      print('⚠️ 用户未登录，跳过天气加载');
      return;
    }

    // 只有在用户手动选择城市时才调用API
    final cityStore = CitySelectionStore();
    if (!cityStore.hasManualSelection) {
      print('⚠️ 用户未手动选择城市，使用默认天气');
      _loadDefaultWeather();
      return;
    }

    // 如果不是强制刷新，检查是否需要更新
    if (!forceRefresh && !_shouldRefreshWeather()) {
      print('⏱️ 天气数据仍在有效期内，跳过API调用');
      return;
    }

    try {
      // 如果不是首次加载，不显示loading状态
      final isInitialLoad = _weatherInfo == null;
      if (isInitialLoad && mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // 使用用户手动选择的城市
      final city = cityStore.selectedCity!;
      print('📍 使用用户选择的城市: ${city.name} (${city.adcode})');

      // 获取天气信息
      final weather = await WeatherService.getRealTimeWeather(city.adcode);

      if (weather != null) {
        // 天气获取成功，保存到本地缓存和数据库缓存
        print('✅ 天气获取成功，保存到缓存');
        
        // 更新最后更新时间
        _lastWeatherUpdate = DateTime.now();
        
        final weatherData = {
          'province': weather.province,
          'city': weather.city,
          'adcode': weather.adcode,
          'weather': weather.weather,
          'temperature': weather.temperature,
          'windDirection': weather.windDirection,
          'windPower': weather.windPower,
          'humidity': weather.humidity,
          'reportTime': weather.reportTime,
        };
        
        // 1. 保存到本地缓存（shared_preferences）- 快速访问
        try {
          await CacheService().cacheWeather(
            cityCode: city.adcode,
            weatherData: weatherData,
          );
        } catch (e) {
          print('⚠️ 保存本地缓存失败: $e');
        }
        
        // 2. 保存到数据库缓存 - 持久化
        try {
          await ApiService.saveWeatherCache(weatherData);
          print('✅ 天气缓存保存成功');
        } catch (cacheError) {
          print('⚠️ 天气缓存保存失败: $cacheError');
          // 缓存保存失败不影响天气显示
        }
      }

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
      // API调用失败时，尝试使用缓存的天气
      if (_weatherInfo == null) {
        final cachedWeather = await _loadCachedWeather();
        if (cachedWeather != null) {
          print('✅ API失败，使用缓存的天气数据');
          if (mounted) {
            setState(() {
              _cityInfo = cityStore.selectedCity!;
              _weatherInfo = cachedWeather;
              _isLoading = false;
              _errorMessage = ''; // 清除错误消息，因为有缓存数据
            });
          }
          return;
        }
      }
      
      // 如果没有缓存或缓存也加载失败
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
    // 使用 AnimatedBuilder 同时监听登录状态和城市选择变化
    return AnimatedBuilder(
      animation: Listenable.merge([
        AuthService(),
        CitySelectionStore(),
      ]),
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
      onTap: () => _loadWeather(forceRefresh: true), // 点击刷新天气
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
  DateTime? _lastWeatherUpdate; // 上次更新天气的时间
  Timer? _refreshTimer; // 定时刷新计时器
  
  // 天气缓存有效期（1小时）
  static const Duration _weatherCacheDuration = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadWeather();
    // 监听城市选择变化
    CitySelectionStore().addListener(_onCityChanged);
    // 启动定时刷新（每小时检查一次）
    _startAutoRefresh();
  }
  
  /// 启动自动刷新（每小时检查一次）
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_weatherCacheDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // 只有在已登录且有城市选择的情况下才刷新
      if (AuthService().isAuthenticated && CitySelectionStore().hasManualSelection) {
        _loadWeather(forceRefresh: true);
      }
    });
  }

  /// 检查是否需要刷新天气（超过1小时）
  bool _shouldRefreshWeather() {
    if (_lastWeatherUpdate == null) return true;
    final elapsed = DateTime.now().difference(_lastWeatherUpdate!);
    return elapsed >= _weatherCacheDuration;
  }

  void _checkAuthAndLoadWeather() {
    final authService = AuthService();
    
    if (authService.isAuthenticated) {
      _loadWeatherFromDatabase();
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

  /// 从数据库加载保存的城市，然后加载天气
  Future<void> _loadWeatherFromDatabase() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 1. 从数据库加载保存的城市
      await CitySelectionStore().loadSavedCity();
      
      // 2. 检查是否有保存的城市
      final cityStore = CitySelectionStore();
      if (cityStore.hasManualSelection) {
        // 先尝试从数据库获取缓存的天气
        final cachedWeather = await _loadCachedWeather();
        if (cachedWeather != null) {
          // 先显示缓存的天气
          if (mounted) {
            setState(() {
              _weatherInfo = cachedWeather;
              _isLoading = false;
            });
          }
          
          // 记录为已更新（使用缓存也算）
          _lastWeatherUpdate = DateTime.now();
        }
        
        // 只有在需要刷新时才调用API（超过1小时或者没有缓存）
        if (_shouldRefreshWeather()) {
          await _loadWeather(forceRefresh: false);
        }
      } else {
        // 没有保存的城市，显示默认天气
        _loadDefaultWeather();
      }
    } catch (e) {
      print('❌ 从数据库加载城市失败: $e');
      // 如果加载失败，显示默认天气
      _loadDefaultWeather();
    }
  }

  /// 从缓存加载天气（优先本地缓存，其次数据库）
  Future<WeatherInfo?> _loadCachedWeather() async {
    final cityStore = CitySelectionStore();
    if (!cityStore.hasManualSelection) return null;
    
    final cityCode = cityStore.selectedCity!.adcode;
    
    // 1. 先尝试从本地缓存（shared_preferences）加载
    final localCache = CacheService().getCachedWeather(cityCode);
    if (localCache != null) {
      print('✅ 从本地缓存加载天气');
      return WeatherInfo(
        province: localCache['province'] ?? '',
        city: localCache['city'] ?? '',
        adcode: localCache['adcode'] ?? '',
        weather: localCache['weather'] ?? '',
        temperature: localCache['temperature'] ?? '',
        windDirection: localCache['windDirection'] ?? '',
        windPower: localCache['windPower'] ?? '',
        humidity: localCache['humidity'] ?? '',
        reportTime: localCache['reportTime'] ?? '',
      );
    }
    
    // 2. 如果本地缓存没有，尝试从数据库加载
    try {
      final cachedData = await ApiService.getWeatherCache();
      if (cachedData != null) {
        print('✅ 从数据库缓存加载天气');
        // 同时保存到本地缓存
        await CacheService().cacheWeather(
          cityCode: cityCode,
          weatherData: cachedData,
        );
        return WeatherInfo(
          province: cachedData['province'] ?? '',
          city: cachedData['city'] ?? '',
          adcode: cachedData['adcode'] ?? '',
          weather: cachedData['weather'] ?? '',
          temperature: cachedData['temperature'] ?? '',
          windDirection: cachedData['windDirection'] ?? '',
          windPower: cachedData['windPower'] ?? '',
          humidity: cachedData['humidity'] ?? '',
          reportTime: cachedData['reportTime'] ?? '',
        );
      }
    } catch (e) {
      print('❌ 加载数据库缓存天气失败: $e');
    }
    return null;
  }

  /// 加载默认天气（北京，晴）
  void _loadDefaultWeather() {
    if (mounted) {
      setState(() {
        _weatherInfo = WeatherInfo(
          province: '北京',
          city: '北京市',
          adcode: '110000',
          weather: '晴',
          temperature: '20',
          windDirection: '无风',
          windPower: '≤3',
          humidity: '50',
          reportTime: DateTime.now().toString(),
        );
        _isLoading = false;
      });
    }
  }

  void _onAuthChanged() {
    final authService = AuthService();
    
    if (authService.isAuthenticated && _weatherInfo == null) {
      // 用户刚登录，从数据库加载保存的城市并获取天气
      _loadWeatherFromDatabase();
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
      final cityStore = CitySelectionStore();
      // 只有在用户手动选择城市时才调用API
      if (cityStore.hasManualSelection) {
        _loadWeather(forceRefresh: true);
      } else {
        // 如果用户清除了选择，恢复默认天气
        _loadDefaultWeather();
      }
    }
  }

  @override
  void dispose() {
    // 停止定时器
    _refreshTimer?.cancel();
    AuthService().removeListener(_onAuthChanged);
    CitySelectionStore().removeListener(_onCityChanged);
    super.dispose();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    if (!AuthService().isAuthenticated) {
      return;
    }

    // 只有在用户手动选择城市时才调用API
    final cityStore = CitySelectionStore();
    if (!cityStore.hasManualSelection) {
      _loadDefaultWeather();
      return;
    }

    // 如果不是强制刷新，检查是否需要更新
    if (!forceRefresh && !_shouldRefreshWeather()) {
      return;
    }

    try {
      final isInitialLoad = _weatherInfo == null;
      if (isInitialLoad && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final city = cityStore.selectedCity!;
      final weather = await WeatherService.getRealTimeWeather(city.adcode);

      if (weather != null) {
        // 更新最后更新时间
        _lastWeatherUpdate = DateTime.now();
        
        // 保存天气到缓存
        try {
          await ApiService.saveWeatherCache({
            'province': weather.province,
            'city': weather.city,
            'adcode': weather.adcode,
            'weather': weather.weather,
            'temperature': weather.temperature,
            'windDirection': weather.windDirection,
            'windPower': weather.windPower,
            'humidity': weather.humidity,
            'reportTime': weather.reportTime,
          });
        } catch (cacheError) {
          // 缓存保存失败不影响天气显示
        }
      }

      if (mounted) {
        setState(() {
          _weatherInfo = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      // API调用失败时，尝试使用缓存的天气
      if (_weatherInfo == null) {
        final cachedWeather = await _loadCachedWeather();
        if (cachedWeather != null) {
          if (mounted) {
            setState(() {
              _weatherInfo = cachedWeather;
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 AnimatedBuilder 同时监听登录状态和城市选择变化
    return AnimatedBuilder(
      animation: Listenable.merge([
        AuthService(),
        CitySelectionStore(),
      ]),
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

