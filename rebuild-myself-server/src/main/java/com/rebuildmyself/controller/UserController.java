package com.rebuildmyself.controller;

import com.rebuildmyself.common.BusinessException;
import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.User;
import com.rebuildmyself.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/login")
    public Result<String> login(@RequestBody User user) {
        String token = userService.login(user.getPhone(), user.getPassword());
        return Result.ok(token);
    }

    @PostMapping("/register")
    public Result<User> register(@RequestBody User user) {
        return Result.ok(userService.register(user.getPhone(), user.getPassword(), null));
    }

    @GetMapping("/profile")
    public Result<User> getProfile(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        User user = userService.getById(userId);
        if (user != null) user.setPhone(null); // never expose phone hash
        return Result.ok(user);
    }

    @PutMapping("/profile")
    public Result<Void> updateProfile(@RequestBody User user, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        userService.updateProfile(userId, user);
        return Result.ok();
    }

    @PostMapping("/lock-pwd")
    public Result<Void> setLockPwd(@RequestBody User user, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        userService.setLockPwd(userId, user.getLocalLockPwd());
        return Result.ok();
    }

    @PostMapping("/avatar")
    public Result<String> uploadAvatar(@RequestParam MultipartFile file,
                                        HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        String url = userService.updateAvatar(userId, file);
        return Result.ok(url);
    }

    @DeleteMapping("/account")
    public Result<Void> deleteAccount(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        userService.deleteAccount(userId);
        return Result.ok();
    }

    @PostMapping("/change-password")
    public Result<Void> changePassword(@RequestBody Map<String, String> body,
                                       HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");
        if (oldPassword == null || oldPassword.isBlank()
                || newPassword == null || newPassword.isBlank()) {
            throw new BusinessException("密码不能为空");
        }
        if (newPassword.length() < 6) throw new BusinessException("新密码至少6位");
        userService.changePassword(userId, oldPassword, newPassword);
        return Result.ok();
    }
}
