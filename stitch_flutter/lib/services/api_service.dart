import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3001';
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static bool get isAuthenticated {
    return _token != null;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // 自拍管理相关API
  static Future<Map<String, dynamic>> getSelfies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/selfies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取自拍列表失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> deleteSelfie(String selfieId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/selfies/$selfieId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('删除自拍失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> setDefaultSelfie(String selfieId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/selfies/$selfieId/default'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('设置默认自拍失败: ${response.statusCode}');
    }
  }

  // 获取上传URL
  static Future<Map<String, dynamic>> getUploadUrl(String filename, String contentType) async {
    print('请求上传URL - 文件名: $filename, 内容类型: $contentType');
    
    final response = await http.post(
      Uri.parse('$baseUrl/selfies/upload-url'),
      headers: _headers,
      body: json.encode({
        'filename': filename,
        'content_type': contentType,
      }),
    );

    print('上传URL响应状态码: ${response.statusCode}');
    print('上传URL响应体: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('解析的响应数据: $responseData');
      
      // 验证响应数据完整性
      if (responseData['upload_url'] == null || responseData['image_path'] == null) {
        print('错误: 响应数据缺少必要字段');
        throw Exception('上传URL响应数据不完整: ${responseData}');
      }
      
      return responseData;
    } else {
      print('获取上传URL失败，状态码: ${response.statusCode}');
      throw Exception('获取上传URL失败: ${response.statusCode} - ${response.body}');
    }
  }

  // 创建自拍记录
  static Future<Map<String, dynamic>> createSelfie(String imagePath, {bool isDefault = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/selfies'),
      headers: _headers,
      body: json.encode({
        'image_path': imagePath,
        'is_default': isDefault,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('创建自拍记录失败: ${response.statusCode}');
    }
  }

  // 上传文件到Supabase Storage
  static Future<void> uploadFileToStorage(String uploadUrl, Uint8List fileBytes, String contentType) async {
    print('开始上传文件到Supabase Storage...');
    print('上传URL: $uploadUrl');
    print('内容类型: $contentType');
    print('文件大小: ${fileBytes.length} bytes');

    try {
      // 确保URL格式正确
      if (uploadUrl.isEmpty) {
        throw Exception('上传URL为空');
      }

      // 如果URL包含中文或特殊字符，进行编码
      String processedUrl = uploadUrl;
      if (uploadUrl.contains('微信图片') || uploadUrl.contains('%')) {
        // URL可能已经被编码，直接使用
        processedUrl = uploadUrl;
      }

      print('处理后的上传URL: $processedUrl');

      final response = await http.put(
        Uri.parse(processedUrl),
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length.toString(),
          // 添加缓存控制头部
          'Cache-Control': 'public, max-age=31536000',
          // 确保使用二进制数据上传
          'Accept': '*/*',
          // 移除可能引起问题的头部
          'User-Agent': 'Flutter/Dart',
        },
        body: fileBytes,
      );

      print('上传响应状态码: ${response.statusCode}');
      print('上传响应头部: ${response.headers}');
      
      // 对于文件上传，响应体可能为空或很大，只打印部分信息
      final responseBody = response.body;
      if (responseBody.length > 200) {
        print('上传响应体(前200字符): ${responseBody.substring(0, 200)}...');
      } else if (responseBody.isNotEmpty) {
        print('上传响应体: $responseBody');
      } else {
        print('上传响应体: (空)');
      }

      // Supabase Storage上传可能返回多种状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('文件上传成功！');
      } else {
        throw Exception('上传文件失败: ${response.statusCode} - ${responseBody}');
      }
    } catch (e) {
      print('文件上传异常: $e');
      if (e.toString().contains('400')) {
        print('提示: 400错误通常表示请求格式不正确，请检查文件大小和格式');
      } else if (e.toString().contains('401')) {
        print('提示: 401错误表示认证失败，请检查上传权限');
      } else if (e.toString().contains('413')) {
        print('提示: 413错误表示文件太大，请压缩图片后重试');
      }
      rethrow;
    }
  }

  // 衣物管理相关API
  static Future<Map<String, dynamic>> getClothingItems({String? category}) async {
    String url = '$baseUrl/wardrobe';
    if (category != null && category != '全部') {
      url += '?category=${Uri.encodeComponent(category)}';
    }
    print('请求衣柜列表: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    print('衣柜列表响应状态码: ${response.statusCode}');
    print('衣柜列表响应体长度: ${response.body.length}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取衣物列表失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> deleteClothingItem(String itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wardrobe/$itemId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('删除衣物失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> setDefaultClothingItem(String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/$itemId/default'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('设置默认衣物失败: ${response.statusCode}');
    }
  }

  // 获取衣物上传URL
  static Future<Map<String, dynamic>> getClothingUploadUrl(String filename, String contentType) async {
    print('请求衣物上传URL - 文件名: $filename, 内容类型: $contentType');
    
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/upload-url'),
      headers: _headers,
      body: json.encode({
        'filename': filename,
        'content_type': contentType,
      }),
    );

    print('衣物上传URL响应状态码: ${response.statusCode}');
    print('衣物上传URL响应体: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('解析的衣物响应数据: $responseData');
      
      // 验证响应数据完整性
      if (responseData['upload_url'] == null || responseData['image_path'] == null) {
        print('错误: 衣物响应数据缺少必要字段');
        throw Exception('衣物上传URL响应数据不完整: ${responseData}');
      }
      
      return responseData;
    } else {
      print('获取衣物上传URL失败，状态码: ${response.statusCode}');
      throw Exception('获取衣物上传URL失败: ${response.statusCode} - ${response.body}');
    }
  }

  // 创建衣物记录
  static Future<Map<String, dynamic>> createClothingItem(String imagePath, String name, String category, {bool isDefault = false}) async {
    print('创建衣物记录: path=$imagePath, name=$name, category=$category');
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe'),
      headers: _headers,
      body: json.encode({
        'image_path': imagePath,
        'name': name,
        'category': category,
        'is_default': isDefault,
      }),
    );
    print('创建衣物响应状态码: ${response.statusCode}');
    print('创建衣物响应体: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('创建衣物记录失败: ${response.statusCode}');
    }
  }

  // 用户资料相关API
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取用户资料失败: ${response.statusCode}');
    }
  }

  /// 更新用户资料
  static Future<Map<String, dynamic>> updateUserProfile({
    String? nickname,
    String? avatarUrl,
    String? city,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (city != null) body['city'] = city;

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('更新用户资料失败: ${response.statusCode}');
    }
  }

  // 保存穿搭相关API
  static Future<Map<String, dynamic>> createSavedLook({
    required String coverImageUrl,
    required List<String> clothingImageUrls,
    String? aiTaskId,
    String? recommendationId,
  }) async {
    print('创建保存穿搭: coverImage=$coverImageUrl, clothingImages=${clothingImageUrls.length}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/saved-looks'),
      headers: _headers,
      body: json.encode({
        'cover_image_url': coverImageUrl,
        'clothing_image_urls': clothingImageUrls,
        'ai_task_id': aiTaskId,
        'recommendation_id': recommendationId,
      }),
    );

    print('创建保存穿搭响应状态码: ${response.statusCode}');
    print('创建保存穿搭响应体: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('创建保存穿搭失败: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getSavedLooks({int page = 1, int pageSize = 20}) async {
    print('获取保存穿搭列表: page=$page, pageSize=$pageSize');
    
    final response = await http.get(
      Uri.parse('$baseUrl/saved-looks?page=$page&pageSize=$pageSize'),
      headers: _headers,
    );

    print('获取保存穿搭列表响应状态码: ${response.statusCode}');
    print('获取保存穿搭列表响应体长度: ${response.body.length}');
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取保存穿搭列表失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> deleteSavedLook(String lookId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/saved-looks/$lookId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('删除保存穿搭失败: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> publishSavedLook(String lookId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/saved-looks/$lookId/publish'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('发布保存穿搭失败: ${response.statusCode}');
    }
  }
}
