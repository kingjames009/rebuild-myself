package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.EmptyMoodLog;

import java.time.LocalDate;
import java.util.Map;

public interface EmptyMoodLogService extends IService<EmptyMoodLog> {

    Page<EmptyMoodLog> pageByUser(Long userId, Integer page, Integer size);

    Map<String, Object> getTrendStats(Long userId, LocalDate start, LocalDate end);
}
