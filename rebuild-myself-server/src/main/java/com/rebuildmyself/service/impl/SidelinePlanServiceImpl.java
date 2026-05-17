package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.SidelinePlan;
import com.rebuildmyself.mapper.SidelinePlanMapper;
import com.rebuildmyself.service.SidelinePlanService;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class SidelinePlanServiceImpl extends ServiceImpl<SidelinePlanMapper, SidelinePlan> implements SidelinePlanService {

    @Override
    public Page<SidelinePlan> pageByUser(Long userId, Integer page, Integer size) {
        Page<SidelinePlan> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<SidelinePlan> wrapper = new LambdaQueryWrapper<SidelinePlan>()
                .eq(SidelinePlan::getUserId, userId)
                .orderByDesc(SidelinePlan::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getProgressStats(Long userId) {
        List<SidelinePlan> list = this.lambdaQuery()
                .eq(SidelinePlan::getUserId, userId)
                .list();

        Map<Integer, List<SidelinePlan>> grouped = list.stream()
                .collect(Collectors.groupingBy(SidelinePlan::getSideType));

        Map<String, Object> result = new HashMap<>();
        Map<String, Object> progressByType = new HashMap<>();

        for (Map.Entry<Integer, List<SidelinePlan>> entry : grouped.entrySet()) {
            List<SidelinePlan> records = entry.getValue();
            Map<String, Object> stat = new HashMap<>();
            stat.put("avgProgress", records.stream()
                    .filter(r -> r.getProgress() != null)
                    .collect(Collectors.averagingInt(SidelinePlan::getProgress)));
            stat.put("recordCount", records.size());
            progressByType.put(String.valueOf(entry.getKey()), stat);
        }

        result.put("progressByType", progressByType);
        result.put("overallAvgProgress", list.stream()
                .filter(r -> r.getProgress() != null)
                .collect(Collectors.averagingInt(SidelinePlan::getProgress)));
        result.put("totalRecords", list.size());
        return result;
    }
}
