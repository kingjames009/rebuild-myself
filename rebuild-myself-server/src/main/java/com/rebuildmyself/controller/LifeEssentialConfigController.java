package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.LifeEssentialConfig;
import com.rebuildmyself.service.LifeEssentialConfigService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/essential")
public class LifeEssentialConfigController {

    private final LifeEssentialConfigService lifeEssentialConfigService;

    public LifeEssentialConfigController(LifeEssentialConfigService lifeEssentialConfigService) {
        this.lifeEssentialConfigService = lifeEssentialConfigService;
    }

    @GetMapping("/list")
    public Result<?> list(@RequestAttribute("userId") Long userId) {
        return Result.ok(lifeEssentialConfigService.listByUser(userId));
    }

    @PutMapping("/{id}/toggle")
    public Result<?> toggle(@PathVariable Long id,
                            @RequestBody LifeEssentialConfig config) {
        lifeEssentialConfigService.toggleEnabled(id, config.getEnabled());
        return Result.ok();
    }

    @PostMapping("/reset")
    public Result<?> reset(@RequestAttribute("userId") Long userId) {
        lifeEssentialConfigService.resetToDefaults(userId);
        return Result.ok(lifeEssentialConfigService.listByUser(userId));
    }
}
