package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.UserGoal;
import com.rebuildmyself.mapper.UserGoalMapper;
import com.rebuildmyself.service.UserGoalService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserGoalServiceImpl extends ServiceImpl<UserGoalMapper, UserGoal> implements UserGoalService {

    @Override
    public List<UserGoal> listByUserAndLevel(Long userId, Integer goalLevel) {
        return list(new LambdaQueryWrapper<UserGoal>()
                .eq(UserGoal::getUserId, userId)
                .eq(UserGoal::getGoalLevel, goalLevel));
    }

    @Override
    public Page<UserGoal> pageByUser(Long userId, Integer page, Integer size) {
        Page<UserGoal> pageParam = new Page<>(page, size);
        return page(pageParam, new LambdaQueryWrapper<UserGoal>()
                .eq(UserGoal::getUserId, userId)
                .orderByAsc(UserGoal::getGoalLevel)
                .orderByDesc(UserGoal::getCreateTime));
    }

    @Override
    public void updateProgress(Long goalId, Integer progress) {
        UserGoal userGoal = getById(goalId);
        if (userGoal != null) {
            userGoal.setProgress(progress);
            if (progress != null && progress == 100) {
                userGoal.setStatus(1);
            }
            updateById(userGoal);
        }
    }
}
