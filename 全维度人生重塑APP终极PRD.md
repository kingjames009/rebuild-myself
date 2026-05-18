# 日新｜全维度人生重塑自律成长 APP — 产品文档

> 最后更新：2026-05-18

## 文档用途

本文档为项目最终官方需求文档，描述已实现的全部功能、数据表、接口和代码结构。所有模块均已交付。

---

## 一、项目总览

### 1.1 项目名称

**日新** — 全维度人生重塑自律成长 APP

多端支持：Flutter 移动端（Android/iOS） + UniApp 移动端（Android/iOS/H5） + Vue3 PC 网页端

### 1.2 用户真实现状与项目背景

1. 年龄 35 岁，存在中年危机感，经济紧张、资金短缺；主观想赚钱，但客观行动力严重缺失
2. 需长期进修三大能力：**英语演讲、AI 系统化学习、应用开发编程**
3. 有副业刚需，想要低体能消耗、长期复利的轻量副业
4. 长期顽固陋习：重度拖延、懒惰乏力、空闲情欲杂念频发、短视频成瘾
5. 日常生活极度单调：下班习惯性刷手机，陷入空虚→颓废→内耗→停滞恶性循环
6. 有读书需求：财商赚钱、认知成长、心理治愈类书籍
7. 缺少优秀作息参照，空余时间无清晰规划
8. 身心状态一般，所有计划必须：**低压力、循序渐进、不透支身体、可持续执行**
9. 需要从**心理根源→行为矫正→目标落地→生活重塑**全链路改造

### 1.3 产品核心定位

基于**临床心理学 + 行为矫正学 + 精英习惯对标**的全维度私人成长工具。

覆盖领域：账号隐私、目标管理、日常记录、心理陋习干预、财务行动矫正、多赛道学习、副业落地、阅读体系、生活丰盈、精英作息对标、AI 全域复盘、多端数据同步。

目标：戒掉陋习、缓解焦虑、落地赚钱、提升技能、丰富生活、对标强者、稳步蜕变。

### 1.4 项目仓库结构

```
rebuildmyself/
├── rebuild-myself-server/     # Spring Boot 后端
├── rebuild-myself-flutter/    # Flutter 移动端（主力移动端）
├── rebuild-myself-mobile/     # UniApp 移动端（Vue3 跨平台）
├── rebuild-myself-web/        # Vue3 + Element Plus PC网页端
├── DEPLOY.md                  # 阿里云部署文档
└── 全维度人生重塑APP终极PRD.md  # 本文档
```

### 1.5 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Spring Boot 3.x + MySQL 8.0 + MyBatis-Plus + JWT |
| 移动端（主力） | Flutter 3.x + Provider 状态管理 |
| 移动端（辅助） | UniApp (Vue 3) + Pinia + Vite |
| Web 前端 | Vue 3 + Element Plus + Axios + ECharts |
| AI | 对接大模型 API，结构化数据 → 复盘报告 |
| 存储 | 云端 MySQL + 本地 localStorage/JSON 文件离线缓存 |
| 安全 | AES 数据加密、本地隐私锁、JWT Bearer 认证 |

### 1.6 底层支撑心理学理论

意志力耗竭理论、ABC 情绪理论、认知行为 CBT、**MCT 元认知疗法（Wells 2009）**、5 分钟启动法则、习惯回路、多巴胺管控、延迟满足、自我接纳、时间知觉矫正、系统脱敏、破窗效应、焦虑逃避行为模型。

MCT 核心理论：反刍思维由 CAS（认知注意综合征）维持——一种对侵入性想法的习得性反应模式（过度思考、威胁监控、想法抑制）。治疗目标不是挑战想法内容，而是改变与想法的元认知关系。5 项练习每日循环：ATT 注意训练、分离觉察、反刍中断 3 步法、具体化切换、行为实验。

---

## 二、全局通用强制规则

1. 所有学习、任务、副业、作息：**禁止高强度透支身体，全部低压力渐进式**
2. 所有干预优先**微行动、低门槛启动**，降低心理抗拒
3. 财务、心理杂念、空虚记录、陋习数据**全程加密，仅本人可见**
4. 全功能支持离线录入，本地缓存，联网自动同步云端
5. UI 极简沉静、无花哨娱乐元素，适合长期静心自用
6. 所有数据支持日/周/月/年统计、图表可视化
7. 所有模块数据互通，AI 可聚合全量数据做全域复盘

---

## 三、全部功能模块与数据库表

### 模块 1：用户账号与隐私安全

