package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.SidelinePlan;

import java.util.Map;

public interface SidelinePlanService extends IService<SidelinePlan> {

    Page<SidelinePlan> pageByUser(Long userId, Integer page, Integer size);

    Map<String, Object> getProgressStats(Long userId);
}
