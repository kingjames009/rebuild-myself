package com.rebuildmyself.service.impl;

import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.LifeEssentialConfig;
import com.rebuildmyself.mapper.LifeEssentialConfigMapper;
import com.rebuildmyself.service.LifeEssentialConfigService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class LifeEssentialConfigServiceImpl extends ServiceImpl<LifeEssentialConfigMapper, LifeEssentialConfig> implements LifeEssentialConfigService {

    @Override
    public List<LifeEssentialConfig> listByUser(Long userId) {
        return this.list(new LambdaQueryWrapper<LifeEssentialConfig>()
                .eq(LifeEssentialConfig::getUserId, userId)
                .orderByAsc(LifeEssentialConfig::getCategory));
    }

    @Override
    public void toggleEnabled(Long id, Integer enabled) {
        this.update(new LambdaUpdateWrapper<LifeEssentialConfig>()
                .set(LifeEssentialConfig::getEnabled, enabled)
                .eq(LifeEssentialConfig::getId, id));
    }

    @Override
    public void resetToDefaults(Long userId) {
        // Remove existing
        this.remove(new LambdaQueryWrapper<LifeEssentialConfig>()
                .eq(LifeEssentialConfig::getUserId, userId));
        // Insert defaults
        List<LifeEssentialConfig> defaults = buildDefaults(userId);
        this.saveBatch(defaults);
    }

    public static List<LifeEssentialConfig> buildDefaults(Long userId) {
        List<LifeEssentialConfig> list = new java.util.ArrayList<>();

        LifeEssentialConfig e1 = new LifeEssentialConfig();
        e1.setUserId(userId); e1.setCategory(1); e1.setName("低强度微运动");
        e1.setDefaultDuration(15);
        e1.setVariants(JSONUtil.toJsonStr(java.util.List.of("快走15分钟", "八段锦12分钟", "晨间拉伸10分钟", "靠墙静蹲5组")));
        e1.setEnergyLevel(2); e1.setMinWeeklyFreq(3); e1.setMaxWeeklyFreq(7);
        e1.setPreferredPeriod("morning"); e1.setEnabled(1);
        list.add(e1);

        LifeEssentialConfig e2 = new LifeEssentialConfig();
        e2.setUserId(userId); e2.setCategory(2); e2.setName("每日阅读");
        e2.setDefaultDuration(20);
        e2.setVariants(JSONUtil.toJsonStr(java.util.List.of("财商经济类阅读", "心理成长类阅读", "人文经典类阅读", "技术专业类阅读")));
        e2.setEnergyLevel(1); e2.setMinWeeklyFreq(5); e2.setMaxWeeklyFreq(7);
        e2.setPreferredPeriod("evening"); e2.setEnabled(1);
        list.add(e2);

        LifeEssentialConfig e3 = new LifeEssentialConfig();
        e3.setUserId(userId); e3.setCategory(3); e3.setName("正念冥想/呼吸");
        e3.setDefaultDuration(10);
        e3.setVariants(JSONUtil.toJsonStr(java.util.List.of("正念呼吸练习", "身体扫描冥想", "慈悲冥想", "478呼吸法")));
        e3.setEnergyLevel(1); e3.setMinWeeklyFreq(3); e3.setMaxWeeklyFreq(7);
        e3.setPreferredPeriod("night"); e3.setEnabled(1);
        list.add(e3);

        LifeEssentialConfig e4 = new LifeEssentialConfig();
        e4.setUserId(userId); e4.setCategory(5); e4.setName("品质放松");
        e4.setDefaultDuration(15);
        e4.setVariants(JSONUtil.toJsonStr(java.util.List.of("治愈短句/诗歌", "轻音乐欣赏", "环境整理/断舍离", "自由写作/日记")));
        e4.setEnergyLevel(1); e4.setMinWeeklyFreq(2); e4.setMaxWeeklyFreq(7);
        e4.setPreferredPeriod("evening"); e4.setEnabled(1);
        list.add(e4);

        return list;
    }
}
