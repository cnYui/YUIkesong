import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/stitch_tab.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';
import '../state/current_recommendation_store.dart';
import '../state/fitting_room_trigger.dart';
import '../state/saved_looks_store.dart';
import '../state/wardrobe_selection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';

class AiFittingRoomPage extends StatefulWidget {
  const AiFittingRoomPage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.autoGenerate = false,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;
  final bool autoGenerate; // 是否自动生成（从衣柜页面点击"一键生成"时使用）

  @override
  State<AiFittingRoomPage> createState() => _AiFittingRoomPageState();
}

class _AiFittingRoomPageState extends State<AiFittingRoomPage>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _modeIndex = 0;
  int _currentImageIndex = 0;
  bool _isGenerating = false;
  List<Uint8List> _generatedImages = []; // 存储生成的图片字节数据
  String? _errorMessage;
  int _lastProcessedTriggerTimestamp = 0; // 记录上次处理的触发时间戳，避免重复触发

  static const _modeLabels = ['生成图片', '生成视频'];

  @override
  void initState() {
    super.initState();
    // 如果是从衣柜页面点击"一键生成"跳转过来的（通过Navigator.push），自动生成
    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndGenerate();
      });
    }

    // 监听全局触发标志（用于通过StitchShellCoordinator切换tab的情况）
    FittingRoomTrigger.listenable.addListener(_onTriggerGenerate);
  }

  @override
  void dispose() {
    FittingRoomTrigger.listenable.removeListener(_onTriggerGenerate);
    _pageController.dispose();
    super.dispose();
  }

  /// 当全局触发标志被设置时调用
  void _onTriggerGenerate() {
    final currentTimestamp = FittingRoomTrigger.listenable.value;
    
    // 检查是否是新的触发（时间戳不为0且与上次处理的不同）
    if (currentTimestamp > 0 && 
        currentTimestamp != _lastProcessedTriggerTimestamp && 
        mounted) {
      // 记录已处理的时间戳，避免重复触发
      _lastProcessedTriggerTimestamp = currentTimestamp;
      
      // 只有在当前tab是AI试穿室时才生成
      // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在tab切换完成后执行
      if (widget.currentTab == StitchTab.fittingRoom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
        _checkAndGenerate();
          }
        });
      }
    }
  }

  /// 检查是否有选择的衣服，如果有则生成
  Future<void> _checkAndGenerate() async {
    // 防止重复触发：如果正在生成中，直接返回
    if (_isGenerating) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在生成中，请稍候...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // 检查是否有选择的衣服
    final recommendationImages = CurrentRecommendationStore.getClothingImages();
    final wardrobeImages = WardrobeSelectionStore.getSelectedImages();

    if (recommendationImages.isNotEmpty || wardrobeImages.isNotEmpty) {
      // 有选择的衣服，生成
      await _generateFittingImage();
    }
  }

  /// 将image_path转换为完整的Supabase公开URL
  String _getImageUrl(String imagePath) {
    // 如果已经是完整URL，直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // 否则构造Supabase公开URL
    final supabaseUrl = ApiService.supabaseUrl;
    // 判断是自拍还是衣物
    if (imagePath.contains('selfies')) {
      return '$supabaseUrl/storage/v1/object/public/selfies/$imagePath';
    } else {
      return '$supabaseUrl/storage/v1/object/public/wardrobe/$imagePath';
    }
  }

  /// 获取默认头像（自拍）
  Future<Uint8List?> _getDefaultAvatar() async {
    try {
      final response = await ApiService.getSelfies();
      final List<dynamic> selfieList = response['list'] ?? [];

      if (selfieList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请先上传一张自拍作为头像'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // 找到默认自拍，如果没有则使用第一个
      final defaultSelfie = selfieList.firstWhere(
        (selfie) => selfie['is_default'] == true,
        orElse: () => selfieList[0],
      );

      final imagePath =
          defaultSelfie['image_url'] ?? defaultSelfie['image_path'];
      if (imagePath == null || imagePath.isEmpty) {
        return null;
      }

      // 转换为完整URL
      final imageUrl = _getImageUrl(imagePath);

      // 下载图片
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode == 200) {
        final imageBytes = imageResponse.bodyBytes;
        
        // 验证图片是否有效（至少要有基本的文件头）
        if (imageBytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('头像图片为空，请重新上传'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return null;
        }
        
        // 验证图片格式
        final mimeType = _getImageMimeType(imageBytes);
        if (kDebugMode) {
          print('📸 下载的头像信息:');
          print('  - URL: $imageUrl');
          print('  - 大小: ${imageBytes.length} bytes');
          print('  - 格式: $mimeType');
          // 打印文件头用于调试
          if (imageBytes.length >= 4) {
            final header = imageBytes.sublist(0, 4).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ');
            print('  - 文件头: $header');
          }
        }
        
        return imageBytes;
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取头像失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return null;
    }
  }

  /// 获取选择的衣服图片
  Future<List<Uint8List>> _getSelectedClothingImages() async {
    final selectedImages = <Uint8List>[];

    // 优先级1: 从首页推荐store中获取衣服图片
    final recommendationImages = CurrentRecommendationStore.getClothingImages();
    if (recommendationImages.isNotEmpty) {
      for (var imagePath in recommendationImages) {
        try {
          // 转换为完整URL
          final imageUrl = _getImageUrl(imagePath);
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            selectedImages.add(response.bodyBytes);
          }
        } catch (e) {
          print('下载推荐图片失败: $e');
        }
      }
      if (selectedImages.isNotEmpty) return selectedImages;
    }

    // 优先级2: 从衣柜store中获取用户选择的衣服图片
    final wardrobeImages = WardrobeSelectionStore.getSelectedImages();
    if (wardrobeImages.isNotEmpty) {
      for (var imagePath in wardrobeImages) {
        try {
          // 转换为完整URL
          final imageUrl = _getImageUrl(imagePath);
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            selectedImages.add(response.bodyBytes);
          }
        } catch (e) {
          print('下载衣柜图片失败: $e');
        }
      }
    }

    return selectedImages;
  }

  /// 获取图片的MIME类型
  String _getImageMimeType(Uint8List imageBytes) {
    // 检查图片格式
    if (imageBytes.length >= 4) {
      // JPEG: FF D8 FF
      if (imageBytes[0] == 0xFF &&
          imageBytes[1] == 0xD8 &&
          imageBytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // PNG: 89 50 4E 47
      if (imageBytes[0] == 0x89 &&
          imageBytes[1] == 0x50 &&
          imageBytes[2] == 0x4E &&
          imageBytes[3] == 0x47) {
        return 'image/png';
      }
      // WebP: RIFF ... WEBP
      if (imageBytes.length >= 12 &&
          imageBytes[0] == 0x52 &&
          imageBytes[1] == 0x49 &&
          imageBytes[2] == 0x46 &&
          imageBytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    // 默认返回jpeg
    return 'image/jpeg';
  }

  /// 生成试穿图片
  Future<void> _generateFittingImage() async {
    // 检查用户是否已登录
    if (!ApiService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _errorMessage = '请先登录';
        });
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // 1. 获取默认头像
      final avatarBytes = await _getDefaultAvatar();
      if (avatarBytes == null) {
        setState(() {
          _isGenerating = false;
          _errorMessage = '未找到默认头像，请先上传自拍';
        });
        return;
      }

      // 2. 获取选择的衣服图片
      final clothingImagesBytes = await _getSelectedClothingImages();
      if (clothingImagesBytes.isEmpty) {
        setState(() {
          _isGenerating = false;
          _errorMessage = '请先在我的衣柜中选择衣服';
        });
        return;
      }

      // 3. 准备MIME类型
      final avatarMimeType = _getImageMimeType(avatarBytes);
      final clothingMimeTypes = clothingImagesBytes
          .map((bytes) => _getImageMimeType(bytes))
          .toList();

      // 4. 调用Gemini API生成试穿图片
      final generatedImage = await GeminiService.generateFittingImage(
        avatarBytes,
        avatarMimeType,
        clothingImagesBytes,
        clothingMimeTypes,
      );

      // 5. 更新UI显示生成的图片
      if (mounted) {
        setState(() {
          _generatedImages = [generatedImage];
          _currentImageIndex = 0;
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 试穿图片生成成功！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString();
        });

        String errorMessage;
        if (e is GeminiQuotaException) {
          errorMessage = 'Gemini API 配额已用完，将使用默认图片。您可以稍后再试。';
        } else {
          errorMessage = '生成试穿图片失败: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
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
                          child: _isGenerating
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(
                                        '正在生成试穿图片...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6C6C70),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _generatedImages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage ?? '暂无生成的图片',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: _generatedImages.length,
                                  onPageChanged: (index) => setState(
                                    () => _currentImageIndex = index,
                                  ),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      color: Colors.white,
                                      child: Image.memory(
                                        _generatedImages[index],
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (_generatedImages.isNotEmpty)
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
                            onPressed: _isGenerating
                                ? null
                                : _generateFittingImage,
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
      // 获取用户选择的衣服图片URL列表
      final selectedClothingImages = _getSelectedClothingImageUrls();

      print('======= AI试穿室保存穿搭 =======');
      print('选中的衣物图片: $selectedClothingImages');
      print('衣物数量: ${selectedClothingImages.length}');
      print('封面图片: ${_generatedImages[_currentImageIndex]}');
      print('===============================');

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

      // 如果有生成的图片，需要先上传到服务器获取URL
      String? coverImageUrl;
      if (_generatedImages.isNotEmpty &&
          _currentImageIndex < _generatedImages.length) {
        // 将生成的图片上传到服务器
        try {
          final generatedImageBytes = _generatedImages[_currentImageIndex];
          final filename =
              'fitting_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final contentType = 'image/jpeg';

          // 获取上传URL
          final uploadData = await ApiService.getClothingUploadUrl(
            filename,
            contentType,
          );

          // 上传图片
          await ApiService.uploadFileToStorage(
            uploadData['upload_url'],
            generatedImageBytes,
            contentType,
          );

          // 获取公开URL（这里需要根据实际API调整）
          coverImageUrl = uploadData['image_path'] ?? uploadData['image_url'];
        } catch (e) {
          print('上传生成的图片失败: $e');
          // 如果上传失败，使用第一个选择的衣服图片作为封面
          if (selectedClothingImages.isNotEmpty) {
            coverImageUrl = selectedClothingImages[0];
          }
        }
      } else if (selectedClothingImages.isNotEmpty) {
        // 如果没有生成的图片，使用第一个选择的衣服图片作为封面
        coverImageUrl = selectedClothingImages[0];
      }

      if (coverImageUrl == null) {
        throw Exception('无法获取封面图片');
      }

      // 调用后端API保存穿搭
      print('开始调用后端API...');
      final response = await ApiService.createSavedLook(
        coverImageUrl: coverImageUrl,
        clothingImageUrls: selectedClothingImages,
      );
      print('后端响应: $response');

      if (response['id'] != null) {
        // 本地也保存一份，用于即时显示
        final look = SavedLook(
          id: response['id'],
          resultImage: coverImageUrl,
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

  /// 获取选择的衣服图片URL列表（用于保存穿搭）
  List<String> _getSelectedClothingImageUrls() {
    print('\n--- 获取选中的衣物图片URL ---');

    // 优先级1: 从首页推荐store中获取衣服图片
    final recommendationImages = CurrentRecommendationStore.getClothingImages();
    print('首页推荐图片: $recommendationImages');
    if (recommendationImages.isNotEmpty) {
      print('使用首页推荐图片');
      return recommendationImages;
    }

    // 优先级2: 从衣柜store中获取用户选择的衣服图片
    final wardrobeImages = WardrobeSelectionStore.getSelectedImages();
    print('衣柜选择图片: $wardrobeImages');
    if (wardrobeImages.isNotEmpty) {
      print('使用衣柜选择图片');
      return wardrobeImages;
    }

    // 如果没有选择任何衣物，返回空列表
    print('未找到任何衣物图片');
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
