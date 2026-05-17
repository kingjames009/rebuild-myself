package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.EmptyMoodLog;
import com.rebuildmyself.service.EmptyMoodLogService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/empty")
public class EmptyMoodController {

    private final EmptyMoodLogService emptyMoodLogService;

    public EmptyMoodController(EmptyMoodLogService emptyMoodLogService) {
        this.emptyMoodLogService = emptyMoodLogService;
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(emptyMoodLogService.pageByUser(userId, page, size));
    }

    @GetMapping("/trend")
    public Result<?> getTrendStats(@RequestParam String start,
                                   @RequestParam String end,
                                   HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(emptyMoodLogService.getTrendStats(userId, LocalDate.parse(start), LocalDate.parse(end)));
    }

    @PostMapping
    public Result<?> save(@RequestBody EmptyMoodLog record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        emptyMoodLogService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> updateById(@RequestBody EmptyMoodLog record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        emptyMoodLogService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> removeById(@PathVariable Long id) {
        emptyMoodLogService.removeById(id);
        return Result.ok();
    }
}
