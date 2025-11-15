-- 添加外键约束以支持Supabase的关联查询

-- 1. 为 community_posts 添加外键到 profiles
ALTER TABLE public.community_posts 
DROP CONSTRAINT IF EXISTS community_posts_user_id_fkey;

ALTER TABLE public.community_posts 
ADD CONSTRAINT community_posts_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- 2. 为 community_post_images 添加外键到 community_posts（如果还没有）
ALTER TABLE public.community_post_images 
DROP CONSTRAINT IF EXISTS community_post_images_post_id_fkey;

ALTER TABLE public.community_post_images 
ADD CONSTRAINT community_post_images_post_id_fkey 
FOREIGN KEY (post_id) 
REFERENCES public.community_posts(id) 
ON DELETE CASCADE;

-- 3. 为 community_likes 添加外键
ALTER TABLE public.community_likes 
DROP CONSTRAINT IF EXISTS community_likes_post_id_fkey;

ALTER TABLE public.community_likes 
ADD CONSTRAINT community_likes_post_id_fkey 
FOREIGN KEY (post_id) 
REFERENCES public.community_posts(id) 
ON DELETE CASCADE;

ALTER TABLE public.community_likes 
DROP CONSTRAINT IF EXISTS community_likes_user_id_fkey;

ALTER TABLE public.community_likes 
ADD CONSTRAINT community_likes_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- 4. 为 community_comments 添加外键
ALTER TABLE public.community_comments 
DROP CONSTRAINT IF EXISTS community_comments_post_id_fkey;

ALTER TABLE public.community_comments 
ADD CONSTRAINT community_comments_post_id_fkey 
FOREIGN KEY (post_id) 
REFERENCES public.community_posts(id) 
ON DELETE CASCADE;

ALTER TABLE public.community_comments 
DROP CONSTRAINT IF EXISTS community_comments_user_id_fkey;

ALTER TABLE public.community_comments 
ADD CONSTRAINT community_comments_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

ALTER TABLE public.community_comments 
DROP CONSTRAINT IF EXISTS community_comments_parent_id_fkey;

ALTER TABLE public.community_comments 
ADD CONSTRAINT community_comments_parent_id_fkey 
FOREIGN KEY (parent_id) 
REFERENCES public.community_comments(id) 
ON DELETE CASCADE;

-- 验证外键已创建
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name IN ('community_posts', 'community_post_images', 'community_likes', 'community_comments')
ORDER BY tc.table_name, kcu.column_name;

