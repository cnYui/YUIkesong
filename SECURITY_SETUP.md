# 安全配置指南

本文档说明如何正确配置项目的API密钥，避免密钥泄露。

## ⚠️ 重要提醒

**永远不要将API密钥硬编码到源代码中！**

所有敏感配置都应通过环境变量传递，并确保配置文件被`.gitignore`排除。

## 后端配置（Node.js）

### 1. 创建环境变量文件

复制模板文件并填入真实值：

```bash
cd backend/api
cp .env.example .env
```

### 2. 编辑 `.env` 文件

使用文本编辑器打开 `backend/api/.env`，填入实际的配置值：

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_actual_service_role_key
JWT_SECRET=your_random_jwt_secret
PORT=3000
FRONTEND_URL=http://localhost:3000
```

### 3. 获取配置值

#### Supabase配置
1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择您的项目
3. 进入 Settings → API
4. 复制：
   - `URL` → `SUPABASE_URL`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY`

#### JWT Secret
生成一个随机密钥（至少32字符）：
```bash
openssl rand -base64 32
```

### 4. 验证配置

启动服务器，检查是否正常运行：
```bash
cd backend/api
npm start
```

---

## Flutter前端配置

### 方案一：使用 dart-define（推荐）

在运行或构建时通过命令行传递配置：

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --dart-define=AMAP_API_KEY=your_amap_key \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=API_BASE_URL=http://your-server:3000
```

对于VS Code，可以在 `.vscode/launch.json` 中配置：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Development)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=GEMINI_API_KEY=your_gemini_key",
        "--dart-define=AMAP_API_KEY=your_amap_key",
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=API_BASE_URL=http://localhost:3000"
      ]
    }
  ]
}
```

**注意**: `.vscode/launch.json` 应该添加到 `.gitignore` 中，避免泄露配置。

### 方案二：使用配置文件（仅本地开发）

创建 `stitch_flutter/lib/config/env.dart`（不要提交到Git）：

```dart
class Env {
  static const geminiApiKey = 'your_gemini_key';
  static const amapApiKey = 'your_amap_key';
  static const supabaseUrl = 'https://your-project.supabase.co';
  static const apiBaseUrl = 'http://localhost:3000';
}
```

然后在 `ApiConfig` 中使用：
```dart
static const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: Env.geminiApiKey, // fallback到配置文件
);
```

**确保将此文件添加到 `.gitignore`**：
```
stitch_flutter/lib/config/env.dart
```

### 获取API密钥

#### Gemini API Key
1. 访问 [Google AI Studio](https://ai.google.dev/)
2. 点击 "Get API Key"
3. 创建或选择项目
4. 复制API密钥

#### 高德地图API Key
1. 登录 [高德开放平台](https://console.amap.com/)
2. 进入应用管理
3. 创建应用并添加Key
4. 选择平台类型（Android/iOS/Web）
5. 复制API密钥

---

## 生产环境部署

### 后端部署

在生产服务器或CI/CD平台上设置环境变量，例如：

- **Vercel/Netlify**: 在项目设置中添加环境变量
- **Docker**: 使用 `docker run -e SUPABASE_URL=...` 或 docker-compose.yml
- **传统服务器**: 在服务器上创建 `.env` 文件

### Flutter应用发布

在CI/CD流程中使用 `--dart-define` 传递配置：

```bash
flutter build apk \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=AMAP_API_KEY=$AMAP_API_KEY \
  --dart-define=SUPABASE_URL=$SUPABASE_URL
```

---

## 密钥轮换

如果怀疑密钥泄露，立即执行以下步骤：

1. **Gemini API**:
   - 在Google Cloud Console中禁用旧密钥
   - 生成新密钥
   - 更新所有环境配置

2. **Supabase Service Role Key**:
   - 在Supabase Dashboard中重新生成
   - 更新后端 `.env` 文件
   - 重启服务器

3. **高德地图API**:
   - 在控制台中删除旧Key
   - 创建新Key
   - 更新Flutter配置

---

## 安全检查清单

- [ ] 所有密钥通过环境变量传递
- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] `.vscode/launch.json` 已添加到 `.gitignore`（如果包含密钥）
- [ ] 没有硬编码的密钥在源代码中
- [ ] 使用 `git log` 检查历史提交中是否有泄露
- [ ] 生产环境使用独立的密钥
- [ ] 定期轮换密钥

---

## 故障排查

### 后端报错：缺少环境变量

确保：
1. `backend/api/.env` 文件存在
2. 文件中包含所有必需的变量
3. 变量名拼写正确
4. 重启服务器

### Flutter报错：API密钥未配置

确保：
1. 使用 `--dart-define` 传递配置
2. 配置名称拼写正确
3. 检查 `ApiConfig.printStatus()` 输出

---

## 需要帮助？

如有问题，请检查：
1. 环境变量是否正确设置
2. `.gitignore` 是否包含敏感文件
3. API密钥是否有效且未过期
