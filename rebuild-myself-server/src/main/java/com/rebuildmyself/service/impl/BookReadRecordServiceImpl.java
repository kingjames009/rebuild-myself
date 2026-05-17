package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.BookReadRecord;
import com.rebuildmyself.mapper.BookReadRecordMapper;
import com.rebuildmyself.service.BookReadRecordService;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class BookReadRecordServiceImpl extends ServiceImpl<BookReadRecordMapper, BookReadRecord> implements BookReadRecordService {

    @Override
    public Page<BookReadRecord> pageByUser(Long userId, Integer page, Integer size, Integer bookType) {
        Page<BookReadRecord> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<BookReadRecord> wrapper = new LambdaQueryWrapper<BookReadRecord>()
                .eq(BookReadRecord::getUserId, userId);
        if (bookType != null) {
            wrapper.eq(BookReadRecord::getBookType, bookType);
        }
        wrapper.orderByDesc(BookReadRecord::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getReadingStats(Long userId) {
        List<BookReadRecord> list = this.lambdaQuery()
                .eq(BookReadRecord::getUserId, userId)
                .list();

        Map<Integer, List<BookReadRecord>> grouped = list.stream()
                .collect(Collectors.groupingBy(BookReadRecord::getBookType));

        Map<String, Object> result = new HashMap<>();
        Map<String, Object> statsByType = new HashMap<>();

        for (Map.Entry<Integer, List<BookReadRecord>> entry : grouped.entrySet()) {
            List<BookReadRecord> records = entry.getValue();
            Map<String, Object> stat = new HashMap<>();
            stat.put("totalReadMinutes", records.stream()
                    .filter(r -> r.getReadMinutes() != null)
                    .mapToInt(BookReadRecord::getReadMinutes)
                    .sum());
            stat.put("avgProgress", records.stream()
                    .filter(r -> r.getReadProgress() != null)
                    .collect(Collectors.averagingInt(BookReadRecord::getReadProgress)));
            stat.put("recordCount", records.size());
            statsByType.put(String.valueOf(entry.getKey()), stat);
        }

        result.put("statsByType", statsByType);
        result.put("totalReadMinutes", list.stream()
                .filter(r -> r.getReadMinutes() != null)
                .mapToInt(BookReadRecord::getReadMinutes)
                .sum());
        result.put("overallAvgProgress", list.stream()
                .filter(r -> r.getReadProgress() != null)
                .collect(Collectors.averagingInt(BookReadRecord::getReadProgress)));
        result.put("totalRecords", list.size());
        return result;
    }
}
