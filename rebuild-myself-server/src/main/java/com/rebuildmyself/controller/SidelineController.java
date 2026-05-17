package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.SidelinePlan;
import com.rebuildmyself.service.SidelinePlanService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/sideline")
public class SidelineController {

    private final SidelinePlanService sidelinePlanService;

    public SidelineController(SidelinePlanService sidelinePlanService) {
        this.sidelinePlanService = sidelinePlanService;
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(sidelinePlanService.pageByUser(userId, page, size));
    }

    @GetMapping("/progress")
    public Result<?> getProgressStats(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(sidelinePlanService.getProgressStats(userId));
    }

    @PostMapping
    public Result<?> save(@RequestBody SidelinePlan record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        sidelinePlanService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> updateById(@RequestBody SidelinePlan record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        sidelinePlanService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> removeById(@PathVariable Long id) {
        sidelinePlanService.removeById(id);
        return Result.ok();
    }
}
