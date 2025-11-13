import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../state/city_selection_store.dart';

/// 地区选择页面
/// 用户可以直接点击城市进行选择
class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  static const routeName = '/city-selection';

  // 获取城市列表（供外部访问）
  static List<CityInfo> getCitiesList() {
    return _cities;
  }

  // 写死的城市列表（常用城市）
  static const List<CityInfo> _cities = [
    CityInfo(name: '北京市', adcode: '110000'),
    CityInfo(name: '天津市', adcode: '120000'),
    CityInfo(name: '石家庄市', adcode: '130100'),
    CityInfo(name: '太原市', adcode: '140100'),
    CityInfo(name: '呼和浩特市', adcode: '150100'),
    CityInfo(name: '沈阳市', adcode: '210100'),
    CityInfo(name: '长春市', adcode: '220100'),
    CityInfo(name: '哈尔滨市', adcode: '230100'),
    CityInfo(name: '上海市', adcode: '310000'),
    CityInfo(name: '南京市', adcode: '320100'),
    CityInfo(name: '杭州市', adcode: '330100'),
    CityInfo(name: '合肥市', adcode: '340100'),
    CityInfo(name: '福州市', adcode: '350100'),
    CityInfo(name: '南昌市', adcode: '360100'),
    CityInfo(name: '济南市', adcode: '370100'),
    CityInfo(name: '郑州市', adcode: '410100'),
    CityInfo(name: '武汉市', adcode: '420100'),
    CityInfo(name: '长沙市', adcode: '430100'),
    CityInfo(name: '广州市', adcode: '440100'),
    CityInfo(name: '深圳市', adcode: '440300'),
    CityInfo(name: '南宁市', adcode: '450100'),
    CityInfo(name: '海口市', adcode: '460100'),
    CityInfo(name: '重庆市', adcode: '500000'),
    CityInfo(name: '成都市', adcode: '510100'),
    CityInfo(name: '贵阳市', adcode: '520100'),
    CityInfo(name: '昆明市', adcode: '530100'),
    CityInfo(name: '拉萨市', adcode: '540100'),
    CityInfo(name: '西安市', adcode: '610100'),
    CityInfo(name: '兰州市', adcode: '620100'),
    CityInfo(name: '西宁市', adcode: '630100'),
    CityInfo(name: '银川市', adcode: '640100'),
    CityInfo(name: '乌鲁木齐市', adcode: '650100'),
  ];

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  // 使用静态列表
  List<CityInfo> get _cities => CitySelectionPage._cities;
  CityInfo? _selectedCity;

  @override
  void initState() {
    super.initState();
    // 加载当前选择的城市
    final store = CitySelectionStore();
    if (store.hasManualSelection) {
      _selectedCity = store.selectedCity;
    }
  }

  /// 保存选择并查询天气
  Future<void> _saveSelection(CityInfo city) async {
    // 保存选择的城市（会保存到数据库）
    await CitySelectionStore().setCity(city);
    
    // 返回上一页
    if (mounted) {
      Navigator.of(context).pop();
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到 ${city.name}'),
          duration: const Duration(seconds: 1),
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
      body: Column(
        children: [
          // 城市列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = _selectedCity?.adcode == city.adcode;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF1F1F21) 
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                      // 点击后立即保存并查询天气
                      _saveSelection(city);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              city.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF1F1F21),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 底部保存按钮（可选，因为点击城市后已经自动保存）
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCity != null
                    ? () => _saveSelection(_selectedCity!)
                    : null,
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
          ),
        ],
      ),
    );
  }
}
