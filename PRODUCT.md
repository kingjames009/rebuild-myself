# 精进｜全维度人生重塑 — 产品文档

## 版本历史

### v1.0.5 (2026-05-18)

- **首页计划完成标记**：每个计划项点击圆点进入详情弹窗，新增"标记为已完成"开关。已完成项在列表中显示绿色圆点 + 删除线 + "已完成"标签。服务端新增 `PUT /api/plan/toggle` 接口。
- **实际状况记录增强**：记录实际状况时自动标记 `isCompleted=1`，计划项不区分笔记和完成两种状态。已完成项优先显示"已完成"标签。
- **上班时段计划清洗**：AI 生成的今日规划中，上班时段（上午/下午）仅保留冥想/专注提醒内容（30分钟一条，共10条轮换），所有目标/待办/习惯自动安排到上班前、午休、下班后时段。
- **复盘报告删除修复**：删除报告后不再被服务端数据复活。`loadAll()` 改为合并模式（仅插入新记录），`delete()` 直接删除本地 DB 并从内存列表移除，不再触发全量拉取。
- **统计页生成日期选择**：数据统计页点击"生成复盘报告"先弹出确认对话框，支持日期选择器（日复盘）或直接确认（周/月/年），与报告页逻辑一致。
- **历史报告删除按钮**：统计页历史报告列表每项右侧新增红色删除按钮，支持单独删除。

**相关文件：**
- `lib/pages/home/home_page.dart` — 完成标记开关、列表完成状态展示
- `lib/providers/elite_provider.dart` — `updatePlanCompletion()`, `_sanitizeWorkHourPlans()`
- `lib/providers/report_provider.dart` — `loadAll()` 合并模式, `delete()` 修复
- `lib/pages/stats/stats_page.dart` — 生成前日期选择、删除按钮
- 服务端：`DailyModelPlanController.java` — `PUT /api/plan/toggle`
- 服务端：`DailyModelPlanServiceImpl.java` — `toggleComplete()`, `updateNote()` 修复

### v1.0.3 (2026-05-17)

- **AI复盘日期选择**：日复盘支持选择指定日期生成报告（默认昨天），服务端 `generateReport` 新增 `date` 参数，周/月/年复盘以所选日期为参考
- **健康信息保存修复**：体重、健康备注输入框补充焦点监听，失焦时自动保存；设置页退出时兜底保存
- **拖拽手柄优化**：增大拖拽手柄尺寸（18→22px），proxyDecorator 简化为 Material 提升拖拽稳定性
- **预设图标修复**：emoji 去除逻辑从无效正则改为已知图标列表匹配

**相关文件：**
- `lib/pages/report/report_page.dart` — 日复盘日期选择器
- `lib/providers/report_provider.dart` — `generateReport()` 支持 date 参数
- `lib/pages/settings/settings_page.dart` — 体重/健康备注焦点监听 + dispose 兜底保存
- `lib/pages/home/home_page.dart` — 拖拽手柄优化、emoji 正则修复
- 服务端：`AiReportController.java`, `AiPsychologicalReportServiceImpl.java` — 日期参数

### v1.0.2 (2026-05-17)

- **计划内容编辑**：首页今日规划支持直接点击内容或编辑图标修改计划文字，提供 12 个预设 emoji 图标
- **时间段调整**：支持修改计划项的开始/结束时间，提供快捷预设（30分钟、1小时、提前/推迟30分钟）
- **拖拽重排优化**：拖拽排序改为时间槽移位模式——中间所有项目的时间段自动滑动，而非简单交换

### v1.0.1 (2026-05-16)

---

## 一、焦点计时器增强

### 1.1 墙上时钟计时
计时器改用 `DateTime.now().difference()` 计算耗时，即使手机锁屏或切到后台仍继续计时，不会丢失时间。

### 1.2 倒计时模式
计时器改为倒计时显示，选择目标分钟数后开始倒数，到达 0 自动暂停。支持暂停/继续/结束操作。

### 1.3 记录时长（首页统计）
首页 MiniStats 中的"学习时长"已改为"记录时长"。当计时器运行时，统计数据实时累加（已存储的学习分钟数 + 计时器当前已用分钟数），每秒刷新。

**相关文件：**
- `lib/providers/focus_timer_provider.dart`
- `lib/pages/home/home_page.dart`

---

## 二、今日计划 AI 智能生成

