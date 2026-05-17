package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.StudyTrackRecord;
import com.rebuildmyself.service.StudyTrackRecordService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/study")
public class StudyTrackController {

    private final StudyTrackRecordService studyTrackRecordService;

    public StudyTrackController(StudyTrackRecordService studyTrackRecordService) {
        this.studyTrackRecordService = studyTrackRecordService;
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          @RequestParam(required = false) Integer trackType,
                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(studyTrackRecordService.pageByUser(userId, page, size, trackType));
    }

    @GetMapping("/stats")
    public Result<?> getStatsByTrack(@RequestParam String start,
                                     @RequestParam String end,
                                     HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(studyTrackRecordService.getStatsByTrack(userId, LocalDate.parse(start), LocalDate.parse(end)));
    }

    @PostMapping
    public Result<?> save(@RequestBody StudyTrackRecord record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        studyTrackRecordService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> updateById(@RequestBody StudyTrackRecord record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        studyTrackRecordService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> removeById(@PathVariable Long id) {
        studyTrackRecordService.removeById(id);
        return Result.ok();
    }
}
