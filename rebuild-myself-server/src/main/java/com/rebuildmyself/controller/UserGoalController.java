package com.rebuildmyself.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.UserGoal;
import com.rebuildmyself.service.UserGoalService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/goal")
public class UserGoalController {

    private final UserGoalService userGoalService;

    public UserGoalController(UserGoalService userGoalService) {
        this.userGoalService = userGoalService;
    }

    @GetMapping("/list")
    public Result<List<UserGoal>> list(@RequestParam(required = false, defaultValue = "1") Integer level,
                                       HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(userGoalService.listByUserAndLevel(userId, level));
    }

    @GetMapping("/page")
    public Result<Page<UserGoal>> page(@RequestParam(defaultValue = "1") Integer page,
                                       @RequestParam(defaultValue = "10") Integer size,
                                       HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(userGoalService.pageByUser(userId, page, size));
    }

    @PostMapping
    public Result<Void> save(@RequestBody UserGoal userGoal, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        userGoal.setUserId(userId);
        userGoalService.save(userGoal);
        return Result.ok();
    }

    @PutMapping
    public Result<Void> update(@RequestBody UserGoal userGoal) {
        userGoalService.updateById(userGoal);
        return Result.ok();
    }

    @PutMapping("/progress")
    public Result<Void> updateProgress(@RequestBody Map<String, Object> params) {
        Long goalId = Long.valueOf(params.get("goalId").toString());
        Integer progress = Integer.valueOf(params.get("progress").toString());
        userGoalService.updateProgress(goalId, progress);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable Long id) {
        userGoalService.removeById(id);
        return Result.ok();
    }
}
