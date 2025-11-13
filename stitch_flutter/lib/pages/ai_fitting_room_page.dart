import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../services/api_service.dart';
import '../state/current_recommendation_store.dart';
import '../state/saved_looks_store.dart';
import '../state/wardrobe_selection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';

class AiFittingRoomPage extends StatefulWidget {
  const AiFittingRoomPage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<AiFittingRoomPage> createState() => _AiFittingRoomPageState();
}

class _AiFittingRoomPageState extends State<AiFittingRoomPage>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _modeIndex = 0;
  int _currentImageIndex = 0;

  static const _modeLabels = ['生成图片', '生成视频'];

  static const _generatedImages = [
    'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=80',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        const Text(
                          'AI试穿室',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: StitchColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.download,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: List.generate(_modeLabels.length, (index) {
                          final selected = index == _modeIndex;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _modeIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: selected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x11000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _modeLabels[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? Colors.black
                                        : const Color(0xFF6C6C70),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _generatedImages.length,
                            onPageChanged: (index) =>
                                setState(() => _currentImageIndex = index),
                            itemBuilder: (context, index) {
                              return Image.network(
                                _generatedImages[index],
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_generatedImages.length, (index) {
                      final selected = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 12 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.black
                              : const Color(0xFFCED1D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _modeIndex == 0 ? _saveLook : () {},
                            child: _ActionLabel(
                              icon: _modeIndex == 0
                                  ? Icons.save_outlined
                                  : Icons.movie_creation_outlined,
                              label: _modeIndex == 0 ? '保存穿搭' : '生成视频',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {},
                            child: _ActionLabel(
                              icon: Icons.refresh,
                              label: _modeIndex == 0 ? '重新生成' : '重新生成',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNav(
              currentTab: widget.currentTab,
              onTabSelected: widget.onTabSelected,
              variant: BottomNavVariant.fittingRoom,
            ),
          ),
        ],
      ),
    );
  }

  void _saveLook() async {
    try {
      // 获取用户选择的衣服图片列表
      final selectedClothingImages = _getSelectedClothingImages();
      
      if (selectedClothingImages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请先选择要保存的衣服'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 显示加载状态
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在保存穿搭...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 调用后端API保存穿搭
      final response = await ApiService.createSavedLook(
        coverImageUrl: _generatedImages[_currentImageIndex],
        clothingImageUrls: selectedClothingImages,
      );

      if (response['id'] != null) {
        // 本地也保存一份，用于即时显示
        final look = SavedLook(
          id: response['id'],
          resultImage: _generatedImages[_currentImageIndex],
          clothingImages: selectedClothingImages,
          timestamp: DateTime.now(),
        );
        SavedLooksStore.addLook(look);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('穿搭已保存成功！'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('保存失败：服务器未返回ID');
      }
    } catch (e) {
      print('保存穿搭失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存穿搭失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getSelectedClothingImages() {
    // 优先级1: 从首页推荐store中获取衣服图片
    final recommendationImages = CurrentRecommendationStore.getClothingImages();
    if (recommendationImages.isNotEmpty) {
      return recommendationImages;
    }

    // 优先级2: 从衣柜store中获取用户选择的衣服图片
    final wardrobeImages = WardrobeSelectionStore.getSelectedImages();
    if (wardrobeImages.isNotEmpty) {
      return wardrobeImages;
    }

    // 如果没有选择任何衣物，返回空列表
    return [];
  }

  @override
  bool get wantKeepAlive => true;
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
