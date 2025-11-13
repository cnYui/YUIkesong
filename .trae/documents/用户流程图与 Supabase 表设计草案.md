## 用户使用流程图（文本版）

1. 新用户 → 注册

* 输入：用户名、邮箱、两次密码 → 创建账户

* 成功 → 跳转登录

1. 登录

* 输入账号/密码 → 鉴权通过 → 进入首页

1. 首页

* 获取地理位置与天气 → 展示今日提示

* 生成今日推荐（来自后端推荐或规则）

* 分支：

  * A. 点击“立即试穿” → 进入 AI 试穿室（带当前推荐的衣物）

  * B. 进入“我的衣柜” → 自由选择衣物 → 点击“一键生成” → 进入 AI 试穿室

1. AI 试穿室

* 生成图片（3 张）/生成视频（当前图片为第一帧）

* 操作：

  * 保存穿搭 → 写入“我保存的穿搭”

  * 重新生成 → 重新提交任务

  * 下载：图片/视频

1. 我保存的穿搭

* 浏览已保存记录：合成图 + 衣物列表

* 多选后：删除 / 发布到社区

* 发布社区 → 社区流新增帖子（封面：合成图；后续：衣物大图）

1. 管理我的自拍

* 上传/删除自拍 → 选中为默认

* 删除流程：选中图片→黑勾→点击黑勾变红×→点击红×删除

1. 社区

* 初次加载 6 条帖子，向下滚动继续分页加载

* 点击帖子 → 详情页（模特/衣服/作者头像昵称/点赞/评论）

* 评论发布 → 立即显示在该帖子评论区

1. 帖子详情页

* 多图 PageView（封面→衣物）+ 指示点

* 点赞、评论、分享（后端接口）

***

## Supabase 数据库表设计（public schema）

说明：用户认证使用 Supabase `auth.users`；业务表均启用 RLS，规则为 `user_id = auth.uid()`（社区公开读除外）。

1. profiles（用户扩展资料）

* id UUID PK（=auth.users.id）

* nickname VARCHAR(32)

* avatar\_url TEXT

* city VARCHAR(64)

* created\_at TIMESTAMP

* 索引：`profiles_pkey`、`idx_profiles_city`

* RLS：select/insert/update 仅限本人（`id = auth.uid()`）

1. selfies（用户自拍）

* id UUID PK

* user\_id UUID FK → auth.users(id)

* image\_path TEXT（Storage 路径）

* is\_default BOOL DEFAULT false

* created\_at TIMESTAMP

* 索引：`idx_selfies_user_default (user_id, is_default)`

* RLS：按 `user_id = auth.uid()`

1. wardrobe\_categories（衣柜类别）

* id SERIAL PK

* name TEXT UNIQUE

* icon TEXT

* sort\_order INT

1. wardrobe\_items（衣柜单品）

* id UUID PK

* user\_id UUID FK → auth.users(id)

* category\_id INT FK → wardrobe\_categories(id)

* image\_path TEXT

* color TEXT

* season TEXT

* metadata JSONB

* created\_at TIMESTAMP, updated\_at TIMESTAMP, deleted\_at TIMESTAMP NULL

* 索引：`idx_wardrobe_user_cat (user_id, category_id)`、`idx_wardrobe_user_created (user_id, created_at)`

* RLS：按 `user_id = auth.uid()`

1. recommendations（推荐方案）

* id UUID PK

* user\_id UUID FK

* weather\_tag TEXT

* title TEXT

* description TEXT

* source TEXT CHECK in ('ai','manual')

* created\_at TIMESTAMP

* 索引：`idx_reco_user_created (user_id, created_at)`

* RLS：按 `user_id = auth.uid()`

1. recommendation\_items（推荐衣物 N:N）

* recommendation\_id UUID FK → recommendations(id)

* wardrobe\_item\_id UUID FK → wardrobe\_items(id)

* slot TEXT（top/bottom/shoes...）

* PK (recommendation\_id, wardrobe\_item\_id)

* RLS：联表 `recommendations.user_id = auth.uid()`

1. ai\_tasks（AI 生成任务）

* id UUID PK

* user\_id UUID FK

* task\_type TEXT CHECK in ('image','video')

* status TEXT CHECK in ('pending','processing','finished','failed')

* input\_payload JSONB（自拍/衣服列表）

* result\_url TEXT

