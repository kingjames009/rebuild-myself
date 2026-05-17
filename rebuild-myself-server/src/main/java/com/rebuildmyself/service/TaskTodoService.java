package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.TaskTodo;

import java.time.LocalDate;
import java.util.List;

public interface TaskTodoService extends IService<TaskTodo> {

    List<TaskTodo> listByUserAndDate(Long userId, LocalDate date);

    void toggleComplete(Long taskId);

    List<TaskTodo> listByQuadrant(Long userId, Integer level);
}
