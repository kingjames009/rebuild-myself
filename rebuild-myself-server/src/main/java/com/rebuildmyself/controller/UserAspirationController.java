package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.UserAspiration;
import com.rebuildmyself.service.UserAspirationService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/aspiration")
public class UserAspirationController {

    private final UserAspirationService userAspirationService;

    public UserAspirationController(UserAspirationService userAspirationService) {
        this.userAspirationService = userAspirationService;
    }

    @GetMapping("/list")
    public Result<?> list(@RequestAttribute("userId") Long userId) {
        return Result.ok(userAspirationService.listByUser(userId));
    }

    @PostMapping
    public Result<?> add(@RequestBody UserAspiration aspiration,
                         @RequestAttribute("userId") Long userId) {
        return Result.ok(userAspirationService.add(userId, aspiration));
    }

    @PutMapping("/{id}")
    public Result<?> update(@PathVariable Long id,
                            @RequestBody UserAspiration aspiration) {
        aspiration.setId(id);
        userAspirationService.updateById(aspiration);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> delete(@PathVariable Long id) {
        userAspirationService.removeById(id);
        return Result.ok();
    }

    @PutMapping("/{id}/status")
    public Result<?> updateStatus(@PathVariable Long id,
                                  @RequestBody UserAspiration aspiration) {
        userAspirationService.updateStatus(id, aspiration.getStatus());
        return Result.ok();
    }
}
