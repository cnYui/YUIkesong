/// API配置管理
/// 
/// 使用方法：
/// 1. 开发环境：通过 --dart-define 传递配置
///    flutter run --dart-define=GEMINI_API_KEY=your_key
/// 2. 生产环境：在CI/CD中配置环境变量
class ApiConfig {
  // Gemini API配置
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // 高德地图API配置
  static const String amapApiKey = String.fromEnvironment(
    'AMAP_API_KEY',
    defaultValue: '',
  );

  // Supabase配置
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  // API服务器配置
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// 验证配置是否完整
  static bool validate() {
    if (geminiApiKey.isEmpty) {
      print('⚠️ GEMINI_API_KEY 未配置');
      return false;
    }
    if (amapApiKey.isEmpty) {
      print('⚠️ AMAP_API_KEY 未配置');
      return false;
    }
    if (supabaseUrl.isEmpty) {
      print('⚠️ SUPABASE_URL 未配置');
      return false;
    }
    return true;
  }

  /// 打印配置状态（仅用于调试）
  static void printStatus() {
    print('📋 API配置状态:');
    print('  Gemini API: ${geminiApiKey.isNotEmpty ? "已配置" : "未配置"}');
    print('  高德地图: ${amapApiKey.isNotEmpty ? "已配置" : "未配置"}');
    print('  Supabase: ${supabaseUrl.isNotEmpty ? "已配置" : "未配置"}');
    print('  API服务器: $apiBaseUrl');
  }
}
