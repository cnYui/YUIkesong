import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../theme/app_theme.dart';

enum BottomNavVariant { home, wardrobe, fittingRoom, profile, community }

class StitchBottomNav extends StatelessWidget {
  const StitchBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.variant,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;
  final BottomNavVariant variant;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final bottomInsets = padding.bottom == 0 ? 16.0 : padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInsets),
        child: switch (variant) {
          BottomNavVariant.home => _HomeBottomNav(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
          ),
          BottomNavVariant.wardrobe => _WardrobeBottomNav(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
          ),
          BottomNavVariant.fittingRoom => _AiBottomNav(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
          ),
          BottomNavVariant.profile => _ProfileBottomNav(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
          ),
          BottomNavVariant.community => _UnifiedBottomNav(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
          ),
        },
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.currentTab, required this.onTabSelected});

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return _UnifiedBottomNav(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
    );
  }
}

class _WardrobeBottomNav extends StatelessWidget {
  const _WardrobeBottomNav({
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return _UnifiedBottomNav(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
    );
  }
}

class _AiBottomNav extends StatelessWidget {
  const _AiBottomNav({required this.currentTab, required this.onTabSelected});

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return _UnifiedBottomNav(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav({
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return _UnifiedBottomNav(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
    );
  }
}

class _UnifiedBottomNav extends StatelessWidget {
  const _UnifiedBottomNav({
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: StitchColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: StitchTab.values.map((tab) {
            return Expanded(
              child: _buildNavItem(tab, currentTab, onTabSelected),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    StitchTab tab,
    StitchTab currentTab,
    ValueChanged<StitchTab> onTabSelected,
  ) {
    final selected = tab == currentTab;
    final color = selected ? const Color(0xFF1E1E1E) : const Color(0xFF8E8E93);
    return GestureDetector(
      onTap: () => onTabSelected(tab),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, color: color, size: selected ? 26 : 24),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
