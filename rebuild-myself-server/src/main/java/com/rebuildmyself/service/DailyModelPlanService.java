package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.DailyModelPlan;

import java.time.LocalDate;
import java.util.List;

public interface DailyModelPlanService extends IService<DailyModelPlan> {

    List<DailyModelPlan> listByUserAndDate(Long userId, LocalDate date);

    List<DailyModelPlan> generateTodayPlan(Long userId);

    DailyModelPlan updateNote(Long userId, LocalDate planDate, String timePeriod, String actualNote);
}
