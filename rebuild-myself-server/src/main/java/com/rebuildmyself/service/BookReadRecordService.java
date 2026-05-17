package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.BookReadRecord;

import java.util.Map;

public interface BookReadRecordService extends IService<BookReadRecord> {

    Page<BookReadRecord> pageByUser(Long userId, Integer page, Integer size, Integer bookType);

    Map<String, Object> getReadingStats(Long userId);
}
