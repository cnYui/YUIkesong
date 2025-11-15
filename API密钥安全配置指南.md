# API 密钥安全配置指南

## 📋 概述

本指南将帮助您将项目中所有硬编码的 API 密钥迁移到环境变量配置，确保在将代码上传到 GitHub 时不会泄露敏感信息。

## 🔍 发现的敏感信息

### 后端 (Node.js)
- ✅ Supabase URL
- ✅ Supabase Service Role Key
- ✅ JWT Secret

### 前端 (Flutter)
- ✅ Gemini API Key
- ✅ 高德地图 API Key
- ✅ Supabase URL

---

## 🚀 快速开始

### 步骤 1: 后端配置

#### 1.1 创建 `.env` 文件

在 `backend/api/` 目录下创建 `.env` 文件：

```bash
cd backend/api
cp .env.example .env
```

#### 1.2 填写配置信息

编辑 `backend/api/.env` 文件，填入您的实际配置：

```env
# Supabase 配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# JWT 密钥（建议使用随机字符串，至少32个字符）
JWT_SECRET=your-jwt-secret-key-here-min-32-chars

# 服务器端口
PORT=3001

# 前端 URL（用于密码重置等功能的回调）
FRONTEND_URL=http://localhost:3000
```

#### 1.3 获取 Supabase 配置

