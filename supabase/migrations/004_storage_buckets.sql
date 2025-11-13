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

-- 配置selfies bucket的RLS策略
CREATE POLICY "用户可上传自己的自拍" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'selfies' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可查看自己的自拍" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'selfies' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可删除自己的自拍" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'selfies' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 配置wardrobe bucket的RLS策略
CREATE POLICY "用户可上传自己的衣物图片" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'wardrobe' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可查看自己的衣物图片" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'wardrobe' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可删除自己的衣物图片" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'wardrobe' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 配置saved_looks bucket的RLS策略
CREATE POLICY "用户可上传自己的保存穿搭" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'saved_looks' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可查看自己的保存穿搭" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'saved_looks' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可删除自己的保存穿搭" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'saved_looks' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 配置community bucket的RLS策略（公开读取）
CREATE POLICY "公开读取社区图片" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'community');

CREATE POLICY "用户可上传社区图片" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'community' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "用户可删除自己的社区图片" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'community' AND (storage.foldername(name))[1] = auth.uid()::text);