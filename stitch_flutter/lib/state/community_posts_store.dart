import 'package:flutter/foundation.dart';

class CommunityPostData {
  const CommunityPostData({
    required this.id,
    required this.images,
    required this.username,
    required this.avatar,
    this.description,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.createdAt,
  });

  final String id;
  final List<String> images;
  final String username;
  final String avatar;
  final String? description;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime? createdAt;

  CommunityPostData copyWith({
    String? id,
    List<String>? images,
    String? username,
    String? avatar,
    String? description,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return CommunityPostData(
      id: id ?? this.id,
      images: images ?? this.images,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CommentData {
  const CommentData({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String nickname;
  final String avatarUrl;
  final String content;
  final DateTime createdAt;
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
    // 添加到列表开头（最新的在前面）
    _postsNotifier.value = [post, ..._postsNotifier.value];
  }

  static void setPosts(List<CommunityPostData> posts) {
    _postsNotifier.value = posts;
  }

  static void updatePost(String postId, CommunityPostData updatedPost) {
    final currentPosts = List<CommunityPostData>.from(_postsNotifier.value);
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      currentPosts[index] = updatedPost;
      _postsNotifier.value = currentPosts;
    }
  }

  static void clear() {
    _postsNotifier.value = [];
  }
}