### 2.1 目标驱动生成
生成今日计划时，用户的所有**活跃目标**会自动传给 AI，AI 将目标拆解为今天具体的执行步骤并安排到时间槽中。每个目标至少安排 1 个专属时段，重要目标安排 2-3 个时段。

### 2.2 目标标题标记
AI 生成的计划项如与目标相关，会带 `【目标标题】` 前缀。未被 AI 匹配的目标，Flutter 端会自动创建专属计划项，确保所有目标都出现在计划中。

### 2.3 周末不跳过目标
无论工作日还是周末/节假日，目标都会被安排到计划中。周末的学习类目标安排在下午或晚上。

### 2.4 生成中状态提示
点击"生成今日计划"按钮后显示加载动画和"生成中..."文字，避免用户误以为没反应。

### 2.5 离线降级
AI 生成失败时自动降级到本地规则引擎，确保计划始终可用。

**相关文件：**
- `lib/providers/elite_provider.dart` — `generateTodayPlanWithAI()`, `_tagPlanWithGoalTitles()`
- `lib/pages/home/home_page.dart`
- `lib/pages/elite/elite_page.dart`
- 服务端：`DailyModelPlanServiceImpl.java` — `buildPlanPrompt()`, `generateTodayPlan()`

---

## 三、计划拖拽排序

首页今日计划支持拖拽排序。按住 `≡` 手柄拖动某个计划项，系统会交换两个计划的时间段。

**相关文件：**
- `lib/providers/elite_provider.dart` — `reorderPlan()`
- `lib/pages/home/home_page.dart` — `ReorderableListView.builder`

---

## 四、登录凭据持久化

### 4.1 记住密码
登录成功后自动保存手机号和密码到本地存储。下次启动 App 自动填充。

### 4.2 注册后自动记住
注册并自动登录后同样保存凭据。

### 4.3 退出登录不丢失凭据
退出登录时只清除 JWT token，保留手机号和密码。重新进入登录页时仍会自动填充。

**相关文件：**
- `lib/services/token_store_io.dart` — `saveCreds()`, `loadCreds()`, `clear()` 改为只移除 token
- `lib/services/token_store_web.dart`
- `lib/pages/auth/login_page.dart`
- `lib/pages/auth/register_page.dart`

---

## 五、用户资料持久化

### 5.1 资料同步
设置页修改的昵称、头像、身高、体重、健康备注通过 `PUT /api/user/profile` 保存到服务端数据库。

### 5.2 卸载重装后恢复
登录成功后自动调用 `GET /api/user/profile` 拉取完整用户资料（昵称、头像、身高、体重、健康备注），卸载重装不再丢失。

**相关文件：**
- `lib/providers/auth_provider.dart` — `_fetchProfile()`, `login()` 登录后自动拉取
- `lib/pages/settings/settings_page.dart`
- `lib/models/user.dart`
- 服务端：`User.java` — 含 height/weight/healthNote 字段

---

## 六、中国节假日智能识别

### 6.1 节假日数据
包含 2026 年完整法定节假日安排（元旦、春节、清明、劳动节、端午、中秋、国庆）及对应的调休补班日。

### 6.2 工作日判断
所有涉及工作日/休息日的判断统一使用 `HolidayUtil.isWorkday()`（服务端）/ `HolidayConfig.isWorkday()`（Flutter）。补班日（原本周末但需要上班）会正确识别为工作日。

### 6.3 实时查询接口
服务端提供 `GET /api/config/workday-status?date=YYYY-MM-DD` 接口，返回指定日期是否为工作日。

**相关文件：**
- `lib/config/holiday_config.dart`
- 服务端：`HolidayUtil.java`
- 服务端：`ConfigController.java`

---

## 七、周末/节假日时间设置

### 7.1 动态切换
精英对标页的时间设置卡片根据当前日期自动切换：
- **工作日**：标题"工作时间设置"，字段"上班/下班/午休开始/午休结束"
- **休息日**：标题"时间设置"，字段"开始学习/结束学习/午休开始/午休结束"

### 7.2 持久化
工作日和休息日的时间设置统一保存到 `work_schedule` 表，只需设置一次，后续自动根据日期类型展示对应界面。

### 7.3 提示信息
休息日模式下显示"工作日将自动切换为上下班时间设置"的提示。

**相关文件：**
- `lib/models/time_block.dart` — `WorkSchedule` 新增 `studyStart`/`studyEnd`
- `lib/pages/elite/elite_page.dart` — `_buildWorkScheduleCard()`
- `lib/providers/elite_provider.dart`

