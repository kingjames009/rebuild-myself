package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("elite_habit_lib")
public class EliteHabitLib {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Integer habitCategory;
    private String habitContent;
    private Integer intensityLevel;
    private Integer suitBodyType;
    private LocalDateTime createTime;
}
