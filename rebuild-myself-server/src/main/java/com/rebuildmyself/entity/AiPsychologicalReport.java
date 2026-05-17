package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("ai_psychological_report")
public class AiPsychologicalReport {

    @TableId(type = IdType.AUTO)
    private Long reportId;
    private Long userId;
    private Integer cycleType;
    private String cycleRange;
    private String originalData;
    private String reportContent;
    private LocalDateTime createTime;
}
