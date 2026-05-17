package com.rebuildmyself.service.impl;

import cn.hutool.crypto.SecureUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.common.BusinessException;
import com.rebuildmyself.entity.LifeEssentialConfig;
import com.rebuildmyself.entity.User;
import com.rebuildmyself.mapper.LifeEssentialConfigMapper;
import com.rebuildmyself.mapper.UserMapper;
import com.rebuildmyself.service.UserService;
import com.rebuildmyself.service.impl.LifeEssentialConfigServiceImpl;
import com.rebuildmyself.util.AESUtil;
import com.rebuildmyself.util.JwtUtil;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final JwtUtil jwtUtil;
    private final AESUtil aesUtil;
    private final LifeEssentialConfigMapper lifeEssentialConfigMapper;

    public UserServiceImpl(JwtUtil jwtUtil, AESUtil aesUtil,
                          LifeEssentialConfigMapper lifeEssentialConfigMapper) {
        this.jwtUtil = jwtUtil;
        this.aesUtil = aesUtil;
        this.lifeEssentialConfigMapper = lifeEssentialConfigMapper;
    }

    @Override
    public String login(String phone, String password) {
        User user = getOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
        if (user == null) throw new BusinessException("账号不存在");
        if (!SecureUtil.sha256(password).equals(user.getPassword())) throw new BusinessException("密码错误");
        user.setLastLoginTime(LocalDateTime.now());
        updateById(user);
        return jwtUtil.generateToken(user.getUserId());
    }

    @Override
    public User register(String phone, String password, String code) {
        if (getOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone)) != null)
            throw new BusinessException("手机号已注册");
        User user = new User();
        user.setPhone(phone);
        user.setPassword(SecureUtil.sha256(password));
        save(user);
        // Seed default life essentials for new user
        List<LifeEssentialConfig> defaults = LifeEssentialConfigServiceImpl.buildDefaults(user.getUserId());
        for (LifeEssentialConfig e : defaults) {
            lifeEssentialConfigMapper.insert(e);
        }
        return user;
    }

    @Override
    public void updateProfile(Long userId, User user) {
        User exist = getById(userId);
        if (exist == null) throw new BusinessException("用户不存在");
        if (user.getNickname() != null) exist.setNickname(user.getNickname());
        if (user.getAvatar() != null) exist.setAvatar(user.getAvatar());
        if (user.getLongTermGoal() != null) exist.setLongTermGoal(aesUtil.encrypt(user.getLongTermGoal()));
        if (user.getHeight() != null) exist.setHeight(user.getHeight());
        if (user.getWeight() != null) exist.setWeight(user.getWeight());
        if (user.getHealthNote() != null) exist.setHealthNote(user.getHealthNote());
        updateById(exist);
    }

    @Override
    public String updateAvatar(Long userId, MultipartFile file) {
        User user = getById(userId);
        if (user == null) throw new BusinessException("用户不存在");

        try {
            String uploadDir = System.getProperty("user.dir") + File.separator + "uploads" + File.separator + "avatars";
            File dir = new File(uploadDir);
            if (!dir.exists()) dir.mkdirs();

            String ext = ".jpg";
            String original = file.getOriginalFilename();
            if (original != null && original.contains(".")) {
                ext = original.substring(original.lastIndexOf("."));
            }
            String filename = "user_" + userId + "_" + System.currentTimeMillis() + ext;
            File dest = new File(dir, filename);
            file.transferTo(dest);

            String avatarUrl = "/avatars/" + filename;
            user.setAvatar(avatarUrl);
            updateById(user);

            return avatarUrl;
        } catch (Exception e) {
            throw new BusinessException("头像上传失败");
        }
    }

    @Override
    public void setLockPwd(Long userId, String lockPwd) {
        User user = getById(userId);
        user.setLocalLockPwd(SecureUtil.sha256(lockPwd));
        updateById(user);
    }

    @Override
    public void deleteAccount(Long userId) {
        removeById(userId);
    }
}
