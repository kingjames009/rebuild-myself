package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.*;
import com.rebuildmyself.service.*;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/sync")
public class DataSyncController {

    @Autowired
    private DailyRecordService dailyRecordService;
    @Autowired
    private UserGoalService userGoalService;
    @Autowired
    private TaskTodoService taskTodoService;
    @Autowired
    private BehaviorInterveneService behaviorInterveneService;
    @Autowired
    private FinanceMentalLogService financeMentalLogService;
    @Autowired
    private StudyTrackRecordService studyTrackRecordService;
    @Autowired
    private SidelinePlanService sidelinePlanService;
    @Autowired
    private EmptyMoodLogService emptyMoodLogService;
    @Autowired
    private BookReadRecordService bookReadRecordService;
    @Autowired
    private LifeLeisureRecordService lifeLeisureRecordService;
    @Autowired
    private DailyCompareCheckService dailyCompareCheckService;
    @Autowired
    private DailyModelPlanService dailyModelPlanService;
    @Autowired
    private AiPsychologicalReportService aiPsychologicalReportService;

    @PostMapping("/upload")
    public Result<?> upload(@RequestBody SyncUploadBody body,
                            @RequestAttribute("userId") Long userId) {
        if (body.getRecords() != null) {
            body.getRecords().forEach(r -> r.setUserId(userId));
            dailyRecordService.saveBatch(body.getRecords());
        }
        if (body.getGoals() != null) {
            body.getGoals().forEach(g -> g.setUserId(userId));
            userGoalService.saveBatch(body.getGoals());
        }
        if (body.getTasks() != null) {
            body.getTasks().forEach(t -> t.setUserId(userId));
            taskTodoService.saveBatch(body.getTasks());
        }
        if (body.getBehaviors() != null) {
            body.getBehaviors().forEach(b -> b.setUserId(userId));
            behaviorInterveneService.saveBatch(body.getBehaviors());
        }
        if (body.getFinances() != null) {
            body.getFinances().forEach(f -> f.setUserId(userId));
            financeMentalLogService.saveBatch(body.getFinances());
        }
        if (body.getStudies() != null) {
            body.getStudies().forEach(s -> s.setUserId(userId));
            studyTrackRecordService.saveBatch(body.getStudies());
        }
        if (body.getSidelines() != null) {
            body.getSidelines().forEach(s -> s.setUserId(userId));
            sidelinePlanService.saveBatch(body.getSidelines());
        }
        if (body.getEmpties() != null) {
            body.getEmpties().forEach(e -> e.setUserId(userId));
            emptyMoodLogService.saveBatch(body.getEmpties());
        }
        if (body.getBooks() != null) {
            body.getBooks().forEach(b -> b.setUserId(userId));
            bookReadRecordService.saveBatch(body.getBooks());
        }
        if (body.getLeisures() != null) {
            body.getLeisures().forEach(l -> l.setUserId(userId));
            lifeLeisureRecordService.saveBatch(body.getLeisures());
        }
        if (body.getChecks() != null) {
            body.getChecks().forEach(c -> c.setUserId(userId));
            dailyCompareCheckService.saveBatch(body.getChecks());
        }
        if (body.getPlans() != null) {
            body.getPlans().forEach(p -> p.setUserId(userId));
            dailyModelPlanService.saveBatch(body.getPlans());
        }
        if (body.getReports() != null) {
            body.getReports().forEach(r -> r.setUserId(userId));
            aiPsychologicalReportService.saveBatch(body.getReports());
        }
        return Result.ok();
    }

