import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'post_detail_page.dart';
import '../state/community_posts_store.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedTab = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    // 只有在已登录时才加载社区帖子
    if (ApiService.isAuthenticated) {
      _loadCommunityPosts(isRefresh: true);
    }
  }

  /// 加载社区帖子
  Future<void> _loadCommunityPosts({bool isRefresh = false}) async {
    // 检查登录状态
    if (!ApiService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '请先登录';
        });
      }
      return;
    }

    if (_isLoading || (!_hasMore && !isRefresh)) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _error = null;
      });
      CommunityPostsStore.clear();
    }

    setState(() => _isLoading = true);

    try {
      print('开始加载社区帖子，页码: $_currentPage');
      final response = await ApiService.getCommunityPosts(
        page: _currentPage,
        pageSize: _pageSize,
      );

      print('API响应: $response');
      final List<dynamic> list = response['list'] ?? [];
      final int total = response['total'] ?? 0;
      print('获取到 ${list.length} 个帖子，总共 $total 个');

      final posts = list.map((item) {
        print('处理帖子数据: ${item['id']}');
        final List<dynamic> imagesData = [];
        
        // 如果返回的是完整的帖子详情（包含images数组）
        if (item['images'] != null && item['images'] is List) {
          imagesData.addAll(item['images']);
        } else {
          // 否则只有封面图
          if (item['cover_image_url'] != null) {
            imagesData.add({'image_url': item['cover_image_url']});
          }
        }

        final images = imagesData
            .map((img) => (img is String) ? img : (img['image_url'] as String))
            .toList();

        return CommunityPostData(
          id: item['id']?.toString() ?? '',
          images: images,
          username: item['username'] ?? '匿名用户',
          avatar: item['avatar'] ?? '',
          description: item['description'],
          likesCount: item['likes_count'] ?? 0,
          commentsCount: item['comments_count'] ?? 0,
          isLiked: item['is_liked'] ?? false,
          createdAt: item['created_at'] != null 
              ? DateTime.tryParse(item['created_at'])
              : null,
        );
      }).toList();
      
      print('成功处理 ${posts.length} 个帖子');

      if (isRefresh) {
        CommunityPostsStore.setPosts(posts);
      } else {
        for (final post in posts) {
          CommunityPostsStore.addPost(post);
        }
      }

      setState(() {
        _isLoading = false;
        _hasMore = list.length == _pageSize;
        if (!isRefresh && list.length == _pageSize) {
          _currentPage++;
        }
      });
    } catch (e) {
      print('加载社区帖子失败: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
      ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      const Expanded(
                        child: Text(
                          '社区',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: StitchColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: StitchColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 0
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '推荐',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? Colors.black
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 1
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '关注',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 1
                                  ? Colors.black
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<CommunityPostData>>(
                  valueListenable: CommunityPostsStore.listenable,
                  builder: (context, posts, _) {
                    if (_isLoading && posts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_error != null && posts.isEmpty) {
                      // 检查是否是未登录错误
                      if (_error == '请先登录') {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                '请先登录查看社区内容',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/login');
                                },
                                child: const Text(
                                  '前往登录',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // 其他错误显示重试按钮
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('加载失败: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadCommunityPosts(isRefresh: true),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (posts.isEmpty) {
                      return const Center(
                        child: Text('暂无帖子', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _loadCommunityPosts(isRefresh: true),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                              child: Column(
                              children: [
                                  ...posts.asMap().entries.where((entry) => entry.key % 2 == 0).map(
                                    (entry) => _PostCard(post: entry.value),
                                  ),
                              ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.1,
                          ),
                          child: Column(
                                  children: [
                                    ...posts.asMap().entries.where((entry) => entry.key % 2 == 1).map(
                                      (entry) => _PostCard(post: entry.value),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNav(
              currentTab: widget.currentTab,
              onTabSelected: widget.onTabSelected,
              variant: BottomNavVariant.community,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPostData post;

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    final supabaseUrl = ApiService.supabaseUrl;
    return '$supabaseUrl/storage/v1/object/public/wardrobe/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                postId: post.id,
                images: post.images,
                username: post.username,
                avatar: post.avatar,
              ),
              ),
            );
          },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  _getImageUrl(post.images.isNotEmpty ? post.images.first : ''),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 48),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(_getImageUrl(post.avatar)),
                    onBackgroundImageError: (_, __) {},
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.username,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
