package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.EmptyMoodLog;
import com.rebuildmyself.mapper.EmptyMoodLogMapper;
import com.rebuildmyself.service.EmptyMoodLogService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class EmptyMoodLogServiceImpl extends ServiceImpl<EmptyMoodLogMapper, EmptyMoodLog> implements EmptyMoodLogService {

    @Override
    public Page<EmptyMoodLog> pageByUser(Long userId, Integer page, Integer size) {
        Page<EmptyMoodLog> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<EmptyMoodLog> wrapper = new LambdaQueryWrapper<EmptyMoodLog>()
                .eq(EmptyMoodLog::getUserId, userId)
                .orderByDesc(EmptyMoodLog::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getTrendStats(Long userId, LocalDate start, LocalDate end) {
        List<EmptyMoodLog> list = this.lambdaQuery()
                .eq(EmptyMoodLog::getUserId, userId)
                .ge(start != null, EmptyMoodLog::getRecordDate, start)
                .le(end != null, EmptyMoodLog::getRecordDate, end)
                .list();

        Map<LocalDate, List<EmptyMoodLog>> groupedByDay = list.stream()
                .collect(Collectors.groupingBy(EmptyMoodLog::getRecordDate));

        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> dailyTrends = new ArrayList<>();

        for (Map.Entry<LocalDate, List<EmptyMoodLog>> entry : groupedByDay.entrySet()) {
            List<EmptyMoodLog> dayRecords = entry.getValue();
            Map<String, Object> dayStat = new HashMap<>();
            dayStat.put("recordDate", entry.getKey().toString());
            dayStat.put("avgEmptyLevel", dayRecords.stream()
                    .filter(r -> r.getEmptyLevel() != null)
                    .collect(Collectors.averagingInt(EmptyMoodLog::getEmptyLevel)));
            dayStat.put("totalWasteHours", dayRecords.stream()
                    .filter(r -> r.getWasteHours() != null)
                    .mapToDouble(EmptyMoodLog::getWasteHours)
                    .sum());
            dayStat.put("recordCount", dayRecords.size());
            dailyTrends.add(dayStat);
        }

        dailyTrends.sort(Comparator.comparing(m -> m.get("recordDate").toString()));

        result.put("dailyTrends", dailyTrends);
        result.put("totalDays", groupedByDay.size());
        result.put("overallAvgEmptyLevel", list.stream()
                .filter(r -> r.getEmptyLevel() != null)
                .collect(Collectors.averagingInt(EmptyMoodLog::getEmptyLevel)));
        result.put("totalWasteHours", list.stream()
                .filter(r -> r.getWasteHours() != null)
                .mapToDouble(EmptyMoodLog::getWasteHours)
                .sum());
        return result;
    }
}
