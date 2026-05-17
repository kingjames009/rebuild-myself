package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.LifeLeisureRecord;

import java.time.LocalDate;
import java.util.Map;

public interface LifeLeisureRecordService extends IService<LifeLeisureRecord> {

    Page<LifeLeisureRecord> pageByUser(Long userId, Integer page, Integer size);

    Map<String, Object> getHappyScoreTrend(Long userId, LocalDate start, LocalDate end);
}
