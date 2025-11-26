import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../state/saved_looks_store.dart';
import '../state/community_posts_store.dart';

class SavedLooksPage extends StatefulWidget {
  const SavedLooksPage({super.key});

  static const routeName = '/saved-looks';

  @override
  State<SavedLooksPage> createState() => _SavedLooksPageState();
}

class _SavedLooksPageState extends State<SavedLooksPage> {
  final Set<String> _selectedIds = <String>{};
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 进入页面时先清空本地数据，避免重复显示
      SavedLooksStore.clearAll();
      _loadSavedLooks(isRefresh: true);
    });
  }

  Future<void> _loadSavedLooks({bool isRefresh = false}) async {
    if (isRefresh) {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          _error = null;
        });
      }
    }

    if (!_hasMore && !isRefresh) return;

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      final response = await ApiService.getSavedLooks(
        page: _currentPage,
        pageSize: _pageSize,
      );

      final List<dynamic> items = response['list'] ?? [];
      final int total = response['total'] ?? 0;

      print('======= 后端返回的原始数据 =======');
      print('响应数据: $response');
      print('穿搭列表长度: ${items.length}');
      print('================================');

      // 将后端数据转换为本地SavedLook对象
      final List<SavedLook> looks = items.map((item) {
        print('\n--- 处理穿搭 ${item['id']} ---');
        print('原始item数据: $item');
        
        final List<String> clothingImagePaths = 
            (item['clothing_image_urls'] as List<dynamic>?)
                ?.cast<String>() ?? [];
        
        print('解析后的衣物图片路径: $clothingImagePaths');
        print('衣物图片数量: ${clothingImagePaths.length}');
        
        return SavedLook(
          id: item['id'].toString(),
          resultImage: item['cover_image_url'] ?? '',
          clothingImages: clothingImagePaths,
          timestamp: DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();

      // 更新本地存储
      if (isRefresh) {
        SavedLooksStore.clearAll();
      }
      
      for (final look in looks) {
        SavedLooksStore.addLook(look);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = items.length == _pageSize;
          if (!isRefresh && items.length == _pageSize) {
            _currentPage++;
          }
        });
      }

    } catch (e) {
      print('加载保存穿搭失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '我保存的穿搭',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => _loadSavedLooks(isRefresh: true),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<SavedLook>>(
        valueListenable: SavedLooksStore.listenable,
        builder: (context, looks, _) {
          if (_isLoading && looks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null && looks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: $_error', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadSavedLooks(isRefresh: true),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final existingIds = looks.map((look) => look.id).toSet();
          if (looks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    '浏览并管理你保存的穿搭组合，随时重新查看灵感。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  SizedBox(height: 24),
                  Expanded(child: _SavedLooksEmptyView()),
                ],
              ),
            );
          }

          final invalidIds = _selectedIds.where(
            (id) => !existingIds.contains(id),
          );
          if (invalidIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedIds.removeAll(invalidIds));
            });
          }

          final selectedLooks = looks
              .where((look) => _selectedIds.contains(look.id))
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () => _loadSavedLooks(isRefresh: true),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '浏览并管理你保存的穿搭组合，随时重新查看灵感。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          itemCount: looks.length + (_hasMore ? 1 : 0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.6,
                              ),
                          itemBuilder: (context, index) {
                            if (index == looks.length) {
                              // 加载更多指示器
                              if (_isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (_hasMore) {
                                // 使用addPostFrameCallback避免在构建过程中调用setState
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _loadSavedLooks(isRefresh: false);
                                });
                                return const Center(child: CircularProgressIndicator());
                              } else {
                                return const SizedBox.shrink();
                              }
                            }
                            
                            final look = looks[index];
                            final isSelected = _selectedIds.contains(look.id);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(look.id);
                                  } else {
                                    _selectedIds.add(look.id);
                                  }
                                });
                              },
                              child: _SavedLookCard(
                                look: look,
                                isSelected: isSelected,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedLooks.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SelectionBar(
                      looks: selectedLooks,
                      onDeletePressed: () => _handleDelete(selectedLooks),
                      onPublishPressed: () =>
                          _handlePublish(selectedLooks.length),
                      onLookTapped: (look) {
                        setState(() => _selectedIds.remove(look.id));
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDelete(List<SavedLook> looks) async {
    if (looks.isEmpty) return;
    
    try {
      for (final look in looks) {
        print('正在删除穿搭: ID=${look.id}, 图片=${look.resultImage}');
        await ApiService.deleteSavedLook(look.id);
        SavedLooksStore.removeLook(look.id);
      }
      
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除选中的穿搭'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      print('删除穿搭失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePublish(int count) async {
    if (count == 0) return;
    
    try {
      final looks = SavedLooksStore.looks
          .where((l) => _selectedIds.contains(l.id))
          .toList(growable: false);
          
      int successCount = 0;
      
      for (final look in looks) {
        try {
          final response = await ApiService.publishSavedLook(look.id);
          print('发布成功: ${response['post_id']}');
          successCount++;
        } catch (e) {
          print('发布穿搭 ${look.id} 失败: $e');
        }
      }
      
      setState(() => _selectedIds.clear());
      
      if (mounted) {
        if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('已成功发布 $successCount 套穿搭到社区'),
              backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('发布失败，请稍后重试'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('发布穿搭失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SavedLooksEmptyView extends StatelessWidget {
  const _SavedLooksEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Color(0xFFCED1D6)),
          SizedBox(height: 16),
          Text(
            '还没有保存的穿搭',
            style: TextStyle(fontSize: 16, color: Color(0xFF6C6C70)),
          ),
        ],
      ),
    );
  }
}

class _SavedLookCard extends StatelessWidget {
  const _SavedLookCard({required this.look, required this.isSelected});

  final SavedLook look;
  final bool isSelected;

  // 将image_path转换为公开URL
  String _getImageUrl(String imagePath) {
    // 如果已经是完整URL，直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // 否则构造Supabase公开URL
    return '${ApiConfig.supabaseUrl}/storage/v1/object/public/wardrobe/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getImageUrl(look.resultImage),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    print('封面图片加载失败: ${look.resultImage}, 错误: $error');
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: look.clothingImages.isEmpty
                  ? const SizedBox.shrink()
                  : look.clothingImages.length <= 2
                      ? Row(
                          children: [
                            for (var i = 0; i < look.clothingImages.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: i < look.clothingImages.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _getImageUrl(look.clothingImages[i]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('衣物图片加载失败: ${look.clothingImages[i]}, 错误: $error');
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: look.clothingImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _getImageUrl(look.clothingImages[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('衣物图片加载失败: ${look.clothingImages[index]}, 错误: $error');
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.looks,
    required this.onDeletePressed,
    required this.onPublishPressed,
    required this.onLookTapped,
  });

  final List<SavedLook> looks;
  final VoidCallback onDeletePressed;
  final VoidCallback onPublishPressed;
  final ValueChanged<SavedLook> onLookTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final look in looks)
                      GestureDetector(
                        onTap: () => onLookTapped(look),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(look.resultImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: onDeletePressed,
              child: const Text(
                '删除',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: onPublishPressed,
              child: const Text(
                '发布社区',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
