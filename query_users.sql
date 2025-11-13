-- 查看所有注册用户数据
SELECT 
    '=== 用户认证数据 ===' as section;

-- 查询auth.users表中的用户数据（需要管理员权限）
-- 注意：这个查询需要service_role密钥才能访问

SELECT 
    '=== 用户资料数据 ===' as section;

-- 查询profiles表中的用户数据
SELECT 
    id,
    nickname,
    avatar_url,
    city,
    created_at
FROM profiles 
ORDER BY created_at DESC;

SELECT 
    '=== 用户统计 ===' as section;

-- 统计用户数量
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN nickname IS NOT NULL THEN 1 END) as users_with_nickname,
    COUNT(CASE WHEN avatar_url IS NOT NULL THEN 1 END) as users_with_avatar,
    COUNT(CASE WHEN city IS NOT NULL THEN 1 END) as users_with_city
FROM profiles;

-- 查看最近注册的用户
SELECT 
    '=== 最近注册用户 ===' as section;

SELECT 
    id,
    nickname,
    city,
    created_at
FROM profiles 
ORDER BY created_at DESC 
LIMIT 5;