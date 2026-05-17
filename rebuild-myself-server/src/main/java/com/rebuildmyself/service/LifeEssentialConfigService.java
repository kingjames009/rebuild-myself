package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.LifeEssentialConfig;

import java.util.List;

public interface LifeEssentialConfigService extends IService<LifeEssentialConfig> {
    List<LifeEssentialConfig> listByUser(Long userId);
    void toggleEnabled(Long id, Integer enabled);
    void resetToDefaults(Long userId);
}