---

## 八、数据库变更

### 8.1 user 表新增字段
| 字段 | 类型 | 说明 |
|------|------|------|
| height | DECIMAL(5,2) | 身高 cm |
| weight | DECIMAL(5,2) | 体重 kg |
| health_note | VARCHAR(500) | 健康备注（血压、睡眠等） |

### 8.2 user_aspiration 表
用户近期想做事项，用于 AI 计划生成。

### 8.3 life_essential_config 表
生活必备项配置（锻炼、阅读、冥想、技能、休闲），包含变体、建议时长、偏好时段、最低/最高周频率。

---

## 九、API 接口变更

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/config/workday-status` | GET | 新增：查询指定日期是否为工作日 |
| `/api/user/profile` | PUT | 增强：支持 height/weight/healthNote 字段 |
| `/api/plan/generate` | POST | 增强：AI prompt 包含目标、健康状况、生活必备项 |
| `/api/aspiration` | CRUD | 用户近期目标管理 |
| `/api/essential` | CRUD | 生活必备项管理 |
| `/api/plan/toggle` | PUT | 新增：切换计划项完成状态（isCompleted + completedAt） |
| `/api/plan/note` | PUT | 增强：记录实际状况时同步标记 isCompleted=1 |

---

## 十、计划项完成标记

### 10.1 详情弹窗完成开关
首页点击计划项的圆点或笔记本图标，弹出详情弹窗。弹窗顶部新增完成状态切换（Switch 开关 + 勾选图标），打开即标记为已完成，关闭即恢复未完成。切换即时生效，无需额外保存。

### 10.2 列表视觉反馈
已完成项在列表中显示：
- 左侧圆点变为绿色
- 内容文字添加删除线，颜色变灰
- 底部状态区显示绿色"已完成"标签（优先级高于实际状况记录）

### 10.3 计时器完成自动标记
专注计时器归零并点击"记录并结束"后，对应计划项自动标记 `isCompleted=1` + `completedAt`。

**相关文件：**
- `lib/pages/home/home_page.dart` — `_showFocusSheet()` 完成开关、列表渲染
- `lib/providers/elite_provider.dart` — `updatePlanCompletion()`
- `lib/providers/focus_timer_provider.dart` — `stopTimer()` 自动标记
- 服务端：`DailyModelPlanController.java` — `PUT /api/plan/toggle`
- 服务端：`DailyModelPlanServiceImpl.java` — `toggleComplete()`

---

## 十一、上班时段计划清洗

### 11.1 规则
AI 或本地引擎生成今日计划后，所有落在「上班时·上午」和「上班时·下午」时段的计划项，自动替换为冥想/专注提醒内容。30 分钟一条，共 10 条轮换（正念呼吸、身体扫描、专注觉察等）。

### 11.2 目标标记跳过
目标标题匹配（`_tagPlanWithGoalTitles`）阶段跳过工作时段计划项，避免将目标标题注入到冥想提醒中。

### 11.3 双层保障
- 本地引擎 (`generateTodayPlan`)：生成时已按时间块分段，工作时段仅 30 分钟冥想槽位
- AI 生成后清洗 (`_sanitizeWorkHourPlans`)：AI 返回的计划如果仍有非冥想内容落在工作时段，自动替换

**相关文件：**
- `lib/providers/elite_provider.dart` — `_sanitizeWorkHourPlans()`, `_isWorkSegment()`
- `lib/config/holiday_config.dart` — `WorkSchedule.segmentFor()` 时段判断

---

## 十二、复盘报告删除修复

### 12.1 问题
删除报告后，`loadAll()` 从服务端全量拉取并覆盖本地数据，导致已删除的报告复活。

### 12.2 修复
- `loadAll()` 改为合并模式：服务端数据仅在 `report_id` 不存在于本地时才插入，不再覆盖或清空本地数据。
- `delete()` 同步删除服务端 + 本地 DB + 内存列表，不调用 `loadAll()`。
- `generateReport()` 生成成功后直接从本地 DB 重读，不走 `loadAll()` 服务端拉取。

**相关文件：**
- `lib/providers/report_provider.dart`
- `lib/pages/stats/stats_page.dart` — 删除按钮 + 生成前日期选择
- `lib/pages/report/report_page.dart` — 删除按钮
