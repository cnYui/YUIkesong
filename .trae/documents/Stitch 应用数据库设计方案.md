## 目标与范围
- 建立支撑首页推荐、衣柜管理、AI 生成、保存穿搭、社区等业务的关系型数据库模型
- 覆盖用户认证与令牌、资源存储（URL）、多端读写一致性、审计字段与软删除、常用索引

## 选型与约定
- 数据库：MySQL 8.0（如需 PostgreSQL，可按同结构调整类型/枚举实现）
- 字符集：`utf8mb4`，排序规则：`utf8mb4_0900_ai_ci`
- 主键：`BIGINT` 自增（或可切换 Snowflake/UUID，根据后端偏好）
- 通用字段：`created_at DATETIME`、`updated_at DATETIME`、`deleted_at DATETIME NULL`（软删除）
- 外链资源：图片统一存储对象存储，表内保存 `image_url`

## 实体与表结构
### 用户与认证
1. users
- `id BIGINT PK AUTO_INCREMENT`
- `email VARCHAR(128) UNIQUE NULL`、`phone VARCHAR(32) UNIQUE NULL`
- `password_hash VARCHAR(255) NULL`、`provider ENUM('local','oauth') DEFAULT 'local'`
- `nickname VARCHAR(32)`、`avatar_url VARCHAR(255)`、`gender TINYINT DEFAULT 0`、`city VARCHAR(64)`
- 审计：`created_at`、`updated_at`
- 索引：`idx_users_email`、`idx_users_phone`

2. auth_tokens（刷新令牌/会话）
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK users(id)`
- `refresh_token_hash VARCHAR(255)`、`expires_at DATETIME`、`revoked_at DATETIME NULL`
- 审计：`created_at`
- 索引：`idx_tokens_user_expires (user_id, expires_at)`

### 自拍与衣柜
3. selfies
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`
- `image_url VARCHAR(255)`、`is_default TINYINT(1) DEFAULT 0`
- 审计：`created_at`
- 索引：`idx_selfies_user_default (user_id, is_default)`

4. wardrobe_categories
- `id BIGINT PK AUTO_INCREMENT`、`name VARCHAR(32)`、`icon VARCHAR(64)`、`sort_order INT DEFAULT 0`

5. wardrobe_items
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`、`category_id BIGINT FK`
- `image_url VARCHAR(255)`、`color VARCHAR(32)`、`season VARCHAR(32)`、`metadata JSON`
- 审计：`created_at`、`updated_at`、`deleted_at`
- 索引：`idx_wardrobe_user_cat (user_id, category_id)`、`idx_wardrobe_user_created (user_id, created_at)`

### 推荐与 AI 任务
6. recommendations
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`
- `weather_tag VARCHAR(32)`、`title VARCHAR(64)`、`description VARCHAR(255)`
- `source ENUM('ai','manual') DEFAULT 'ai'`
- 审计：`created_at`
- 索引：`idx_reco_user_created (user_id, created_at)`

7. recommendation_items（N:N）
- `recommendation_id BIGINT FK`、`wardrobe_item_id BIGINT FK`、`slot VARCHAR(16)`
- PK：`PRIMARY KEY (recommendation_id, wardrobe_item_id)`

8. ai_tasks
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`
- `task_type ENUM('image','video')`、`status ENUM('pending','processing','finished','failed')`
- `input_payload JSON`、`result_url VARCHAR(255) NULL`
- 审计：`created_at`、`updated_at`
- 索引：`idx_ai_user_status (user_id, status)`、`idx_ai_created (created_at)`

### 保存穿搭
9. saved_looks
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`
- `ai_task_id BIGINT NULL FK`、`recommendation_id BIGINT NULL FK`
- `cover_image_url VARCHAR(255)`
- 审计：`created_at`
- 索引：`idx_looks_user_created (user_id, created_at)`

10. saved_look_items（N:N）
- `saved_look_id BIGINT FK`、`wardrobe_item_id BIGINT FK`、`slot VARCHAR(16)`
- PK：`PRIMARY KEY (saved_look_id, wardrobe_item_id)`

### 社区模块
11. community_posts
- `id BIGINT PK AUTO_INCREMENT`、`user_id BIGINT FK`
- `cover_image_url VARCHAR(255)`、`description VARCHAR(500) NULL`
- `visibility ENUM('public','private') DEFAULT 'public'`
- 审计：`created_at`、`updated_at`、`deleted_at`
- 索引：`idx_posts_user_created (user_id, created_at)`

