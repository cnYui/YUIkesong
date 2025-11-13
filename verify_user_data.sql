-- 检查所有用户数据详情
SELECT 
    id, 
    nickname, 
    avatar_url, 
    city, 
    created_at 
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 10;

-- 检查用户总数
SELECT COUNT(*) as total_users FROM public.profiles;

-- 检查最新的用户
SELECT * FROM public.profiles 
WHERE id = 'dcef3953-c8d4-4800-8811-f8098b999e7c';