#### 功能
1. 手机号注册、密码登录（JWT 认证）
2. 个人资料：昵称、头像、长期人生目标
3. 本地密码锁/指纹锁隐私保护
4. 账号注销、数据清空、云端备份
5. 全量数据加密存储

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/user/login` | 登录，返回 JWT token |
| POST | `/api/user/register` | 注册 |
| GET | `/api/user/profile` | 获取个人资料（需认证） |
| PUT | `/api/user/profile` | 更新个人资料 |
| POST | `/api/user/lock-pwd` | 设置本地锁屏密码 |
| DELETE | `/api/user/account` | 注销账号 |

#### user 表
```sql
CREATE TABLE `user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT,
  `phone` varchar(11) NOT NULL,
  `password` varchar(64) DEFAULT NULL,
  `nickname` varchar(20) DEFAULT '自律用户',
  `avatar` varchar(255) DEFAULT NULL,
  `long_term_goal` text,
  `height` decimal(5,2) DEFAULT NULL COMMENT '身高(cm)',
  `weight` decimal(5,2) DEFAULT NULL COMMENT '体重(kg)',
  `health_note` varchar(500) DEFAULT NULL COMMENT '健康备注（血压、睡眠等）',
  `local_lock_pwd` varchar(32) DEFAULT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_time` datetime DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 模块 2：四级目标管理 + 四象限待办

