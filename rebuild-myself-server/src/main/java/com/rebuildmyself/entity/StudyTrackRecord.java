package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("study_track_record")
public class StudyTrackRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Integer trackType;
    private String studyContent;
    private Integer studyMinutes;
    private Integer difficultyLevel;
    private Integer escapeStatus;
    private LocalDate recordDate;
    private LocalDateTime createTime;
}
