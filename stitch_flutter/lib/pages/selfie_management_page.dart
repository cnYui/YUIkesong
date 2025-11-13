import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SelfieManagementPage extends StatefulWidget {
  const SelfieManagementPage({super.key});

  static const routeName = '/selfie-management';

  @override
  State<SelfieManagementPage> createState() => _SelfieManagementPageState();
}

class _SelfieManagementPageState extends State<SelfieManagementPage> {
  List<SelfieItem> _selfies = [];
  int _selectedIndex = 0;
  int? _pendingDeleteIndex;
  bool _isLoading = true;
  String? _error;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSelfies();
  }

  Future<void> _loadSelfies() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService.getSelfies();
      final List<dynamic> selfieList = response['list'] ?? [];
      
      print('获取到自拍列表: ${selfieList.length} 张');
      
      setState(() {
        _selfies = selfieList.map((selfie) {
          final imageUrl = selfie['image_url'] ?? selfie['image_path'];
          print('自拍 ${selfie['id']} 的图片URL: $imageUrl');
          
          return SelfieItem(
            id: selfie['id'],
            imageUrl: imageUrl,
            isDefault: selfie['is_default'] ?? false,
            createdAt: DateTime.parse(selfie['created_at']),
          );
        }).toList();
        
        // 设置默认选中的自拍
        if (_selfies.isNotEmpty) {
          final defaultIndex = _selfies.indexWhere((s) => s.isDefault);
          _selectedIndex = defaultIndex >= 0 ? defaultIndex : 0;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载自拍失败: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 加载自拍失败：${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteSelfie(int index) async {
    if (index < 0 || index >= _selfies.length) return;
    
    final selfie = _selfies[index];
    
    try {
      await ApiService.deleteSelfie(selfie.id);
      
      setState(() {
        _selfies.removeAt(index);
        _pendingDeleteIndex = null;
        
        // 调整选中索引
        if (_selfies.isEmpty) {
          _selectedIndex = 0;
        } else if (_selectedIndex >= _selfies.length) {
          _selectedIndex = _selfies.length - 1;
        } else if (_selectedIndex == index && _selfies.isNotEmpty) {
          _selectedIndex = 0;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 自拍删除成功！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 删除失败：${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _pendingDeleteIndex = null;
      });
    }
  }

  Future<void> _setDefaultSelfie(int index) async {
    if (index < 0 || index >= _selfies.length) return;
    
    final selfie = _selfies[index];
    
    try {
      await ApiService.setDefaultSelfie(selfie.id);
      
      setState(() {
        // 取消所有默认状态
        for (var s in _selfies) {
          s.isDefault = false;
        }
        // 设置新的默认
        _selfies[index].isDefault = true;
        _selectedIndex = index;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已设置为默认自拍'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 设置默认失败：${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '管理我的自拍',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: StitchColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSelfies,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '选择一张清晰、光线充足、无遮挡的正面自拍，以获得最佳的试穿效果。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          itemCount: _selfies.length + 1,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _selfies.length) {
                              return _buildUploadButton();
                            }
                            final selected = index == _selectedIndex;
                            return _buildSelfieItem(index, selected);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUploadButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _showUploadSheet,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 8),
              Text(
                '上传新自拍',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieItem(int index, bool selected) {
    final selfie = _selfies[index];
    
    print('构建自拍项 $index: URL=${selfie.imageUrl}');
    
    return GestureDetector(
      onTap: () {
        if (_pendingDeleteIndex != index) {
          setState(() {
            _selectedIndex = index;
            _pendingDeleteIndex = null;
          });
          _setDefaultSelfie(index);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              selfie.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  print('图片 $index 加载完成');
                  return child;
                }
                print('图片 $index 加载中: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('图片 $index 加载失败: $error');
                print('图片URL: ${selfie.imageUrl}');
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: (_pendingDeleteIndex == index)
                  ? GestureDetector(
                      onTap: () => _deleteSelfie(index),
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _pendingDeleteIndex = index;
                        });
                      },
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
            ),
          if (selfie.isDefault)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showUploadSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.black87),
                  title: const Text('拍照上传'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.black87),
                  title: const Text('从相册选择'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, maxWidth: 2048);
      if (!mounted) return;
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        await _uploadSelfie(bytes, xfile.name);
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 上传失败：${err.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _uploadSelfie(Uint8List bytes, String filename) async {
    try {
      // 根据文件扩展名确定MIME类型
      String contentType = 'image/jpeg'; // 默认
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }

      print('开始上传文件: $filename, MIME类型: $contentType');

      // 获取上传URL
      print('步骤1: 获取上传URL...');
      final uploadData = await ApiService.getUploadUrl(filename, contentType);
      
      // 验证上传数据
      if (uploadData == null) {
        throw Exception('获取上传URL返回null');
      }
      
      final uploadUrl = uploadData['upload_url'];
      final imagePath = uploadData['image_path'];

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw Exception('上传URL为空或null: $uploadUrl');
      }
      
      if (imagePath == null || imagePath.isEmpty) {
        throw Exception('图片路径为空或null: $imagePath');
      }

      print('获取到上传URL: $uploadUrl');
      print('图片路径: $imagePath');

      // 上传到Supabase Storage
      print('步骤2: 上传到Supabase Storage...');
      await ApiService.uploadFileToStorage(uploadUrl, bytes, contentType);
      print('文件上传成功');

      // 创建自拍记录
      print('步骤3: 创建自拍记录...');
      final result = await ApiService.createSelfie(imagePath, isDefault: false);
      print('自拍记录创建成功: $result');

      // 重新加载自拍列表
      print('步骤4: 重新加载自拍列表...');
      await _loadSelfies();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 新自拍上传成功！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('上传流程完成！');
    } catch (e) {
      print('上传失败错误: $e');
      print('错误类型: ${e.runtimeType}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 上传失败：${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      // 重新抛出错误以便调试
      rethrow;
    }
  }
}

class SelfieItem {
  final String id;
  final String imageUrl;
  bool isDefault;
  final DateTime createdAt;

  SelfieItem({
    required this.id,
    required this.imageUrl,
    required this.isDefault,
    required this.createdAt,
  });
}