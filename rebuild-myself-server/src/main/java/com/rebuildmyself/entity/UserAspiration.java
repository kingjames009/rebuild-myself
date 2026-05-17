package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("user_aspiration")
public class UserAspiration {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String content;
    private Integer category;
    private Integer priority;
    private Integer status;
    private Integer scheduleCount;
    private LocalDate startDate;
    private LocalDate endDate;
    private LocalDateTime createTime;
}
