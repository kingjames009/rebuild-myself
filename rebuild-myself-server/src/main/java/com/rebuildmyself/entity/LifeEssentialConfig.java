package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("life_essential_config")
public class LifeEssentialConfig {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer category;
    private String name;
    private Integer defaultDuration;
    private String variants;
    private Integer energyLevel;
    private Integer minWeeklyFreq;
    private Integer maxWeeklyFreq;
    private String preferredPeriod;
    private Integer enabled;
    private LocalDateTime createTime;
}
