-- 完整的社区功能数据库初始化脚本
-- 包含表创建和RLS策略设置

-- 1. 创建profiles表（如果不存在）
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY,
  nickname text,
  avatar_url text,
  city text,
  last_login_at timestamp,
  created_at timestamp DEFAULT now()
);

-- 2. 创建社区帖子表
CREATE TABLE IF NOT EXISTS public.community_posts (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL,
  cover_image_url text,
  description text,
  visibility text CHECK (visibility IN ('public','private')) DEFAULT 'public',
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  deleted_at timestamp
);

CREATE INDEX IF NOT EXISTS idx_posts_user_created ON public.community_posts(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_posts_vis_created ON public.community_posts(visibility, created_at);

-- 3. 创建帖子图片表
CREATE TABLE IF NOT EXISTS public.community_post_images (
  id uuid PRIMARY KEY,
  post_id uuid NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  sort_order int
);

CREATE INDEX IF NOT EXISTS idx_post_images_post ON public.community_post_images(post_id);

-- 4. 创建点赞表
CREATE TABLE IF NOT EXISTS public.community_likes (
  post_id uuid NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  created_at timestamp DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);

-- 5. 创建评论表
CREATE TABLE IF NOT EXISTS public.community_comments (
  id uuid PRIMARY KEY,
  post_id uuid NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  content text NOT NULL,
  parent_id uuid REFERENCES public.community_comments(id) ON DELETE CASCADE,
  created_at timestamp DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_comments_post_created ON public.community_comments(post_id, created_at);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.community_comments(parent_id);

-- 6. 启用RLS（Row Level Security）
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_post_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

-- 7. 删除旧的RLS策略（如果存在）
DROP POLICY IF EXISTS profiles_owner_select ON public.profiles;
DROP POLICY IF EXISTS profiles_owner_write ON public.profiles;
DROP POLICY IF EXISTS profiles_public_select ON public.profiles;
DROP POLICY IF EXISTS posts_public_select ON public.community_posts;
DROP POLICY IF EXISTS posts_owner_write ON public.community_posts;
DROP POLICY IF EXISTS post_images_public_select ON public.community_post_images;
DROP POLICY IF EXISTS post_images_owner_write ON public.community_post_images;
DROP POLICY IF EXISTS likes_public_select ON public.community_likes;
DROP POLICY IF EXISTS likes_user_write ON public.community_likes;
DROP POLICY IF EXISTS comments_public_select ON public.community_comments;
DROP POLICY IF EXISTS comments_user_write ON public.community_comments;

-- 8. 创建新的RLS策略

-- Profiles: 所有已认证用户可以查看所有profiles（用于显示用户名和头像），但只能修改自己的
CREATE POLICY profiles_public_select ON public.profiles 
  FOR SELECT 
  USING (true);  -- 允许所有人查看（service role会绕过这个）

CREATE POLICY profiles_owner_write ON public.profiles 
  FOR ALL 
  USING (id = auth.uid()) 
  WITH CHECK (id = auth.uid());

-- Posts: 所有人可以查看公开帖子，只有作者可以修改自己的帖子
CREATE POLICY posts_public_select ON public.community_posts 
  FOR SELECT 
  USING (visibility = 'public' OR user_id = auth.uid());

CREATE POLICY posts_owner_write ON public.community_posts 
  FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

-- Post Images: 根据帖子的可见性决定
CREATE POLICY post_images_public_select ON public.community_post_images 
  FOR SELECT 
  USING (
    EXISTS(
      SELECT 1 FROM public.community_posts p 
      WHERE p.id = post_id 
      AND (p.visibility = 'public' OR p.user_id = auth.uid())
    )
  );

CREATE POLICY post_images_owner_write ON public.community_post_images 
  FOR ALL 
  USING (
    EXISTS(
      SELECT 1 FROM public.community_posts p 
      WHERE p.id = post_id 
      AND p.user_id = auth.uid()
    )
  ) 
  WITH CHECK (
    EXISTS(
      SELECT 1 FROM public.community_posts p 
      WHERE p.id = post_id 
      AND p.user_id = auth.uid()
    )
  );

-- Likes: 所有人可以查看，只能管理自己的点赞
CREATE POLICY likes_public_select ON public.community_likes 
  FOR SELECT 
  USING (true);

CREATE POLICY likes_user_write ON public.community_likes 
  FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

-- Comments: 所有人可以查看，只能管理自己的评论
CREATE POLICY comments_public_select ON public.community_comments 
  FOR SELECT 
  USING (true);

CREATE POLICY comments_user_write ON public.community_comments 
  FOR ALL 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

