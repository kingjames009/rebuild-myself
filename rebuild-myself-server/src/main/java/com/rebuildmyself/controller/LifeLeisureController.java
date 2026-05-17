package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.LifeLeisureRecord;
import com.rebuildmyself.service.LifeLeisureRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/leisure")
public class LifeLeisureController {

    @Autowired
    private LifeLeisureRecordService lifeLeisureRecordService;

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          @RequestAttribute("userId") Long userId) {
        return Result.ok(lifeLeisureRecordService.pageByUser(userId, page, size));
    }

    @GetMapping("/trend")
    public Result<?> getHappyScoreTrend(@RequestParam String start,
                                        @RequestParam String end,
                                        @RequestAttribute("userId") Long userId) {
        return Result.ok(lifeLeisureRecordService.getHappyScoreTrend(
                userId, LocalDate.parse(start), LocalDate.parse(end)));
    }

    @PostMapping
    public Result<?> save(@RequestBody LifeLeisureRecord record,
                          @RequestAttribute("userId") Long userId) {
        record.setUserId(userId);
        lifeLeisureRecordService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> update(@RequestBody LifeLeisureRecord record) {
        lifeLeisureRecordService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> remove(@PathVariable Long id) {
        lifeLeisureRecordService.removeById(id);
        return Result.ok();
    }
}
