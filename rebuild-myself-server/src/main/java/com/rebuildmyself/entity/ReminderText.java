package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("reminder_text")
public class ReminderText {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String category;
    private String content;
    private Integer sortOrder;
    private LocalDateTime createTime;
}
