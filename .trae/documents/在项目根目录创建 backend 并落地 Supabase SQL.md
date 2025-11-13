## 目标

* 在项目根目录新增 `backend/` 作为后端与数据库脚本的存放目录

* 提供可直接用于 Supabase 的 SQL 脚本（表结构、RLS 策略、存储 buckets）

* 预留 `api/` 子目录用于后续服务端 API 实现（先占位）

## 目录结构

* `backend/`

  * `supabase/`

    * `db_schema.sql`：全部业务表结构（profiles/selfies/wardrobe/recommendations/ai\_tasks/saved\_looks/community 等）

    * `rls_policies.sql`：启用 RLS 与策略（按 `user_id = auth.uid()`；社区公开读）

    * `storage_buckets.sql`：创建 Storage buckets（selfies/wardrobe/saved\_looks/community）

  * `api/`

    * `.gitkeep`：占位，不添加文档文件

  * `.gitkeep`：保证目录可见

## 说明

* 不添加 README 等文档文件，遵循不主动创建文档的约束

* SQL 无注释，便于直接在 Supabase SQL 编辑器执行

## 执行

* 创建上述目录与文件，并写入 SQL 内容

