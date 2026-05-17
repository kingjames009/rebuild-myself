package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.DailyRecord;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public interface DailyRecordService extends IService<DailyRecord> {

    Page<DailyRecord> pageByUser(Long userId, Integer page, Integer size, Integer recordType);

    List<Map<String, Object>> statsByType(Long userId, LocalDate start, LocalDate end);

    List<DailyRecord> listByUserAndDate(Long userId, LocalDate date);
}
