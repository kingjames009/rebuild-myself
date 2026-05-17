package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.AiPsychologicalReport;

public interface AiPsychologicalReportService extends IService<AiPsychologicalReport> {

    AiPsychologicalReport generateReport(Long userId, Integer cycleType);

    Page<AiPsychologicalReport> pageByUser(Long userId, Integer page, Integer size);
}
