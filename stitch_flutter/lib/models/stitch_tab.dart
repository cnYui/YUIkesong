import 'package:flutter/material.dart';

enum StitchTab { home, wardrobe, community, fittingRoom, profile }

extension StitchTabX on StitchTab {
  String get label => switch (this) {
    StitchTab.home => '首页',
    StitchTab.wardrobe => '我的衣柜',
    StitchTab.community => '社区',
    StitchTab.fittingRoom => 'AI试穿室',
    StitchTab.profile => '我的',
  };

  IconData get icon => switch (this) {
    StitchTab.home => Icons.home,
    StitchTab.wardrobe => Icons.checkroom,
    StitchTab.community => Icons.people,
    StitchTab.fittingRoom => Icons.dry_cleaning,
    StitchTab.profile => Icons.person,
  };
}
