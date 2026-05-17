package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.StudyTrackRecord;

import java.time.LocalDate;
import java.util.Map;

public interface StudyTrackRecordService extends IService<StudyTrackRecord> {

    Page<StudyTrackRecord> pageByUser(Long userId, Integer page, Integer size, Integer trackType);

    Map<String, Object> getStatsByTrack(Long userId, LocalDate start, LocalDate end);
}
