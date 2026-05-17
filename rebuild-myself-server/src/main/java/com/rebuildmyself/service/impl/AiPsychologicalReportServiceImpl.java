package com.rebuildmyself.service.impl;

import cn.hutool.json.JSONUtil;
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
    public AiPsychologicalReport generateReport(Long userId, Integer cycleType) {
        // Calculate date range based on cycleType
        LocalDate today = LocalDate.now();
        LocalDate startDate;
        LocalDate endDate;

        switch (cycleType) {
            case 1: // 今天
                startDate = today;
                endDate = today;
                break;
            case 2: // 本周
                startDate = today.with(DayOfWeek.MONDAY);
                endDate = today.with(DayOfWeek.SUNDAY);
                break;
            case 3: // 本月
                startDate = today.withDayOfMonth(1);
                endDate = today.withDayOfMonth(today.lengthOfMonth());
                break;
            case 4: // 本年
                startDate = today.withDayOfYear(1);
                endDate = today.withDayOfYear(today.lengthOfYear());
                break;
            default:
                startDate = today;
                endDate = today;
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

        // === Build comprehensive JSON string ===
        cn.hutool.json.JSONObject json = JSONUtil.createObj();
        json.set("dailyRecords", JSONUtil.parseArray(dailyRecords));
        json.set("behaviorIntervenes", JSONUtil.parseArray(behaviorIntervenes));
        json.set("financeMentalLogs", JSONUtil.parseArray(financeMentalLogs));
        json.set("studyTrackRecords", JSONUtil.parseArray(studyTrackRecords));
        json.set("sidelinePlans", JSONUtil.parseArray(sidelinePlans));
        json.set("emptyMoodLogs", JSONUtil.parseArray(emptyMoodLogs));
        json.set("bookReadRecords", JSONUtil.parseArray(bookReadRecords));
        json.set("lifeLeisureRecords", JSONUtil.parseArray(lifeLeisureRecords));
        json.set("dailyCompareChecks", JSONUtil.parseArray(dailyCompareChecks));
        json.set("dailyModelPlans", JSONUtil.parseArray(dailyModelPlans));

        String originalData = json.toString();

        // === Call AI via AiUtil ===
        String systemPrompt = "你是一位资深认知行为心理学顾问。请基于以下用户的全维度数据，生成一份专业的心理行为复盘报告。报告包含四部分：1.数据总结 2.问题诊断 3.根源溯源 4.定制优化方案。特别注意 dailyModelPlans 数据中的 planContent（原计划）和 actualNote（实际状况记录）的对比，分析执行偏差和逃避模式。";
        String reportContent = aiUtil.generateReport(systemPrompt, originalData);

        // === Save report ===
        AiPsychologicalReport report = new AiPsychologicalReport();
        report.setUserId(userId);
        report.setCycleType(cycleType);
        report.setCycleRange(startDate + " ~ " + endDate);
        report.setOriginalData(originalData);
        report.setReportContent(reportContent);
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
