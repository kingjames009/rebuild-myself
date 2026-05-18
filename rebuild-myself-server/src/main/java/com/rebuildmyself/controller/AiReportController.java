package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.AiPsychologicalReport;
import com.rebuildmyself.service.AiPsychologicalReportService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/report")
public class AiReportController {

    @Autowired
    private AiPsychologicalReportService aiPsychologicalReportService;

    @PostMapping("/generate")
    public Result<?> generateReport(@RequestBody Map<String, Object> body,
                                    @RequestAttribute("userId") Long userId) {
        int cycleType = body.get("cycleType") instanceof Integer i ? i : 1;
        String dateStr = body.get("date") instanceof String s && !s.isEmpty() ? s : null;
        LocalDate date = dateStr != null ? LocalDate.parse(dateStr) : null;
        log.info("Report generate REQUEST — userId={}, cycleType={}, date={}", userId, cycleType, dateStr);
        long start = System.currentTimeMillis();
        AiPsychologicalReport report = aiPsychologicalReportService.generateReport(userId, cycleType, date);
        long elapsed = System.currentTimeMillis() - start;
        log.info("Report generate DONE — userId={}, reportId={}, contentLen={}, elapsed={}ms",
                userId, report.getReportId(),
                report.getReportContent() != null ? report.getReportContent().length() : 0,
                elapsed);
        return Result.ok(report);
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          @RequestAttribute("userId") Long userId) {
        return Result.ok(aiPsychologicalReportService.pageByUser(userId, page, size));
    }

    @GetMapping("/{id}")
    public Result<?> getById(@PathVariable Long id) {
        return Result.ok(aiPsychologicalReportService.getById(id));
    }

    @DeleteMapping("/{id}")
    public Result<?> remove(@PathVariable Long id) {
        aiPsychologicalReportService.removeById(id);
        return Result.ok();
    }
}
