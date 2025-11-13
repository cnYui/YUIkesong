# Supabase在线部署指南

## 🚨 重要提醒

**当前状态：后端API代码已完成，但数据库结构尚未部署到在线Supabase项目！**

## 📋 手动部署步骤

### 第一步：访问Supabase Dashboard

1. 打开浏览器访问：https://app.supabase.com
2. 使用你的Supabase账号登录
3. 选择项目：`tbjyhqcazhgcmtbdgwpg`（或你的项目）

### 第二步：创建数据库表结构

1. 在左侧菜单点击 **"SQL Editor"**
2. 点击 **"New query"** 创建新查询
3. 复制执行以下SQL（来自 `001_create_tables.sql`）：

```sql
-- 创建用户资料表
create table if not exists public.profiles (
  id uuid primary key,
  nickname text,
  avatar_url text,
  city text,
  created_at timestamp default now()
);

-- 创建自拍表
create table if not exists public.selfies (
  id uuid primary key,
  user_id uuid not null,
  image_path text not null,
  is_default boolean default false,
  created_at timestamp default now()
);

create index if not exists idx_selfies_user_default on public.selfies(user_id, is_default);

-- 创建衣柜分类表
create table if not exists public.wardrobe_categories (
  id serial primary key,
  name text unique not null,
  icon text,
  sort_order int default 0
);

-- 创建衣柜物品表
create table if not exists public.wardrobe_items (
  id uuid primary key,
  user_id uuid not null,
  category_id int references public.wardrobe_categories(id),
  image_path text not null,
  color text,
  season text,
  metadata jsonb,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  deleted_at timestamp
);

create index if not exists idx_wardrobe_user_cat on public.wardrobe_items(user_id, category_id);
create index if not exists idx_wardrobe_user_created on public.wardrobe_items(user_id, created_at);

-- 创建推荐表
create table if not exists public.recommendations (
  id uuid primary key,
  user_id uuid,
  weather_tag text,
  title text not null,
  description text,
  source text check (source in ('ai','manual')) default 'ai',
  created_at timestamp default now()
);

create index if not exists idx_reco_user_created on public.recommendations(user_id, created_at);

-- 创建推荐物品关联表
create table if not exists public.recommendation_items (
  recommendation_id uuid not null,
  wardrobe_item_id uuid not null,
  slot text,
  primary key (recommendation_id, wardrobe_item_id)
);

-- 创建AI任务表
create table if not exists public.ai_tasks (
  id uuid primary key,
  user_id uuid not null,
  task_type text check (task_type in ('image','video')) not null,
  status text check (status in ('pending','processing','finished','failed')) default 'pending',
  input_payload jsonb,
  result_url text,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

create index if not exists idx_ai_user_status on public.ai_tasks(user_id, status);
create index if not exists idx_ai_created on public.ai_tasks(created_at);

-- 创建保存穿搭表
create table if not exists public.saved_looks (
  id uuid primary key,
  user_id uuid not null,
  ai_task_id uuid,
  recommendation_id uuid,
  cover_image_url text not null,
  created_at timestamp default now()
);

create index if not exists idx_looks_user_created on public.saved_looks(user_id, created_at);

-- 创建保存穿搭物品关联表
create table if not exists public.saved_look_items (
  saved_look_id uuid not null,
  wardrobe_item_id uuid not null,
  slot text,
  primary key (saved_look_id, wardrobe_item_id)
);

-- 创建社区帖子表
create table if not exists public.community_posts (
  id uuid primary key,
  user_id uuid not null,
  cover_image_url text,
  description text,
  visibility text check (visibility in ('public','private')) default 'public',
  created_at timestamp default now(),
  updated_at timestamp default now(),
  deleted_at timestamp
);

create index if not exists idx_posts_user_created on public.community_posts(user_id, created_at);
create index if not exists idx_posts_vis_created on public.community_posts(visibility, created_at);

-- 创建社区帖子图片表
create table if not exists public.community_post_images (
  id uuid primary key,
  post_id uuid not null,
  image_url text not null,
  sort_order int
);

create index if not exists idx_post_images_post on public.community_post_images(post_id);

-- 创建社区点赞表
create table if not exists public.community_likes (
  post_id uuid not null,
  user_id uuid not null,
  created_at timestamp default now(),
  primary key (post_id, user_id)
);

-- 创建社区评论表
create table if not exists public.community_comments (
  id uuid primary key,
  post_id uuid not null,
  user_id uuid not null,
  content text not null,
  parent_id uuid,
  created_at timestamp default now()
);

create index if not exists idx_comments_post_created on public.community_comments(post_id, created_at);
create index if not exists idx_comments_parent on public.community_comments(parent_id);

-- 创建关注表
create table if not exists public.follows (
  follower_id uuid not null,
  followee_id uuid not null,
  created_at timestamp default now(),
  primary key (follower_id, followee_id)
);
```

4. 点击 **"RUN"** 执行查询

### 第三步：初始化分类数据

在SQL Editor中创建新查询，执行：

```sql
-- 初始化衣柜分类数据
INSERT INTO public.wardrobe_categories (name, icon, sort_order) VALUES
('上衣', '👔', 1),
('下装', '👖', 2),
('外套', '🧥', 3),
('鞋子', '👟', 4),
('配饰', '👜', 5),
('连衣裙', '👗', 6),
('套装', '🥼', 7)
ON CONFLICT (name) DO NOTHING;
```

### 第四步：启用RLS并配置策略

执行 `003_rls_policies.sql` 的内容（由于内容较长，建议分批执行）：

**第一部分：启用RLS**
```sql
-- 启用所有表的RLS（行级安全）
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.selfies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_looks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_look_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_post_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
```

**第二部分：基础权限策略**（继续在同一查询或新查询中执行剩余的策略）

### 第五步：配置Storage Buckets

执行 `004_storage_buckets.sql` 的内容：

```sql
-- 创建Storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
('selfies', 'selfies', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('wardrobe', 'wardrobe', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('saved_looks', 'saved_looks', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('community', 'community', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
```

### 第六步：验证部署

执行验证查询：

```sql
-- 检查表是否创建成功
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 检查RLS是否启用
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- 检查Storage buckets
SELECT * FROM storage.buckets;

-- 检查分类数据
SELECT * FROM public.wardrobe_categories;
```

## ✅ 部署完成验证

如果一切正常，你应该看到：
- ✅ 14个数据表已创建
- ✅ RLS策略已启用
- ✅ 4个Storage buckets已配置
- ✅ 7个衣柜分类已初始化

## 🚀 启动后端服务

数据库部署完成后，启动后端API：

```bash
cd backend/api
npm install
npm run dev
```

## 🎯 最终确认

完成以上步骤后，请告诉我，我会验证在线Supabase的部署状态，确保一切正常工作！