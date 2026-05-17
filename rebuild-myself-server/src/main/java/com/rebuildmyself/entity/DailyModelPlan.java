package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("daily_model_plan")
public class DailyModelPlan {

    @TableId(type = IdType.AUTO)
    private Long planId;
    private Long userId;
    private LocalDate planDate;
    private String timePeriod;
    private String planContent;
    private Integer planType;
    private Integer difficulty;
    private LocalDateTime createTime;
    private Integer isCompleted;
    private String actualNote;
    private LocalDateTime completedAt;
}
