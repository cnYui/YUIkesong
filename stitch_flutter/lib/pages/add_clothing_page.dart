import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/gemini_service.dart';

class AddClothingPage extends StatefulWidget {
  const AddClothingPage({super.key});

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  File? _imageFile;
  Uint8List? _webImage;
  Uint8List? _originalImageBytes; // 保存原始图片用于处理
  String? _selectedCategory;
  bool _isUploading = false;
  bool _isProcessing = false; // 图片处理状态

  final List<String> _categories = ['上装', '下装', '连衣裙', '外套', '鞋履', '配饰'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        // 读取原始图片字节
        final originalBytes = await pickedFile.readAsBytes();
        _originalImageBytes = originalBytes;

        // 显示原始图片
        if (kIsWeb) {
          setState(() {
            _webImage = originalBytes;
            _imageFile = null;
            _isProcessing = true;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _isProcessing = true;
          });
        }
        
        // 自动生成文件名
        if (_nameController.text.isEmpty) {
          final fileName = pickedFile.name;
          _nameController.text = fileName.split('.').first;
        }

        // 调用Gemini API处理图片
        await _processImageWithGemini(originalBytes, pickedFile.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 使用Gemini API处理图片
  /// 只有在用户登录后才调用Gemini API
  Future<void> _processImageWithGemini(
    Uint8List imageBytes,
    String fileName,
  ) async {
    // 检查用户是否已登录
    if (!ApiService.isAuthenticated) {
      if (kDebugMode) {
        print('⚠️ 用户未登录，跳过Gemini图片处理');
      }
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔄 开始使用Gemini处理图片...');
      }

      // 获取图片MIME类型
      final mimeType = _getImageMimeType(fileName);

      // 调用Gemini API处理图片
      final processedBytes = await GeminiService.processClothingImage(
        imageBytes,
        mimeType,
      );

      if (kDebugMode) {
        print('✅ Gemini图片处理完成，大小: ${processedBytes.length} bytes');
      }

      // 更新UI显示处理后的图片
      if (mounted) {
        // 对于非Web平台，先将处理后的图片保存为临时文件
        File? tempFile;
        if (!kIsWeb) {
          final tempDir = Directory.systemTemp;
          tempFile = File(
            '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(processedBytes);
        }

        setState(() {
          if (kIsWeb) {
            _webImage = processedBytes;
            _imageFile = null;
          } else {
            _imageFile = tempFile;
            _webImage = null;
          }
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 图片处理完成！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemini图片处理失败: $e');
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // 根据错误类型显示不同的提示
        String errorMessage;
        Color backgroundColor;
        int duration;

        if (e is GeminiQuotaException) {
          // 配额错误：显示友好的提示
          errorMessage = 'Gemini API 配额已用完，将使用原始图片。您可以稍后再试或联系管理员。';
          backgroundColor = Colors.orange;
          duration = 5;
        } else {
          // 其他错误：显示错误信息
          final errorStr = e.toString();
          if (errorStr.length > 100) {
            errorMessage = '图片处理失败，将使用原始图片: ${errorStr.substring(0, 100)}...';
          } else {
            errorMessage = '图片处理失败，将使用原始图片: $errorStr';
          }
          backgroundColor = Colors.orange;
          duration = 4;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: duration),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照添加衣物'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择衣物'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getImageMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _uploadClothing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择衣物图片')));
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择衣物类别')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 获取文件名和图片字节（使用处理后的图片，如果处理失败则使用原始图片）
      String filename;
      Uint8List imageBytes;
      
      if (_imageFile != null) {
        filename = _imageFile!.path.split('/').last;
        imageBytes = await _imageFile!.readAsBytes();
      } else if (_webImage != null) {
        filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageBytes = _webImage!;
      } else if (_originalImageBytes != null) {
        // 如果处理失败，使用原始图片
        filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageBytes = _originalImageBytes!;
      } else {
        throw Exception('没有可用的图片数据');
      }

      final contentType = _getImageMimeType(filename);

      // 1. 获取上传URL
      final uploadData = await ApiService.getClothingUploadUrl(
        filename,
        contentType,
      );
      
      // 2. 上传图片
      await ApiService.uploadFileToStorage(
        uploadData['upload_url'],
        imageBytes,
        contentType,
      );

      // 3. 创建衣物记录
      final clothingData = await ApiService.createClothingItem(
        uploadData['image_path'],
        _nameController.text,
        _selectedCategory!,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('衣物添加成功！')));
        Navigator.pop(context, clothingData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '添加衣物',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片预览
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _isProcessing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                '正在处理图片...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          )
                        : _webImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  _webImage!,
                                  fit: BoxFit.cover,
                                  width: 200,
                                  height: 200,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '点击添加衣物图片',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 衣物名称
              const Text(
                '衣物名称',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '请输入衣物名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入衣物名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 选择类别
              const Text(
                '选择类别',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  hintText: '请选择类别',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '请选择衣物类别';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadClothing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '保存到衣柜',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
