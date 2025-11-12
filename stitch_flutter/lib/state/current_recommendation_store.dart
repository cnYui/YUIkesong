import 'package:flutter/foundation.dart';

/// 当前选中的推荐穿搭信息
class CurrentRecommendation {
  const CurrentRecommendation({
    required this.title,
    required this.clothingImages,
  });

  final String title;
  final List<String> clothingImages;
}

/// 全局状态：存储用户从首页点击的推荐穿搭
class CurrentRecommendationStore {
  const CurrentRecommendationStore._();

  static final ValueNotifier<CurrentRecommendation?> _notifier = ValueNotifier(
    null,
  );

  static ValueListenable<CurrentRecommendation?> get listenable => _notifier;

  static CurrentRecommendation? get current => _notifier.value;

  /// 设置当前推荐
  static void setRecommendation(CurrentRecommendation recommendation) {
    _notifier.value = recommendation;
  }

  /// 清除当前推荐
  static void clear() {
    _notifier.value = null;
  }

  /// 获取当前推荐的衣服图片列表
  static List<String> getClothingImages() {
    return _notifier.value?.clothingImages ?? [];
  }
}
