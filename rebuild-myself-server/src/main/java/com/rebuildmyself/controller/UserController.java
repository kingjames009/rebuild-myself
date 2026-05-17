package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.User;
import com.rebuildmyself.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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
        return Result.ok(userService.getById(userId));
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
}
