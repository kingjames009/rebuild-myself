package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.EliteHabitLib;
import com.rebuildmyself.service.EliteHabitLibService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/elite-habit")
public class EliteHabitController {

    @Autowired
    private EliteHabitLibService eliteHabitLibService;

    @GetMapping("/list")
    public Result<?> listByCategory(@RequestParam(required = false) Integer category) {
        return Result.ok(eliteHabitLibService.listByCategory(category));
    }

    @PostMapping("/generate")
    public Result<?> generate() {
        List<EliteHabitLib> habits = eliteHabitLibService.generateHabits();
        if (habits.isEmpty()) {
            return Result.fail(500, "AI生成失败，请检查AI API配置");
        }
        return Result.ok(habits);
    }

    @PostMapping
    public Result<?> save(@RequestBody EliteHabitLib habit) {
        eliteHabitLibService.save(habit);
        return Result.ok();
    }

    @PutMapping
    public Result<?> update(@RequestBody EliteHabitLib habit) {
        eliteHabitLibService.updateById(habit);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> remove(@PathVariable Long id) {
        eliteHabitLibService.removeById(id);
        return Result.ok();
    }
}
