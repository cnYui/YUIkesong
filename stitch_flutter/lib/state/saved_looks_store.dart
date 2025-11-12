import 'package:flutter/foundation.dart';

class SavedLook {
  const SavedLook({
    required this.id,
    required this.resultImage,
    required this.clothingImages,
    required this.timestamp,
  });

  final String id;
  final String resultImage;
  final List<String> clothingImages;
  final DateTime timestamp;
}

class SavedLooksStore {
  const SavedLooksStore._();

  static final ValueNotifier<List<SavedLook>> _looksNotifier = ValueNotifier(
    [],
  );

  static ValueListenable<List<SavedLook>> get listenable => _looksNotifier;

  static List<SavedLook> get looks => List.unmodifiable(_looksNotifier.value);

  static void addLook(SavedLook look) {
    _looksNotifier.value = [..._looksNotifier.value, look];
  }

  static void removeLook(String id) {
    _looksNotifier.value = _looksNotifier.value
        .where((look) => look.id != id)
        .toList();
  }

  static void clearAll() {
    _looksNotifier.value = [];
  }
}
