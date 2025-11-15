-- 添加天气缓存字段到 profiles 表

-- 添加天气缓存字段（使用 JSONB 存储完整的天气信息）
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS cached_weather JSONB;

-- 添加天气缓存更新时间
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS weather_updated_at TIMESTAMP;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_profiles_weather_updated 
ON public.profiles(weather_updated_at);

-- 添加注释说明
COMMENT ON COLUMN public.profiles.cached_weather IS '缓存的天气信息，包含: province, city, adcode, weather, temperature, windDirection, windPower, humidity, reportTime';
COMMENT ON COLUMN public.profiles.weather_updated_at IS '天气信息最后更新时间';

-- 查看更新后的表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;

