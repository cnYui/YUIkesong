-- 确保保存穿搭相关表的权限设置
-- 为anon和authenticated角色授予必要的权限

-- saved_looks表权限
GRANT SELECT ON saved_looks TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON saved_looks TO authenticated;

-- saved_look_items表权限
GRANT SELECT ON saved_look_items TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON saved_look_items TO authenticated;

-- 检查当前权限
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name IN ('saved_looks', 'saved_look_items')
AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee;