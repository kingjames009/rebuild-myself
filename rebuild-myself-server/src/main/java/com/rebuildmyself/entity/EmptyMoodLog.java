package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("empty_mood_log")
public class EmptyMoodLog {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer emptyLevel;
    private Float emptyHours;
    private String triggerCause;
    private Float wasteHours;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
