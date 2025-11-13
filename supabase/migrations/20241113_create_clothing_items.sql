-- 创建衣物表
CREATE TABLE clothing_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,
  image_path TEXT NOT NULL,
  image_url TEXT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 添加外键约束
ALTER TABLE clothing_items 
ADD CONSTRAINT fk_clothing_user 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 创建索引
CREATE INDEX idx_clothing_items_user_id ON clothing_items(user_id);
CREATE INDEX idx_clothing_items_category ON clothing_items(category);
CREATE INDEX idx_clothing_items_created_at ON clothing_items(created_at DESC);

-- 启用RLS（行级安全）
ALTER TABLE clothing_items ENABLE ROW LEVEL SECURITY;

-- 创建策略：用户只能查看自己的衣物
CREATE POLICY "用户只能查看自己的衣物" ON clothing_items
  FOR SELECT USING (auth.uid() = user_id);

-- 创建策略：用户只能插入自己的衣物
CREATE POLICY "用户只能插入自己的衣物" ON clothing_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 创建策略：用户只能更新自己的衣物
CREATE POLICY "用户只能更新自己的衣物" ON clothing_items
  FOR UPDATE USING (auth.uid() = user_id);

-- 创建策略：用户只能删除自己的衣物
CREATE POLICY "用户只能删除自己的衣物" ON clothing_items
  FOR DELETE USING (auth.uid() = user_id);

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON clothing_items TO authenticated;
GRANT SELECT ON clothing_items TO anon;

-- 创建更新时间的触发器
CREATE OR REPLACE FUNCTION update_clothing_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_clothing_updated_at
  BEFORE UPDATE ON clothing_items
  FOR EACH ROW
  EXECUTE FUNCTION update_clothing_updated_at();