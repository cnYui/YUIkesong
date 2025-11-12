# 前端实现说明（提供给后端）

## 1. 项目概览
- 框架：Flutter 3.x，Material 设计体系，自定义主题位于 `lib/theme/app_theme.dart`。
- 入口：`lib/main.dart`，通过 `StitchShell` 承载底部导航的四大主页面：`首页`、`我的衣柜`、`AI试穿室`、`我的`。
- 字体：全局使用 Google Fonts `PlusJakartaSans`，已在 `pubspec.yaml` 中配置。
- 资源：页面视觉参考均来源于 `stitch_/` 目录下的 HTML + PNG，Flutter 端已经完全复刻样式与交互。

## 2. 主要依赖包
| 包名 | 作用 | 备注 |
| --- | --- | --- |
| `google_fonts` | 自定义字体 | 已在根主题中加载 |
| `image_picker` | 调用相机 / 相册 | `我的衣柜` 中添加衣物使用 |
| `http` | 预留网络请求 | 当前未直接使用，可供后端集成 |
| `cupertino_icons` | 备用图标 | 默认依赖 |

## 3. 导航结构
- 底部导航（`StitchBottomNav`）：统一黑白样式，使用 `IndexedStack` 保持页面状态。
- 页面路由：
  - `SelfieManagementPage`（管理我的自拍）
  - `SavedLooksPage`（我保存的穿搭）
  - `SettingsPage`（设置）
  - `AboutPage`（关于我们）
- 通过 `Navigator.pushNamed` 进入子页面；`StitchShellCoordinator` 提供跨页面切换 tab 的能力（例如首页跳转 AI 试穿室）。

## 4. 页面功能明细
### 4.1 首页 (`lib/pages/home_page.dart`)
- 顶部展示定位 + 天气提示（目前使用静态文案，后端可替换为真实接口）。
- 今日推荐卡片：
  - 每张卡片展示 22 的服饰图片组合（来自 `_Recommendation.images`）。
  - 点击 立即试穿 后：
    1. 将当前搭配写入 `CurrentRecommendationStore`
    2. 通过 `StitchShellCoordinator` 切换到 `AI试穿室`

### 4.2 我的衣柜 (`lib/pages/wardrobe_page.dart`)
- `SliverAppBar` 固定，包含分类 Tab、搜索与筛选入口。
- 衣物列表支持：
  - 分类筛选（模拟数据）
  - 点选衣服出现黑色勾选图标，再次点击取消
  - 底部弹出悬浮条显示已选衣物，可横向滚动 & 移除
  - 一键生成 按钮跳转到 `AI试穿室`
- 浮动相机按钮：弹出 `BottomSheet`，可拍照或选取相册图片  模拟的处理中页  保存页。

### 4.3 AI 试穿室 (`lib/pages/ai_fitting_room_page.dart`)
- 支持 生成图片 / 生成视频 两种模式，按钮和图标动态切换。
- `PageView` 轮播展示生成结果（当前为静态示例图）。
- 保存穿搭 行为：
  1. 调用 `_getSelectedClothingImages()`，优先顺序：
     - `CurrentRecommendationStore`（首页推荐）
     - `WardrobeSelectionStore`（衣柜选择）
     - 默认占位服饰
  2. 创建 `SavedLook` 并写入 `SavedLooksStore`
  3. Toast 提示保存成功

### 4.4 我的 (`lib/pages/profile_page.dart`)
- 四个快捷入口改为黑色图标。
- 进入子页面：管理自拍、我保存的穿搭、设置、关于我们。

### 4.5 我保存的穿搭 (`lib/pages/saved_looks_page.dart`)
- 读取 `SavedLooksStore` 数据。
- 每条记录展示：
  - 主结果图
  - 下方衣物列表（<=2 张平铺；>2 张横向滚动）
- AppBar 底部增加说明文字。

### 4.6 管理我的自拍 (`lib/pages/selfie_management_page.dart`)
- 单选机制，选中头像右上角出现黑色勾选，只允许同时选一张。

### 4.7 设置 (`lib/pages/settings_page.dart`)
- 所有文本统一黑色，保留静态选项，后端可替换为数据驱动。

