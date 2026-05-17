package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.FinanceMentalLog;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public interface FinanceMentalLogService extends IService<FinanceMentalLog> {

    Page<FinanceMentalLog> pageByUser(Long userId, Integer page, Integer size);

    Map<String, Object> getWeekStats(Long userId);

    List<FinanceMentalLog> listByDateRange(Long userId, LocalDate start, LocalDate end);
}