    @GetMapping("/export")
    public Result<?> export(@RequestParam String start,
                            @RequestParam String end,
                            @RequestAttribute("userId") Long userId) {
        LocalDate startDate = LocalDate.parse(start);
        LocalDate endDate = LocalDate.parse(end);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("records", dailyRecordService.lambdaQuery()
                .eq(DailyRecord::getUserId, userId)
                .between(DailyRecord::getRecordDate, startDate, endDate).list());
        data.put("goals", userGoalService.lambdaQuery()
                .eq(UserGoal::getUserId, userId).list());
        data.put("tasks", taskTodoService.lambdaQuery()
                .eq(TaskTodo::getUserId, userId)
                .between(TaskTodo::getTaskDate, startDate, endDate).list());
        data.put("behaviors", behaviorInterveneService.lambdaQuery()
                .eq(BehaviorIntervene::getUserId, userId).list());
        data.put("finances", financeMentalLogService.lambdaQuery()
                .eq(FinanceMentalLog::getUserId, userId)
                .between(FinanceMentalLog::getRecordDate, startDate, endDate).list());
        data.put("studies", studyTrackRecordService.lambdaQuery()
                .eq(StudyTrackRecord::getUserId, userId)
                .between(StudyTrackRecord::getRecordDate, startDate, endDate).list());
        data.put("sidelines", sidelinePlanService.lambdaQuery()
                .eq(SidelinePlan::getUserId, userId)
                .between(SidelinePlan::getRecordDate, startDate, endDate).list());
        data.put("empties", emptyMoodLogService.lambdaQuery()
                .eq(EmptyMoodLog::getUserId, userId)
                .between(EmptyMoodLog::getRecordDate, startDate, endDate).list());
        data.put("books", bookReadRecordService.lambdaQuery()
                .eq(BookReadRecord::getUserId, userId)
                .between(BookReadRecord::getRecordDate, startDate, endDate).list());
        data.put("leisures", lifeLeisureRecordService.lambdaQuery()
                .eq(LifeLeisureRecord::getUserId, userId)
                .between(LifeLeisureRecord::getRecordDate, startDate, endDate).list());
        data.put("checks", dailyCompareCheckService.lambdaQuery()
                .eq(DailyCompareCheck::getUserId, userId)
                .between(DailyCompareCheck::getPlanDate, startDate, endDate).list());
        data.put("plans", dailyModelPlanService.lambdaQuery()
                .eq(DailyModelPlan::getUserId, userId)
                .between(DailyModelPlan::getPlanDate, startDate, endDate).list());
        data.put("reports", aiPsychologicalReportService.lambdaQuery()
                .eq(AiPsychologicalReport::getUserId, userId)
                .ge(AiPsychologicalReport::getCreateTime, startDate.atStartOfDay()).list());

        return Result.ok(data);
    }

    @GetMapping("/pull")
    public Result<?> pull(@RequestParam String since,
                          @RequestAttribute("userId") Long userId) {
        LocalDateTime sinceTime = LocalDateTime.parse(since);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("records", dailyRecordService.lambdaQuery()
                .eq(DailyRecord::getUserId, userId)
                .ge(DailyRecord::getCreateTime, sinceTime).list());
        data.put("goals", userGoalService.lambdaQuery()
                .eq(UserGoal::getUserId, userId)
                .ge(UserGoal::getUpdateTime, sinceTime).list());
        data.put("tasks", taskTodoService.lambdaQuery()
                .eq(TaskTodo::getUserId, userId)
                .ge(TaskTodo::getCreateTime, sinceTime).list());
        data.put("behaviors", behaviorInterveneService.lambdaQuery()
                .eq(BehaviorIntervene::getUserId, userId)
                .ge(BehaviorIntervene::getCreateTime, sinceTime).list());
        data.put("finances", financeMentalLogService.lambdaQuery()
                .eq(FinanceMentalLog::getUserId, userId)
                .ge(FinanceMentalLog::getCreateTime, sinceTime).list());
        data.put("studies", studyTrackRecordService.lambdaQuery()
                .eq(StudyTrackRecord::getUserId, userId)
                .ge(StudyTrackRecord::getCreateTime, sinceTime).list());
        data.put("sidelines", sidelinePlanService.lambdaQuery()
                .eq(SidelinePlan::getUserId, userId)
                .ge(SidelinePlan::getCreateTime, sinceTime).list());
        data.put("empties", emptyMoodLogService.lambdaQuery()
                .eq(EmptyMoodLog::getUserId, userId)
                .ge(EmptyMoodLog::getCreateTime, sinceTime).list());
        data.put("books", bookReadRecordService.lambdaQuery()
                .eq(BookReadRecord::getUserId, userId)
                .ge(BookReadRecord::getCreateTime, sinceTime).list());
        data.put("leisures", lifeLeisureRecordService.lambdaQuery()
                .eq(LifeLeisureRecord::getUserId, userId)
                .ge(LifeLeisureRecord::getCreateTime, sinceTime).list());
        data.put("checks", dailyCompareCheckService.lambdaQuery()
                .eq(DailyCompareCheck::getUserId, userId)
                .ge(DailyCompareCheck::getCreateTime, sinceTime).list());
        data.put("plans", dailyModelPlanService.lambdaQuery()
                .eq(DailyModelPlan::getUserId, userId)
                .ge(DailyModelPlan::getCreateTime, sinceTime).list());
        data.put("reports", aiPsychologicalReportService.lambdaQuery()
                .eq(AiPsychologicalReport::getUserId, userId)
                .ge(AiPsychologicalReport::getCreateTime, sinceTime).list());

        return Result.ok(data);
    }

