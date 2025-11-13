import 'package:flutter/material.dart';
import '../state/city_selection_store.dart';
import 'city_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // 监听城市选择变化
    CitySelectionStore().addListener(_onCityChanged);
  }

  @override
  void dispose() {
    CitySelectionStore().removeListener(_onCityChanged);
    super.dispose();
  }

  void _onCityChanged() {
    setState(() {});
  }

  String _getCityDisplayText() {
    final store = CitySelectionStore();
    if (store.hasManualSelection) {
      return store.selectedCity!.name;
    }
    return '自动定位';
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
          '设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _SettingCard(
              items: [
                const _SettingItem(
                  icon: Icons.language,
                  title: '语言',
                  subtitle: '简体中文',
                ),
                const _SettingItem(
                  icon: Icons.contrast,
                  title: '颜色风格',
                  subtitle: '白色风格',
                ),
                _SettingItem(
                  icon: Icons.location_on,
                  title: '地区',
                  subtitle: _getCityDisplayText(),
                  onTap: () {
                    Navigator.of(context).pushNamed(CitySelectionPage.routeName);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingCard(
              items: const [
                _SettingItem(icon: Icons.notifications, title: '通知'),
                _SettingItem(icon: Icons.delete, title: '清除缓存'),
              ],
            ),
            const SizedBox(height: 16),
            _SettingCard(
              items: const [
                _SettingItem(icon: Icons.lock, title: '隐私政策'),
                _SettingItem(icon: Icons.info, title: '关于我们'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.items});

  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (entry) => _SettingRow(
                item: entry.value,
                showDivider: entry.key != items.length - 1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.item, required this.showDivider});

  final _SettingItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(item.icon, color: const Color(0xFF6B7280)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFB0B1B6)),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}

class _SettingItem {
  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
}
