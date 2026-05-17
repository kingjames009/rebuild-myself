package com.rebuildmyself.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.StudyTrackRecord;
import com.rebuildmyself.mapper.StudyTrackRecordMapper;
import com.rebuildmyself.service.StudyTrackRecordService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class StudyTrackRecordServiceImpl extends ServiceImpl<StudyTrackRecordMapper, StudyTrackRecord> implements StudyTrackRecordService {

    @Override
    public Page<StudyTrackRecord> pageByUser(Long userId, Integer page, Integer size, Integer trackType) {
        Page<StudyTrackRecord> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<StudyTrackRecord> wrapper = new LambdaQueryWrapper<StudyTrackRecord>()
                .eq(StudyTrackRecord::getUserId, userId);
        if (trackType != null) {
            wrapper.eq(StudyTrackRecord::getTrackType, trackType);
        }
        wrapper.orderByDesc(StudyTrackRecord::getRecordDate);
        return this.page(pageParam, wrapper);
    }

    @Override
    public Map<String, Object> getStatsByTrack(Long userId, LocalDate start, LocalDate end) {
        List<StudyTrackRecord> list = this.lambdaQuery()
                .eq(StudyTrackRecord::getUserId, userId)
                .ge(start != null, StudyTrackRecord::getRecordDate, start)
                .le(end != null, StudyTrackRecord::getRecordDate, end)
                .list();

        Map<Integer, List<StudyTrackRecord>> grouped = list.stream()
                .collect(Collectors.groupingBy(StudyTrackRecord::getTrackType));

        Map<String, Object> result = new HashMap<>();
        Map<String, Object> trackStats = new HashMap<>();

        for (Map.Entry<Integer, List<StudyTrackRecord>> entry : grouped.entrySet()) {
            List<StudyTrackRecord> records = entry.getValue();
            Map<String, Object> stat = new HashMap<>();
            stat.put("totalMinutes", records.stream()
                    .filter(r -> r.getStudyMinutes() != null)
                    .mapToInt(StudyTrackRecord::getStudyMinutes)
                    .sum());
            stat.put("avgDifficulty", records.stream()
                    .filter(r -> r.getDifficultyLevel() != null)
                    .collect(Collectors.averagingInt(StudyTrackRecord::getDifficultyLevel)));
            stat.put("escapeCount", records.stream()
                    .filter(r -> r.getEscapeStatus() != null && r.getEscapeStatus() == 1)
                    .count());
            stat.put("recordCount", records.size());
            trackStats.put(String.valueOf(entry.getKey()), stat);
        }

        result.put("trackStats", trackStats);
        result.put("totalTracks", grouped.size());
        return result;
    }
}
