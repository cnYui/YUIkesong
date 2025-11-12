import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'about_page.dart';
import 'saved_looks_page.dart';
import 'selfie_management_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  static const _shortcuts = [
    _ProfileShortcut(
      label: '管理我的自拍',
      icon: Icons.photo_camera,
      routeName: SelfieManagementPage.routeName,
    ),
    _ProfileShortcut(
      label: '我保存的穿搭',
      icon: Icons.bookmark,
      routeName: SavedLooksPage.routeName,
    ),
  ];

  static const _settings = [
    _ProfileShortcut(
      label: '设置',
      icon: Icons.settings,
      routeName: SettingsPage.routeName,
    ),
    _ProfileShortcut(
      label: '关于我们',
      icon: Icons.info,
      routeName: AboutPage.routeName,
    ),
  ];

  void _openRoute(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '我的',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: StitchColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCeBnG-RJYwReA5PdBj2L8GdRunsfgcsYD-XIsWsHttDb89yxpuCuVu8s-QzQkLMX7mfFQLcW73EoaoTpVDU5woG4xjO7jvZmWUAx34yTlV4clAYYdC7xAwrZNSUR6w2g5BndIktVmiBEcXSfHgPl380QrVIuIgx7IW9432fOfndtFwyUCD3U1c-c2tOScs7bIpO673mVlHEr3Db58xFuL1pqF5mz--93cgR-l7WQHHDH9NxScg_S2io9-nEKeH89mWqHq_LZvAg08',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            '时尚达人小王',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              color: StitchColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProfileCard(items: _shortcuts, onTap: _openRoute),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ProfileCard(items: _settings, onTap: _openRoute),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNav(
              currentTab: widget.currentTab,
              onTabSelected: widget.onTabSelected,
              variant: BottomNavVariant.profile,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.items, required this.onTap});

  final List<_ProfileShortcut> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .asMap()
            .entries
            .map(
              (entry) => _ProfileRow(
                shortcut: entry.value,
                onTap: () => onTap(entry.value.routeName),
                showDivider: entry.key != items.length - 1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.shortcut,
    required this.onTap,
    required this.showDivider,
  });

  final _ProfileShortcut shortcut;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Icon(shortcut.icon, color: Colors.black87, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      shortcut.label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: StitchColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFB0B1B6)),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFE5E6EB),
          ),
      ],
    );
  }
}

class _ProfileShortcut {
  const _ProfileShortcut({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;
}
