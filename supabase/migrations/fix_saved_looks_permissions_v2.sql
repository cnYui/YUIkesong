-- 检查并修复saved_looks表的权限设置
-- 确保authenticated用户只能访问自己的数据

-- 检查当前权限
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name = 'saved_looks' 
AND grantee IN ('anon', 'authenticated');

-- 授予authenticated用户对saved_looks表的必要权限
GRANT SELECT, INSERT, UPDATE, DELETE ON saved_looks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON saved_look_items TO authenticated;

-- 确保RLS策略正确
ALTER TABLE saved_looks ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_look_items ENABLE ROW LEVEL SECURITY;

-- 更新现有的RLS策略
DROP POLICY IF EXISTS "用户只能查看自己的保存穿搭" ON saved_looks;
DROP POLICY IF EXISTS "用户只能插入自己的保存穿搭" ON saved_looks;
DROP POLICY IF EXISTS "用户只能更新自己的保存穿搭" ON saved_looks;
DROP POLICY IF EXISTS "用户只能删除自己的保存穿搭" ON saved_looks;

DROP POLICY IF EXISTS "用户只能查看自己的保存穿搭项目" ON saved_look_items;
DROP POLICY IF EXISTS "用户只能插入自己的保存穿搭项目" ON saved_look_items;
DROP POLICY IF EXISTS "用户只能更新自己的保存穿搭项目" ON saved_look_items;
DROP POLICY IF EXISTS "用户只能删除自己的保存穿搭项目" ON saved_look_items;

-- 创建新的RLS策略，确保用户只能访问自己的数据
CREATE POLICY "用户只能查看自己的保存穿搭" ON saved_looks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户只能插入自己的保存穿搭" ON saved_looks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户只能更新自己的保存穿搭" ON saved_looks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户只能删除自己的保存穿搭" ON saved_looks
    FOR DELETE USING (auth.uid() = user_id);

-- 对saved_look_items表也创建相应的策略
CREATE POLICY "用户只能查看自己的保存穿搭项目" ON saved_look_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM saved_looks 
            WHERE saved_looks.id = saved_look_items.saved_look_id 
            AND saved_looks.user_id = auth.uid()
        )
    );

CREATE POLICY "用户只能插入自己的保存穿搭项目" ON saved_look_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM saved_looks 
            WHERE saved_looks.id = saved_look_items.saved_look_id 
            AND saved_looks.user_id = auth.uid()
        )
    );

CREATE POLICY "用户只能更新自己的保存穿搭项目" ON saved_look_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM saved_looks 
            WHERE saved_looks.id = saved_look_items.saved_look_id 
            AND saved_looks.user_id = auth.uid()
        )
    );

CREATE POLICY "用户只能删除自己的保存穿搭项目" ON saved_look_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM saved_looks 
            WHERE saved_looks.id = saved_look_items.saved_look_id 
            AND saved_looks.user_id = auth.uid()
        )
    );