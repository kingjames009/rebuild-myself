package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.AiPsychologicalReport;

import java.time.LocalDate;
import java.util.Map;

public interface AiPsychologicalReportService extends IService<AiPsychologicalReport> {

    AiPsychologicalReport generateReport(Long userId, Integer cycleType, LocalDate date, Map<String, Object> morningCheckIn);

    Page<AiPsychologicalReport> pageByUser(Long userId, Integer page, Integer size);
}
