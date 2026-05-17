package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.UserAspiration;

import java.util.List;

public interface UserAspirationService extends IService<UserAspiration> {
    List<UserAspiration> listByUser(Long userId);
    UserAspiration add(Long userId, UserAspiration aspiration);
    void updateStatus(Long id, Integer status);
}
