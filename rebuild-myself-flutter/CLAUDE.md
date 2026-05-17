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
3. 按配置的时间块遍历（工作时段为30分钟块，其余为60分钟块）：
   - **上班前/午休/下班后** → 填入待办、习惯、目标内容
   - **上班时·上午/下午** → 仅填入冥想专注提醒（30分钟一条），不安排任何目标/待办/习惯
4. 超出槽位的待办合并到最后一个计划项
5. 自动判断日类型：周六日用 weekend 模板，其他用 workday 模板
6. **计时器完成自动标记**：FocusTimerProvider 的 `stopTimer()` 在保存学习记录后，会将对应 `daily_model_plan` 行标记为 `isCompleted=1` + `completedAt`

时间块配置（ElitePage → 时间设置卡片）：
- 工作日/周末两套独立配置，存储在 `time_block_config` 表
- 可编辑每块的起止时间、类型、标签
- 工作时段（上班时·上午/下午）固定为30分钟块，用于高频冥想提醒
- 预设：下班后(18:00-22:30)、全天候(6:00-22:00)、紧凑型(19:00-22:00)

工作时段冥想提醒（`_workFocusReminders`，共10条）：
- 简单的正念/呼吸/身体扫描提示，每条一句话
- 上班时段每30分钟轮换一条，帮助用户回到当下
- 替代了之前的MCT反刍干预协议

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
│   ├── elite_provider.dart        # 计划生成核心逻辑（含工作时段冥想提醒）
│   ├── focus_timer_provider.dart  # 专注计时器（墙钟计时+计划完成标记）
│   ├── goal_provider.dart         # 目标 + 任务（TaskTodo）
│   ├── study_provider.dart        # 学习记录（今日累计时长统计）
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
│   ├── notification_service.dart  # 本地通知（app进入后台时发送当前任务提醒）
│   ├── local_storage.dart         # 平台分发
│   ├── local_storage_web.dart     # Web localStorage 实现
│   └── local_storage_io.dart      # IO 文件 JSON 实现
└── android/                       # Android 配置
    ├── build.gradle.kts           # 阿里云镜像源
    └── settings.gradle.kts        # 阿里云镜像源
```

## AI 心理复盘报告

入口：首页「AI复盘报告」快捷导航 → `POST /api/report/generate`

**客户端** (`report_provider.dart`)：
- `generateReport(cycleType, date)` → 调用服务端生成接口
- `loadHistory(page, size)` → 加载历史报告列表

**服务端** (`AiPsychologicalReportServiceImpl.generateReport()`)：
1. 根据 `cycleType`（1=日/2=周/3=月/4=年）计算日期范围
2. 聚合该范围内用户的全维度数据（10张表）：今日规划、学习记录、日常记录、财务心理、行为干预、阅读、休闲、每日自检、副业规划、空虚情绪
3. 每条计划带4种状态标记：已完成（有记录）/已完成（无记录）/有记录未完成/未做（无任何记录）
4. 构建结构化文本摘要（非JSON dump）发给 AI 生成报告
5. 若 AI 不可用，自动回退保存数据摘要作为报告内容

AI 参数 (`AiUtil.java`)：timeout=60s, max_tokens=8192, temperature=0.7

## 后端

`rebuild-myself-server/` — Spring Boot 3.x + MyBatis-Plus + JWT

关键接口：
- `POST /api/user/login` — 登录返回 JWT
- `POST /api/user/register` — 注册
- `GET /api/user/profile` — 验证 token
- `POST /api/sync/upload` — 上传数据
- `GET /api/sync/pull?since=` — 增量拉取
- `GET /api/sync/export?start=&end=` — 全量导出
- `POST /api/report/generate` — 生成AI复盘报告（body: cycleType, date）
- `GET /api/report/history?page=&size=` — 历史报告分页

启动：`cd rebuild-myself-server && mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"`

## 常见问题

- **Consumer2 "Closure" bug**：Flutter Web 上 Consumer2 渲染 Function toString()，已改为分别用 Consumer
- **localStorage 数据不跨端口**：不同端口=不同 origin，localStorage 不共享
- **字段名不一致**：插入用驼峰（toJson），删除/查询两种都试
- **Android HTTP 明文**：已在 AndroidManifest 添加 `usesCleartextTraffic="true"`
