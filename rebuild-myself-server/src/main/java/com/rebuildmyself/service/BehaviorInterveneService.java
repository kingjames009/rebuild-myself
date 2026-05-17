package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.BehaviorIntervene;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public interface BehaviorInterveneService extends IService<BehaviorIntervene> {

    Map<String, Object> getStats(Long userId, LocalDate start, LocalDate end);

    List<BehaviorIntervene> listByUserAndType(Long userId, Integer interveneType);
}
