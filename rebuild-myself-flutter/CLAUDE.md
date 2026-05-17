# 精进｜全维度人生重塑 — Flutter 端

## 项目概览

Flutter 移动端应用，搭配 Spring Boot 后端。离线优先架构（localStorage + 同步到后端 MySQL）。

## 启动

```bash
# 本地开发（Web 模式，连 localhost:8080）
flutter run -d chrome --web-port 3000

# 构建 APK（release 自动连服务器 47.92.98.182:8080）
flutter build apk --release
# APK 路径: build/app/outputs/flutter-apk/app-release.apk
```

## 后端地址切换

`lib/config/api_config.dart` — 用 `kReleaseMode` 自动切换：
- Debug 模式 → `http://localhost:8080/api`
- Release 模式 → `http://47.92.98.182:8080/api`

## 核心架构

### 状态管理：Provider（ChangeNotifier）

13 个 Provider 在 `lib/providers/`，顶层在 `main.dart` 的 `MultiProvider` 注入。

### 本地存储：localStorage 模拟 SQLite

`lib/services/local_storage.dart` 按平台分发：
- Web: `local_storage_web.dart` → `window.localStorage`（每表存一个 JSON key）
- 移动端: `local_storage_io.dart` → 文件 JSON

**字段命名注意**：插入用 `toJson()`（驼峰），查询时两种命名都可能存在，SyncService 有 `_keyMap` 做转换。

### 数据同步：SyncService

`lib/services/sync_service.dart`：
- `syncAll()` → push 未同步数据到 `POST /api/sync/upload` → pull `GET /api/sync/pull?since=`（增量）或 `/api/sync/export`（全量）
- 每行通过 `synced` 字段（1/0）标记同步状态
- 字段名驼峰↔下划线转换：`_keyMap`

### 认证：AuthProvider + JWT

`lib/providers/auth_provider.dart`：
- `init()` → 从 TokenStore 加载 token → `/api/user/profile` 验证
- `login(phone, pwd)` → `/api/user/login` → 保存 JWT
- `logout()` → 清 token，AuthGate 自动跳登录页
- `lib/main.dart` 的 `AuthGate` 控制启动流程：初始化 → 登录页 / 隐私锁 / 主页

### 导航：MainShell + routes

`lib/config/shell.dart` — BottomNavigationBar 5 个 tab：
0. 首页 (HomePage)
1. 目标 (GoalPage)
2. 记录 (RecordPage)
3. 数据 (StatsPage)
4. 我的 (SettingsPage)

`lib/config/routes.dart` — 命名路由：`/elite`, `/finance`, `/study`, `/sideline`, `/reading`, `/leisure`, `/intervene`, `/reports`

## 数据模型（lib/models/）

| 模型 | 对应表 | 关键字段 |
|------|--------|----------|
| `TaskTodo` | `task_todo` | taskTitle, taskLevel(1-4四象限), isComplete, taskDate |
| `DailyModelPlan` | `daily_model_plan` | planDate, timePeriod("18:00-18:30"), planContent, planType, difficulty |
| `DailyCompareCheck` | `daily_compare_check` | planDate, deviationContent, escapeReason, progressScore |
| `Goal` | `user_goal` | goalLevel, goalType, targetDate |
| `EliteHabit` | `elite_habit_lib` | habitCategory(1-4), habitContent, intensityLevel |
| `TimeBlockConfig` | `time_block_config` | start, end, label, type(0固定/1待办/2推荐), day_type |

## 今日计划生成（核心功能）

入口：
- 精英页「生成今日计划」按钮 → `EliteProvider.generateTodayPlan()`
- 首页无计划时「生成今日计划」按钮 → 同上

逻辑（`EliteProvider.generateTodayPlan()`）：
1. 清空当天已有计划
2. 读取当天未完成待办，按优先级排序（taskLevel: 1最重要→4最不重要）
3. 按配置的时间块遍历：
   - type=0 (固定锚点) → 用 label 作为内容
   - type=1 (待办槽位) → 填入优先待办
   - type=2 (推荐) → 用 label 作为推荐内容
4. 超出槽位的待办合并到最后一个计划项
5. 自动判断日类型：周六日用 weekend 模板，其他用 workday 模板

时间块配置（ElitePage → 时间设置卡片）：
- 工作日/周末两套独立配置，存储在 `time_block_config` 表
- 可编辑每块的起止时间、类型、标签
- 预设：下班后(18:00-22:30)、全天候(6:00-22:00)、紧凑型(19:00-22:00)

## 首页卡片

- **当前时段卡片**（`_CurrentFocusCard`）：根据当前时间匹配计划时段，显示该做的事
- **MiniStats**：当前显示静态 "-"，之前 Consumer2 导致 "Closure" 渲染 bug
- **快捷导航**：财务行动、三赛道学习、副业规划、书籍阅读、精英对标、AI复盘报告

## 关键文件索引

```
lib/
├── main.dart                      # App入口 + AuthGate + MultiProvider
├── config/
│   ├── api_config.dart            # 后端地址（debug/release自动切换）
│   ├── theme.dart                 # 主题色
│   ├── routes.dart                # 命名路由
│   └── shell.dart                 # MainShell 底部导航
├── models/                        # 数据模型（见上表）
├── providers/                     # ChangeNotifier 提供者
│   ├── elite_provider.dart        # 计划生成核心逻辑在此
│   ├── goal_provider.dart         # 目标 + 任务（TaskTodo）
│   └── auth_provider.dart         # JWT认证
├── pages/
│   ├── home/home_page.dart        # 首页（当前时段卡片+快捷导航+今日规划）
│   ├── elite/elite_page.dart      # 精英对标（计划生成+时间设置+自检+习惯库）
│   ├── goal/goal_page.dart        # 目标页（长期/年度/月度/每日/四象限）
│   └── settings/settings_page.dart # 设置（隐私锁+数据管理+退出）
├── services/
│   ├── api_client.dart            # HTTP 客户端（JWT Bearer）
│   ├── sync_service.dart          # 数据同步 push/pull
│   ├── database_helper.dart       # LocalStorage 封装
│   ├── local_storage.dart         # 平台分发
│   ├── local_storage_web.dart     # Web localStorage 实现
│   └── local_storage_io.dart      # IO 文件 JSON 实现
└── android/                       # Android 配置
    ├── build.gradle.kts           # 阿里云镜像源
    └── settings.gradle.kts        # 阿里云镜像源
```

## 后端

`rebuild-myself-server/` — Spring Boot 3.x + MyBatis-Plus + JWT

关键接口：
- `POST /api/user/login` — 登录返回 JWT
- `POST /api/user/register` — 注册
- `GET /api/user/profile` — 验证 token
- `POST /api/sync/upload` — 上传数据
- `GET /api/sync/pull?since=` — 增量拉取
- `GET /api/sync/export?start=&end=` — 全量导出

启动：`cd rebuild-myself-server && mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"`

## 常见问题

- **Consumer2 "Closure" bug**：Flutter Web 上 Consumer2 渲染 Function toString()，已改为分别用 Consumer
- **localStorage 数据不跨端口**：不同端口=不同 origin，localStorage 不共享
- **字段名不一致**：插入用驼峰（toJson），删除/查询两种都试
- **Android HTTP 明文**：已在 AndroidManifest 添加 `usesCleartextTraffic="true"`