1. 访问 [Supabase 控制台](https://app.supabase.com/)
2. 选择您的项目
3. 进入 **Settings** → **API**
4. 复制以下信息：
   - **Project URL** → `SUPABASE_URL`
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY` ⚠️ **注意：这是敏感密钥，不要泄露！**

#### 1.4 生成 JWT Secret

使用以下命令生成随机密钥（至少32个字符）：

```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

### 步骤 2: 前端配置

#### 2.1 安装依赖

```bash
cd stitch_flutter
flutter pub get
```

#### 2.2 创建 `.env` 文件

在 `stitch_flutter/` 目录下创建 `.env` 文件：

```bash
cd stitch_flutter
# 复制示例文件（如果存在）
cp .env.example .env
```

#### 2.3 填写配置信息

编辑 `stitch_flutter/.env` 文件：

```env
# Gemini API 配置
GEMINI_API_KEY=your-gemini-api-key-here

# 高德地图 API 配置
AMAP_API_KEY=your-amap-api-key-here

# Supabase 配置
SUPABASE_URL=https://your-project.supabase.co

# 后端 API 地址
API_BASE_URL=http://localhost:3001
```

#### 2.4 获取 API 密钥

**Gemini API Key:**
1. 访问 [Google AI Studio](https://aistudio.google.com/app/apikey)
2. 创建新的 API 密钥
3. 复制密钥到 `GEMINI_API_KEY`

**高德地图 API Key:**
1. 访问 [高德开放平台](https://console.amap.com/dev/key/app)
2. 创建应用并获取 Key
3. 复制密钥到 `AMAP_API_KEY`

**Supabase URL:**
- 与后端使用相同的 Supabase URL

---

## ✅ 验证配置

### 后端验证

```bash
cd backend/api
npm start
```

如果配置正确，服务器会正常启动。如果缺少环境变量，会显示错误提示。

### 前端验证

```bash
cd stitch_flutter
flutter run
```

如果配置正确，应用会正常启动。如果缺少环境变量，会在控制台显示错误。

---

## 🔒 安全最佳实践

### 1. `.gitignore` 配置

确保 `.gitignore` 文件包含以下内容：

```gitignore
# 环境变量文件
*.env
backend/**/.env
stitch_flutter/.env
stitch_flutter/**/.env
```

### 2. 不要提交 `.env` 文件

⚠️ **重要**: 永远不要将 `.env` 文件提交到 Git！

```bash
# 检查 .env 是否被忽略
git status

# 如果 .env 出现在未跟踪文件中，确保 .gitignore 配置正确
```

### 3. 使用 `.env.example` 作为模板

`.env.example` 文件应该：
- ✅ 包含所有必需的变量名
- ✅ 使用占位符值（如 `your-api-key-here`）
- ✅ 包含注释说明
- ✅ 可以安全地提交到 Git

### 4. 团队成员配置

当新成员加入项目时：
1. 从 Git 克隆代码
2. 复制 `.env.example` 为 `.env`
3. 填写实际的 API 密钥
4. **不要**将 `.env` 提交到 Git

### 5. 生产环境配置

在生产环境（如 Vercel, Railway, Heroku）中：
- 使用平台的环境变量配置功能
- 不要将 `.env` 文件部署到服务器
- 使用平台提供的密钥管理服务

---

## 📝 已修改的文件

### 后端文件

1. **`backend/api/server.js`**
   - ✅ 移除硬编码的 Supabase URL 和密钥
   - ✅ 添加环境变量检查
   - ✅ 移除 JWT Secret 的 fallback

2. **`backend/api/test-db-query.js`**
   - ✅ 使用环境变量

3. **`backend/api/init-db.js`**
   - ✅ 使用环境变量

### 前端文件

1. **`stitch_flutter/lib/main.dart`**
   - ✅ 添加环境变量加载

2. **`stitch_flutter/lib/services/gemini_service.dart`**
   - ✅ 使用 `GEMINI_API_KEY` 环境变量

3. **`stitch_flutter/lib/services/location_service.dart`**
   - ✅ 使用 `AMAP_API_KEY` 环境变量

4. **`stitch_flutter/lib/services/weather_service.dart`**
   - ✅ 使用 `AMAP_API_KEY` 环境变量

5. **`stitch_flutter/lib/services/api_service.dart`**
   - ✅ 使用 `API_BASE_URL` 和 `SUPABASE_URL` 环境变量

6. **`stitch_flutter/lib/pages/ai_fitting_room_page.dart`**
   - ✅ 使用 `ApiService.supabaseUrl`

7. **`stitch_flutter/lib/pages/community_page.dart`**
   - ✅ 使用 `ApiService.supabaseUrl`

8. **`stitch_flutter/lib/pages/post_detail_page.dart`**
   - ✅ 使用 `ApiService.supabaseUrl`

9. **`stitch_flutter/lib/pages/saved_looks_page.dart`**
   - ✅ 使用 `ApiService.supabaseUrl`

---

## 🐛 常见问题

### Q1: 启动后端时提示"缺少必要的环境变量"

**解决方案:**
1. 确保在 `backend/api/` 目录下创建了 `.env` 文件
2. 检查 `.env` 文件格式是否正确（没有多余的空格）
3. 确保所有必需的变量都已设置

### Q2: Flutter 应用启动时提示"无法加载 .env 文件"

**解决方案:**
1. 确保 `.env` 文件在 `stitch_flutter/` 目录下
2. 确保 `pubspec.yaml` 中已添加 `.env` 到 `assets`
3. 运行 `flutter clean` 然后重新运行

### Q3: API 调用失败，提示密钥错误

**解决方案:**
1. 检查 `.env` 文件中的密钥是否正确
2. 确保没有多余的空格或引号
3. 重新获取 API 密钥并更新 `.env` 文件

### Q4: 如何在不同环境使用不同配置？

**解决方案:**
- 开发环境: 使用 `.env` 文件
- 生产环境: 使用平台的环境变量配置
- 测试环境: 创建 `.env.test` 并在测试代码中加载

---

## 📚 相关资源

- [Supabase 文档](https://supabase.com/docs)
- [Google AI Studio](https://aistudio.google.com/)
- [高德开放平台](https://lbs.amap.com/)
- [flutter_dotenv 文档](https://pub.dev/packages/flutter_dotenv)
- [dotenv 文档](https://www.npmjs.com/package/dotenv)

---

## ✅ 检查清单

在将代码提交到 GitHub 之前，请确认：

- [ ] 所有 `.env` 文件已添加到 `.gitignore`
- [ ] `.env.example` 文件已创建并提交
- [ ] 代码中不再有硬编码的 API 密钥
- [ ] 后端服务器可以正常启动
- [ ] Flutter 应用可以正常启动
- [ ] 所有 API 调用正常工作
- [ ] 团队成员知道如何配置环境变量

---

## 🎉 完成！

现在您的项目已经安全配置，可以安全地上传到 GitHub 了！

如果遇到任何问题，请参考本文档的"常见问题"部分，或查看相关服务的官方文档。

