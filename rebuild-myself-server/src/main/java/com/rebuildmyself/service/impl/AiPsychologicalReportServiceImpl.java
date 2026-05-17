package com.rebuildmyself.service.impl;


import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.*;
import com.rebuildmyself.mapper.*;
import com.rebuildmyself.service.AiPsychologicalReportService;
import com.rebuildmyself.util.AiUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiPsychologicalReportServiceImpl extends ServiceImpl<AiPsychologicalReportMapper, AiPsychologicalReport> implements AiPsychologicalReportService {

    private final AiPsychologicalReportMapper aiPsychologicalReportMapper;
    private final DailyRecordMapper dailyRecordMapper;
    private final BehaviorInterveneMapper behaviorInterveneMapper;
    private final FinanceMentalLogMapper financeMentalLogMapper;
    private final StudyTrackRecordMapper studyTrackRecordMapper;
    private final SidelinePlanMapper sidelinePlanMapper;
    private final EmptyMoodLogMapper emptyMoodLogMapper;
    private final BookReadRecordMapper bookReadRecordMapper;
    private final LifeLeisureRecordMapper lifeLeisureRecordMapper;
    private final DailyCompareCheckMapper dailyCompareCheckMapper;
    private final DailyModelPlanMapper dailyModelPlanMapper;
    private final AiUtil aiUtil;

    @Override
    public AiPsychologicalReport generateReport(Long userId, Integer cycleType, LocalDate date) {
        // Use provided date, default to today
        LocalDate refDate = date != null ? date : LocalDate.now();
        LocalDate startDate;
        LocalDate endDate;

        switch (cycleType) {
            case 1: // 日复盘 — refDate 那天
                startDate = refDate;
                endDate = refDate;
                break;
            case 2: // 本周
                startDate = refDate.with(DayOfWeek.MONDAY);
                endDate = refDate.with(DayOfWeek.SUNDAY);
                break;
            case 3: // 本月
                startDate = refDate.withDayOfMonth(1);
                endDate = refDate.withDayOfMonth(refDate.lengthOfMonth());
                break;
            case 4: // 本年
                startDate = refDate.withDayOfYear(1);
                endDate = refDate.withDayOfYear(refDate.lengthOfYear());
                break;
            default:
                startDate = refDate;
                endDate = refDate;
        }

        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(LocalTime.MAX);

        // === Aggregate ALL data within date range ===

        // 1. DailyRecord - has recordDate (LocalDate)
        List<DailyRecord> dailyRecords = dailyRecordMapper.selectList(
                new LambdaQueryWrapper<DailyRecord>()
                        .eq(DailyRecord::getUserId, userId)
                        .ge(DailyRecord::getRecordDate, startDate)
                        .le(DailyRecord::getRecordDate, endDate));

        // 2. BehaviorIntervene - has interveneTime (LocalDateTime)
        List<BehaviorIntervene> behaviorIntervenes = behaviorInterveneMapper.selectList(
                new LambdaQueryWrapper<BehaviorIntervene>()
                        .eq(BehaviorIntervene::getUserId, userId)
                        .ge(BehaviorIntervene::getInterveneTime, startDateTime)
                        .le(BehaviorIntervene::getInterveneTime, endDateTime));

        // 3. FinanceMentalLog - has recordDate (LocalDate)
        List<FinanceMentalLog> financeMentalLogs = financeMentalLogMapper.selectList(
                new LambdaQueryWrapper<FinanceMentalLog>()
                        .eq(FinanceMentalLog::getUserId, userId)
                        .ge(FinanceMentalLog::getRecordDate, startDate)
                        .le(FinanceMentalLog::getRecordDate, endDate));

        // 4. StudyTrackRecord - has recordDate (LocalDate)
        List<StudyTrackRecord> studyTrackRecords = studyTrackRecordMapper.selectList(
                new LambdaQueryWrapper<StudyTrackRecord>()
                        .eq(StudyTrackRecord::getUserId, userId)
                        .ge(StudyTrackRecord::getRecordDate, startDate)
                        .le(StudyTrackRecord::getRecordDate, endDate));

        // 5. SidelinePlan - has recordDate (LocalDate)
        List<SidelinePlan> sidelinePlans = sidelinePlanMapper.selectList(
                new LambdaQueryWrapper<SidelinePlan>()
                        .eq(SidelinePlan::getUserId, userId)
                        .ge(SidelinePlan::getRecordDate, startDate)
                        .le(SidelinePlan::getRecordDate, endDate));

        // 6. EmptyMoodLog - has recordDate (LocalDate)
        List<EmptyMoodLog> emptyMoodLogs = emptyMoodLogMapper.selectList(
                new LambdaQueryWrapper<EmptyMoodLog>()
                        .eq(EmptyMoodLog::getUserId, userId)
                        .ge(EmptyMoodLog::getRecordDate, startDate)
                        .le(EmptyMoodLog::getRecordDate, endDate));

        // 7. BookReadRecord - has recordDate (LocalDate)
        List<BookReadRecord> bookReadRecords = bookReadRecordMapper.selectList(
                new LambdaQueryWrapper<BookReadRecord>()
                        .eq(BookReadRecord::getUserId, userId)
                        .ge(BookReadRecord::getRecordDate, startDate)
                        .le(BookReadRecord::getRecordDate, endDate));

        // 8. LifeLeisureRecord - has recordDate (LocalDate)
        List<LifeLeisureRecord> lifeLeisureRecords = lifeLeisureRecordMapper.selectList(
                new LambdaQueryWrapper<LifeLeisureRecord>()
                        .eq(LifeLeisureRecord::getUserId, userId)
                        .ge(LifeLeisureRecord::getRecordDate, startDate)
                        .le(LifeLeisureRecord::getRecordDate, endDate));

        // 9. DailyCompareCheck - has planDate (LocalDate)
        List<DailyCompareCheck> dailyCompareChecks = dailyCompareCheckMapper.selectList(
                new LambdaQueryWrapper<DailyCompareCheck>()
                        .eq(DailyCompareCheck::getUserId, userId)
                        .ge(DailyCompareCheck::getPlanDate, startDate)
                        .le(DailyCompareCheck::getPlanDate, endDate));

        // 10. DailyModelPlan - has planDate (LocalDate), includes hourly plan vs actual_note
        List<DailyModelPlan> dailyModelPlans = dailyModelPlanMapper.selectList(
                new LambdaQueryWrapper<DailyModelPlan>()
                        .eq(DailyModelPlan::getUserId, userId)
                        .ge(DailyModelPlan::getPlanDate, startDate)
                        .le(DailyModelPlan::getPlanDate, endDate));

        // === Build a structured, AI-friendly summary (not raw JSON dump) ===
        StringBuilder data = new StringBuilder();

        // ---- Part: 今日规划执行详情 (most important) ----
        data.append("=== 今日规划执行详情 ===\n");
        if (dailyModelPlans.isEmpty()) {
            data.append("（无计划记录）\n");
        } else {
            for (int i = 0; i < dailyModelPlans.size(); i++) {
                DailyModelPlan plan = dailyModelPlans.get(i);
                String period = plan.getTimePeriod() != null ? plan.getTimePeriod() : "未知时段";
                String planContent = plan.getPlanContent() != null ? plan.getPlanContent() : "";
                String actualNote = plan.getActualNote() != null && !plan.getActualNote().isEmpty()
                        ? plan.getActualNote() : "";
                boolean completed = plan.getIsCompleted() != null && plan.getIsCompleted() == 1;

                // Find matching study records for this plan date
                int totalMinutes = 0;
                if (plan.getPlanDate() != null) {
                    for (StudyTrackRecord s : studyTrackRecords) {
                        if (plan.getPlanDate().equals(s.getRecordDate())) {
                            totalMinutes += s.getStudyMinutes() != null ? s.getStudyMinutes() : 0;
                        }
                    }
                }

                data.append(i + 1).append(". [").append(period).append("] ");
                data.append(planContent).append("\n");

                if (completed && actualNote.isEmpty()) {
                    data.append("   → 状态：已完成（计时器跑完，但未记录实际状况）\n");
                } else if (completed && !actualNote.isEmpty()) {
                    data.append("   → 状态：已完成，实际记录：").append(actualNote).append("\n");
                } else if (!completed && !actualNote.isEmpty()) {
                    data.append("   → 状态：有记录但未标记完成，实际记录：").append(actualNote).append("\n");
                } else {
                    data.append("   → 状态：未做（无任何记录）\n");
                }

                if (totalMinutes > 0) {
                    data.append("   → 该日期总专注时长：").append(totalMinutes).append("分钟\n");
                }
            }
        }
        data.append("\n");

        // ---- Part: 专注学习记录 ----
        data.append("=== 专注学习记录（").append(studyTrackRecords.size()).append("条） ===\n");
        for (StudyTrackRecord s : studyTrackRecords) {
            String typeLabel = switch (s.getTrackType() != null ? s.getTrackType() : 0) {
                case 1 -> "英语";
                case 2 -> "AI";
                case 3 -> "开发";
                default -> "其他";
            };
            data.append("- [").append(typeLabel).append("] ");
            data.append(s.getStudyContent() != null ? s.getStudyContent() : "").append(" — ");
            data.append(s.getStudyMinutes() != null ? s.getStudyMinutes() : 0).append("分钟");
            if (s.getRecordDate() != null) data.append(" (").append(s.getRecordDate()).append(")");
            data.append("\n");
        }
        data.append("\n");

        // ---- Part: 日常记录 ----
        data.append("=== 日常记录（").append(dailyRecords.size()).append("条） ===\n");
        for (DailyRecord r : dailyRecords) {
            String typeLabel = switch (r.getRecordType() != null ? r.getRecordType() : 0) {
                case 1 -> "学习";
                case 2 -> "作息";
                case 3 -> "情绪";
                case 4 -> "拖延";
                case 5 -> "短视频";
                case 6 -> "私密杂念";
                default -> "其他";
            };
            data.append("- [").append(typeLabel).append("] ");
            if (r.getContent() != null) data.append(r.getContent());
            if (r.getCostTime() != null) data.append(" — ").append(r.getCostTime()).append("分钟");
            if (r.getEmotionScore() != null) data.append(" — 情绪").append(r.getEmotionScore()).append("/10");
            data.append("\n");
        }
        data.append("\n");

        // ---- Part: 财务心理 ----
        if (!financeMentalLogs.isEmpty()) {
            data.append("=== 财务心理记录（").append(financeMentalLogs.size()).append("条） ===\n");
            for (FinanceMentalLog f : financeMentalLogs) {
                if (f.getMoneyPressure() != null) data.append("- 金钱压力：").append(f.getMoneyPressure()).append("/5");
                if (f.getIncomeRecord() != null && !f.getIncomeRecord().isEmpty())
                    data.append("，收入记录：").append(f.getIncomeRecord());
                if (f.getActionMinutes() != null) data.append("，行动").append(f.getActionMinutes()).append("分钟");
                data.append("\n");
            }
            data.append("\n");
        }

        // ---- Part: 行为干预 ----
        if (!behaviorIntervenes.isEmpty()) {
            data.append("=== 行为干预记录（").append(behaviorIntervenes.size()).append("条） ===\n");
            for (BehaviorIntervene b : behaviorIntervenes) {
                String typeLabel = switch (b.getInterveneType() != null ? b.getInterveneType() : 0) {
                    case 1 -> "拖延干预";
                    case 2 -> "逃避干预";
                    case 3 -> "情绪干预";
                    default -> "其他干预";
                };
                data.append("- [").append(typeLabel).append("]");
                if (b.getMoodBefore() != null) data.append(" 干预前情绪：").append(b.getMoodBefore());
                if (b.getIsSuccess() != null) data.append(b.getIsSuccess() == 1 ? " → 成功" : " → 未成功");
                data.append("\n");
            }
            data.append("\n");
        }

        // ---- Part: 阅读记录 ----
        if (!bookReadRecords.isEmpty()) {
            data.append("=== 阅读记录（").append(bookReadRecords.size()).append("条） ===\n");
            for (BookReadRecord b : bookReadRecords) {
                data.append("- ").append(b.getBookName() != null ? b.getBookName() : "");
                if (b.getReadMinutes() != null) data.append(" — ").append(b.getReadMinutes()).append("分钟");
                data.append("\n");
            }
            data.append("\n");
        }

        // ---- Part: 休闲记录 ----
        if (!lifeLeisureRecords.isEmpty()) {
            data.append("=== 休闲记录（").append(lifeLeisureRecords.size()).append("条） ===\n");
            for (LifeLeisureRecord l : lifeLeisureRecords) {
                String typeLabel = switch (l.getLeisureType() != null ? l.getLeisureType() : 0) {
                    case 1 -> "运动";
                    case 2 -> "社交";
                    case 3 -> "娱乐";
                    case 4 -> "放松";
                    default -> "其他";
                };
                data.append("- [").append(typeLabel).append("] ");
                if (l.getLeisureMinutes() != null) data.append(l.getLeisureMinutes()).append("分钟");
                if (l.getHappyScore() != null) data.append(" — 愉悦度").append(l.getHappyScore()).append("/10");
                data.append("\n");
            }
            data.append("\n");
        }

        // ---- Part: 每日自检 ----
        if (!dailyCompareChecks.isEmpty()) {
            data.append("=== 每日自检（").append(dailyCompareChecks.size()).append("条） ===\n");
            for (DailyCompareCheck c : dailyCompareChecks) {
                if (c.getDeviationContent() != null) data.append("- 偏差：").append(c.getDeviationContent()).append("\n");
                if (c.getEscapeReason() != null) data.append("  逃避原因：").append(c.getEscapeReason()).append("\n");
                if (c.getProgressScore() != null) data.append("  进度评分：").append(c.getProgressScore()).append("/10\n");
            }
            data.append("\n");
        }

        // ---- Part: 副业规划 ----
        if (!sidelinePlans.isEmpty()) {
            data.append("=== 副业规划（").append(sidelinePlans.size()).append("条） ===\n");
            for (SidelinePlan s : sidelinePlans) {
                if (s.getDailyAction() != null) data.append("- ").append(s.getDailyAction());
                if (s.getProgress() != null) data.append(" — 进度").append(s.getProgress()).append("%");
                if (s.getBlockReason() != null && !s.getBlockReason().isEmpty())
                    data.append(" — 阻碍：").append(s.getBlockReason());
                data.append("\n");
            }
            data.append("\n");
        }

        // ---- Part: 空虚情绪 ----
        if (!emptyMoodLogs.isEmpty()) {
            data.append("=== 空虚情绪记录（").append(emptyMoodLogs.size()).append("条） ===\n");
            for (EmptyMoodLog e : emptyMoodLogs) {
                if (e.getEmptyLevel() != null) data.append("- 空虚程度：").append(e.getEmptyLevel()).append("/5");
                if (e.getTriggerCause() != null && !e.getTriggerCause().isEmpty())
                    data.append("，触发原因：").append(e.getTriggerCause());
                if (e.getWasteHours() != null) data.append("，浪费").append(e.getWasteHours()).append("小时");
                data.append("\n");
            }
            data.append("\n");
        }

        String originalData = data.toString();

        // === Call AI via AiUtil ===
        String systemPrompt = "你是一位资深认知行为心理学顾问。请基于以下用户的今日全维度数据，生成一份专业的心理行为复盘报告。\n\n报告必须包含四部分：\n1. 📊 数据总结 — 用数字说话，概括今日计划完成情况、专注时长、情绪状态\n2. 🔍 问题诊断 — 逐项分析每条计划：哪些做到了、哪些没做、哪些有偏差\n3. 🎯 根源溯源 — 从逃避原因、拖延模式、情绪波动中追溯行为问题的心理根源\n4. 💡 定制优化方案 — 3-5条具体、可执行的改进建议\n\n重点关注「今日规划执行详情」中每条计划的状态（已完成/未做/有记录未完成）。对标记为「未做」的项，分析可能的逃避原因并给出明天可执行的对策。对已完成项，肯定执行力的同时检查实际记录是否有改进空间。";
        String reportContent = aiUtil.generateReport(systemPrompt, originalData);

        // === Save report ===
        AiPsychologicalReport report = new AiPsychologicalReport();
        report.setUserId(userId);
        report.setCycleType(cycleType);
        report.setCycleRange(startDate + " ~ " + endDate);
        report.setOriginalData(originalData);

        if (reportContent == null || reportContent.trim().isEmpty()) {
            report.setReportContent("AI报告生成失败，请检查AI服务配置或稍后重试。\n\n已收集数据摘要：\n" + originalData);
        } else {
            report.setReportContent(reportContent);
        }

        report.setCreateTime(LocalDateTime.now());
        this.save(report);

        return report;
    }

    @Override
    public Page<AiPsychologicalReport> pageByUser(Long userId, Integer page, Integer size) {
        Page<AiPsychologicalReport> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<AiPsychologicalReport> wrapper = new LambdaQueryWrapper<AiPsychologicalReport>()
                .eq(AiPsychologicalReport::getUserId, userId)
                .orderByDesc(AiPsychologicalReport::getCreateTime);
        return this.page(pageParam, wrapper);
    }
}
