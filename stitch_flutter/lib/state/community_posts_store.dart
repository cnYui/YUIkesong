import 'package:flutter/foundation.dart';

class CommunityPostData {
  const CommunityPostData({
    required this.id,
    required this.images,
    required this.username,
    required this.avatar,
  });

  final String id;
  final List<String> images;
  final String username;
  final String avatar;
}

class CommunityPostsStore {
  const CommunityPostsStore._();

  static final ValueNotifier<List<CommunityPostData>> _postsNotifier =
      ValueNotifier<List<CommunityPostData>>([]);

  static ValueListenable<List<CommunityPostData>> get listenable =>
      _postsNotifier;

  static List<CommunityPostData> get posts =>
      List.unmodifiable(_postsNotifier.value);

  static void addPost(CommunityPostData post) {
    _postsNotifier.value = [..._postsNotifier.value, post];
  }

  static void clear() {
    _postsNotifier.value = [];
  }
}

