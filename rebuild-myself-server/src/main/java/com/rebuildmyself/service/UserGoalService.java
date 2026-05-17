package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.UserGoal;

import java.util.List;

public interface UserGoalService extends IService<UserGoal> {

    List<UserGoal> listByUserAndLevel(Long userId, Integer goalLevel);

    Page<UserGoal> pageByUser(Long userId, Integer page, Integer size);

    void updateProgress(Long goalId, Integer progress);
}
