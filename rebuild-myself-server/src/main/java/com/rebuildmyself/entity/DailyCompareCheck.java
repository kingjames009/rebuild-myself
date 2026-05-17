package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("daily_compare_check")
public class DailyCompareCheck {

    @TableId(type = IdType.AUTO)
    private Long checkId;
    private Long userId;
    private LocalDate planDate;
    private String deviationContent;
    private String escapeReason;
    private Integer progressScore;
    private LocalDateTime createTime;
}
