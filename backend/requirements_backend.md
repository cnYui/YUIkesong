# 后端需求说明（v1）

## 背景与范围
- 基于现有前端实现（Flutter），提供用户注册/登录、资料管理、自拍管理、衣柜管理、AI 试穿任务、保存穿搭、社区发布/浏览/详情/点赞/评论等接口与数据存储。
- 数据库选型为 Supabase（Postgres + Storage + RLS），或可用同等 REST 服务；本文以 REST/Supabase 为约定。

## 环境与配置
- 环境变量：
  - `API_BASE_URL`（REST 入口）
  - `SUPABASE_URL`、`SUPABASE_ANON_KEY`（前端直连可选）
- Storage buckets：`selfies`、`wardrobe`、`saved_looks`（私有）、`community`（公开或签名URL）
- 安全：所有含 `user_id` 的表启用 RLS，策略 `user_id = auth.uid()`；社区公开读，写入受作者约束。

## 统一约定
- 鉴权：Bearer Token（或 Supabase auth）；所有写操作需登录。
- 分页：`page`（≥1），`pageSize`；返回 `{ list, page, pageSize, total }`
- 错误：`{ code, message }`
- 时间：`created_at` 降序列表；必要索引已在 `backend/supabase/db_schema.sql` 中定义。

## 数据实体（摘要）
- `profiles(id, nickname, avatar_url, city, created_at)`
- `selfies(id, user_id, image_path, is_default, created_at)`
- `wardrobe_categories(id, name, icon, sort_order)`
- `wardrobe_items(id, user_id, category_id, image_path, color, season, metadata, created_at)`
- `recommendations(id, user_id, weather_tag, title, description, source, created_at)`
- `recommendation_items(recommendation_id, wardrobe_item_id, slot)`
- `ai_tasks(id, user_id, task_type, status, input_payload, result_url, created_at, updated_at)`
- `saved_looks(id, user_id, ai_task_id?, recommendation_id?, cover_image_url, created_at)`
- `saved_look_items(saved_look_id, wardrobe_item_id, slot)`
- `community_posts(id, user_id, cover_image_url, description?, visibility, created_at, updated_at)`
- `community_post_images(id, post_id, image_url, sort_order)`
- `community_likes(post_id, user_id, created_at)`
- `community_comments(id, post_id, user_id, content, parent_id?, created_at)`

## API 需求列表（REST）

### 1. Auth
- POST `/auth/login`
  - req: `{ email|phone, password }`
  - res: `{ token, user: { id, nickname, avatar_url } }`
- POST `/auth/register`
  - req: `{ email, password, nickname }`
  - res: `{ id }`
- POST `/auth/reset`
  - req: `{ email }` 或 `{ token, new_password }`
  - res: `{ ok: true }`

### 2. Profiles
- GET `/users/me`
  - res: `{ id, nickname, avatar_url, city }`
- PUT `/users/me`
  - req: `{ nickname?, avatar_url?, city? }`
  - res: `{ id, nickname, avatar_url, city }`

### 3. Selfies（管理我的自拍）
- POST `/selfies/upload-url`
  - 说明：返回上传签名URL；客户端上传后回填记录
  - req: `{ filename, content_type }`
  - res: `{ upload_url, image_path }`
- POST `/selfies`
  - req: `{ image_path, is_default? }`
  - res: `{ id }`
- GET `/selfies`
  - res: `{ list: [{ id, image_path, is_default, created_at }] }`
- DELETE `/selfies/{id}`
  - res: `{ ok: true }`
- POST `/selfies/{id}/default`
  - res: `{ ok: true }`

### 4. Wardrobe（我的衣柜）
- GET `/wardrobe/categories`
  - res: `{ list: [{ id, name, icon, sort_order }] }`
- GET `/wardrobe/items?page=&pageSize=&category_id?&q?`
  - res: `{ list: [{ id, image_path, category_id, color, season }], page, pageSize, total }`
