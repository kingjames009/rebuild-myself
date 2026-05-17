package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("sideline_plan")
public class SidelinePlan {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer sideType;
    private String dailyAction;
    private Integer progress;
    private String blockReason;
    private Integer energyCost;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
