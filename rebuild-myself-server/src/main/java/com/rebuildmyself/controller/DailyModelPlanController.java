package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.DailyModelPlan;
import com.rebuildmyself.service.DailyModelPlanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/plan")
public class DailyModelPlanController {

    @Autowired
    private DailyModelPlanService dailyModelPlanService;

    @GetMapping("/date/{date}")
    public Result<?> listByUserAndDate(@PathVariable String date,
                                       @RequestAttribute("userId") Long userId) {
        return Result.ok(dailyModelPlanService.listByUserAndDate(userId, LocalDate.parse(date)));
    }

    @PostMapping("/generate")
    public Result<?> generateTodayPlan(@RequestAttribute("userId") Long userId) {
        return Result.ok(dailyModelPlanService.generateTodayPlan(userId));
    }

    @PostMapping
    public Result<?> save(@RequestBody DailyModelPlan plan,
                          @RequestAttribute("userId") Long userId) {
        plan.setUserId(userId);
        dailyModelPlanService.save(plan);
        return Result.ok();
    }

    @PutMapping
    public Result<?> update(@RequestBody DailyModelPlan plan) {
        dailyModelPlanService.updateById(plan);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> remove(@PathVariable Long id) {
        dailyModelPlanService.removeById(id);
        return Result.ok();
    }

    @DeleteMapping("/date/{date}")
    public Result<?> removeByDate(@PathVariable String date,
                                  @RequestAttribute("userId") Long userId) {
        int count = dailyModelPlanService.deleteByUserAndDate(userId, LocalDate.parse(date));
        return Result.ok(Map.of("deleted", count));
    }

    @PutMapping("/note")
    public Result<?> updateNote(@RequestBody Map<String, String> body,
                                @RequestAttribute("userId") Long userId) {
        String planDate = body.get("planDate");
        String timePeriod = body.get("timePeriod");
        String actualNote = body.get("actualNote");
        if (planDate == null || timePeriod == null) {
            return Result.fail("planDate and timePeriod are required");
        }
        DailyModelPlan updated = dailyModelPlanService.updateNote(
                userId, LocalDate.parse(planDate), timePeriod, actualNote);
        return updated != null ? Result.ok(updated) : Result.fail(404, "Plan not found");
    }

    @PutMapping("/date/{date}")
    public Result<?> replaceByDate(@PathVariable String date,
                                   @RequestBody List<DailyModelPlan> plans,
                                   @RequestAttribute("userId") Long userId) {
        dailyModelPlanService.replaceByUserAndDate(userId, LocalDate.parse(date), plans);
        return Result.ok();
    }
}
