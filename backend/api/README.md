# Stitch AI穿搭应用后端API

基于Express.js和Supabase的RESTful API服务，为AI穿搭应用提供完整的后端支持。

## 功能特性

- **用户认证**: 注册、登录、密码重置
- **用户资料**: 个人资料管理
- **自拍管理**: 自拍上传、删除、默认设置
- **衣柜管理**: 衣物分类、上传、管理
- **AI试穿**: AI任务创建和状态跟踪
- **保存穿搭**: 穿搭保存和管理
- **社区功能**: 帖子发布、浏览、点赞、评论

## 技术栈

- Node.js + Express.js
- Supabase (PostgreSQL + Storage + Auth)
- JWT认证
- 文件上传支持

## 环境配置

1. 安装依赖：
```bash
cd backend/api
npm install
```

2. 配置环境变量：
```bash
# 复制.env文件并修改配置
cp .env.example .env
```

必需的环境变量：
- `SUPABASE_URL`: Supabase项目URL
- `SUPABASE_SERVICE_KEY`: Supabase服务角色密钥
- `PORT`: 服务器端口（默认3001）
- `FRONTEND_URL`: 前端应用URL

3. 启动服务器：
```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

## API文档

### 认证接口

#### 注册用户
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "nickname": "用户名"
}
```

#### 用户登录
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### 重置密码
```http
POST /auth/reset
Content-Type: application/json

{
  "email": "user@example.com"
}
```

### 用户资料接口

#### 获取我的资料
```http
GET /users/me
Authorization: Bearer <token>
```

#### 更新我的资料
```http
PUT /users/me
Authorization: Bearer <token>
Content-Type: application/json

{
  "nickname": "新用户名",
  "avatar_url": "https://example.com/avatar.jpg",
  "city": "北京"
}
```

### 自拍管理接口

#### 获取上传URL
```http
POST /selfies/upload-url
Authorization: Bearer <token>
Content-Type: application/json

{
  "filename": "selfie.jpg",
  "content_type": "image/jpeg"
}
```

#### 创建自拍记录
```http
POST /selfies
Authorization: Bearer <token>
Content-Type: application/json

{
  "image_path": "user-id/selfie.jpg",
  "is_default": true
}
```

#### 获取自拍列表
```http
GET /selfies
Authorization: Bearer <token>
```

### 衣柜管理接口

#### 获取分类列表
```http
GET /wardrobe/categories
Authorization: Bearer <token>
```

#### 获取衣物列表
```http
GET /wardrobe/items?page=1&pageSize=20&category_id=1&q=搜索词
Authorization: Bearer <token>
```

#### 上传衣物图片
```http
POST /wardrobe/items/upload-url
Authorization: Bearer <token>
Content-Type: application/json

{
  "filename": "clothing.jpg",
  "content_type": "image/jpeg"
}
```

### AI试穿接口

#### 创建AI任务
```http
POST /ai/tasks
Authorization: Bearer <token>
Content-Type: application/json

{
  "task_type": "image",
  "selfie_url": "https://example.com/selfie.jpg",
  "clothing_image_urls": ["https://example.com/clothing1.jpg", "https://example.com/clothing2.jpg"]
}
```

### 社区接口

#### 创建帖子
```http
POST /community/posts
Authorization: Bearer <token>
Content-Type: application/json

{
  "images": ["https://example.com/cover.jpg", "https://example.com/detail1.jpg"],
  "description": "穿搭分享",
  "visibility": "public"
}
```

#### 获取帖子列表
```http
GET /community/posts?page=1&pageSize=6
Authorization: Bearer <token>
```

## 数据库结构

主要数据表：
- `profiles`: 用户资料表
- `selfies`: 自拍表
- `wardrobe_categories`: 衣物分类表
- `wardrobe_items`: 衣物表
- `ai_tasks`: AI任务表
- `saved_looks`: 保存穿搭表
- `community_posts`: 社区帖子表
- `community_likes`: 点赞表
- `community_comments`: 评论表

## 安全特性

- JWT令牌认证
- 行级安全策略(RLS)
- 文件访问权限控制
- 用户数据隔离
- 输入验证和 sanitization

## 部署

1. 构建应用：
```bash
npm run build
```

2. 设置生产环境变量

3. 启动服务：
```bash
npm start
```

## 许可证

MIT License