12. community_post_images
- `id BIGINT PK AUTO_INCREMENT`、`post_id BIGINT FK`、`image_url VARCHAR(255)`、`sort_order INT`
- 索引：`idx_post_images_post (post_id)`

13. community_likes
- `post_id BIGINT FK`、`user_id BIGINT FK`、`created_at DATETIME`
- PK：`PRIMARY KEY (post_id, user_id)`

14. community_comments
- `id BIGINT PK AUTO_INCREMENT`、`post_id BIGINT FK`、`user_id BIGINT FK`
- `content VARCHAR(500)`、`parent_id BIGINT NULL`（二级回复）
- 审计：`created_at`
- 索引：`idx_comments_post_created (post_id, created_at)`、`idx_comments_parent (parent_id)`

15. follows（关注关系）
- `follower_id BIGINT FK users(id)`、`followee_id BIGINT FK users(id)`、`created_at DATETIME`
- PK：`PRIMARY KEY (follower_id, followee_id)`

## 关系与级联策略
- 用户删除：通常逻辑删除（`deleted_at`），避免级联清空；依赖表保留记录
- 归档表（items/comments/likes）使用 `ON DELETE CASCADE` 清理子记录，仅当业务允许
- 交叉表（recommendation_items/saved_look_items）使用 CASCADE 以保持参照完整性

## 索引与查询优化
- 所有列表页按 `created_at DESC` 建组合索引（含外键）
- 常用过滤：`(user_id, category_id)`、`(user_id, status)`、`(post_id)`
- 文本搜索：如需衣物名称/描述搜索，推荐外置搜索或 MySQL 全文索引（InnoDB FTS）

## DDL 示例（MySQL 8）
- 核心表（节选）
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(128) UNIQUE,
  phone VARCHAR(32) UNIQUE,
  password_hash VARCHAR(255),
  provider ENUM('local','oauth') DEFAULT 'local',
  nickname VARCHAR(32) NOT NULL,
  avatar_url VARCHAR(255),
  gender TINYINT DEFAULT 0,
  city VARCHAR(64),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE wardrobe_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  category_id BIGINT,
  image_url VARCHAR(255) NOT NULL,
  color VARCHAR(32),
  season VARCHAR(32),
  metadata JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_wardrobe_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_wardrobe_category FOREIGN KEY (category_id) REFERENCES wardrobe_categories(id)
);

CREATE TABLE ai_tasks (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  task_type ENUM('image','video') NOT NULL,
  status ENUM('pending','processing','finished','failed') DEFAULT 'pending',
  input_payload JSON,
  result_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ai_task_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE saved_looks (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  ai_task_id BIGINT,
  recommendation_id BIGINT,
  cover_image_url VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_saved_look_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_saved_look_task FOREIGN KEY (ai_task_id) REFERENCES ai_tasks(id),
  CONSTRAINT fk_saved_look_reco FOREIGN KEY (recommendation_id) REFERENCES recommendations(id)
);

CREATE TABLE community_posts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  cover_image_url VARCHAR(255),
  description VARCHAR(500),
  visibility ENUM('public','private') DEFAULT 'public',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES users(id)
);
```
- 其余表可按上文字段定义补齐（我可在确认后输出完整 SQL 文件）

## 安全与合规
- 存储密码使用强哈希（argon2 或 bcrypt），令牌仅存哈希
- 所有外部 URL 做签名校验或来源白名单；上传走服务端鉴权
- 关键业务操作记录审计日志（可选：`operation_logs`）

## 迁移与版本控制
- 使用 Flyway/Liquibase 或自研迁移器，按 `V1__init.sql` → `V2__community.sql` 递增
- 开发/测试/生产分库，严格走迁移脚本，禁止手工改表

## 对前端的映射
- `SavedLooksStore` 对应 `saved_looks`/`saved_look_items`
- `WardrobeSelectionStore` 对应 `wardrobe_items`
- `CurrentRecommendationStore` 对应 `recommendations`/`recommendation_items`
- 社区页对应 `community_posts`/`community_post_images`/`community_likes`/`community_comments`

## 实施里程碑
- 第 1 阶段：users/selfies/wardrobe/*、recommendations/*、ai_tasks、saved_looks/*（核心闭环）
- 第 2 阶段：community/*、follows、likes/comments
- 第 3 阶段：auth_tokens、软删除与审计、索引体检与压测

## 需要你确认
- 是否使用 MySQL 8（或改为 PostgreSQL）
- 是否启用社区的评论/点赞/关注功能首版即上线
- 密码学方案（argon2/bcrypt）与令牌有效期策略
- 我是否直接输出完整 DDL 文件并创建迁移脚本