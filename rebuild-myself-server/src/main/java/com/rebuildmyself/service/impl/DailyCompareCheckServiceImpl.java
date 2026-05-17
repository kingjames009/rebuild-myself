package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.DailyCompareCheck;
import com.rebuildmyself.mapper.DailyCompareCheckMapper;
import com.rebuildmyself.service.DailyCompareCheckService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class DailyCompareCheckServiceImpl extends ServiceImpl<DailyCompareCheckMapper, DailyCompareCheck> implements DailyCompareCheckService {

    @Override
    public DailyCompareCheck getByUserAndDate(Long userId, LocalDate date) {
        LambdaQueryWrapper<DailyCompareCheck> wrapper = new LambdaQueryWrapper<DailyCompareCheck>()
                .eq(DailyCompareCheck::getUserId, userId)
                .eq(DailyCompareCheck::getPlanDate, date);
        return this.getOne(wrapper);
    }

    @Override
    public Map<String, Object> getWeekCompareStats(Long userId) {
        LocalDate today = LocalDate.now();
        LocalDate sevenDaysAgo = today.minusDays(6);

        List<DailyCompareCheck> records = this.lambdaQuery()
                .eq(DailyCompareCheck::getUserId, userId)
                .ge(DailyCompareCheck::getPlanDate, sevenDaysAgo)
                .le(DailyCompareCheck::getPlanDate, today)
                .list();

        double avgProgress = records.stream()
                .filter(r -> r.getProgressScore() != null)
                .mapToInt(DailyCompareCheck::getProgressScore)
                .average()
                .orElse(0.0);

        List<String> deviationPatterns = records.stream()
                .filter(r -> r.getDeviationContent() != null && !r.getDeviationContent().isEmpty())
                .map(DailyCompareCheck::getDeviationContent)
                .collect(Collectors.toList());

        Map<String, Object> result = new HashMap<>();
        result.put("avgProgressScore", Math.round(avgProgress * 100.0) / 100.0);
        result.put("totalDays", records.size());
        result.put("deviationPatterns", deviationPatterns);
        return result;
    }
}
