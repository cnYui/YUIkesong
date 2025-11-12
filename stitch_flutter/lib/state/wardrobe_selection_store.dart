import 'package:flutter/foundation.dart';

class WardrobeSelectionStore {
  const WardrobeSelectionStore._();

  static final ValueNotifier<Set<int>> _selectionNotifier = ValueNotifier({});
  static final ValueNotifier<Map<int, String>> _itemImagesNotifier =
      ValueNotifier({});

  static ValueListenable<Set<int>> get listenable => _selectionNotifier;

  static Set<int> get selections => Set.unmodifiable(_selectionNotifier.value);

  static void setSelections(Set<int> indices) {
    _selectionNotifier.value = Set.from(indices);
  }

  static void setItemImages(Map<int, String> images) {
    _itemImagesNotifier.value = Map.from(images);
  }

  static List<String> getSelectedImages() {
    final selections = _selectionNotifier.value;
    final images = _itemImagesNotifier.value;
    return selections
        .map((index) => images[index] ?? '')
        .where((img) => img.isNotEmpty)
        .toList();
  }
}
