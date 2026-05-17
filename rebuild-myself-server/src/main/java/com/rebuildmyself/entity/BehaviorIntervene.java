package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("behavior_intervene")
public class BehaviorIntervene {

    @TableId(type = IdType.AUTO)
    private Long interveneId;
    private Long userId;
    private Integer interveneType;
    private LocalDateTime interveneTime;
    private Integer isSuccess;
    private String moodBefore;
    private LocalDateTime createTime;
}
