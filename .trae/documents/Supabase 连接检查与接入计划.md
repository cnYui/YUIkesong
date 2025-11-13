## 检查结论
- 当前仓库未发现任何 Supabase 相关引用：
  - 代码检索未命中 `supabase`、`supabase_flutter`、`SUPABASE_URL/ANON_KEY` 等关键词
  - `stitch_flutter/pubspec.yaml` 未包含 Supabase 依赖
  - 仓库中不存在 `.env` 或 `dart-define` 配置文件
- 结论：项目尚未配置 Supabase 连接，需要新增依赖与初始化代码，并准备数据库/存储/RLS 策略。

## 接入整体方案
### 第 1 阶段：依赖与初始化
1. 依赖：在 `pubspec.yaml` 添加 `supabase_flutter`（客户端 SDK）
2. 初始化：在 `lib/main.dart` 的 `runApp` 之前调用 `Supabase.initialize(url, anonKey)` 并持有 `Supabase.instance.client`
3. 配置：
   - 使用 `--dart-define` 注入 `SUPABASE_URL`、`SUPABASE_ANON_KEY`（跨平台可靠）
   - Windows/Chrome 启动示例：
     - `flutter run -d windows --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...`
     - `flutter run -d chrome  --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...`
4. 封装：新增 `lib/services/supabase_client.dart` 提供统一入口（auth/db/storage），避免散落调用。

### 第 2 阶段：数据库与存储（Supabase/Postgres）
1. 表设计（public schema），与现有前端功能一一映射：
   - `profiles`（与 `auth.users` 关联）：`id UUID (PK, references auth.users)`、`nickname`、`avatar_url`、`city`、`created_at`
   - `selfies`：`id UUID`、`user_id UUID references auth.users`、`image_path TEXT`、`is_default BOOL`、`created_at`
   - `wardrobe_categories`：`id SERIAL`、`name TEXT UNIQUE`、`icon TEXT`、`sort_order INT`
   - `wardrobe_items`：`id UUID`、`user_id UUID`、`category_id INT`、`image_path TEXT`、`color TEXT`、`season TEXT`、`metadata JSONB`、`created_at`、`updated_at`、`deleted_at`
   - `recommendations` / `recommendation_items`：支持推荐组合（N:N，含 `slot`）
   - `ai_tasks`：`task_type ENUM`、`status ENUM`、`input_payload JSONB`、`result_url TEXT`
   - `saved_looks` / `saved_look_items`：保存穿搭（N:N，含 `slot`）
   - `community_posts` / `community_post_images` / `community_likes` / `community_comments` / `follows`
2. RLS 策略：所有包含 `user_id` 的表开启 RLS，规则 `user_id = auth.uid()`；社区公开数据允许 `SELECT`，写入受限于作者。
3. 存储（Storage）：
   - Bucket 规划：`selfies`、`wardrobe`、`saved_looks`、`community`
   - 访问策略：默认私有 + 签名 URL；公开资源（社区封面）可设公开读。
4. 索引：常用查询建立组合索引（如 `(user_id, created_at)`、`(post_id)`、`(status)`）。

### 第 3 阶段：前端模块接入
1. 认证：用 `supabase.auth` 对接登录/注册/重置密码；登录成功后拉取 `profiles` 同步到本地状态
2. 衣柜：`wardrobe_items` 列表 + 上传图片到 `wardrobe` 存储，写入表记录
3. AI 任务：提交 `ai_tasks` 并轮询状态；生成完成写入 `result_url`
4. 保存穿搭：向 `saved_looks`/`saved_look_items` 写入，并替换当前内存 Store
5. 社区：分页查询 `community_posts`，发布帖子写入 `post_images`，点赞/评论表操作
6. 图片加载：全量切换为 `cached_network_image`（占位/错误态），并支持签名 URL 刷新

### 验证与运维
- 连接验证：启动后在 `main.dart` 调试一次 `await supabase.auth.getUser()` 或从某个表 `select()` 验证连通性
- 迁移：使用 Supabase SQL 或迁移工具（`supabase db`）管理版本；环境分离（dev/prod）采用不同 `url/key`
- 安全：不在代码中写 `service_role` 密钥；客户端仅使用 `anon key`，所有写入受 RLS 约束

## 我将交付的产物
1. 完整 DDL（PostgreSQL）+ RLS 策略 SQL + Storage bucket 初始化清单
2. Flutter 侧初始化与封装代码草案（`supabase_client.dart`、`main.dart` 初始化）
3. 关键页面的数据接入示例（衣柜、AI 任务、保存穿搭、社区）

## 需要你确认
- 是否采用 `supabase_flutter` 最新版接入
- RLS 策略是否按“仅本人可读写”执行，社区读公开
- Bucket 访问策略（默认私有 + 签名 URL，社区封面公开）
- 我是否直接生成完整 SQL（DDL+RLS）与 Flutter 初始化代码草案