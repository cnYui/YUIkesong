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

-- profiles表策略
CREATE POLICY "用户可查看所有公开资料" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "用户只能更新自己的资料" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "用户只能插入自己的资料" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- selfies表策略
CREATE POLICY "用户只能查看自己的自拍" ON public.selfies
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的自拍" ON public.selfies
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的自拍" ON public.selfies
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的自拍" ON public.selfies
  FOR DELETE USING (auth.uid() = user_id);

-- wardrobe_categories表策略（公开读取）
CREATE POLICY "所有用户可查看分类" ON public.wardrobe_categories
  FOR SELECT USING (true);

-- wardrobe_items表策略
CREATE POLICY "用户只能查看自己的衣物" ON public.wardrobe_items
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的衣物" ON public.wardrobe_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的衣物" ON public.wardrobe_items
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的衣物" ON public.wardrobe_items
  FOR DELETE USING (auth.uid() = user_id);

-- recommendations表策略
CREATE POLICY "用户只能查看自己的推荐" ON public.recommendations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的推荐" ON public.recommendations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的推荐" ON public.recommendations
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的推荐" ON public.recommendations
  FOR DELETE USING (auth.uid() = user_id);

-- recommendation_items表策略
CREATE POLICY "用户只能查看自己的推荐项" ON public.recommendation_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.recommendations r 
      WHERE r.id = recommendation_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能插入自己的推荐项" ON public.recommendation_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recommendations r 
      WHERE r.id = recommendation_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能删除自己的推荐项" ON public.recommendation_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.recommendations r 
      WHERE r.id = recommendation_id AND r.user_id = auth.uid()
    )
  );

-- ai_tasks表策略
CREATE POLICY "用户只能查看自己的AI任务" ON public.ai_tasks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的AI任务" ON public.ai_tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的AI任务" ON public.ai_tasks
  FOR UPDATE USING (auth.uid() = user_id);

-- saved_looks表策略
CREATE POLICY "用户只能查看自己的保存穿搭" ON public.saved_looks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的保存穿搭" ON public.saved_looks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的保存穿搭" ON public.saved_looks
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的保存穿搭" ON public.saved_looks
  FOR DELETE USING (auth.uid() = user_id);

-- saved_look_items表策略
CREATE POLICY "用户只能查看自己的保存穿搭项" ON public.saved_look_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.saved_looks sl 
      WHERE sl.id = saved_look_id AND sl.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能插入自己的保存穿搭项" ON public.saved_look_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.saved_looks sl 
      WHERE sl.id = saved_look_id AND sl.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能删除自己的保存穿搭项" ON public.saved_look_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.saved_looks sl 
      WHERE sl.id = saved_look_id AND sl.user_id = auth.uid()
    )
  );

-- community_posts表策略
CREATE POLICY "公开帖子可查看" ON public.community_posts
  FOR SELECT USING (visibility = 'public' AND deleted_at IS NULL);

CREATE POLICY "用户可查看自己的私有帖子" ON public.community_posts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的帖子" ON public.community_posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的帖子" ON public.community_posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的帖子" ON public.community_posts
  FOR DELETE USING (auth.uid() = user_id);

-- community_post_images表策略
CREATE POLICY "用户可查看公开帖子图片" ON public.community_post_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.visibility = 'public' AND cp.deleted_at IS NULL
    )
  );

CREATE POLICY "用户可查看自己帖子图片" ON public.community_post_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能插入自己帖子图片" ON public.community_post_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能删除自己帖子图片" ON public.community_post_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.user_id = auth.uid()
    )
  );

-- community_likes表策略
CREATE POLICY "用户可查看公开帖子点赞" ON public.community_likes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.visibility = 'public' AND cp.deleted_at IS NULL
    )
  );

CREATE POLICY "用户可查看自己帖子点赞" ON public.community_likes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能点赞公开帖子" ON public.community_likes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.visibility = 'public' AND cp.deleted_at IS NULL
    )
  );

CREATE POLICY "用户只能删除自己的点赞" ON public.community_likes
  FOR DELETE USING (auth.uid() = user_id);

-- community_comments表策略
CREATE POLICY "用户可查看公开帖子评论" ON public.community_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.visibility = 'public' AND cp.deleted_at IS NULL
    )
  );

CREATE POLICY "用户可查看自己帖子评论" ON public.community_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "用户只能评论公开帖子" ON public.community_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    EXISTS (
      SELECT 1 FROM public.community_posts cp 
      WHERE cp.id = post_id AND cp.visibility = 'public' AND cp.deleted_at IS NULL
    )
  );

CREATE POLICY "用户只能更新自己的评论" ON public.community_comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的评论" ON public.community_comments
  FOR DELETE USING (auth.uid() = user_id);

-- follows表策略
CREATE POLICY "用户可查看公开关注关系" ON public.follows
  FOR SELECT USING (true);

CREATE POLICY "用户只能创建自己的关注" ON public.follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "用户只能删除自己的关注" ON public.follows
  FOR DELETE USING (auth.uid() = follower_id);

-- 授权基本权限给anon和authenticated角色
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;