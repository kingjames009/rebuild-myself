package com.rebuildmyself.controller;

import com.rebuildmyself.common.Result;
import com.rebuildmyself.entity.BookReadRecord;
import com.rebuildmyself.service.BookReadRecordService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/book")
public class BookReadController {

    private final BookReadRecordService bookReadRecordService;

    public BookReadController(BookReadRecordService bookReadRecordService) {
        this.bookReadRecordService = bookReadRecordService;
    }

    @GetMapping("/page")
    public Result<?> page(@RequestParam(defaultValue = "1") Integer page,
                          @RequestParam(defaultValue = "10") Integer size,
                          @RequestParam(required = false) Integer bookType,
                          HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(bookReadRecordService.pageByUser(userId, page, size, bookType));
    }

    @GetMapping("/stats")
    public Result<?> getReadingStats(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return Result.ok(bookReadRecordService.getReadingStats(userId));
    }

    @PostMapping
    public Result<?> save(@RequestBody BookReadRecord record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        bookReadRecordService.save(record);
        return Result.ok();
    }

    @PutMapping
    public Result<?> updateById(@RequestBody BookReadRecord record, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        record.setUserId(userId);
        bookReadRecordService.updateById(record);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<?> removeById(@PathVariable Long id) {
        bookReadRecordService.removeById(id);
        return Result.ok();
    }
}
