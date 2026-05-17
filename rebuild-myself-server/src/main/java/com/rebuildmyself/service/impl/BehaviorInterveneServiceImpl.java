package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.BehaviorIntervene;
import com.rebuildmyself.mapper.BehaviorInterveneMapper;
import com.rebuildmyself.service.BehaviorInterveneService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class BehaviorInterveneServiceImpl extends ServiceImpl<BehaviorInterveneMapper, BehaviorIntervene> implements BehaviorInterveneService {

    @Override
    public Map<String, Object> getStats(Long userId, LocalDate start, LocalDate end) {
        List<BehaviorIntervene> records = list(new LambdaQueryWrapper<BehaviorIntervene>()
                .eq(BehaviorIntervene::getUserId, userId)
                .ge(start != null, BehaviorIntervene::getInterveneTime, start.atStartOfDay())
                .le(end != null, BehaviorIntervene::getInterveneTime, end.plusDays(1).atStartOfDay()));

        long total = records.size();
        long successCount = records.stream().filter(r -> r.getIsSuccess() != null && r.getIsSuccess() == 1).count();
        double successRate = total > 0 ? (double) successCount / total * 100 : 0.0;

        Map<String, Object> stats = new HashMap<>();
        stats.put("total", total);
        stats.put("successCount", successCount);
        stats.put("successRate", Math.round(successRate * 100.0) / 100.0);
        return stats;
    }

    @Override
    public List<BehaviorIntervene> listByUserAndType(Long userId, Integer interveneType) {
        LambdaQueryWrapper<BehaviorIntervene> wrapper = new LambdaQueryWrapper<BehaviorIntervene>()
                .eq(BehaviorIntervene::getUserId, userId);
        if (interveneType != null) {
            wrapper.eq(BehaviorIntervene::getInterveneType, interveneType);
        }
        wrapper.orderByDesc(BehaviorIntervene::getInterveneTime);
        return list(wrapper);
    }
}