* created\_at TIMESTAMP, updated\_at TIMESTAMP

* 索引：`idx_ai_user_status (user_id, status)`、`idx_ai_created (created_at)`

* RLS：按 `user_id = auth.uid()`

1. saved\_looks（保存的穿搭）

* id UUID PK

* user\_id UUID FK

* ai\_task\_id UUID FK → ai\_tasks(id) NULL

* recommendation\_id UUID FK → recommendations(id) NULL

* cover\_image\_url TEXT（合成图）

* created\_at TIMESTAMP

* 索引：`idx_looks_user_created (user_id, created_at)`

* RLS：按 `user_id = auth.uid()`

1. saved\_look\_items（保存穿搭的衣物 N:N）

* saved\_look\_id UUID FK → saved\_looks(id)

* wardrobe\_item\_id UUID FK → wardrobe\_items(id)

* slot TEXT

* PK (saved\_look\_id, wardrobe\_item\_id)

* RLS：联表 `saved_looks.user_id = auth.uid()`

1. community\_posts（社区帖子）

* id UUID PK

* user\_id UUID FK

* cover\_image\_url TEXT

* description TEXT NULL

* visibility TEXT CHECK in ('public','private') DEFAULT 'public'

* created\_at TIMESTAMP, updated\_at TIMESTAMP, deleted\_at TIMESTAMP NULL

* 索引：`idx_posts_user_created (user_id, created_at)`、`idx_posts_vis_created (visibility, created_at)`

* RLS：

  * SELECT：visibility='public' 允许所有；本人可读私有

  * INSERT/UPDATE/DELETE：仅作者（`user_id = auth.uid()`）

1. community\_post\_images（帖子图片）

* id UUID PK

* post\_id UUID FK → community\_posts(id)

* image\_url TEXT

* sort\_order INT

* 索引：`idx_post_images_post (post_id)`

* RLS：联表作者写入；公开读

1. community\_likes（点赞）

* post\_id UUID FK

* user\_id UUID FK

* created\_at TIMESTAMP

* PK (post\_id, user\_id)

* RLS：作者与任意登录用户可写；公开读计数

1. community\_comments（评论）

* id UUID PK

* post\_id UUID FK

* user\_id UUID FK

* content TEXT

* parent\_id UUID NULL（二级回复）

* created\_at TIMESTAMP

* 索引：`idx_comments_post_created (post_id, created_at)`、`idx_comments_parent (parent_id)`

* RLS：登录用户可写；公开读

1. follows（关注）

* follower\_id UUID FK → auth.users(id)

* followee\_id UUID FK → auth.users(id)

* created\_at TIMESTAMP

* PK (follower\_id, followee\_id)

* RLS：登录用户可写；公开读

***

## Storage Buckets（Supabase Storage）

* `selfies`：用户自拍（私有 + 签名 URL）

* `wardrobe`：衣柜单品图片（私有 + 签名 URL）

* `saved_looks`：合成封面图（私有 + 签名 URL）

* `community`：社区帖子图片（公开读或签名 URL，视需求）

***

## 索引与分页建议

* 列表统一分页参数：`page`（≥1）、`pageSize`；按 `created_at DESC` 建组合索引

* 社区首页：`visibility='public' ORDER BY created_at DESC LIMIT 6 OFFSET (page-1)*pageSize`

***

## RLS 策略示例（概要）

* 表含 `user_id`：`policy select for all using (user_id = auth.uid())`；`insert/update/delete with check (user_id = auth.uid())`

* 社区公开读：posts/images/comments/likes 的 `select` 允许 `visibility='public'` 或作者本人

***

## 映射到前端页面

* 登录/注册/重置：映射 `auth` 与 `profiles`

* 我的衣柜：`wardrobe_items/categories`

* AI 试穿室：`ai_tasks`（创建/轮询）

* 我保存的穿搭：`saved_looks/saved_look_items`

* 管理我的自拍：`selfies`（上传/删除/设默认）

* 社区：`community_posts`、`community_post_images`、`community_comments`、`community_likes`

***

## 后续动作

* 我可将以上表结构与 RLS 策略输出为 Supabase SQL 脚本，并在文档中追加 ASCII 流程图或 Mermaid 版本；确认后我将直接更新 `docs/用户使用流程.md` 与新增 `docs/db_schema_supabase.sql`（草案）。

