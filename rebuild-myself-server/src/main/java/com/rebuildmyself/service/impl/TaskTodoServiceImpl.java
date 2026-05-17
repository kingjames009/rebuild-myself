package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.TaskTodo;
import com.rebuildmyself.mapper.TaskTodoMapper;
import com.rebuildmyself.service.TaskTodoService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class TaskTodoServiceImpl extends ServiceImpl<TaskTodoMapper, TaskTodo> implements TaskTodoService {

    @Override
    public List<TaskTodo> listByUserAndDate(Long userId, LocalDate date) {
        return list(new LambdaQueryWrapper<TaskTodo>()
                .eq(TaskTodo::getUserId, userId)
                .eq(TaskTodo::getTaskDate, date));
    }

    @Override
    public void toggleComplete(Long taskId) {
        TaskTodo taskTodo = getById(taskId);
        if (taskTodo != null) {
            taskTodo.setIsComplete(taskTodo.getIsComplete() == 1 ? 0 : 1);
            updateById(taskTodo);
        }
    }

    @Override
    public List<TaskTodo> listByQuadrant(Long userId, Integer level) {
        return list(new LambdaQueryWrapper<TaskTodo>()
                .eq(TaskTodo::getUserId, userId)
                .eq(TaskTodo::getTaskLevel, level));
    }
}
