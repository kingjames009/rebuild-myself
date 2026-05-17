package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.DailyCompareCheck;
import com.rebuildmyself.service.DailyCompareCheckService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/check")
public class DailyCompareCheckController {

    @Autowired
    private DailyCompareCheckService dailyCompareCheckService;

    @GetMapping("/date/{date}")
    public Result<?> getByUserAndDate(@PathVariable String date,
                                      @RequestAttribute("userId") Long userId) {
        return Result.ok(dailyCompareCheckService.getByUserAndDate(userId, LocalDate.parse(date)));
    }

    @GetMapping("/week-stats")
    public Result<?> getWeekCompareStats(@RequestAttribute("userId") Long userId) {
        return Result.ok(dailyCompareCheckService.getWeekCompareStats(userId));
    }

    @PostMapping
    public Result<?> save(@RequestBody DailyCompareCheck check,
                          @RequestAttribute("userId") Long userId) {
        check.setUserId(userId);
        dailyCompareCheckService.save(check);
        return Result.ok();
    }

    @PutMapping
    public Result<?> update(@RequestBody DailyCompareCheck check) {
        dailyCompareCheckService.updateById(check);
        return Result.ok();
    }
}
