package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.FinanceMentalLog;
import com.rebuildmyself.mapper.FinanceMentalLogMapper;
import com.rebuildmyself.service.FinanceMentalLogService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class FinanceMentalLogServiceImpl extends ServiceImpl<FinanceMentalLogMapper, FinanceMentalLog> implements FinanceMentalLogService {

    @Override
    public Page<FinanceMentalLog> pageByUser(Long userId, Integer page, Integer size) {
        Page<FinanceMentalLog> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<FinanceMentalLog> wrapper = new LambdaQueryWrapper<FinanceMentalLog>()
                .eq(FinanceMentalLog::getUserId, userId)
                .orderByDesc(FinanceMentalLog::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getWeekStats(Long userId) {
        LocalDate sevenDaysAgo = LocalDate.now().minusDays(7);
        LocalDate today = LocalDate.now();

        List<FinanceMentalLog> list = this.lambdaQuery()
                .eq(FinanceMentalLog::getUserId, userId)
                .ge(FinanceMentalLog::getRecordDate, sevenDaysAgo)
                .le(FinanceMentalLog::getRecordDate, today)
                .list();

        Map<String, Object> stats = new HashMap<>();
        stats.put("avgMoneyPressure", list.stream()
                .filter(l -> l.getMoneyPressure() != null)
                .collect(Collectors.averagingInt(FinanceMentalLog::getMoneyPressure)));
        stats.put("sumActionMinutes", list.stream()
                .filter(l -> l.getActionMinutes() != null)
                .mapToInt(FinanceMentalLog::getActionMinutes)
                .sum());
        stats.put("sumGapAmount", list.stream()
                .filter(l -> l.getGapAmount() != null)
                .map(FinanceMentalLog::getGapAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        stats.put("totalRecords", list.size());
        return stats;
    }

    @Override
    public List<FinanceMentalLog> listByDateRange(Long userId, LocalDate start, LocalDate end) {
        LambdaQueryWrapper<FinanceMentalLog> wrapper = new LambdaQueryWrapper<FinanceMentalLog>()
                .eq(FinanceMentalLog::getUserId, userId);
        if (start != null && end != null && start.equals(end)) {
            wrapper.ge(FinanceMentalLog::getRecordDate, start);
        } else if (start != null && end != null) {
            wrapper.between(FinanceMentalLog::getRecordDate, start, end);
        } else if (start != null) {
            wrapper.ge(FinanceMentalLog::getRecordDate, start);
        } else if (end != null) {
            wrapper.le(FinanceMentalLog::getRecordDate, end);
        }
        wrapper.orderByDesc(FinanceMentalLog::getRecordDate);
        return this.list(wrapper);
    }
}
