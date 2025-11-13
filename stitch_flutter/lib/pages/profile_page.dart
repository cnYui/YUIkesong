import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  String? _defaultAvatarUrl;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    // 初始状态设置为未加载
    _isLoadingAvatar = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面可见且用户已登录时加载头像
    if (ApiService.isAuthenticated && _defaultAvatarUrl == null && !_isLoadingAvatar) {
      _loadDefaultAvatar();
    }
  }

  Future<void> _loadDefaultAvatar() async {
    if (!ApiService.isAuthenticated) {
      return;
    }

    setState(() {
      _isLoadingAvatar = true;
    });

    try {
      final response = await ApiService.getSelfies();
      final List<dynamic> selfieList = response['list'] ?? [];
      
      if (selfieList.isEmpty) {
        setState(() {
          _defaultAvatarUrl = null;
          _isLoadingAvatar = false;
        });
        return;
      }

      // 查找默认自拍
      final defaultSelfie = selfieList.firstWhere(
        (selfie) => selfie['is_default'] == true,
        orElse: () => selfieList[0], // 如果没有默认的，使用第一个
      );

      if (mounted) {
        setState(() {
          _defaultAvatarUrl = defaultSelfie['image_url'] ?? defaultSelfie['image_path'];
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    }
  }

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
    Navigator.of(context).pushNamed(route).then((_) {
      // 从自拍管理页面返回时重新加载头像
      if (route == SelfieManagementPage.routeName) {
        // 延迟一下确保数据已更新
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && ApiService.isAuthenticated) {
            _loadDefaultAvatar();
          }
        });
      }
    });
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: _isLoadingAvatar
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                )
                              : _defaultAvatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _defaultAvatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: AuthService(),
                            builder: (context, _) {
                              final nickname = AuthService().nickname ?? '时尚达人';
                              return Text(
                                nickname,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.15,
                                  color: StitchColors.textPrimary,
                                ),
                              );
                            },
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