### 4.8 添加衣物流程
1. 我的衣柜  点击相机按钮
2. 底部弹窗选择 拍照添加衣物 或 从相册选择衣物
3. 进入 `AddClothingProcessingPage`，模拟 1 秒加载
4. 跳转 `AddClothingSavePage`：
   - 图片与按钮整体上移
   - 保存到衣柜 按钮黑底白字、圆角与 AI 试穿室一致
   - 点击后返回衣柜页

## 5. 状态管理
| Store | 文件 | 说明 | 后端对接建议 |
| --- | --- | --- | --- |
| `SavedLooksStore` | `lib/state/saved_looks_store.dart` | 维护用户保存的穿搭列表（`ValueNotifier<List<SavedLook>>`） | 后续可替换为调用后端接口并缓存 |
| `WardrobeSelectionStore` | `lib/state/wardrobe_selection_store.dart` | 记录衣柜当前选中衣物（索引 + 图片） | 提供给 AI 试穿室使用，后端可同步选中状态 |
| `CurrentRecommendationStore` | `lib/state/current_recommendation_store.dart` | 存储首页传入的推荐搭配 | 用于在 AI 试穿室直接保存推荐组合 |

数据保存目前全部在前端内存中，便于后端后续接管。

## 6. 与后端的对接点
| 模块 | 当前实现 | 后端需要提供的接口/数据 |
| --- | --- | --- |
| 天气提示 | 静态文案 | 城市定位、天气描述、穿搭建议 |
| 今日推荐 | 本地模拟列表 | 推荐搭配列表（图片 URL、品类、标签等） |
| 我的衣柜 | 本地模拟数据 | 衣物列表、分类、搜索、筛选结果 |
| AI 试穿 | 静态示例图 | 上传自拍、衣服组合、生成图片/视频结果、任务状态 |
| 保存穿搭 | 前端内存 | 保存穿搭记录、查询历史、删除等 |
| 自拍管理 | 本地示例图 | 用户自拍列表、上传/删除接口 |
| 添加衣物 | 使用 `image_picker` 获取本地图片 | 上传衣物图片、识别结果、生成属性 |

> 说明：目前所有图片均使用线上示例 URL，后端接入后可替换为真实资源或对象存储路径。

## 7. 数据模型示例
```dart
class SavedLook {
  final String id;            // 前端以时间戳生成，后端可替换为真实 ID
  final String resultImage;   // AI 生成图 URL
  final List<String> clothingImages; // 搭配中的衣服图片
  final DateTime timestamp;
}
```

```dart
class WardrobeItem {
  final String id;
  final String image;
  final String category;  // 例如：外套、裤装、鞋靴
}
```

## 8. 事件流（关键交互）
1. **首页  AI 试穿室  保存穿搭**
   - 首页 `立即试穿` 按钮  写入 `CurrentRecommendationStore`
   - 自动切换 Tab  AI 试穿室
   - 用户点击 `保存穿搭`  合成当前头像 + 衣服  `SavedLooksStore.add`
2. **衣柜选择  AI 试穿室  保存穿搭**
   - 衣柜选择多件衣服  `WardrobeSelectionStore`
   - 点击悬浮条 `一键生成`  切换到 AI 试穿室
   - `保存穿搭`  从 Wardrobe store 读取衣服列表写入保存
3. **添加衣物**
   - 相机按钮  bottom sheet  选择来源（拍照 / 相册）
   - 进入处理中页  自动延迟 1 秒  保存页
   - 点击 `保存到衣柜`  返回衣柜并保持原状态

## 9. 多语言与主题
- 多语言目前仅展示静态文案；后端若需国际化，可提供标准化字典或配置。
- 主题为浅色系，核心色值集中在 `StitchColors`（见 `app_theme.dart`），后端无需关注。

## 10. 集成建议
1. **网络层**：
   - 推荐使用 `http` 或 `dio`；目前 `http` 已在依赖
   - 可以封装统一的 `ApiClient`，在各页面调用
2. **数据同步**：
   - 可将当前 `ValueNotifier` 替换为 `ChangeNotifier` 或 `Riverpod/Bloc` 等更完善的状态管理，配合后端接口
   - 保存穿搭、衣柜物品建议与后端保持 ID 对齐
3. **离线策略**：
   - 可在 `SavedLooksStore` 中增加本地缓存（如 `shared_preferences`）

## 11. 数据库设计（推荐方案）

