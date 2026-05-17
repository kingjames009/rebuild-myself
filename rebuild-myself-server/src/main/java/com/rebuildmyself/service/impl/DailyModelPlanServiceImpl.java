package com.rebuildmyself.service.impl;

import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.DailyModelPlan;
import com.rebuildmyself.entity.EliteHabitLib;
import com.rebuildmyself.entity.LifeEssentialConfig;
import com.rebuildmyself.entity.TaskTodo;
import com.rebuildmyself.entity.User;
import com.rebuildmyself.entity.UserGoal;
import com.rebuildmyself.mapper.DailyModelPlanMapper;
import com.rebuildmyself.mapper.EliteHabitLibMapper;
import com.rebuildmyself.mapper.LifeEssentialConfigMapper;
import com.rebuildmyself.mapper.TaskTodoMapper;
import com.rebuildmyself.mapper.UserGoalMapper;
import com.rebuildmyself.mapper.UserMapper;
import com.rebuildmyself.service.DailyModelPlanService;
import com.rebuildmyself.util.AiUtil;
import com.rebuildmyself.util.HolidayUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.MonthDay;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class DailyModelPlanServiceImpl extends ServiceImpl<DailyModelPlanMapper, DailyModelPlan> implements DailyModelPlanService {

    private final EliteHabitLibMapper eliteHabitLibMapper;
    private final TaskTodoMapper taskTodoMapper;
    private final UserGoalMapper userGoalMapper;
    private final LifeEssentialConfigMapper lifeEssentialConfigMapper;
    private final UserMapper userMapper;
    private final AiUtil aiUtil;

    public DailyModelPlanServiceImpl(EliteHabitLibMapper eliteHabitLibMapper,
                                     TaskTodoMapper taskTodoMapper,
                                     UserGoalMapper userGoalMapper,
                                     LifeEssentialConfigMapper lifeEssentialConfigMapper,
                                     UserMapper userMapper,
                                     AiUtil aiUtil) {
        this.eliteHabitLibMapper = eliteHabitLibMapper;
        this.taskTodoMapper = taskTodoMapper;
        this.userGoalMapper = userGoalMapper;
        this.lifeEssentialConfigMapper = lifeEssentialConfigMapper;
        this.userMapper = userMapper;
        this.aiUtil = aiUtil;
    }

    @Override
    public List<DailyModelPlan> listByUserAndDate(Long userId, LocalDate date) {
        LambdaQueryWrapper<DailyModelPlan> wrapper = new LambdaQueryWrapper<DailyModelPlan>()
                .eq(DailyModelPlan::getUserId, userId)
                .eq(DailyModelPlan::getPlanDate, date)
                .orderByAsc(DailyModelPlan::getTimePeriod);
        return this.list(wrapper);
    }

    @Override
    public int deleteByUserAndDate(Long userId, LocalDate date) {
        LambdaQueryWrapper<DailyModelPlan> wrapper = new LambdaQueryWrapper<DailyModelPlan>()
                .eq(DailyModelPlan::getUserId, userId)
                .eq(DailyModelPlan::getPlanDate, date);
        return this.baseMapper.delete(wrapper);
    }

    private boolean isWorkday(LocalDate date) {
        return HolidayUtil.isWorkday(date);
    }

    @Override
    public List<DailyModelPlan> generateTodayPlan(Long userId) {
        LocalDate today = LocalDate.now();

        // One plan per user per day: return existing plans if already generated
        List<DailyModelPlan> existing = list(new LambdaQueryWrapper<DailyModelPlan>()
                .eq(DailyModelPlan::getUserId, userId)
                .eq(DailyModelPlan::getPlanDate, today));
        if (!existing.isEmpty()) {
            return existing;
        }

        boolean workday = isWorkday(today);
        List<EliteHabitLib> habits = eliteHabitLibMapper.selectList(null);
        List<TaskTodo> tasks = taskTodoMapper.selectList(
                new LambdaQueryWrapper<TaskTodo>()
                        .eq(TaskTodo::getUserId, userId)
                        .eq(TaskTodo::getTaskDate, today)
                        .eq(TaskTodo::getIsComplete, 0));
        // Use goals as "近期目标": active goals within date range
        List<UserGoal> goals = userGoalMapper.selectList(
                new LambdaQueryWrapper<UserGoal>()
                        .eq(UserGoal::getUserId, userId)
                        .ne(UserGoal::getStatus, 2) // not completed
                        .and(w -> w.isNull(UserGoal::getStartDate).or().le(UserGoal::getStartDate, today))
                        .and(w -> w.isNull(UserGoal::getTargetTime).or().ge(UserGoal::getTargetTime, today)));
        List<LifeEssentialConfig> essentials = lifeEssentialConfigMapper.selectList(
                new LambdaQueryWrapper<LifeEssentialConfig>()
                        .eq(LifeEssentialConfig::getUserId, userId)
                        .eq(LifeEssentialConfig::getEnabled, 1));
        User user = userMapper.selectById(userId);

        // Try AI-powered generation first
        String prompt = buildPlanPrompt(habits, tasks, goals, essentials, user, workday, today);
        String systemPrompt = "你是一位资深的认知行为心理学顾问和自律规划师，精通学习科学、能量管理、习惯养成和行为心理学。你的任务是为用户生成一份科学优化的每日计划，目标是让用户能坚持到底。你必须严格只返回JSON数组，不要包含任何markdown标记或解释文字。";

        try {
            String aiResponse = aiUtil.generateReport(systemPrompt, prompt);
            if (aiResponse != null && !aiResponse.trim().isEmpty()) {
                List<DailyModelPlan> plans = parsePlanResponse(aiResponse, userId, today);
                if (!plans.isEmpty()) {
                    this.saveBatch(plans);
                    return plans;
                }
            }
        } catch (Exception e) {
            log.warn("AI plan generation failed, using fallback", e);
        }

        // Fallback to static rule-based generation
        return generateTodayPlanStatic(userId, today, habits, tasks, workday);
    }

    /**
     * Build a detailed prompt for the AI planner.
     */
    private String buildPlanPrompt(List<EliteHabitLib> habits, List<TaskTodo> tasks,
                                    List<UserGoal> goals, List<LifeEssentialConfig> essentials,
                                    User user, boolean workday, LocalDate today) {
        StringBuilder sb = new StringBuilder();
        sb.append("你是一个精确的时间规划系统。你需要根据用户的目标、待办和习惯，为今天生成一份可执行的行动计划。\n");
        sb.append("核心任务：将用户的每个活跃目标拆解为今天具体要做的执行步骤，合理安排到时间槽中。\n\n");

        // Date context
        String dayType = workday ? "工作日" : "周末/节假日";
        String timeWindow;
        String workConstraint;
        if (workday) {
            timeWindow = "06:00-09:00（晨间深度学习）\n  09:00-12:00（上班时段，每30分钟一个冥想提醒，不安排任何目标/习惯/待办）\n  12:00-13:30（午休，可做轻量阅读+自我关怀练习）\n  13:30-18:00（上班时段，每30分钟一个冥想提醒，不安排任何目标/习惯/待办）\n  18:00-23:00（下班后深度副业/学习）\n  23:00-23:30（睡前准备30分钟）";
            workConstraint = "## 【极其重要】工作日上班时段约束\n上班时段(09:00-12:00, 13:30-18:00)用户正在上班，绝对不能安排任何目标、待办或习惯内容。这段期间唯一的安排是：每30分钟一个简单的冥想专注提醒，帮助用户回到当下。\n\n上班时段计划格式示例：\n{\"timePeriod\":\"09:00-09:30\",\"planContent\":\"🧘 暂停30秒：深呼吸，感受气息。回到当下，继续手头的工作。\",\"planType\":5,\"difficulty\":1}\n{\"timePeriod\":\"09:30-10:00\",\"planContent\":\"🧘 身体扫描：注意坐姿，放松肩膀，做3次自然呼吸。\",\"planType\":5,\"difficulty\":1}\n\n上班时段绝对禁止出现：【目标名称】前缀、待办任务、习惯内容。只需要简单的冥想/正念/回到当下的提醒。每个30分钟块一条。\n\n";
        } else {
            timeWindow = "07:00-12:00（上午5小时）\n  12:00-13:30（午间1.5小时）\n  13:30-18:00（下午4.5小时）\n  18:00-23:00（晚间5小时）\n  23:00-23:30（睡前准备30分钟）";
            workConstraint = "";
        }
        sb.append("## 基础信息\n");
        sb.append("日期: ").append(today).append(" (").append(dayType).append(")\n");
        sb.append("可用时段:\n").append(timeWindow).append("\n");
        sb.append("23:00后只能安排冥想/感恩日记/复盘，23:30必须结束所有活动\n\n");
        sb.append(workConstraint);

        // Health context
        if (user != null) {
            sb.append("## 用户身体状况\n");
            if (user.getHeight() != null) sb.append("身高").append(user.getHeight()).append("cm ");
            if (user.getWeight() != null) sb.append("体重").append(user.getWeight()).append("kg ");
            if (user.getHeight() != null && user.getWeight() != null
                    && user.getHeight().compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal heightM = user.getHeight().divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
                BigDecimal bmi = user.getWeight().divide(heightM.multiply(heightM), 1, RoundingMode.HALF_UP);
                sb.append("BMI≈").append(bmi).append(" ");
                if (bmi.compareTo(new BigDecimal("28")) >= 0) sb.append("（偏重）");
                else if (bmi.compareTo(new BigDecimal("24")) >= 0) sb.append("（超重）");
            }
            sb.append("\n");
            if (user.getHealthNote() != null && !user.getHealthNote().isEmpty()) {
                sb.append("健康备注: ").append(user.getHealthNote()).append("\n");
            }
            sb.append("计划要求：避免高强度运动（跑跳/剧烈竞争），推荐低强度有氧（快走、拉伸、八段锦）；");
            sb.append("每晚安排助眠活动（冥想/呼吸练习/远离屏幕）；控制久坐时间，每坐1小时起身活动2分钟\n\n");
        }

        // User goals — today's execution targets
        if (goals != null && !goals.isEmpty()) {
            String[] goalTypeNames = {"", "学习", "财务", "健康", "习惯"};
            String[] goalLevelNames = {"", "长期", "年度", "月度", "每日"};
            sb.append("## 今天要执行的目标（这是计划的核心，必须为每个目标生成具体执行步骤！）\n");
            for (UserGoal g : goals) {
                String type = g.getGoalType() != null && g.getGoalType() < goalTypeNames.length
                        ? goalTypeNames[g.getGoalType()] : "通用";
                String level = g.getGoalLevel() != null && g.getGoalLevel() < goalLevelNames.length
                        ? goalLevelNames[g.getGoalLevel()] : "";
                sb.append("- [").append(level).append("][").append(type).append("]");
                if (g.getTargetTime() != null) {
                    sb.append("[截止").append(g.getTargetTime()).append("]");
                }
                sb.append(" ").append(g.getGoalTitle());
                if (g.getGoalContent() != null && !g.getGoalContent().isEmpty()) {
                    sb.append(" — ").append(g.getGoalContent());
                }
                sb.append("\n");
            }
            sb.append("\n## 目标执行规划要求（极其重要）\n");
            sb.append("1. 为每个目标拆解今天的具体执行步骤——不要只写目标名称，要写今天具体做什么。\n");
            sb.append("   例如目标「Flutter开发精通」→ 今天执行：「完成用户登录页面的状态管理重构」「学习Provider源码1小时并做笔记」\n");
            sb.append("2. 每个目标至少安排1个专属时间段，重要目标安排2-3个时段。\n");
            sb.append("3. 执行步骤前面必须加上【目标标题】前缀，格式：【目标标题】今天的具体执行内容。\n");
            sb.append("   例如：【Flutter开发精通】完成用户登录页面的状态管理重构，替换为Riverpod方案\n");
            sb.append("4. 学习类目标安排在认知高峰期(07:00-10:00或20:00-22:00)，健康类安排在晨间或下班后，财务类安排在下班后。\n");
            sb.append("5. 临近截止日期的目标优先级最高，必须优先安排足够时间。\n");
            sb.append("6. 每个目标今天都必须安排，周末也不例外。周末可以把工作相关目标安排在下午或晚上，不要跳过。\n\n");
        }

        // Life essentials
        if (essentials != null && !essentials.isEmpty()) {
            String[] essCatNames = {"", "锻炼", "阅读", "冥想", "技能", "休闲"};
            sb.append("## 生活必备项\n");
            for (LifeEssentialConfig e : essentials) {
                String cat = e.getCategory() != null && e.getCategory() < essCatNames.length
                        ? essCatNames[e.getCategory()] : "其他";
                sb.append("- [").append(cat).append("] ").append(e.getName())
                        .append("（建议").append(e.getDefaultDuration()).append("分钟");
                if (e.getPreferredPeriod() != null && !"any".equals(e.getPreferredPeriod())) {
                    String period = switch (e.getPreferredPeriod()) {
                        case "morning" -> "上午";
                        case "afternoon" -> "下午";
                        case "evening" -> "晚间";
                        case "night" -> "睡前";
                        default -> e.getPreferredPeriod();
                    };
                    sb.append("，偏好").append(period);
                }
                sb.append("）");
                if (e.getVariants() != null && !e.getVariants().isEmpty()) {
                    sb.append(" 变体: ").append(e.getVariants());
                }
                sb.append("\n");
            }
            sb.append("每天从中选若干项穿插到计划中，不同变体轮流使用，确保每周至少出现最低频次\n\n");
        }

        // Habit library
        if (habits != null && !habits.isEmpty()) {
            sb.append("## 习惯模板库\n");
            for (EliteHabitLib h : habits) {
                sb.append("- ").append(h.getHabitContent())
                        .append(" [难度").append(h.getIntensityLevel()).append("]\n");
            }
            sb.append("\n");
        }

        // Today's tasks
        if (tasks != null && !tasks.isEmpty()) {
            String[] levelNames = {"", "重要紧急", "重要不紧急", "紧急不重要", "不重要不紧急"};
            sb.append("## 今日待办\n");
            for (TaskTodo t : tasks) {
                String lvl = t.getTaskLevel() != null && t.getTaskLevel() < levelNames.length
                        ? levelNames[t.getTaskLevel()] : "一般";
                sb.append("- [").append(lvl).append("] ").append(t.getTaskTitle()).append("\n");
            }
            sb.append("\n");
        }

        // Scientific principles
        sb.append("## 编排规则\n");
        sb.append("- 认知峰值07:00-10:00：安排最困难的学习/创造性任务\n");
        sb.append("- 上班时段每30分钟只安排1个冥想/正念/回到当下的简短提醒（不安排任何目标/待办/习惯）\n");
        sb.append("- 午休时段安排自我慈悲/身体觉察等关怀类练习\n");
        sb.append("- 能量低谷14:00-16:00：安排轻量复习/阅读/短休息+身心解耦练习\n");
        sb.append("- 第二高峰20:00-22:00：安排副业/开发/深度学习\n");
        sb.append("- 不同主题必须交错穿插，同一主题不能连续出现\n");
        sb.append("- 高强度任务后必须跟5-10分钟轻量缓冲\n");
        sb.append("- 每个时间段为30或60分钟的整数倍\n");
        sb.append("- 时间必须首尾相连无间断，完整覆盖所有可用时段\n");
        sb.append("- 重要紧急的待办优先安排在第一个可用时段\n");
        sb.append("- 上班时段每30分钟一个冥想提醒，内容必须简短（一句话），帮助用户回到当下。上班时段绝对不出现【目标】前缀、待办、习惯等内容\n");
        sb.append("- 用户的近期目标和生活必备项优先于习惯模板库\n\n");

        // CRITICAL output format
        sb.append("## 【关键】输出格式\n");
        sb.append("你必须返回一个JSON数组。每个对象的timePeriod字段必须使用\"HH:MM-HH:MM\"格式（如\"07:00-07:30\"），绝对不能使用\"上午\"、\"下午\"、\"晨间\"、\"晚间\"等文字描述。如果timePeriod不是HH:MM-HH:MM格式，整个计划将无法被系统解析而失效。\n\n");
        sb.append("示例（请严格遵循此格式）:\n");
        sb.append("[{\"timePeriod\":\"07:00-07:30\",\"planContent\":\"5分钟伸展+喝温水+写今日3件要事\",\"planType\":4,\"difficulty\":1},\n");
        sb.append(" {\"timePeriod\":\"07:30-08:00\",\"planContent\":\"15分钟英语影子跟读+5分钟缓冲\",\"planType\":1,\"difficulty\":4},\n");
        sb.append(" {\"timePeriod\":\"08:00-08:30\",\"planContent\":\"20分钟AI技术阅读+5分钟笔记\",\"planType\":1,\"difficulty\":3},\n");
        sb.append(" {\"timePeriod\":\"23:00-23:30\",\"planContent\":\"感恩3件小确幸+回顾今日+明日规划\",\"planType\":5,\"difficulty\":1}]\n\n");
        sb.append("planType: 1=学习 2=副业 3=阅读 4=休闲 5=心理\n");
        sb.append("请生成15-25项计划，直接返回JSON数组（不要```json```标记，不要任何解释文字）。");

        return sb.toString();
    }

    /**
     * Parse the AI response into DailyModelPlan entities.
     * Handles responses that may wrap JSON in markdown code blocks.
     */
    private List<DailyModelPlan> parsePlanResponse(String response, Long userId, LocalDate today) {
        List<DailyModelPlan> plans = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        // Strip markdown code blocks if present
        String json = response.trim();
        if (json.startsWith("```")) {
            int start = json.indexOf('\n');
            int end = json.lastIndexOf("```");
            if (start >= 0 && end > start) {
                json = json.substring(start + 1, end).trim();
            }
        }

        try {
            JSONArray arr = JSONUtil.parseArray(json);
            for (int i = 0; i < arr.size(); i++) {
                JSONObject obj = arr.getJSONObject(i);
                DailyModelPlan plan = new DailyModelPlan();
                plan.setUserId(userId);
                plan.setPlanDate(today);
                plan.setTimePeriod(obj.getStr("timePeriod", "日间"));
                plan.setPlanContent(obj.getStr("planContent", ""));
                plan.setPlanType(obj.getInt("planType", 0));
                plan.setDifficulty(obj.getInt("difficulty", 3));
                plan.setCreateTime(now);
                plans.add(plan);
            }
        } catch (Exception e) {
            log.warn("Failed to parse AI plan response: {}", response, e);
        }

        return plans;
    }

    /**
     * Fallback: static rule-based plan generation (the original logic).
     */
    private List<DailyModelPlan> generateTodayPlanStatic(Long userId, LocalDate today, List<EliteHabitLib> habits, List<TaskTodo> tasks, boolean workday) {
        LocalDateTime now = LocalDateTime.now();
        List<DailyModelPlan> plans = new ArrayList<>();

        // Part 1: Generate plans from elite habits
        for (EliteHabitLib habit : habits) {
            DailyModelPlan plan = new DailyModelPlan();
            plan.setUserId(userId);
            plan.setPlanDate(today);
            plan.setPlanContent(habit.getHabitContent());
            plan.setDifficulty(habit.getIntensityLevel());
            plan.setCreateTime(now);

            String timePeriod;
            if (workday) {
                switch (habit.getHabitCategory()) {
                    case 1: timePeriod = "晨间"; break;
                    case 2: timePeriod = "日间"; break;
                    case 3: timePeriod = "下班后"; break;
                    case 4: timePeriod = "睡前"; break;
                    default: timePeriod = "日间";
                }
            } else {
                switch (habit.getHabitCategory()) {
                    case 1: timePeriod = "上午"; break;
                    case 2: timePeriod = "下午"; break;
                    case 3: timePeriod = "晚间"; break;
                    case 4: timePeriod = "睡前"; break;
                    default: timePeriod = "下午";
                }
            }
            plan.setTimePeriod(timePeriod);
            plan.setPlanType(matchPlanType(habit.getHabitContent()));
            plans.add(plan);
        }

        // Part 2: Pull today's incomplete tasks into the plan
        for (TaskTodo task : tasks) {
            DailyModelPlan plan = new DailyModelPlan();
            plan.setUserId(userId);
            plan.setPlanDate(today);
            plan.setPlanContent(task.getTaskTitle());
            plan.setCreateTime(now);
            plan.setDifficulty(5 - task.getTaskLevel());

            String content = task.getTaskTitle();
            String timePeriod;
            if (containsAny(content, "跑步", "晨跑", "运动", "锻炼", "健身", "跳绳", "拉伸")) {
                timePeriod = workday ? "晨间" : "上午";
            } else if (containsAny(content, "读书", "阅读", "冥想", "日记", "复盘", "写日记")) {
                timePeriod = "睡前";
            } else if (workday && containsAny(content, "午休", "午间", "午餐", "休息", "复习", "回顾", "整理",
                    "规划", "打卡", "记录", "简", "速", "快速", "碎片")) {
                timePeriod = "午间";
            } else {
                timePeriod = workday ? "下班后" : "晚间";
            }
            plan.setTimePeriod(timePeriod);
            plan.setPlanType(matchPlanType(content));
            plans.add(plan);
        }

        if (!plans.isEmpty()) {
            this.saveBatch(plans);
        }
        return plans;
    }

    private boolean containsAny(String text, String... keywords) {
        if (text == null) return false;
        for (String kw : keywords) {
            if (text.contains(kw)) return true;
        }
        return false;
    }

    @Override
    public void replaceByUserAndDate(Long userId, LocalDate date, List<DailyModelPlan> plans) {
        // Delete all existing plans for this user + date
        deleteByUserAndDate(userId, date);
        // Insert the new plans
        LocalDateTime now = LocalDateTime.now();
        for (DailyModelPlan plan : plans) {
            plan.setUserId(userId);
            plan.setPlanDate(date);
            if (plan.getCreateTime() == null) plan.setCreateTime(now);
        }
        if (!plans.isEmpty()) {
            this.saveBatch(plans);
        }
    }

    @Override
    public DailyModelPlan updateNote(Long userId, LocalDate planDate, String timePeriod, String actualNote) {
        LambdaUpdateWrapper<DailyModelPlan> wrapper = new LambdaUpdateWrapper<DailyModelPlan>()
                .set(DailyModelPlan::getActualNote, actualNote)
                .set(DailyModelPlan::getCompletedAt, LocalDateTime.now())
                .eq(DailyModelPlan::getUserId, userId)
                .eq(DailyModelPlan::getPlanDate, planDate)
                .eq(DailyModelPlan::getTimePeriod, timePeriod);
        this.update(wrapper);
        return this.getOne(new LambdaQueryWrapper<DailyModelPlan>()
                .eq(DailyModelPlan::getUserId, userId)
                .eq(DailyModelPlan::getPlanDate, planDate)
                .eq(DailyModelPlan::getTimePeriod, timePeriod));
    }

    /**
     * Match plan type by keywords in the content.
     * 1=学习, 2=副业, 3=阅读, 4=休闲, 5=心理, 0=未分类
     */
    private Integer matchPlanType(String content) {
        if (content == null || content.isEmpty()) {
            return 0;
        }
        if (content.contains("学习")) return 1;
        if (content.contains("副业")) return 2;
        if (content.contains("阅读")) return 3;
        if (content.contains("休闲")) return 4;
        if (content.contains("心理")) return 5;
        return 0;
    }
}
