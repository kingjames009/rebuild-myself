package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.User;
import org.springframework.web.multipart.MultipartFile;

public interface UserService extends IService<User> {

    String login(String phone, String password);

    User register(String phone, String password, String code);

    void updateProfile(Long userId, User user);

    String updateAvatar(Long userId, MultipartFile file);

    void setLockPwd(Long userId, String lockPwd);

    void changePassword(Long userId, String oldPassword, String newPassword);

    void deleteAccount(Long userId);
}
