-- 验证社区功能所需的表是否存在

-- 检查 community_posts 表
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'community_posts'
);

-- 检查 community_post_images 表
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'community_post_images'
);

-- 检查 community_likes 表
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'community_likes'
);

-- 检查 community_comments 表
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'community_comments'
);

-- 检查 profiles 表
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'profiles'
);

-- 查看所有社区帖子（应该为空）
SELECT COUNT(*) as post_count FROM public.community_posts;

-- 查看所有用户profiles（至少应该有当前登录用户的）
SELECT COUNT(*) as profile_count FROM public.profiles;

