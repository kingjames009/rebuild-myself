-- ============================================================
-- 日新 | 全维度人生重塑自律成长 APP — MySQL 建表脚本
-- 版本: 1.0.0
-- 引擎: InnoDB, 字符集: utf8mb4
-- ============================================================

CREATE DATABASE IF NOT EXISTS `rebuild_myself` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `rebuild_myself`;

-- ============================================================
-- 模块1: 用户账号与隐私安全
-- ============================================================
CREATE TABLE `user` (
  `user_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户主键ID',
  `phone` VARCHAR(11) NOT NULL COMMENT '注册手机号',
  `password` VARCHAR(64) DEFAULT NULL COMMENT '加密密码',
  `nickname` VARCHAR(20) DEFAULT '自律用户' COMMENT '昵称',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  `long_term_goal` TEXT COMMENT '长期成长目标',
  `local_lock_pwd` VARCHAR(32) DEFAULT NULL COMMENT '本地锁屏密码',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_time` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `height` DECIMAL(5,2) DEFAULT NULL COMMENT '身高cm',
  `weight` DECIMAL(5,2) DEFAULT NULL COMMENT '体重kg',
  `health_note` VARCHAR(500) DEFAULT NULL COMMENT '健康备注（血压、睡眠等）',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ============================================================
-- 模块2: 四级目标管理
-- ============================================================
CREATE TABLE `user_goal` (
  `goal_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `goal_level` TINYINT NOT NULL COMMENT '1长期2年度3月度4每日',
  `goal_type` TINYINT NOT NULL COMMENT '1学习2财务3健康4习惯',
  `goal_title` VARCHAR(50) NOT NULL COMMENT '目标标题',
  `goal_content` TEXT COMMENT '目标详细内容',
  `start_date` DATE DEFAULT NULL COMMENT '目标开始日期',
  `target_time` DATE DEFAULT NULL COMMENT '目标截止日期',
  `progress` INT DEFAULT 0 COMMENT '进度0-100',
  `status` TINYINT DEFAULT 0 COMMENT '0未开始1进行中2已完成',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`goal_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='四级目标表';

-- ============================================================
-- 模块2: 四象限待办
-- ============================================================
CREATE TABLE `task_todo` (
  `task_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `task_title` VARCHAR(50) NOT NULL COMMENT '待办标题',
  `task_level` TINYINT NOT NULL COMMENT '四象限等级: 1重要紧急 2重要不紧急 3紧急不重要 4无关琐事',
  `is_complete` TINYINT DEFAULT 0 COMMENT '0未完成1已完成',
  `task_date` DATE NOT NULL COMMENT '任务日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`task_id`),
  KEY `idx_user_date` (`user_id`, `task_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='四象限待办表';

-- ============================================================
-- 模块3: 全维度日常行为记录
-- ============================================================
CREATE TABLE `daily_record` (
  `record_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `record_type` TINYINT NOT NULL COMMENT '1学习2作息3情绪4拖延5短视频6私密杂念7健康',
  `content` VARCHAR(255) NOT NULL COMMENT '记录内容',
  `cost_time` INT DEFAULT 0 COMMENT '耗时(分钟)',
  `trigger_reason` VARCHAR(100) DEFAULT NULL COMMENT '诱因/触发原因',
  `emotion_score` INT DEFAULT 0 COMMENT '情绪评分1-10',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`record_id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='全维度日常行为记录表';

-- ============================================================
-- 模块4: 心理学行为矫正干预
-- ============================================================
CREATE TABLE `behavior_intervene` (
  `intervene_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `intervene_type` TINYINT NOT NULL COMMENT '1拖延2杂念3短视频4懒惰',
  `intervene_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '干预触发时间',
  `is_success` TINYINT DEFAULT 0 COMMENT '0失败1成功',
  `mood_before` VARCHAR(50) DEFAULT NULL COMMENT '干预前情绪状态',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`intervene_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='行为矫正干预记录表';

-- ============================================================
-- 模块5: 财务焦虑与赚钱行动力矫正
-- ============================================================
CREATE TABLE `finance_mental_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `money_pressure` INT DEFAULT 0 COMMENT '财务压力等级1-10',
  `gap_amount` DECIMAL(10,2) DEFAULT 0 COMMENT '资金缺口金额',
  `income_record` TEXT COMMENT '当日收入/支出记录',
  `escape_state` TINYINT DEFAULT 0 COMMENT '逃避状态0-10',
  `action_minutes` INT DEFAULT 0 COMMENT '当日赚钱行动时长(分钟)',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='财务心理日志表';

-- ============================================================
-- 模块6: 三赛道学习管理
-- ============================================================
CREATE TABLE `study_track_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `track_type` TINYINT NOT NULL COMMENT '1英语演讲2AI学习3应用开发',
  `study_content` TEXT NOT NULL COMMENT '学习内容描述',
  `study_minutes` INT DEFAULT 0 COMMENT '学习时长(分钟)',
  `difficulty_level` INT DEFAULT 0 COMMENT '难度感知1-10',
  `escape_status` TINYINT DEFAULT 0 COMMENT '逃避状态0未逃避1轻微2中度3严重',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='三赛道学习追踪记录表';

-- ============================================================
-- 模块7: 轻量副业规划与落地追踪
-- ============================================================
CREATE TABLE `sideline_plan` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `side_type` TINYINT NOT NULL COMMENT '1英语方向2AI方向3开发综合',
  `daily_action` TEXT COMMENT '每日副业微行动记录',
  `progress` INT DEFAULT 0 COMMENT '进度0-100',
  `block_reason` TEXT COMMENT '阻碍原因分析',
  `energy_cost` INT DEFAULT 0 COMMENT '体能消耗感知1-10',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='副业规划追踪表';

-- ============================================================
-- 模块8: 空虚状态溯源与生活单调
-- ============================================================
CREATE TABLE `empty_mood_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `empty_level` INT DEFAULT 0 COMMENT '单调空虚等级1-10',
  `empty_hours` FLOAT DEFAULT 0 COMMENT '空虚时长(小时)',
  `trigger_cause` VARCHAR(100) DEFAULT NULL COMMENT '触发原因',
  `waste_hours` FLOAT DEFAULT 0 COMMENT '浪费时长(小时)',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='空虚情绪记录表';

-- ============================================================
-- 模块9: 书籍阅读体系
-- ============================================================
CREATE TABLE `book_read_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `book_type` TINYINT NOT NULL COMMENT '1财商赚钱2心理成长3人文休闲',
  `book_name` VARCHAR(50) NOT NULL COMMENT '书名',
  `read_minutes` INT DEFAULT 0 COMMENT '阅读时长(分钟)',
  `read_progress` INT DEFAULT 0 COMMENT '阅读进度0-100',
  `book_notes` TEXT COMMENT '读书笔记/心得',
  `escape_status` TINYINT DEFAULT 0 COMMENT '逃避状态',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阅读记录表';

-- ============================================================
-- 模块10: 业余生活丰盈 | 多元轻爱好
-- ============================================================
CREATE TABLE `life_leisure_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `leisure_type` TINYINT NOT NULL COMMENT '1放松2冥想3治愈短句4拉伸5环境整理6碎片新知',
  `leisure_minutes` INT DEFAULT 0 COMMENT '休闲时长(分钟)',
  `happy_score` INT DEFAULT 0 COMMENT '愉悦感评分1-10',
  `arrange_state` TINYINT DEFAULT 0 COMMENT '规划执行状态0未规划1已规划2已执行',
  `record_date` DATE NOT NULL COMMENT '记录日期',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生活休闲记录表';

-- ============================================================
-- 模块11: 精英榜样习惯对标
-- ============================================================
CREATE TABLE `elite_habit_lib` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `habit_category` TINYINT NOT NULL COMMENT '1晨间2日间3下班后4睡前',
  `habit_content` TEXT NOT NULL COMMENT '习惯内容描述',
  `intensity_level` INT DEFAULT 0 COMMENT '强度等级1-10',
  `suit_body_type` TINYINT DEFAULT 0 COMMENT '适配体质1低强度2中强度',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='精英习惯库表';

-- ============================================================
-- 模块11: 每日模范规划
-- ============================================================
CREATE TABLE `daily_model_plan` (
  `plan_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `plan_date` DATE NOT NULL COMMENT '规划日期',
  `time_period` VARCHAR(30) NOT NULL COMMENT '时间段描述',
  `plan_content` TEXT NOT NULL COMMENT '规划内容',
  `plan_type` TINYINT NOT NULL COMMENT '1学习2副业3阅读4休闲5心理',
  `difficulty` INT DEFAULT 0 COMMENT '难度等级',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `is_completed` TINYINT DEFAULT 0 COMMENT '是否完成 0否1是',
  `actual_note` TEXT COMMENT '实际每小时状况记录',
  `completed_at` DATETIME COMMENT '完成/记录时间',
  PRIMARY KEY (`plan_id`),
  KEY `user_date` (`user_id`, `plan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日模范规划表';

-- ============================================================
-- 模块11: 每日自查对照
-- ============================================================
CREATE TABLE `daily_compare_check` (
  `check_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `plan_date` DATE NOT NULL COMMENT '自查日期',
  `deviation_content` TEXT COMMENT '偏差内容描述',
  `escape_reason` TEXT COMMENT '逃避/未完成原因',
  `progress_score` INT DEFAULT 0 COMMENT '综合完成评分0-100',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`check_id`),
  KEY `user_date` (`user_id`, `plan_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日自查对照表';

-- ============================================================
-- 模块12: AI全维度综合复盘报告
-- ============================================================
CREATE TABLE `ai_psychological_report` (
  `report_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `cycle_type` TINYINT NOT NULL COMMENT '1日2周3月4年',
  `cycle_range` VARCHAR(50) NOT NULL COMMENT '周期范围(如2026-05-10~2026-05-16)',
  `original_data` LONGTEXT NOT NULL COMMENT '原始聚合JSON数据',
  `report_content` LONGTEXT NOT NULL COMMENT 'AI复盘报告内容',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI心理复盘报告表';

-- ============================================================
-- 精英习惯库: 预置初始数据
-- ============================================================
INSERT INTO `elite_habit_lib` (`habit_category`, `habit_content`, `intensity_level`, `suit_body_type`) VALUES
-- 晨间 (category 1)
(1, '晨起后5分钟伸展，激活身体', 2, 1),
(1, '喝一杯温水，写今日3件要事', 1, 1),
(1, '晨间10分钟冥想呼吸练习', 2, 1),
(1, '晨间15分钟英语听力/口语练习', 3, 2),
-- 日间 (category 2)
(2, '午休20分钟闭目养神，不刷手机', 1, 1),
(2, '工作间隙站立拉伸2分钟', 1, 1),
(2, '记录上午完成事项与感受', 2, 1),
(2, '午间20分钟AI技术阅读/实践', 3, 2),
-- 下班后 (category 3)
(3, '下班后15分钟过渡放松(轻音乐/冥想)', 1, 1),
(3, '30分钟开发练习(算法/项目)', 4, 2),
(3, '20分钟副业微行动(不熬夜、不透支)', 3, 2),
(3, '15分钟演讲练习(发声/表达/即兴)', 3, 2),
(3, '15分钟阅读(财商/成长/人文轮流)', 2, 1),
(3, '10分钟休闲轻爱好(治愈短句/拉伸)', 1, 1),
(3, '5分钟晚间自我复盘+明日规划', 1, 1),
-- 睡前 (category 4)
(4, '睡前30分钟远离屏幕，纸质书或冥想', 2, 1),
(4, '睡前感恩3件小确幸，降低焦虑', 1, 1),
(4, '回顾今日对标精英习惯差距', 2, 1),
(4, '10分钟渐进式肌肉放松练习', 2, 2);

-- ============================================================
-- 模块13: AI智能规划师 — 生活必备项配置
-- ============================================================
CREATE TABLE `life_essential_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `category` TINYINT NOT NULL COMMENT '1锻炼2阅读3冥想4技能5休闲',
  `name` VARCHAR(50) NOT NULL COMMENT '名称',
  `default_duration` INT DEFAULT 30 COMMENT '建议时长(分钟)',
  `variants` TEXT COMMENT 'JSON数组，如["晨间拉伸","快走15分钟"]',
  `energy_level` TINYINT DEFAULT 1 COMMENT '精力消耗1-3',
  `min_weekly_freq` INT DEFAULT 1 COMMENT '每周最少次数',
  `max_weekly_freq` INT DEFAULT 7 COMMENT '每周最多次数',
  `preferred_period` VARCHAR(20) DEFAULT 'any' COMMENT '偏好时段 morning/afternoon/evening/night/any',
  `enabled` TINYINT DEFAULT 1 COMMENT '是否启用',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生活必备项配置表';
