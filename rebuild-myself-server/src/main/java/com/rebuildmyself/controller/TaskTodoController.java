package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.TaskTodo;
import com.rebuildmyself.service.TaskTodoService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/task")
public class TaskTodoController {

    private final TaskTodoService taskTodoService;

    public TaskTodoController(TaskTodoService taskTodoService) {
        this.taskTodoService = taskTodoService;
    }

    @GetMapping("/list")
    public Result<List<TaskTodo>> list(@RequestParam String date,
                                       HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        LocalDate localDate = LocalDate.parse(date);
        return Result.ok(taskTodoService.listByUserAndDate(userId, localDate));
    }

    @GetMapping("/quadrant")
    public Result<List<TaskTodo>> quadrant(@RequestParam(required = false, defaultValue = "1") Integer level,
                                           HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(taskTodoService.listByQuadrant(userId, level));
    }

    @PostMapping
    public Result<Void> save(@RequestBody TaskTodo taskTodo, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        taskTodo.setUserId(userId);
        taskTodoService.save(taskTodo);
        return Result.ok();
    }

    @PutMapping("/toggle/{id}")
    public Result<Void> toggleComplete(@PathVariable Long id) {
        taskTodoService.toggleComplete(id);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable Long id) {
        taskTodoService.removeById(id);
        return Result.ok();
    }
}
