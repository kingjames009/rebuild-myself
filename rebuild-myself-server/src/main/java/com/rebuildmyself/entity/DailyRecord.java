package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("daily_record")
public class DailyRecord {

    @TableId(type = IdType.AUTO)
    private Long recordId;
    private Long userId;
    private Integer recordType;
    private String content;
    private Integer costTime;
    private String triggerReason;
    private Integer emotionScore;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