#### 功能
1. 四级目标：长期→年度→月度→每日目标
2. 目标分类：学习、财务、健康、习惯
3. 进度更新、计划/实际偏差统计、截止预警
4. 四象限待办：重要紧急/重要不紧急/紧急不重要/无关琐事
5. 任务自动优先级排序

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/goal/*` | 目标 CRUD |
| GET/POST/PUT/DELETE | `/api/task/*` | 待办 CRUD |

#### user_goal 表 / task_todo 表
（字段与设计文档一致，详见 `rebuild-myself-server/src/main/resources/db/init.sql`）

### 模块 3：全维度日常行为记录

记录分类：学习、作息、情绪、拖延、短视频、私密杂念、健康。支持增删改查、离线录入、自动同步。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/record/*` | 记录 CRUD |

#### daily_record 表
（字段：record_id, user_id, record_type 1-7, content, cost_time, trigger_reason, emotion_score, record_date）

### 模块 4：心理学行为矫正干预

拖延矫正、情欲杂念疏导、短视频戒断、懒惰动力管理。干预成败记录、改善曲线追踪。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST | `/api/behavior/*` | 行为干预记录 |

#### behavior_intervene 表
（字段：intervene_id, user_id, intervene_type 1-4, is_success, mood_before）

### 模块 5：财务焦虑 + 赚钱行动力矫正

财务台账：收支、负债、资金缺口、压力等级。赚钱行动记录，缺钱逃避专项矫正，5 分钟搞钱微行动。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/finance/*` | 财务心理日志 CRUD |

#### finance_mental_log 表
（字段：id, user_id, money_pressure, gap_amount, income_record, escape_state, action_minutes, record_date）

### 模块 6：三赛道学习管理（英语演讲 / AI 学习 / 应用开发）

三大赛道独立学习档案，智能分配学习强度，学习畏难干预，进度统计。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/study/*` | 学习追踪 CRUD |

#### study_track_record 表
（字段：id, user_id, track_type 1-3, study_content, study_minutes, difficulty_level, escape_status, record_date）

### 模块 7：轻量副业规划与落地追踪

基于英语/AI/开发做低消耗副业规划，每日微行动记录，推进阻碍溯源，进度追踪。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/sideline/*` | 副业计划 CRUD |

#### sideline_plan 表
（字段：id, user_id, side_type 1-3, daily_action, progress, block_reason, energy_cost, record_date）

### 模块 8：空虚状态溯源｜解决生活单调

记录空虚等级、空洞时长、无聊诱因，追踪单调→空虚→刷手机→颓废因果链，高发时段预警。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/empty/*` | 空虚状态 CRUD |

#### empty_mood_log 表
（字段：id, user_id, empty_level, empty_hours, trigger_cause, waste_hours, record_date）

### 模块 9：书籍阅读体系（财商 + 成长 + 人文治愈）

书籍分类：财商赚钱、心理成长、人文休闲。阅读时长、进度、笔记、心得。5 分钟轻阅读启动。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/book/*` | 阅读记录 CRUD |

#### book_read_record 表
（字段：id, user_id, book_type 1-3, book_name, read_minutes, read_progress, book_notes, escape_status, record_date）

### 模块 10：业余生活丰盈｜多元轻爱好

轻爱好库：放松、冥想、治愈短句、拉伸、环境整理、碎片化新知。闲暇时间规划，愉悦感打卡。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/leisure/*` | 休闲记录 CRUD |

#### life_leisure_record 表
（字段：id, user_id, leisure_type 1-6, leisure_minutes, happy_score, arrange_state, record_date）

### 模块 11：精英榜样习惯对标 + 每日模范规划（核心模块）

#### 功能
1. **精英习惯库**：晨间/日间/下班后/睡前四大分类，适配体质轻量化
2. **工作时间设置**（工作日）：指定上班时间、下班时间、午休开始/结束
3. **全天计划生成**：按 1 小时为单位，覆盖上班前、上班时·上午、午休、上班时·下午、下班后五个时段
4. **自定义优先事项**：用户添加的事项优先级最高，可指定插入时段（上班前/午休/下班后）
5. **上班时段正念干预**：上班时间自动填入简洁的冥想/专注提醒（10条轮换：正念呼吸、身体扫描、专注觉察等），每条一句话，30分钟一条，应对胡思乱想和情绪波动
6. **每日自查**：实际执行 vs 模范规划差距对比
7. **时间块配置**（可折叠高级设置）：手动编辑周末/工作日的时间块

#### 计划生成逻辑（工作日）

1. 读取 `WorkSchedule`（上班/下班/午休时间）
2. 按 1 小时为单位拆分全天为约 17 个时间块
3. 每个块分配一项内容，优先级：**自定义优先事项 > 待办任务 > 精英习惯 > 默认项**
4. 上班时段（上午+下午）：**10 条正念专注提醒轮换**（正念呼吸、身体扫描、专注觉察等，每条一句话，30 分钟一条）。不再使用 MCT 元认知疗法 5 项练习（过于复杂，不适合工作间隙执行）
5. 上班前：晨间习惯 + 自定义事项 + 高优先级待办
6. 午休：自定义事项 + 休息恢复
7. 下班后：自定义事项 + 待办 + 下班后习惯 + 睡前习惯
8. 周末：沿用原有时间块逻辑

#### AI 智能规划师（2026-05-16 新增）

核心思路：Flutter 端不再本地生成计划，改为调用服务端 `POST /api/plan/generate`，服务端 AI 根据用户近期目标 + 生活必备项 + 习惯库 + 待办 + 健康状况综合生成。AI 失败时自动降级到本地规则引擎。

**AI Prompt 增强项：**

| 信息来源 | 作用 |
|---------|------|
| 用户健康状况（身高/体重/BMI/血压/睡眠） | AI 据此调整运动强度建议、插入助眠活动、避免高风险项目 |
| 用户近期目标（user_aspiration, status=0/1, 日期范围内） | AI 智能分配到当天合适时段，考虑优先级和已安排次数 |
| 生活必备项（life_essential_config, enabled=1） | AI 每天从中选若干项穿插，不同变体轮流使用 |
| 精英习惯库 | 注入晨间/日间/下班后/睡前习惯参照 |

**健康因素 → AI 调整策略：**

| 健康因素 | AI 调整 |
|---------|---------|
| BMI≈28.9 偏重 | 避免高强度跑跳，推荐快走/游泳/拉伸；控制久坐 |
| 轻微高血压 | 避免剧烈运动/竞争性活动；增加放松/深呼吸练习 |
| 睡眠差 | 睡前安排助眠仪式（冥想/阅读/远离屏幕）；避免晚间咖啡因/高强度脑力 |

**用户近期目标表（user_aspiration）：**

```sql
CREATE TABLE `user_aspiration` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `content` varchar(200) NOT NULL COMMENT '事项描述',
  `category` tinyint NOT NULL DEFAULT 0 COMMENT '0通用1学习2副业3阅读4休闲5健康6技能',
  `priority` tinyint NOT NULL DEFAULT 3 COMMENT '1-5优先级',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '0待安排1进行中2已完成',
  `schedule_count` int NOT NULL DEFAULT 0 COMMENT '已被安排次数(AI排重参考)',
  `start_date` date DEFAULT NULL COMMENT '目标生效日期',
  `end_date` date DEFAULT NULL COMMENT '目标截止日期，过期自动排除',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> 目标在 `start_date` ~ `end_date` 范围内每天都参与 AI 计划生成，过期后自动排除。状态流转：0(待安排)→1(第一次被安排后)→保持1(每天仍可继续安排)，仅在用户手动完成时变为2。

**生活必备项配置表（life_essential_config）：**

```sql
CREATE TABLE `life_essential_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `category` tinyint NOT NULL COMMENT '1锻炼2阅读3冥想4技能5休闲',
  `name` varchar(50) NOT NULL COMMENT '名称',
  `default_duration` int NOT NULL DEFAULT 15 COMMENT '建议时长(分钟)',
  `variants` text COMMENT 'JSON数组变体，如["晨间拉伸","快走15分钟"]',
  `energy_level` tinyint NOT NULL DEFAULT 1 COMMENT '精力消耗1-3',
  `min_weekly_freq` int NOT NULL DEFAULT 1 COMMENT '每周最少次数',
  `max_weekly_freq` int NOT NULL DEFAULT 7 COMMENT '每周最多次数',
  `preferred_period` varchar(20) NOT NULL DEFAULT 'any' COMMENT '偏好时段 morning/afternoon/evening/night/any',
  `enabled` tinyint NOT NULL DEFAULT 1 COMMENT '是否启用',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> 新用户注册时自动插入 4 项默认必备项。所有建表语句已统一至 `db/init.sql`，无独立迁移脚本。

**新增 API 接口：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/aspiration/list` | 获取用户近期目标列表 |
| POST | `/api/aspiration` | 添加近期目标 |
| PUT | `/api/aspiration/{id}` | 更新近期目标 |
| DELETE | `/api/aspiration/{id}` | 删除近期目标 |
| PUT | `/api/aspiration/{id}/status` | 更新目标状态 |
| GET | `/api/essential/list` | 获取生活必备项配置 |
| PUT | `/api/essential/{id}/toggle` | 启用/禁用某项必备项 |
| POST | `/api/essential/reset` | 重置为默认必备项 |

**Flutter 端新增文件：**

| 文件 | 说明 |
|------|------|
| `lib/models/aspiration.dart` | 近期目标模型，含日期范围、到期判断、状态标签 |
| `lib/models/essential_config.dart` | 生活必备项配置模型 |
| `lib/providers/aspiration_provider.dart` | 近期目标 + 生活必备项 CRUD Provider |

**Flutter 端修改文件：**

| 文件 | 修改内容 |
|------|---------|
| `lib/models/user.dart` | 新增 `height`、`weight`、`healthNote` 字段 |
| `lib/main.dart` | 注册 `AspirationProvider` |
| `lib/providers/elite_provider.dart` | 新增 `generateTodayPlanWithAI()` → 调 `POST /api/plan/generate`，成功写本地缓存，失败降级到本地规则引擎 |
| `lib/pages/home/home_page.dart` | 启动加载和"生成今日计划"按钮改为调 `generateTodayPlanWithAI()` |
| `lib/pages/elite/elite_page.dart` | 新增"近期目标"可折叠卡片（输入框+类别/优先级下拉+日期选择+添加/删除）；新增"生活必备项"可折叠卡片（分类列表+启闭开关+重置按钮） |
| `lib/pages/settings/settings_page.dart` | 个人资料卡片新增身高/体重/健康备注输入框，自动保存

#### 每小时实际状况记录（2026-05-13 新增，2026-05-18 增强）

- **核心理念**：不是"完成勾选"（做没做到），而是记录"这个时段实际发生了什么"，为 AI 日复盘提供真实素材
- **入口**：首页深色「当前时段」聚焦卡片右上角 + 按钮；首页下方「今日规划」列表中每项均可点击圆点或右侧图标
- **存储**：写入 `daily_model_plan.actual_note`，通过 `PUT /api/plan/note` 同步到 MySQL（同时自动标记 `is_completed=1`）
- **视觉反馈**：已记录的计划项显示绿色圆点和笔记摘要，聚焦卡片中显示已有记录内容
- **AI 复盘联动**：日复盘时读取当日所有 `actual_note`，AI 对比计划 vs 实际给出精准分析

#### 计划项完成标记（2026-05-18 新增）

- **详情弹窗开关**：首页点击计划项进入详情弹窗，顶部新增"标记为已完成"Switch 开关，切换即时生效
- **列表视觉**：已完成项显示绿色圆点 + 内容删除线 + "已完成"标签（优先级高于实际状况记录）
- **计时器联动**：专注计时器归零点击"记录并结束"后，对应计划项自动标记为已完成
- **数据存储**：写入 `daily_model_plan.is_completed` 和 `completed_at`，通过 `PUT /api/plan/toggle` 同步到服务端

#### 首页专注计时器（2026-05-16 新增）

- **入口**：首页「当前时段」聚焦卡片 + 今日规划列表，点击任意时段打开详情弹窗
- **核心功能**：
  - 番茄钟计时器：预设时长（5/15/25/30/45分钟），支持开始/暂停/继续/停止/放弃
  - 学习赛道选择：当计划类型为"学习"时，可选择计时计入哪个赛道（英语演讲/AI学习/应用开发）
  - 计时结束 → 自动保存到 `study_track_record` 表，学习时长即时更新
  - 聚焦卡片实时反馈：计时中时卡片变为橙色渐变，显示实时走时
- **全局状态管理**：`FocusTimerProvider`，计时器在页面导航间持久运行，不受首页离开影响
- **与学习系统联动**：停止计时后自动刷新 `StudyProvider`，首页"学习时长"统计即时反映

**新增文件：**

| 文件 | 说明 |
|------|------|
| `lib/providers/focus_timer_provider.dart` | 全局番茄钟状态管理，启动/暂停/停止/取消，自动保存学习记录 |

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/elite-habit/*` | 精英习惯库 CRUD |
| POST | `/api/elite-habit/generate` | **AI 生成精英习惯**（调用大模型，基于全球顶尖人物真实日常，返回16条） |
| GET/POST/PUT/DELETE | `/api/plan/*` | 每日模范计划 CRUD |
| PUT | `/api/plan/note` | 按日期+时段更新实际状况记录（同步标记 is_completed=1） |
| PUT | `/api/plan/toggle` | 切换计划项完成状态（isCompleted + completedAt） |
| GET/POST/PUT/DELETE | `/api/daily-check/*` | 每日自检 CRUD |

#### elite_habit_lib 表
```sql
CREATE TABLE `elite_habit_lib` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `habit_category` tinyint NOT NULL COMMENT '1晨间2日间3下班后4睡前',
  `habit_content` text NOT NULL,
  `intensity_level` int DEFAULT 0,
  `suit_body_type` tinyint DEFAULT 0,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### daily_model_plan 表
```sql
CREATE TABLE `daily_model_plan` (
  `plan_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `plan_date` date NOT NULL,
  `time_period` varchar(30) NOT NULL COMMENT '如 18:00-19:00',
  `plan_content` text NOT NULL,
  `plan_type` tinyint NOT NULL COMMENT '1学习2副业3阅读4休闲5心理',
  `difficulty` int DEFAULT 0,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_completed` tinyint DEFAULT 0 COMMENT '是否完成 0否1是',
  `actual_note` text COMMENT '实际每小时状况记录（非勾选，是描述实际发生了什么）',
  `completed_at` datetime COMMENT '记录时间',
  PRIMARY KEY (`plan_id`),
  KEY `user_date` (`user_id`, `plan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> **2026-05-13 新增字段，2026-05-18 增强**：`is_completed`、`actual_note`、`completed_at`。`actual_note` 用于每小时实际状况记录（记录"这个时段实际发生了什么"）；`is_completed` 可通过详情弹窗开关手动标记或计时器完成后自动标记；两字段均供 AI 日复盘分析使用。

#### daily_compare_check 表
```sql
CREATE TABLE `daily_compare_check` (
  `check_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `plan_date` date NOT NULL,
  `deviation_content` text,
  `escape_reason` text,
  `progress_score` int DEFAULT 0,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`check_id`),
  KEY `user_date` (`user_id`, `plan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### time_block_config 表（客户端本地 + 可同步）
```sql
CREATE TABLE `time_block_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `start` varchar(5) NOT NULL COMMENT '开始时间 HH:MM',
  `end` varchar(5) NOT NULL COMMENT '结束时间 HH:MM',
  `label` varchar(100) DEFAULT '',
  `type` tinyint NOT NULL COMMENT '0固定锚点1待办槽位2推荐',
  `day_type` varchar(10) NOT NULL COMMENT 'workday/weekend',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### work_schedule 表（客户端本地，存储工作时间配置）
```sql
CREATE TABLE `work_schedule` (
  `work_start` varchar(5) NOT NULL DEFAULT '09:00',
  `work_end` varchar(5) NOT NULL DEFAULT '18:00',
  `lunch_start` varchar(5) NOT NULL DEFAULT '12:00',
  `lunch_end` varchar(5) NOT NULL DEFAULT '13:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### custom_priority_item 表（客户端本地，用户自定义优先事项）
```sql
CREATE TABLE `custom_priority_item` (
  `id` integer PRIMARY KEY AUTOINCREMENT,
  `content` text NOT NULL,
  `preferred_segment` varchar(10) NOT NULL COMMENT '上班前/午休/下班后',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP
);
```

#### AI 生成精英习惯（2026-05-15 新增）

- **核心逻辑**：精英习惯库不再仅依赖硬编码种子数据，可通过 AI 调用大模型生成，基于全球顶尖精英（世界 500 强 CEO、奥运冠军、顶尖科学家、知名艺术家）的真实日常习惯
- **入口**：精英对标页 → 精英习惯库卡片右上角「✨ AI 生成」按钮
- **后端实现**：`EliteHabitLibServiceImpl.generateHabits()` → 调用 `AiUtil.chat()` → 结构化 prompt 要求返回 JSON 数组，每条含 `habit_category`、`habit_content`（含来源人物）、`intensity_level`
- **返回格式**：`POST /api/elite-habit/generate` 返回 16 条习惯（4 类各 4 条），按 category 1-4 分布
- **离线兜底**：本地保留种子数据（`DatabaseHelper._seedIfNeeded()`），AI 服务不可用时使用预设的 17 条习惯
- **自动入库**：AI 生成后自动写入 MySQL `elite_habit_lib` 表，同时替换客户端本地存储

#### 日间习惯拆分（2026-05-15 修复）

- **问题**：原来 category 2（日间）习惯包含午休专属条目（如"午休不超过30分钟"），但 plan 生成时被轮询到上午/下午工作时段
- **修复**：`EliteProvider._buildWeekdayPlans()` 中将日间习惯按关键词（"午休""午间"）拆分为 `workDayHabits`（工作用）和 `lunchHabits`（午休用），各自独立索引循环
- 工作时段只填充不含"午休""午间"关键词的习惯，午休时段优先使用午休专属习惯

### 模块 12：AI 全维度综合复盘报告

日/周/月/年周期一键复盘，聚合全平台所有数据。四层输出：数据总结→问题诊断→根源溯源→定制优化方案。

#### 后端聚合逻辑（`AiPsychologicalReportServiceImpl.generateReport()`）

根据 `cycleType`（1日/2周/3月/4年）计算日期范围，一次性查询全部 10 张数据表：

| 数据源 | 表 | 日期字段 |
|--------|-----|----------|
| 日常记录 | `daily_record` | record_date |
| 行为干预 | `behavior_intervene` | intervene_time |
| 财务心理 | `finance_mental_log` | record_date |
| 学习追踪 | `study_track_record` | record_date |
| 副业计划 | `sideline_plan` | record_date |
| 空虚状态 | `empty_mood_log` | record_date |
| 阅读记录 | `book_read_record` | record_date |
| 生活休闲 | `life_leisure_record` | record_date |
| 每日自检 | `daily_compare_check` | plan_date |
| **每日计划** | **`daily_model_plan`** | **plan_date** |

> **2026-05-13 新增**：`daily_model_plan` 纳入 AI 复盘聚合查询，将 `plan_content`（原计划）和 `actual_note`（实际状况记录）一并传给 AI，使复盘报告能对比「计划 vs 实际执行」并分析执行偏差和逃避模式。

#### Flutter 客户端对接（2026-05-13）

- **已移除硬编码演示文本**：之前 `ReportPage._demoReport()` 返回静态示例文本，现已删除
- **对接真实后端**：点击「生成报告」→ `ReportProvider.generateReport()` → `POST /api/report/generate` → 服务端聚合数据 → AI 生成 → 返回真实报告
- **离线缓存**：报告生成后同时写入本地 `ai_psychological_report` 表，支持离线查看
- **历史管理**：支持按周期（日/周/月/年）Tab 分类查看、删除历史报告

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/report/generate` | 生成 AI 复盘报告（聚合全维度数据） |
| GET | `/api/report/page` | 分页获取当前用户历史报告 |
| GET | `/api/report/{id}` | 获取报告详情 |
| DELETE | `/api/report/{id}` | 删除报告 |

#### ai_psychological_report 表
（字段：report_id, user_id, cycle_type 1-4, cycle_range, original_data, report_content, create_time）

### 模块 13：多端数据同步

移动端 + Web 双向同步，离线缓存、断网可用、联网自动同步。云端备份、数据导出。

#### 接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/sync/upload` | 上传本地数据到云端 |
| GET | `/api/sync/pull?since=` | 增量拉取（按时间戳） |
| GET | `/api/sync/export?start=&end=` | 全量导出指定日期范围 |
| POST | `/api/sync/backup` | 创建云端备份 |
| GET | `/api/sync/restore/{backupId}` | 恢复备份 |

#### 同步机制
- 客户端：每行数据通过 `synced` 字段（1/0）标记同步状态
- 字段名转换：客户端 JSON 用驼峰（toJson），服务端用下划线，SyncService 通过 `_keyMap` 做转换
- 同步策略：push 未同步数据 → pull 增量数据

---

## 四、页面结构与导航

### Flutter 移动端（主力）

**底部导航（MainShell 5 tab）：**

| Tab | 页面 | 说明 |
|-----|------|------|
| 0. 首页 | HomePage | 欢迎卡片、当前时段聚焦、今日规划、快捷操作、快捷导航 |
| 1. 目标 | GoalPage | 四级目标管理 + 四象限待办 |
| 2. 记录 | RecordPage | 全维度日常记录录入与查看 |
| 3. 数据 | StatsPage | 数据统计可视化 |
| 4. 我的 | SettingsPage | 隐私锁、数据同步、退出登录 |

**命名路由（快捷导航入口）：**

| 路由 | 页面 | 说明 |
|------|------|------|
| `/elite` | ElitePage | 精英对标：计划生成、工作时间设置、自定义优先事项、习惯库、自检 |
| `/finance` | FinancePage | 财务行动 |
| `/study` | StudyPage | 三赛道学习 |
| `/sideline` | SidelinePage | 副业规划 |
| `/reading` | ReadingPage | 书籍阅读 |
| `/leisure` | LeisurePage | 生活丰盈 |
| `/intervene` | IntervenePage | 紧急干预 |
| `/reports` | ReportPage | AI 复盘报告 |

### UniApp 移动端（辅助）

**底部导航（4 tab）：** 首页、复盘、对标、我的

13 个页面：登录、首页（仪表盘）、目标、统计、行为矫正、财务、学习、副业、阅读、休闲、待办、精英对标、设置。

### Vue3 Web 端

侧边栏导航（12 项）：数据控制台、目标管理、数据大屏、行为矫正、财务行动、学习中心、副业落地、读书阅读、生活丰盈、精英对标、AI 复盘、个人设置。

---

## 五、Flutter 客户端架构

### 状态管理：Provider（ChangeNotifier）

15 个 Provider 在 `lib/providers/`，顶层在 `main.dart` 的 `MultiProvider` 注入。

### 本地存储：localStorage 模拟 SQLite

`lib/services/local_storage.dart` 按平台分发：
- Web: `local_storage_web.dart` → `window.localStorage`（每表存一个 JSON key）
- 移动端: `local_storage_io.dart` → 文件 JSON

### 认证：AuthProvider + JWT

- `init()` → 从 TokenStore 加载 token → `/api/user/profile` 验证
- `login(phone, pwd)` → `/api/user/login` → 保存 JWT
- `logout()` → 清 token，AuthGate 自动跳登录页

### 数据同步：SyncService

`syncAll()` → push 未同步数据 → pull 增量数据

### 后端地址切换

`lib/config/api_config.dart` — `kReleaseMode` 自动切换：
- Debug → `http://localhost:8080/api`
- Release → `http://47.92.98.182:8080/api`

### 关键文件索引

```
lib/
├── main.dart                        # App入口 + AuthGate + MultiProvider
├── config/
│   ├── api_config.dart              # 后端地址（debug/release自动切换）
│   ├── theme.dart                   # 主题色
│   ├── routes.dart                  # 命名路由
│   └── shell.dart                   # MainShell 底部导航
├── models/                          # 数据模型（19个文件）
│   ├── time_block.dart              # TimeBlockConfig + WorkSchedule
│   ├── custom_priority.dart         # CustomPriorityItem
│   ├── aspiration.dart              # UserAspiration（近期目标+日期范围）
│   └── essential_config.dart        # LifeEssentialConfig（生活必备项配置）
├── providers/                       # ChangeNotifier 提供者（13个）
│   ├── elite_provider.dart          # 计划生成核心：AI优先+本地降级+工作时间驱动
│   ├── goal_provider.dart           # 目标 + 任务
│   ├── aspiration_provider.dart     # 近期目标+生活必备项CRUD
│   ├── focus_timer_provider.dart    # 番茄钟计时器全局状态（跨页面持久）
│   └── auth_provider.dart           # JWT认证
├── pages/                           # 页面（按模块分目录）
├── services/
│   ├── api_client.dart              # HTTP 客户端（JWT Bearer）
│   ├── sync_service.dart            # 数据同步 push/pull
│   ├── database_helper.dart         # LocalStorage 封装 + 种子数据
│   ├── local_storage.dart           # 平台分发
│   ├── local_storage_web.dart       # Web localStorage 实现
│   └── local_storage_io.dart        # IO 文件 JSON 实现
└── android/                         # Android 配置（阿里云镜像源）
```

---

## 六、部署信息

- 服务器：**47.92.98.182**
- 后端 JAR：`rebuild-myself-server/target/rebuild-myself-server-1.0.0.jar`
- 数据库：MySQL 8.0，库名 `rebuild_myself`
- 服务管理：systemd（`rebuild-myself.service`）
- 日志路径：`/data/rebuild-myself/logs/`
- 环境变量：DB_USERNAME, DB_PASSWORD, JWT_SECRET, AI_API_KEY

### 启动命令

```bash
# 本地开发
cd rebuild-myself-server && mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"

# Flutter Web 开发
cd rebuild-myself-flutter && flutter run -d chrome --web-port 3000

# Web 前端开发
cd rebuild-myself-web && npm run dev

# 生产部署（服务器）
systemctl restart rebuild-myself
```

### Flutter APK 构建

```bash
# Windows PowerShell（需先设 JAVA_HOME 为 JDK 21+）
$env:JAVA_HOME="D:\Program Files\Java\jdk-21"
cd rebuild-myself-flutter && flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## 七、常见问题与注意事项

- **Consumer2 "Closure" bug**：Flutter Web 上 Consumer2 渲染 Function toString()，已改为分别用 Consumer
- **localStorage 数据不跨端口**：不同端口=不同 origin，localStorage 不共享
- **字段名不一致**：插入用驼峰（toJson，客户端格式），删除/查询两种命名都兼容
- **Android HTTP 明文**：已在 AndroidManifest 添加 `usesCleartextTraffic="true"`
- **工作日计划未覆盖全天**：需要先在精英对标页设置上班/下班时间，系统据此划分5个时段
- **上班时段内容**：默认使用 10 条正念专注提醒轮换（正念呼吸、身体扫描等），用户可在日间习惯库中添加自定义内容替代
- **本地存储 AND 条件**：`_matchWhere` 支持 `column = ? AND column2 = ?` 复合条件（2026-05-13 修复，之前仅支持单条件导致 update 匹配到多行）
- **退出登录**：改用 `showDialog<bool>` await 确认结果 → 对话框完全关闭后再 `logout()`，避免之前 `useRootNavigator: true` + `addPostFrameCallback` 方式在手机上失效（2026-05-15 修复）
- **昵称持久化**：`AuthProvider.updateProfile()` 同步更新内存 + 本地缓存 + 服务端
- **Flutter APK 构建**：需 `JAVA_HOME` 指向 JDK 21+，否则 Gradle 报 JVM version 错误
- **generateTodayPlan 卡死**：之前每条计划插入都触发一次全量 `loadAll()`，17 个时段 = 17 次全量查询导致 UI 卡死或操作中断。已改为内存构建 → 批量插入 → 单次 `loadAll()`（2026-05-13 修复）
- **新增每日目标不显示**：`Goal.toJson()` 字段名（id/level/type）与 `fromJson()`（goalId/goalLevel/goalType）不匹配，导致读回后 goalLevel 为 null 无法匹配分类 tab。已统一为 camelCase（2026-05-15 修复）
- **日间习惯串位到工作时段**：含"午休""午间"关键词的习惯被轮询到上午/下午。已拆分为 workDayHabits 和 lunchHabits，各自独立循环（2026-05-15 修复）
- **同事相关习惯措辞不当**："若同事言行触发不适"预设冲突，改为心理学人际调节策略：觉察→暂停→策略性回应（2026-05-15 修复）
- **AI 智能规划师**：计划生成已从纯本地规则引擎升级为服务端 AI 优先+本地降级。用户可在精英对标页设置近期目标和必备项，AI 生成计划时综合考量健康数据（BMI/血压/睡眠）+ 近期目标（日期范围过滤）+ 生活必备项（变体轮换）+ 精英习惯参照（2026-05-16 新增）
- **Dart 可空字段类型提升限制**：公共可空字段（如 `endDate`）在 getter 中直接传给非空参数会编译失败。解决方式：先赋值给局部变量再传递（2026-05-16 修复）
- **番茄钟计时器跨页面持久**：`FocusTimerProvider` 注册在 `MultiProvider` 顶层，使用 `Timer.periodic` 每秒 tick。计时中离开首页不影响计时，返回时聚焦卡片自动显示实时走时。停止时自动保存 `StudyTrackRecord` 并刷新学习时长统计（2026-05-16 新增）

---

## 八、非功能要求

1. 接口≤1s，AI 生成≤5s，页面加载≤2s
2. 私密数据高强度加密（AES）
3. 全机型、全浏览器兼容
4. 离线完整可用，联网自动同步
5. 代码模块化，方便迭代
6. UI 简约克制无娱乐元素
7. 所有计划低压力、循序渐进、可持续执行