- POST `/wardrobe/items/upload-url`
  - req: `{ filename, content_type }`
  - res: `{ upload_url, image_path }`
- POST `/wardrobe/items`
  - req: `{ image_path, category_id, color?, season?, metadata? }`
  - res: `{ id }`
- DELETE `/wardrobe/items/{id}`
  - res: `{ ok: true }`

### 5. AI 任务（AI试穿室）
- POST `/ai/tasks`
  - req: `{ task_type: 'image'|'video', selfie_url, clothing_image_urls: [] }`
  - res: `{ id, status: 'pending' }`
- GET `/ai/tasks/{id}`
  - res: `{ status, result_url? }`

### 6. Saved Looks（我保存的穿搭）
- POST `/saved-looks`
  - req: `{ cover_image_url, clothing_image_urls: [], ai_task_id?, recommendation_id? }`
  - res: `{ id }`
- GET `/saved-looks?page=&pageSize=`
  - res: `{ list: [{ id, cover_image_url, clothing_image_urls: [], created_at }], page, pageSize, total }`
- DELETE `/saved-looks/{id}`
  - res: `{ ok: true }`
- POST `/saved-looks/{id}/publish`
  - 说明：发布到社区，将合成图作为封面，衣物图片按顺序追加
  - res: `{ post_id }`

### 7. Community（社区）
- POST `/community/posts`
  - req: `{ images: [cover, ...clothing], description?, visibility }`
  - res: `{ id }`
- GET `/community/posts?page=&pageSize=`
  - res: `{ list: [{ id, cover_image_url, username, avatar, created_at }], page, pageSize, total }`
- GET `/community/posts/{id}`
  - res: `{ id, images: [], username, avatar, description?, created_at }`
- POST `/community/posts/{id}/likes`
  - res: `{ likes: number }`
- GET `/community/posts/{id}/comments?page=&pageSize=`
  - res: `{ list: [{ id, user: { id, nickname, avatar_url }, content, created_at }], page, pageSize, total }`
- POST `/community/posts/{id}/comments`
  - req: `{ content, parent_id? }`
  - res: `{ id }`

## 事件流支撑（从前端提取）
- 首页 → AI 试穿室（立即试穿）：写入推荐搭配到试穿室，提交 AI 任务，轮询至完成。
- 我的衣柜 → 一键生成：选择衣物，跳转试穿室并生成。
- 试穿室保存穿搭：保存合成图与衣物列表至 `saved_looks`，提示成功。
- 保存穿搭发布社区：发布为帖子，社区首页左列显示封面与作者信息；详情页展示图片序列。
- 管理我的自拍：上传/删除/设默认；删除交互为“选中→黑勾→红×→删除”。

## 验收标准
- 所有列表接口支持分页、稳定排序；弱网下返回错误格式一致。
- 所有上传走签名URL；仅作者可写；公开阅读策略正确。
- 社区分页每次返回 6 条（可配置）；详情包含图片序列（封面→衣物）。
- AI 任务状态流转完整：pending→processing→finished/failed。

## 示例返回（片段）
- `/community/posts`：
```
{
  "list": [
    {"id":"p1","cover_image_url":"...","username":"时尚小魔女","avatar":"...","created_at":"2025-11-12T10:00:00Z"}
  ],
  "page":1,"pageSize":6,"total":120
}
```
- `/saved-looks`：
```
{
  "list": [
    {"id":"l1","cover_image_url":"...","clothing_image_urls":["...","..."],"created_at":"2025-11-12T10:00:00Z"}
  ],
  "page":1,"pageSize":20,"total":3
}
```

## 里程碑
- M1：Auth/Profiles、Selfies、Wardrobe 基础能力
- M2：AI 任务、保存穿搭、发布社区
- M3：社区列表/详情/点赞/评论、性能与安全完善、OpenAPI 文档
