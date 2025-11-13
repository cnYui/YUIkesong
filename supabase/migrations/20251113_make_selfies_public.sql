-- 将selfies存储桶改为公开
UPDATE storage.buckets 
SET public = true 
WHERE id = 'selfies';