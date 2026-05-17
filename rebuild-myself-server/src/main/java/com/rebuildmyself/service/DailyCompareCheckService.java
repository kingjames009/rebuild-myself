package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.DailyCompareCheck;

import java.time.LocalDate;
import java.util.Map;

public interface DailyCompareCheckService extends IService<DailyCompareCheck> {

    DailyCompareCheck getByUserAndDate(Long userId, LocalDate date);

    Map<String, Object> getWeekCompareStats(Long userId);
}
