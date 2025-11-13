import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../state/city_selection_store.dart';

/// 地区选择页面
/// 用户可以选择省份和城市
class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  static const routeName = '/city-selection';

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  List<ProvinceInfo> _provinces = [];
  List<CityInfo> _cities = [];
  ProvinceInfo? _selectedProvince;
  CityInfo? _selectedCity;
  bool _isLoadingProvinces = true;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadCurrentSelection();
  }

  /// 加载当前选择的城市
  void _loadCurrentSelection() {
    final store = CitySelectionStore();
    final currentCity = store.selectedCity;
    if (currentCity != null) {
      _selectedCity = currentCity;
      // 尝试根据城市adcode推断省份（简单处理）
      final provinceAdcode = currentCity.adcode.substring(0, 2) + '0000';
      // 这里可以优化，但为了简化，先这样处理
    }
  }

  /// 加载省份列表
  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });

    try {
      final provinces = await LocationService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      print('❌ 加载省份列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingProvinces = false;
        });
      }
    }
  }

  /// 加载城市列表
  Future<void> _loadCities(String provinceAdcode) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
    });

    try {
      final cities = await LocationService.getCitiesByProvince(provinceAdcode);
      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      print('❌ 加载城市列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  /// 保存选择
  void _saveSelection() {
    if (_selectedCity != null) {
      CitySelectionStore().setCity(_selectedCity!);
      Navigator.of(context).pop();
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到 ${_selectedCity!.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择城市'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '选择地区',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 省份选择
            const Text(
              '省份',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _isLoadingProvinces
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<ProvinceInfo>(
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        value: _selectedProvince,
                        hint: const Text(
                          '请选择省份',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        items: _provinces.map((province) {
                          return DropdownMenuItem<ProvinceInfo>(
                            value: province,
                            child: Text(
                              province.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (province) {
                          if (province != null) {
                            setState(() {
                              _selectedProvince = province;
                            });
                            _loadCities(province.adcode);
                          }
                        },
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // 城市选择
            const Text(
              '城市',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _selectedProvince == null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '请先选择省份',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : _isLoadingCities
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _cities.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '该省份暂无城市数据',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<CityInfo>(
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                value: _selectedCity,
                                hint: const Text(
                                  '请选择城市',
                                  style: TextStyle(color: Color(0xFF9CA3AF)),
                                ),
                                items: _cities.map((city) {
                                  return DropdownMenuItem<CityInfo>(
                                    value: city,
                                    child: Text(
                                      city.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (city) {
                                  setState(() {
                                    _selectedCity = city;
                                  });
                                },
                              ),
                            ),
            ),
            
            const Spacer(),
            
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCity != null ? _saveSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCity != null
                      ? const Color(0xFF1F1F21)
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

