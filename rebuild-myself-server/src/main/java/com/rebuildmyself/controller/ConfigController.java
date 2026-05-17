package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.util.HolidayUtil;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/config")
public class ConfigController {

    @GetMapping("/workday-status")
    public Result<Map<String, Object>> isWorkday(@RequestParam(required = false) String date) {
        LocalDate d = (date != null && !date.isEmpty()) ? LocalDate.parse(date) : LocalDate.now();
        return Result.ok(Map.of(
            "date", d.toString(),
            "workday", HolidayUtil.isWorkday(d)
        ));
    }
}
