import 'package:flutter/foundation.dart';

/// 用于触发AI试穿室页面生成图片的全局标志
class FittingRoomTrigger {
  const FittingRoomTrigger._();

  static final ValueNotifier<int> _triggerTimestamp =
      ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _triggerTimestamp;

  /// 触发生成（从衣柜页面点击"一键生成"时调用）
  /// 使用时间戳机制，避免布尔值的时序问题
  static void triggerGenerate() {
    // 使用时间戳而不是布尔值，确保每次触发都是唯一的
    _triggerTimestamp.value = DateTime.now().millisecondsSinceEpoch;
  }

  /// 重置触发状态（仅在需要时手动调用）
  static void reset() {
    _triggerTimestamp.value = 0;
  }
}
