package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("user_goal")
public class UserGoal {

    @TableId(type = IdType.AUTO)
    private Long goalId;
    private Long userId;
    private Integer goalLevel;
    private Integer goalType;
    private String goalTitle;
    private String goalContent;
    private LocalDate startDate;
    private LocalDate targetTime;
    private Integer progress;
    private Integer status;
    private String preferredSegment;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
