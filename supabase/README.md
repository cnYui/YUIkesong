# 应用数据库迁移脚本

## 使用说明

这些SQL迁移脚本用于在Supabase项目中创建和配置数据库结构。

### 迁移文件列表

1. **001_create_tables.sql** - 创建所有必需的数据表
2. **002_init_categories.sql** - 初始化衣柜分类数据
3. **003_rls_policies.sql** - 配置行级安全策略(RLS)
4. **004_storage_buckets.sql** - 配置Storage buckets和访问策略

### 如何应用迁移

由于Supabase集成工具的限制，你需要手动在Supabase Dashboard中执行这些SQL脚本：

1. 登录 [Supabase Dashboard](https://app.supabase.com)
2. 选择你的项目
3. 进入 SQL Editor
4. 按顺序执行以下SQL文件：

#### 第一步：创建数据表
```sql
-- 执行 001_create_tables.sql 的内容
```

#### 第二步：初始化分类数据
```sql
-- 执行 002_init_categories.sql 的内容
```

#### 第三步：配置RLS策略
```sql
-- 执行 003_rls_policies.sql 的内容
```

#### 第四步：配置Storage buckets
```sql
-- 执行 004_storage_buckets.sql 的内容
```

### 验证迁移结果

执行完所有迁移后，可以通过以下SQL验证：

```sql
-- 检查表是否创建成功
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 检查RLS策略是否启用
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND rowsecurity = true;

-- 检查Storage buckets
SELECT * FROM storage.buckets;
```

### 注意事项

1. 确保按顺序执行迁移文件
2. 每个迁移文件执行前检查是否有错误
3. RLS策略启用后，所有数据访问都需要通过API进行
4. Storage buckets配置需要与前端代码保持一致

### 后端API配置

确保后端API的 `.env` 文件包含正确的Supabase配置：

```
SUPABASE_URL=https://tbjyhqcazhgcmtbdgwpg.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRianlocWNhemhnY210YmRnd3BnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjgzNjU2OSwiZXhwIjoyMDc4NDEyNTY5fQ.rbgExIUuMb3jLJFqVr8qyrxLlPcbD3xgBHAbb1RtJos
```