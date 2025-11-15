import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../state/community_posts_store.dart';
import '../theme/app_theme.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    required this.images,
    required this.username,
    required this.avatar,
  });

  static const routeName = '/post-detail';

  final String postId;
  final List<String> images;
  final String username;
  final String avatar;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int _currentImageIndex = 0;
  bool _isLiked = false;
  int _likesCount = 0;
  List<CommentData> _comments = [];
  String? _description;
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
    _loadComments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetail() async {
    try {
      final response = await ApiService.getCommunityPostDetail(widget.postId);
      if (mounted) {
        setState(() {
          _description = response['description'];
          _likesCount = response['likes_count'] ?? 0;
          _isLiked = response['is_liked'] ?? false;
        });
      }
    } catch (e) {
      print('加载帖子详情失败: $e');
    }
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments) return;

    setState(() => _isLoadingComments = true);

    try {
      final response = await ApiService.getPostComments(postId: widget.postId);
      final List<dynamic> list = response['list'] ?? [];

      final comments = list.map((item) {
        return CommentData(
          id: item['id'].toString(),
          userId: item['user']['id'].toString(),
          nickname: item['user']['nickname'] ?? '匿名用户',
          avatarUrl: item['user']['avatar_url'] ?? '',
          content: item['content'] ?? '',
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('加载评论失败: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载评论失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;

    setState(() => _isTogglingLike = true);

    try {
      final response = await ApiService.toggleLike(widget.postId);
      final newLikesCount = response['likes'] ?? _likesCount;

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount = newLikesCount;
          _isTogglingLike = false;
        });

        // 更新 store 中的数据
        final posts = CommunityPostsStore.posts;
        final postIndex = posts.indexWhere((p) => p.id == widget.postId);
        if (postIndex != -1) {
          final updatedPost = posts[postIndex].copyWith(
            isLiked: _isLiked,
            likesCount: _likesCount,
          );
          CommunityPostsStore.updatePost(widget.postId, updatedPost);
        }
      }
    } catch (e) {
      print('点赞失败: $e');
      if (mounted) {
        setState(() => _isTogglingLike = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入评论内容')),
      );
      return;
    }

    if (_isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);

    try {
      await ApiService.addComment(
        postId: widget.postId,
        content: content,
      );

      _commentController.clear();
      
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('评论成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // 重新加载评论列表
        _loadComments();
      }
    } catch (e) {
      print('提交评论失败: $e');
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final supabaseUrl = ApiService.supabaseUrl;
    return '$supabaseUrl/storage/v1/object/public/wardrobe/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: StitchColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '帖子详情',
          style: TextStyle(
            color: StitchColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // 图片轮播（带底部指示器）
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: widget.images.isEmpty
                    ? Container(color: Colors.grey[300])
                    : Stack(
                        children: [
                          // 图片轮播
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.images.length,
                            onPageChanged: (index) => setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) {
                              return Image.network(
                                _getImageUrl(widget.images[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, size: 48),
                                  );
                                },
                              );
                            },
                          ),
                          // 底部指示器（只在有多张图片时显示）
                          if (widget.images.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(widget.images.length, (index) {
                                  final selected = index == _currentImageIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: selected ? 24 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selected 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
                  // 用户信息
            Row(
              children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: widget.avatar.isNotEmpty
                            ? NetworkImage(_getImageUrl(widget.avatar))
                            : null,
                        onBackgroundImageError: widget.avatar.isNotEmpty
                            ? (_, __) {}
                            : null,
                        backgroundColor: Colors.grey[300],
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: StitchColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
                  if (_description != null && _description!.isNotEmpty) ...[
            const SizedBox(height: 12),
                    Text(
                      _description!,
                      style: const TextStyle(fontSize: 14, color: StitchColors.textSecondary),
            ),
                  ],
            const SizedBox(height: 16),
                  // 操作按钮
            Row(
                    children: [
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        label: _likesCount > 0 ? '$_likesCount' : '点赞',
                        color: _isLiked ? Colors.red : StitchColors.textPrimary,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 20),
                      _ActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: _comments.length > 0 ? '${_comments.length}' : '评论',
                        onTap: () {
                          // 滚动到评论区域
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      const _ActionButton(
                        icon: Icons.share_outlined,
                        label: '分享',
                      ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
                    '评论',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: StitchColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
                  // 评论列表
                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '暂无评论，快来抢沙发吧~',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((comment) => _CommentItem(comment: comment)),
                ],
              ),
            ),
          ),
          // 评论输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '说点什么...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSubmittingComment ? null : _submitComment,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: _isSubmittingComment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '发送',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
            Icon(icon, color: color ?? StitchColors.textPrimary, size: 22),
        const SizedBox(width: 6),
        Text(
          label,
              style: TextStyle(
                fontSize: 13,
                color: color ?? StitchColors.textPrimary,
              ),
        ),
      ],
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment});

  final CommentData comment;

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final supabaseUrl = ApiService.supabaseUrl;
    return '$supabaseUrl/storage/v1/object/public/wardrobe/$imagePath';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}-${time.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.avatarUrl.isNotEmpty
                ? NetworkImage(_getImageUrl(comment.avatarUrl))
                : null,
            onBackgroundImageError: comment.avatarUrl.isNotEmpty
                ? (_, __) {}
                : null,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: StitchColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: StitchColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: StitchColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
