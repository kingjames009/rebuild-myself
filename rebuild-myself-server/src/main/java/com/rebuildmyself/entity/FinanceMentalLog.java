package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("finance_mental_log")
public class FinanceMentalLog {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer moneyPressure;
    private BigDecimal gapAmount;
    private String incomeRecord;
    private Integer escapeState;
    private Integer actionMinutes;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