### 11.1 核心实体
| 表名 | 用途 | 关键字段 |
| --- | --- | --- |
| `users` | 存储用户基础信息 | `id`、`nickname`、`avatar_url`、`gender`、`city` |
| `selfies` | 用户自拍管理 | `id`、`user_id`、`image_url`、`is_default`、`created_at` |
| `wardrobe_items` | 用户衣柜单品 | `id`、`user_id`、`category_id`、`image_url`、`color`、`season`、`metadata` |
| `wardrobe_categories` | 衣物分类字典 | `id`、`name`、`icon`、`sort_order` |
| `recommendations` | 推荐穿搭方案（AI 或规则生成） | `id`、`user_id`、`weather_tag`、`title`、`description`、`source`、`created_at` |
| `recommendation_items` | 推荐方案关联的衣物 | `recommendation_id`、`wardrobe_item_id`、`slot` |
| `ai_tasks` | AI 生成记录（图片/视频） | `id`、`user_id`、`task_type`、`status`、`input_payload`、`result_url`、`created_at`、`updated_at` |
| `saved_looks` | 用户保存的穿搭 | `id`、`user_id`、`ai_task_id`、`recommendation_id`、`cover_image_url`、`created_at` |
| `saved_look_items` | 穿搭所包含的衣物 | `saved_look_id`、`wardrobe_item_id`、`slot` |

> `slot` 字段用于描述衣物位置（例如 top / bottom / shoes），方便前后端保持顺序。

### 11.2 表结构示例（MySQL 8+）
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  nickname VARCHAR(32) NOT NULL,
  avatar_url VARCHAR(255),
  gender TINYINT DEFAULT 0,
  city VARCHAR(64),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wardrobe_categories (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL,
  icon VARCHAR(64),
  sort_order INT DEFAULT 0
);

CREATE TABLE wardrobe_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  category_id BIGINT,
  image_url VARCHAR(255) NOT NULL,
  color VARCHAR(32),
  season VARCHAR(32),
  metadata JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_wardrobe_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_wardrobe_category FOREIGN KEY (category_id) REFERENCES wardrobe_categories(id)
);

CREATE TABLE recommendations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  weather_tag VARCHAR(32),
  title VARCHAR(64) NOT NULL,
  description VARCHAR(255),
  source ENUM('ai', 'manual') DEFAULT 'ai',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reco_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE recommendation_items (
  recommendation_id BIGINT NOT NULL,
  wardrobe_item_id BIGINT NOT NULL,
  slot VARCHAR(16),
  PRIMARY KEY (recommendation_id, wardrobe_item_id),
  CONSTRAINT fk_reco_item_reco FOREIGN KEY (recommendation_id) REFERENCES recommendations(id),
  CONSTRAINT fk_reco_item_wardrobe FOREIGN KEY (wardrobe_item_id) REFERENCES wardrobe_items(id)
);

CREATE TABLE ai_tasks (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  task_type ENUM('image', 'video') NOT NULL,
  status ENUM('pending', 'processing', 'finished', 'failed') DEFAULT 'pending',
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

CREATE TABLE saved_look_items (
  saved_look_id BIGINT NOT NULL,
  wardrobe_item_id BIGINT NOT NULL,
  slot VARCHAR(16),
  PRIMARY KEY (saved_look_id, wardrobe_item_id),
  CONSTRAINT fk_saved_item_look FOREIGN KEY (saved_look_id) REFERENCES saved_looks(id),
  CONSTRAINT fk_saved_item_wardrobe FOREIGN KEY (wardrobe_item_id) REFERENCES wardrobe_items(id)
);

CREATE TABLE selfies (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  image_url VARCHAR(255) NOT NULL,
  is_default TINYINT(1) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_selfie_user FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 11.3 数据流与同步建议
- 推荐与衣橱数据保持 ID 对齐，前端存储 `recommendation_id` / `wardrobe_item_id`，后端可根据这些 ID 快速载入详情。
- `ai_tasks` 支撑生成进度轮询，状态变更后推送结果 URL 前端即可同步。
- `saved_looks` 可以记录来源（推荐/自主搭配），便于后端统计与运营分析。

如需更多细节，可参考对应文件中的实现。如果后端接口已确定，欢迎同步字段/流程，我们可继续调整前端逻辑以适配。
