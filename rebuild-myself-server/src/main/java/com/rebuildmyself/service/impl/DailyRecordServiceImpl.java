package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.DailyRecord;
import com.rebuildmyself.mapper.DailyRecordMapper;
import com.rebuildmyself.service.DailyRecordService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class DailyRecordServiceImpl extends ServiceImpl<DailyRecordMapper, DailyRecord> implements DailyRecordService {

    @Override
    public Page<DailyRecord> pageByUser(Long userId, Integer page, Integer size, Integer recordType) {
        Page<DailyRecord> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<DailyRecord> wrapper = new LambdaQueryWrapper<DailyRecord>()
                .eq(DailyRecord::getUserId, userId);
        if (recordType != null) {
            wrapper.eq(DailyRecord::getRecordType, recordType);
        }
        wrapper.orderByDesc(DailyRecord::getRecordDate);
        return page(pageParam, wrapper);
    }

    @Override
    public List<Map<String, Object>> statsByType(Long userId, LocalDate start, LocalDate end) {
        List<DailyRecord> records = list(new LambdaQueryWrapper<DailyRecord>()
                .eq(DailyRecord::getUserId, userId)
                .ge(start != null, DailyRecord::getRecordDate, start)
                .le(end != null, DailyRecord::getRecordDate, end));
        return records.stream()
                .collect(Collectors.groupingBy(DailyRecord::getRecordType, Collectors.counting()))
                .entrySet().stream()
                .map(entry -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("recordType", entry.getKey());
                    map.put("count", entry.getValue());
                    return map;
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<DailyRecord> listByUserAndDate(Long userId, LocalDate date) {
        return list(new LambdaQueryWrapper<DailyRecord>()
                .eq(DailyRecord::getUserId, userId)
                .eq(DailyRecord::getRecordDate, date));
    }
}
