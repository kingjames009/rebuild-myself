package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.FinanceMentalLog;
import com.rebuildmyself.service.FinanceMentalLogService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/finance")
public class FinanceMentalController {

    private final FinanceMentalLogService financeMentalLogService;

    public FinanceMentalController(FinanceMentalLogService financeMentalLogService) {
        this.financeMentalLogService = financeMentalLogService;
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(financeMentalLogService.pageByUser(userId, page, size));
    }

    @GetMapping("/week-stats")
    public Result<?> getWeekStats(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(financeMentalLogService.getWeekStats(userId));
    }

    @GetMapping("/range")
    public Result<?> listByDateRange(@RequestParam String start,
                                     @RequestParam String end,
                                     HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(financeMentalLogService.listByDateRange(userId, LocalDate.parse(start), LocalDate.parse(end)));
    }

    @PostMapping
    public Result<?> save(@RequestBody FinanceMentalLog record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        financeMentalLogService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> updateById(@RequestBody FinanceMentalLog record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        financeMentalLogService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> removeById(@PathVariable Long id) {
        financeMentalLogService.removeById(id);
        return Result.ok();
    }
}
