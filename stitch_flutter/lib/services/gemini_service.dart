import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gemini API配额异常
class GeminiQuotaException implements Exception {
  final String message;
  final String? retryAfter;

  GeminiQuotaException(this.message, {this.retryAfter});

  @override
  String toString() => message;
}

/// Gemini API服务
/// 用于处理衣物图片：去除背景、平铺展示等
class GeminiService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY 未在 .env 文件中设置');
    }
    return key;
  }

  // 模型配置
  // 可选模型：
  // - gemini-2.5-flash-image: 专用于图片生成
  // - gemini-1.5-pro: Pro模型，支持多模态
  // - gemini-1.5-flash: 快速模型
  static const String _modelForImageProcessing = 'gemini-2.5-flash-image';
  static const String _modelForImageGeneration =
      'gemini-2.5-flash-image'; // 使用Pro模型生成试穿图片

  static String _getBaseUrl(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  /// 处理衣物图片：去除背景、平铺展示、纯白背景
  ///
  /// [imageBytes] - 原始图片的字节数据
  /// [mimeType] - 图片的MIME类型（如 'image/jpeg', 'image/png'）
  ///
  /// 返回处理后的图片字节数据
  static Future<Uint8List> processClothingImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    try {
      // 将图片转换为base64
      final base64Image = base64Encode(imageBytes);

      // 构建提示词
      const prompt =
          '''请将图中人物身上最明显的占据主体位置的一件衣物（或裤子、鞋子、包包、帽子等），整理成平铺的商品展示造型。背景设置为纯白色，确保光线均匀柔和，无阴影。请彻底去除图中所有原始元素，包括人物、手机界面（按钮、广告图标、任何文字或杂物），只保留物品本身和纯白背景，不添加任何其他无关内容。''';

      // 构建请求体
      // 根据官方文档，需要指定 responseModalities 来返回图片
      // 注意：请求中应使用驼峰命名（inlineData, mimeType）
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {'mimeType': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      };

      // 发送请求到Gemini API（使用图片处理模型）
      final baseUrl = _getBaseUrl(_modelForImageProcessing);
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        // 解析错误响应
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            final code = error['code'];
            final message = error['message'] ?? '未知错误';
            final status = error['status'] ?? '';

            // 处理配额限制错误 (429)
            if (response.statusCode == 429 || status == 'RESOURCE_EXHAUSTED') {
              // 尝试提取重试时间
              String retryInfo = '';
              if (error['details'] != null) {
                for (var detail in error['details']) {
                  if (detail['@type'] ==
                          'type.googleapis.com/google.rpc.RetryInfo' &&
                      detail['retryDelay'] != null) {
                    retryInfo = '，建议 ${detail['retryDelay']} 后重试';
                    break;
                  }
                }
              }
              throw GeminiQuotaException(
                'Gemini API 配额已用完（免费层限制）$retryInfo。请稍后再试或升级到付费计划。',
                retryAfter: retryInfo,
              );
            }

            // 其他错误
            throw Exception('Gemini API错误 ($code): $message');
          }
        } catch (e) {
          // 如果解析失败，使用原始错误信息
          if (e is GeminiQuotaException) rethrow;
        }

        // 如果无法解析错误，抛出通用异常
        throw Exception(
          'Gemini API请求失败: ${response.statusCode} - ${response.body}',
        );
      }

      final responseData = json.decode(response.body);

      if (kDebugMode) {
        // 只打印响应结构，不打印完整的base64数据（太长了）
        final debugData = <String, dynamic>{};
        if (responseData['candidates'] != null) {
          debugData['candidates_count'] =
              (responseData['candidates'] as List).length;
          if ((responseData['candidates'] as List).isNotEmpty) {
            final firstCandidate = responseData['candidates'][0];
            debugData['candidate_keys'] = firstCandidate.keys.toList();
            if (firstCandidate['content'] != null) {
              debugData['content_keys'] = firstCandidate['content'].keys
                  .toList();
              if (firstCandidate['content']['parts'] != null) {
                debugData['parts_count'] =
                    (firstCandidate['content']['parts'] as List).length;
                if ((firstCandidate['content']['parts'] as List).isNotEmpty) {
                  final firstPart = firstCandidate['content']['parts'][0];
                  debugData['first_part_keys'] = firstPart.keys.toList();
                  final inlineDataObj =
                      firstPart['inlineData'] ?? firstPart['inline_data'];
                  if (inlineDataObj != null) {
                    debugData['inlineData_keys'] = inlineDataObj.keys.toList();
                    if (inlineDataObj['data'] != null) {
                      debugData['data_length'] =
                          (inlineDataObj['data'] as String).length;
                    }
                  }
                }
              }
            }
          }
        }
        print('📦 Gemini API响应结构: ${json.encode(debugData)}');
      }

      // 解析响应，获取处理后的图片
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty) {
        final candidate = responseData['candidates'][0];

        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty) {
          // 查找图片数据（优先查找图片，因为这是我们的主要目标）
          Uint8List? processedImage;
          String? textResponse;

          for (var part in candidate['content']['parts']) {
            if (kDebugMode) {
              print('🔍 检查part: ${part.keys.toList()}');
            }

            // 检查是否有inlineData字段（驼峰命名，Gemini API使用）
            // 也兼容inline_data（下划线命名，某些版本可能使用）
            final inlineDataObj = part['inlineData'] ?? part['inline_data'];
            if (inlineDataObj != null) {
              if (kDebugMode) {
                print('📦 找到inlineData: ${inlineDataObj.keys.toList()}');
              }

              // 检查data字段（可能是data或mimeType）
              final imageData = inlineDataObj['data'];
              if (imageData != null && imageData is String) {
                // 解码base64图片数据
                final processedImageBase64 = imageData;
                if (kDebugMode) {
                  print(
                    '✅ 找到处理后的图片数据，base64长度: ${processedImageBase64.length}',
                  );
                }
                processedImage = base64Decode(processedImageBase64);
                if (kDebugMode) {
                  print('✅ 图片解码成功，大小: ${processedImage.length} bytes');
                }
                // 找到图片后立即返回
                return processedImage;
              }
            }

            // 也检查是否有直接的data字段（某些API版本可能不同）
            if (part['data'] != null) {
              final data = part['data'];
              if (data is String) {
                if (kDebugMode) {
                  print('✅ 找到直接的data字段，base64长度: ${data.length}');
                }
                processedImage = base64Decode(data);
                if (kDebugMode) {
                  print('✅ 图片解码成功，大小: ${processedImage.length} bytes');
                }
                return processedImage;
              }
            }

            // 同时收集文本响应（可能包含说明信息）
            if (part['text'] != null) {
              textResponse = part['text'];
              if (kDebugMode && textResponse != null) {
                final textLength = textResponse.length;
                final preview = textResponse.substring(
                  0,
                  textLength > 100 ? 100 : textLength,
                );
                print('📝 Gemini同时返回文本响应: $preview...');
              }
            }

            // 检查是否有functionCall（某些情况下可能使用函数调用）
            if (part['functionCall'] != null) {
              if (kDebugMode) {
                print('⚠️ 收到functionCall响应，可能需要不同的处理方式');
              }
            }
          }

          // 如果没有找到图片，但有文本响应，抛出异常
          if (processedImage == null && textResponse != null) {
            final textLength = textResponse.length;
            final preview = textResponse.substring(
              0,
              textLength > 200 ? 200 : textLength,
            );
            throw Exception('Gemini API返回了文本响应而不是图片。响应内容: $preview...');
          }

          // 如果既没有图片也没有文本，说明响应格式异常
          if (processedImage == null) {
            // 打印详细的调试信息
            if (kDebugMode) {
              print('❌ 未找到图片数据，parts详情:');
              for (var i = 0; i < candidate['content']['parts'].length; i++) {
                final part = candidate['content']['parts'][i];
                print('  Part $i keys: ${part.keys.toList()}');
                final inlineDataObj = part['inlineData'] ?? part['inline_data'];
                if (inlineDataObj != null) {
                  print(
                    '  Part $i inlineData keys: ${inlineDataObj.keys.toList()}',
                  );
                  if (inlineDataObj['data'] != null) {
                    print(
                      '  Part $i data存在，类型: ${inlineDataObj['data'].runtimeType}',
                    );
                  }
                }
              }
            }
            throw Exception(
              'Gemini API响应中未找到图片数据，parts数量: ${candidate['content']['parts'].length}。请检查响应结构。',
            );
          }
        }

        // 检查是否有finishReason
        if (candidate['finishReason'] != null) {
          if (kDebugMode) {
            print('🏁 FinishReason: ${candidate['finishReason']}');
          }
          if (candidate['finishReason'] == 'SAFETY' ||
              candidate['finishReason'] == 'RECITATION') {
            throw Exception(
              'Gemini API因安全或内容问题拒绝了请求: ${candidate['finishReason']}',
            );
          }
        }
      }

      // 如果没有找到图片，尝试从其他字段获取
      // 某些情况下，Gemini可能返回不同的响应格式
      if (responseData['inline_data'] != null &&
          responseData['inline_data']['data'] != null) {
        final processedImageBase64 = responseData['inline_data']['data'];
        return base64Decode(processedImageBase64);
      }

      // 检查是否有错误信息
      if (responseData['error'] != null) {
        final error = responseData['error'];
        throw Exception('Gemini API错误: ${error['message'] ?? '未知错误'}');
      }

      throw Exception(
        'Gemini API响应中未找到处理后的图片数据。响应结构: ${json.encode(responseData)}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemini图片处理失败: $e');
      }
      rethrow;
    }
  }

  /// 生成试穿图片：将用户头像和选择的衣服组合生成试穿效果图
  ///
  /// [avatarBytes] - 用户头像（自拍）的字节数据
  /// [avatarMimeType] - 头像的MIME类型
  /// [clothingImagesBytes] - 衣服图片列表的字节数据
  /// [clothingMimeTypes] - 衣服图片的MIME类型列表
  ///
  /// 返回生成的试穿图片字节数据
  static Future<Uint8List> generateFittingImage(
    Uint8List avatarBytes,
    String avatarMimeType,
    List<Uint8List> clothingImagesBytes,
    List<String> clothingMimeTypes,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 开始生成试穿图片...');
        print('头像大小: ${avatarBytes.length} bytes');
        print('衣服数量: ${clothingImagesBytes.length}');
      }

      // 构建提示词
      const prompt = '''请严格按照以下要求生成图片：

【重要】图片中的第一张人物形象是用户的自拍照片，这是参考人物形象的唯一标准。你必须使用这张自拍中的人物形象，不能使用任何其他人物形象。

关键要求：

1. 人物形象必须100%一致：
   - 将人物自拍替换为生成的试穿图片的人物头像
   - 面部特征（眼睛、鼻子、嘴巴、脸型）必须与自拍完全一致
   - 发型、发色必须与自拍完全一致
   - 如果自拍中有眼镜，必须保留相同的眼镜样式
   - 肤色、面部细节（如胡须、痣等）必须与自拍完全一致
   - 人物的整体外观和气质必须与自拍中的人物完全一致

2. 服装单品：
   - 精确使用提供的所有服装单品（第二张及之后的图片）
   - 确保服装的款式、颜色、材质与原图一模一样
   - 服装必须自然地穿在人物身上

3. 表情与姿态：
   - 人物面带自然微笑，身体姿态放松且自然
   - 若人物为男性，请展现挺拔的身材
   - 若人物为女性，请展现优雅的姿态

4. 背景：纯白色

5. 构图：画面中只包含该人物和纯白色背景，无其他任何衣物、道具、场景或多余元素。

请确保生成的人物就是自拍中的那个人，而不是其他任何人。''';

      // 构建parts数组：先添加提示词，然后添加头像，最后添加所有衣服图片
      // 注意：根据Gemini API官方文档，请求中应使用驼峰命名（inlineData）
      final parts = <dynamic>[
        {'text': prompt},
        {
          'inlineData': {
            'mimeType': avatarMimeType,
            'data': base64Encode(avatarBytes),
          },
        },
      ];

      if (kDebugMode) {
        print('📤 上传图片到Gemini API（按顺序）:');
        print('  [0] 提示词文本');
        print(
          '  [1] ✅ 头像（第一张图片）: ${avatarBytes.length} bytes (${avatarMimeType})',
        );
        // 验证头像格式
        print('  📋 头像格式验证:');
        print('    - 文件大小: ${avatarBytes.length} bytes');
        print('    - MIME类型: $avatarMimeType');
        print('    - Base64长度: ${base64Encode(avatarBytes).length} chars');
        // 检查头像前几个字节，验证格式
        if (avatarBytes.length >= 4) {
          final header = avatarBytes.sublist(0, 4).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ');
          print('    - 文件头: $header');
          if (avatarBytes[0] == 0xFF && avatarBytes[1] == 0xD8) {
            print('    - ✅ 确认为JPEG格式');
          } else if (avatarBytes[0] == 0x89 && avatarBytes[1] == 0x50) {
            print('    - ✅ 确认为PNG格式');
          } else {
            print('    - ⚠️ 未知格式，可能有问题');
          }
        }
      }

      // 添加所有衣服图片
      for (var i = 0; i < clothingImagesBytes.length; i++) {
        parts.add({
          'inlineData': {
            'mimeType': clothingMimeTypes[i],
            'data': base64Encode(clothingImagesBytes[i]),
          },
        });
        if (kDebugMode) {
          print(
            '  [${i + 2}] ✅ 衣服${i + 1}（第${i + 2}张图片）: ${clothingImagesBytes[i].length} bytes (${clothingMimeTypes[i]})',
          );
        }
      }

      if (kDebugMode) {
        print('📤 总共上传 ${parts.length} 个parts:');
        print('  - [0] 提示词: 1个');
        print('  - [1] 头像（第一张图片）: 1个');
        print(
          '  - [2-${parts.length - 1}] 衣服图片: ${clothingImagesBytes.length}个',
        );
        print('✅ 图片顺序正确：第一张是头像，第二张及之后是衣服');
        print('📋 请求体结构验证:');
        print('  - parts[0] 类型: ${parts[0].runtimeType} (应该是包含text的Map)');
        print('  - parts[1] 类型: ${parts[1].runtimeType} (应该是包含inlineData的Map)');
        if (parts[1] is Map && (parts[1] as Map).containsKey('inlineData')) {
          print('  - ✅ parts[1] 包含 inlineData 字段');
          final inlineData = (parts[1] as Map)['inlineData'];
          if (inlineData is Map) {
            print('    - inlineData.mimeType: ${inlineData['mimeType']}');
            print('    - inlineData.data 长度: ${(inlineData['data'] as String?)?.length ?? 0}');
          }
        } else {
          print('  - ❌ parts[1] 不包含 inlineData 字段！');
        }
      }

      // 构建请求体
      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      };

      // 发送请求到Gemini API（使用Pro模型生成试穿图片）
      final baseUrl = _getBaseUrl(_modelForImageGeneration);
      if (kDebugMode) {
        print('🌐 使用模型: $_modelForImageGeneration');
        print('🌐 API端点: $baseUrl');
      }
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        // 解析错误响应
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            final code = error['code'];
            final message = error['message'] ?? '未知错误';
            final status = error['status'] ?? '';

            // 处理配额限制错误 (429)
            if (response.statusCode == 429 || status == 'RESOURCE_EXHAUSTED') {
              String retryInfo = '';
              if (error['details'] != null) {
                for (var detail in error['details']) {
                  if (detail['@type'] ==
                          'type.googleapis.com/google.rpc.RetryInfo' &&
                      detail['retryDelay'] != null) {
                    retryInfo = '，建议 ${detail['retryDelay']} 后重试';
                    break;
                  }
                }
              }
              throw GeminiQuotaException(
                'Gemini API 配额已用完（免费层限制）$retryInfo。请稍后再试或升级到付费计划。',
                retryAfter: retryInfo,
              );
            }

            throw Exception('Gemini API错误 ($code): $message');
          }
        } catch (e) {
          if (e is GeminiQuotaException) rethrow;
        }

        throw Exception(
          'Gemini API请求失败: ${response.statusCode} - ${response.body}',
        );
      }

      final responseData = json.decode(response.body);

      if (kDebugMode) {
        // 只打印响应结构，不打印完整的base64数据
        final debugData = <String, dynamic>{};
        if (responseData['candidates'] != null) {
          debugData['candidates_count'] =
              (responseData['candidates'] as List).length;
          if ((responseData['candidates'] as List).isNotEmpty) {
            final firstCandidate = responseData['candidates'][0];
            debugData['candidate_keys'] = firstCandidate.keys.toList();
            if (firstCandidate['content'] != null) {
              debugData['content_keys'] = firstCandidate['content'].keys
                  .toList();
              if (firstCandidate['content']['parts'] != null) {
                debugData['parts_count'] =
                    (firstCandidate['content']['parts'] as List).length;
                if ((firstCandidate['content']['parts'] as List).isNotEmpty) {
                  final firstPart = firstCandidate['content']['parts'][0];
                  debugData['first_part_keys'] = firstPart.keys.toList();
                  final inlineDataObj =
                      firstPart['inlineData'] ?? firstPart['inline_data'];
                  if (inlineDataObj != null) {
                    debugData['inlineData_keys'] = inlineDataObj.keys.toList();
                    if (inlineDataObj['data'] != null) {
                      debugData['data_length'] =
                          (inlineDataObj['data'] as String).length;
                    }
                  }
                }
              }
            }
          }
        }
        print('📦 Gemini API响应结构: ${json.encode(debugData)}');
      }

      // 解析响应，获取生成的图片
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty) {
        final candidate = responseData['candidates'][0];

        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty) {
          // 查找图片数据
          for (var part in candidate['content']['parts']) {
            if (kDebugMode) {
              print('🔍 检查part: ${part.keys.toList()}');
            }

            // 检查是否有inlineData字段（驼峰命名，Gemini API使用）
            final inlineDataObj = part['inlineData'] ?? part['inline_data'];
            if (inlineDataObj != null) {
              if (kDebugMode) {
                print('📦 找到inlineData: ${inlineDataObj.keys.toList()}');
              }

              // 检查data字段
              final imageData = inlineDataObj['data'];
              if (imageData != null && imageData is String) {
                // 解码base64图片数据
                final generatedImageBase64 = imageData;
                if (kDebugMode) {
                  print(
                    '✅ 找到生成的试穿图片数据，base64长度: ${generatedImageBase64.length}',
                  );
                }
                final generatedImage = base64Decode(generatedImageBase64);
                if (kDebugMode) {
                  print('✅ 图片解码成功，大小: ${generatedImage.length} bytes');
                }
                return generatedImage;
              }
            }
          }

          throw Exception(
            'Gemini API响应中未找到生成的图片数据，parts数量: ${candidate['content']['parts'].length}',
          );
        }
      }

      throw Exception(
        'Gemini API响应中未找到生成的试穿图片数据。响应结构: ${json.encode(responseData)}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gemini试穿图片生成失败: $e');
      }
      rethrow;
    }
  }

  /// 检查Gemini API是否可用
  static Future<bool> checkApiAvailability() async {
    try {
      // 发送一个简单的测试请求
      final response = await http.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
