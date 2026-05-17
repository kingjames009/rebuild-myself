package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.LifeLeisureRecord;
import com.rebuildmyself.mapper.LifeLeisureRecordMapper;
import com.rebuildmyself.service.LifeLeisureRecordService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class LifeLeisureRecordServiceImpl extends ServiceImpl<LifeLeisureRecordMapper, LifeLeisureRecord> implements LifeLeisureRecordService {

    @Override
    public Page<LifeLeisureRecord> pageByUser(Long userId, Integer page, Integer size) {
        Page<LifeLeisureRecord> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<LifeLeisureRecord> wrapper = new LambdaQueryWrapper<LifeLeisureRecord>()
                .eq(LifeLeisureRecord::getUserId, userId)
                .orderByDesc(LifeLeisureRecord::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getHappyScoreTrend(Long userId, LocalDate start, LocalDate end) {
        List<LifeLeisureRecord> records = this.lambdaQuery()
                .eq(LifeLeisureRecord::getUserId, userId)
                .ge(start != null, LifeLeisureRecord::getRecordDate, start)
                .le(end != null, LifeLeisureRecord::getRecordDate, end)
                .orderByAsc(LifeLeisureRecord::getRecordDate)
                .list();

        Map<LocalDate, Double> trend = records.stream()
                .filter(r -> r.getHappyScore() != null)
                .collect(Collectors.groupingBy(
                        LifeLeisureRecord::getRecordDate,
                        Collectors.averagingInt(LifeLeisureRecord::getHappyScore)
                ));

        Map<String, Object> result = new HashMap<>();
        result.put("trend", trend);
        result.put("total", records.size());
        return result;
    }
}
