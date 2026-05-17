package com.rebuildmyself.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("task_todo")
public class TaskTodo {

    @TableId(type = IdType.AUTO)
    private Long taskId;
    private Long userId;
    private String taskTitle;
    private Integer taskLevel;
    private Integer isComplete;
    private LocalDate taskDate;
    private LocalDateTime createTime;
}
