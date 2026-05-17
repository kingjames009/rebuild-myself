package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("life_leisure_record")
public class LifeLeisureRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer leisureType;
    private Integer leisureMinutes;
    private Integer happyScore;
    private Integer arrangeState;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
