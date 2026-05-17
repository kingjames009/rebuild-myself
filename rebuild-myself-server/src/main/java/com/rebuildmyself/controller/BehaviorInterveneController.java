package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.BehaviorIntervene;
import com.rebuildmyself.service.BehaviorInterveneService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/behavior")
public class BehaviorInterveneController {

    private final BehaviorInterveneService behaviorInterveneService;

    public BehaviorInterveneController(BehaviorInterveneService behaviorInterveneService) {
        this.behaviorInterveneService = behaviorInterveneService;
    }

    @GetMapping("/stats")
    public Result<Map<String, Object>> stats(@RequestParam String start,
                                             @RequestParam String end,
                                             HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        LocalDate startDate = LocalDate.parse(start);
        LocalDate endDate = LocalDate.parse(end);
        return Result.ok(behaviorInterveneService.getStats(userId, startDate, endDate));
    }

    @GetMapping("/list")
    public Result<List<BehaviorIntervene>> list(@RequestParam(required = false) Integer type,
                                                HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(behaviorInterveneService.listByUserAndType(userId, type));
    }

    @PostMapping
    public Result<Void> save(@RequestBody BehaviorIntervene behaviorIntervene, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        behaviorIntervene.setUserId(userId);
        behaviorInterveneService.save(behaviorIntervene);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable Long id) {
        behaviorInterveneService.removeById(id);
        return Result.ok();
    }
}
