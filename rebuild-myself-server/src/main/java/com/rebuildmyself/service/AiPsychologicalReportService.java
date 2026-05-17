package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.AiPsychologicalReport;

import java.time.LocalDate;

public interface AiPsychologicalReportService extends IService<AiPsychologicalReport> {

    AiPsychologicalReport generateReport(Long userId, Integer cycleType, LocalDate date);

    Page<AiPsychologicalReport> pageByUser(Long userId, Integer page, Integer size);
}
