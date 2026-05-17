package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.UserAspiration;
import com.rebuildmyself.mapper.UserAspirationMapper;
import com.rebuildmyself.service.UserAspirationService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class UserAspirationServiceImpl extends ServiceImpl<UserAspirationMapper, UserAspiration> implements UserAspirationService {

    @Override
    public List<UserAspiration> listByUser(Long userId) {
        return this.list(new LambdaQueryWrapper<UserAspiration>()
                .eq(UserAspiration::getUserId, userId)
                .orderByDesc(UserAspiration::getCreateTime));
    }

    @Override
    public UserAspiration add(Long userId, UserAspiration aspiration) {
        aspiration.setUserId(userId);
        aspiration.setStatus(0);
        aspiration.setScheduleCount(0);
        if (aspiration.getPriority() == null) aspiration.setPriority(3);
        if (aspiration.getCategory() == null) aspiration.setCategory(0);
        if (aspiration.getStartDate() == null) aspiration.setStartDate(LocalDate.now());
        this.save(aspiration);
        return aspiration;
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        this.update(new LambdaUpdateWrapper<UserAspiration>()
                .set(UserAspiration::getStatus, status)
                .eq(UserAspiration::getId, id));
    }
}