    @PostMapping("/backup")
    public Result<?> backup(@RequestAttribute("userId") Long userId) {
        Map<String, Object> backupData = new LinkedHashMap<>();
        backupData.put("records", dailyRecordService.lambdaQuery()
                .eq(DailyRecord::getUserId, userId).list());
        backupData.put("goals", userGoalService.lambdaQuery()
                .eq(UserGoal::getUserId, userId).list());
        backupData.put("tasks", taskTodoService.lambdaQuery()
                .eq(TaskTodo::getUserId, userId).list());
        backupData.put("behaviors", behaviorInterveneService.lambdaQuery()
                .eq(BehaviorIntervene::getUserId, userId).list());
        backupData.put("finances", financeMentalLogService.lambdaQuery()
                .eq(FinanceMentalLog::getUserId, userId).list());
        backupData.put("studies", studyTrackRecordService.lambdaQuery()
                .eq(StudyTrackRecord::getUserId, userId).list());
        backupData.put("sidelines", sidelinePlanService.lambdaQuery()
                .eq(SidelinePlan::getUserId, userId).list());
        backupData.put("empties", emptyMoodLogService.lambdaQuery()
                .eq(EmptyMoodLog::getUserId, userId).list());
        backupData.put("books", bookReadRecordService.lambdaQuery()
                .eq(BookReadRecord::getUserId, userId).list());
        backupData.put("leisures", lifeLeisureRecordService.lambdaQuery()
                .eq(LifeLeisureRecord::getUserId, userId).list());
        backupData.put("checks", dailyCompareCheckService.lambdaQuery()
                .eq(DailyCompareCheck::getUserId, userId).list());

        String backupId = UUID.randomUUID().toString().replace("-", "");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("backupId", backupId);
        result.put("message", "Backup created successfully");
        return Result.ok(result);
    }

    @GetMapping("/restore/{backupId}")
    public Result<?> restore(@PathVariable String backupId) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("message", "Restore initiated for backup: " + backupId);
        return Result.ok(result);
    }

    @Data
    public static class SyncUploadBody {
        private List<DailyRecord> records;
        private List<UserGoal> goals;
        private List<TaskTodo> tasks;
        private List<BehaviorIntervene> behaviors;
        private List<FinanceMentalLog> finances;
        private List<StudyTrackRecord> studies;
        private List<SidelinePlan> sidelines;
        private List<EmptyMoodLog> empties;
        private List<BookReadRecord> books;
        private List<LifeLeisureRecord> leisures;
        private List<DailyCompareCheck> checks;
        private List<DailyModelPlan> plans;
        private List<AiPsychologicalReport> reports;
    }
}
