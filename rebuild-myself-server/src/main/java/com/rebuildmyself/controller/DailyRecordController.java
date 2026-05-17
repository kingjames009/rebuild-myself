package com.rebuildmyself.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.DailyRecord;
import com.rebuildmyself.service.DailyRecordService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/record")
public class DailyRecordController {

    private final DailyRecordService dailyRecordService;

    public DailyRecordController(DailyRecordService dailyRecordService) {
        this.dailyRecordService = dailyRecordService;
    }

    @GetMapping("/page")
    public Result<Page<DailyRecord>> page(@RequestParam(defaultValue = "1") Integer page,
                                          @RequestParam(defaultValue = "10") Integer size,
                                          @RequestParam(required = false) Integer type,
                                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(dailyRecordService.pageByUser(userId, page, size, type));
    }

    @GetMapping("/stats")
    public Result<List<Map<String, Object>>> stats(@RequestParam String start,
                                                   @RequestParam String end,
                                                   HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        LocalDate startDate = LocalDate.parse(start);
        LocalDate endDate = LocalDate.parse(end);
        return Result.ok(dailyRecordService.statsByType(userId, startDate, endDate));
    }

    @GetMapping("/date/{date}")
    public Result<List<DailyRecord>> listByDate(@PathVariable String date,
                                                HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        LocalDate localDate = LocalDate.parse(date);
        return Result.ok(dailyRecordService.listByUserAndDate(userId, localDate));
    }

    @PostMapping
    public Result<Void> save(@RequestBody DailyRecord dailyRecord, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        dailyRecord.setUserId(userId);
        dailyRecordService.save(dailyRecord);
        return Result.ok();
    }

    @PutMapping
    public Result<Void> update(@RequestBody DailyRecord dailyRecord) {
        dailyRecordService.updateById(dailyRecord);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable Long id) {
        dailyRecordService.removeById(id);
        return Result.ok();
    }
}
