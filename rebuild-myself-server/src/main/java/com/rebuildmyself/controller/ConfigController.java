package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.ReminderText;
import com.rebuildmyself.mapper.ReminderTextMapper;
import com.rebuildmyself.util.HolidayUtil;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/config")
public class ConfigController {

    private final ReminderTextMapper reminderTextMapper;

    public ConfigController(ReminderTextMapper reminderTextMapper) {
        this.reminderTextMapper = reminderTextMapper;
    }

    @GetMapping("/workday-status")
    public Result<Map<String, Object>> isWorkday(@RequestParam(required = false) String date) {
        LocalDate d = (date != null && !date.isEmpty()) ? LocalDate.parse(date) : LocalDate.now();
        return Result.ok(Map.of(
            "date", d.toString(),
            "workday", HolidayUtil.isWorkday(d)
        ));
    }

    @GetMapping("/reminders")
    public Result<List<ReminderText>> reminders() {
        List<ReminderText> list = reminderTextMapper.selectList(
            new QueryWrapper<ReminderText>().orderByAsc("category", "sort_order"));
        return Result.ok(list);
    }
}
