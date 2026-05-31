# 精进｜全维度人生重塑 — Flutter 端

## 项目概览

Flutter 移动端应用，搭配 Spring Boot 后端。服务端优先架构（MySQL + API 为主，客户端 localStorage 为缓存，双向同步）。

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

**性能关键规则：所有 Provider 的写操作（add/update/delete）均为增量更新**——操作内存中的单条记录 + 一次 `notifyListeners()`，**绝不**调用 `loadAll()` 全量重载。只有首次加载、日期切换、服务端同步合并时才全量刷新。

- 本地 DB Provider（finance/reading/sideline/leisure/intervene/empty_mood）：
  add → `db.insert` 获取新 ID → `copyWith(id:)` → `_records.insert(0, ...)` → `notifyListeners()`
  update → `db.update` → for 循环替换 → `notifyListeners()`
  delete → `db.delete` → `removeWhere` → `notifyListeners()`
- API Provider（goal/record/aspiration）：POST 响应返回实体则直接插入，否则 fallback 到 `loadAll()`

### 计时器性能隔离

`FocusTimerProvider` 使用 `ValueNotifier<int> tick` + `ListenableBuilder` 做秒级刷新隔离：
- 每秒仅 `tick.value++`（ValueNotifier），不触发 ChangeNotifier 全树重建
- 仅计时器显示文本包裹在 `ListenableBuilder(listenable: timer.tick, ...)` 中
- 状态转换（start/stop/pause/resume）才调用 `notifyListeners()`
- 首页 30 秒周期性刷新也改为 `_focusTick.value++` 替代 `setState()`

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

### 提醒文案：服务端管理 + 客户端 fallback

`lib/config/reminders.dart` — 冥想/专注提醒文案（focus/body_anchor/physical_interrupt/anti_doomscroll 四类 ~140 条）：
- **服务端**：存储在 MySQL `reminder_text` 表，通过 `GET /api/config/reminders` 提供（无需认证）
- **客户端启动时**：`HomePage._loadData()` 异步拉取 → `RemindersStore.applyServer()` 缓存
- **offline fallback**：`RemindersStore` 内置完整 const fallback，网络不可用时自动降级
- **DataInitializer**：服务端 `ApplicationRunner` 组件，启动时自动检测并创建表+种子数据，幂等安全

## 数据模型（lib/models/）

| 模型 | 对应表 | 关键字段 |
|------|--------|----------|
| `TaskTodo` | `task_todo` | taskTitle, taskLevel(1-4四象限), isComplete, taskDate |
| `DailyModelPlan` | `daily_model_plan` | planDate, timePeriod("18:00-18:30"), planContent, planType(0-7), difficulty, isCompleted(0-3) |
| `DailyCompareCheck` | `daily_compare_check` | planDate, deviationContent, escapeReason, progressScore |
| `Goal` | `user_goal` | goalLevel, goalType, targetDate, preferredSegment |
| `EliteHabit` | `elite_habit_lib` | habitCategory(1-4), habitContent, intensityLevel |
| `TimeBlockConfig` | `time_block_config` | start, end, label, type(0固定/1待办/2推荐), day_type |
| `VentingEntry` | `venting_log` | recordDate, content — 本地存储，不同步 |
| `DailySummaryEntry` | `daily_summary_log` | recordDate, content — 本地存储，不同步 |

**所有模型均有 `copyWith` 方法**，用于 Provider 增量更新时的 ID 注入和字段修改。

## 今日计划生成（核心功能）

**入口：首页「✨ 生成」按钮** → `EliteProvider.generateTodayPlanWithAI()`
AI 不可用时自动 fallback 到本地 `generateTodayPlan()`。

逻辑（`EliteProvider`）：
1. 清空当天已有计划
2. 读取当天未完成待办，按优先级排序（taskLevel: 1最重要→4最不重要）
3. 按配置的时间块遍历（工作时段为30分钟块，其余为60分钟块）：
   - **上班前/午休/下班后** → 填入待办、习惯、目标内容
   - **上班时·上午/下午** → **仅工作日**填入冥想专注提醒（30分钟一条），周末保留学习/待办内容
4. 超出槽位的待办合并到最后一个计划项
5. 自动判断日类型：周末/节假日用 weekend 模板，其他用 workday 模板
6. **目标首选时段**：目标可配置 `preferredSegment`（上班前/午休/下班后），未匹配目标自动安排在指定时段，具体时间从 `WorkSchedule` 推导
7. **发声内容移晚间**：含"英语""演讲""口语""朗读"等关键词的计划自动移至 18:00 后（安全网，首选时段已覆盖大部分场景）
8. **定点吐槽/每日总结**：若配置了 `ventingTime` 或 `summaryTime`，在对应时间块优先插入吐槽项（planType=6）或总结项（planType=7），使用 `_blockContainsTime()` 判断
9. **计时器完成自动标记**：FocusTimerProvider 的 `stopTimer()` 将计划项标记为 `isCompleted=2`（完成）
10. **四状态完成体系**：`isCompleted` 0=未做, 1=做了部分, 2=完成, 3=超额完成。`completionState`/`completionLabel` getter 在模型层提供统一访问。`completedAt` 仅在状态 >= 2 时写入
11. **完成预设快捷填入**：FocusSheet 提供 6 个预设短语，点击填入实际状况记录，支持二次点击追加

**计划类型码**：0=综合, 1=学习, 2=副业, 3=阅读, 4=休闲, 5=心理, 6=吐槽, 7=总结

**配置**：
- 首页计划设置（`_showPlanSettings`）：工作时间、午休、学习时段、定点吐槽开关+时间、每日总结开关+时间
- 精英对标页（`ElitePage`）：时间块配置（工作日/周末两套）、自定义优先事项、精英习惯库

## 页面职责

### 首页 (`home/home_page.dart`) — 今日行动中心
- **当前时段卡片**（`_CurrentFocusCard`）：根据当前时间匹配计划时段，显示该做的事
- **今日规划**：计划列表（可拖拽排序、点击编辑、标记完成）+ 生成按钮
- **快捷导航**：财务行动、三赛道学习、副业规划、书籍阅读、精英对标、AI复盘报告

### 精英对标 (`elite/elite_page.dart`) — 配置 + 复盘
- 工作时间设置、时间块编辑、自定义优先事项
- 生活必备项、每日自检、精英习惯库
- **不包含**计划展示和生成（已移至首页）

## 关键文件索引

```
lib/
├── main.dart                      # App入口 + AuthGate + MultiProvider
├── config/
│   ├── api_config.dart            # 后端地址（debug/release自动切换）
│   ├── theme.dart                 # 主题色
│   ├── routes.dart                # 命名路由
│   ├── shell.dart                 # MainShell 底部导航
│   ├── reminders.dart             # 提醒文案（服务端拉取 + const fallback）
│   └── holiday_config.dart        # 节假日判断（工作日/周末/假期）
├── models/                        # 数据模型（见上表，全部含copyWith）
├── providers/                     # ChangeNotifier 提供者（全部增量更新模式）
│   ├── elite_provider.dart        # 计划生成核心逻辑 + 习惯库 + 自检
│   ├── focus_timer_provider.dart  # 专注计时器（ValueNotifier tick隔离 + 状态持久化）
│   ├── goal_provider.dart         # 目标 + 任务（API）
│   ├── study_provider.dart        # 学习记录（今日累计时长，即时累加不等待DB）
│   ├── record_provider.dart       # 日常记录（API，按日期筛选）
│   ├── finance_provider.dart      # 财务心理日志
│   ├── reading_provider.dart      # 阅读记录
│   ├── sideline_provider.dart     # 副业规划
│   ├── leisure_provider.dart      # 生活休闲
│   ├── intervene_provider.dart    # 行为干预
│   ├── empty_mood_provider.dart   # 空虚情绪日志
│   ├── aspiration_provider.dart   # 心愿清单 + 生活必备（API）
│   ├── report_provider.dart       # AI复盘报告（API）
│   └── auth_provider.dart         # JWT认证
├── pages/
│   ├── home/home_page.dart        # 首页（今日行动中心：当前卡片+规划+导航）
│   ├── elite/elite_page.dart      # 精英对标（配置+复盘：作息/自检/习惯库）
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
2. 聚合该范围内用户的全维度数据（10张表）
3. 每条计划带4种状态标记
4. 构建结构化文本摘要发给 AI 生成报告
5. 若 AI 不可用，自动回退保存数据摘要作为报告内容

AI 参数 (`AiUtil.java`)：timeout=60s, max_tokens=8192, temperature=0.7

## 后端

`rebuild-myself-server/` — Spring Boot 3.x + MyBatis-Plus + JWT

### 关键接口
- `POST /api/user/login` — 登录返回 JWT
- `POST /api/user/register` — 注册
- `GET /api/user/profile` — 验证 token
- `POST /api/sync/upload` — 上传数据
- `GET /api/sync/pull?since=` — 增量拉取
- `GET /api/sync/export?start=&end=` — 全量导出
- `POST /api/report/generate` — 生成AI复盘报告（body: cycleType, date）
- `GET /api/report/history?page=&size=` — 历史报告分页
- `GET /api/config/reminders` — 提醒文案列表（4类 ~140条）
- `GET /api/config/workday-status?date=` — 工作日判断

### 数据库迁移
- `reminder_text` 表通过 `DataInitializer` 组件在服务启动时自动创建+种子数据，幂等安全
- SQL 源文件：`src/main/resources/db/migration_001_reminders.sql`
- 首次启动：检测表不存在 → CREATE TABLE + INSERT IGNORE（~140条）
- 后续启动：检测表已存在 → 跳过

### 启动
```bash
cd rebuild-myself-server
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"
```

## 常见问题

- **Consumer2 "Closure" bug**：Flutter Web 上 Consumer2 渲染 Function toString()，已改为分别用 Consumer
- **localStorage 数据不跨端口**：不同端口=不同 origin，localStorage 不共享
- **字段名不一致**：插入用驼峰（toJson），删除/查询两种都试
- **Android HTTP 明文**：已在 AndroidManifest 添加 `usesCleartextTraffic="true"`
- **周末计划只有冥想**：2026-05 已修复，周末/节假日不再强制净化工作时段，保留学习内容
- **服务端编译失败 `--release` 错误**：JAVA_HOME 需指向 JDK 21+，Maven 自动选取的 JDK 8 不支持
