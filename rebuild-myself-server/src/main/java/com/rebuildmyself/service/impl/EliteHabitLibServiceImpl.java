package com.rebuildmyself.service.impl;

import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.rebuildmyself.entity.EliteHabitLib;
import com.rebuildmyself.mapper.EliteHabitLibMapper;
import com.rebuildmyself.service.EliteHabitLibService;
import com.rebuildmyself.util.AiUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class EliteHabitLibServiceImpl extends ServiceImpl<EliteHabitLibMapper, EliteHabitLib> implements EliteHabitLibService {

    private final AiUtil aiUtil;

    @Override
    public List<EliteHabitLib> listByCategory(Integer habitCategory) {
        LambdaQueryWrapper<EliteHabitLib> wrapper = new LambdaQueryWrapper<EliteHabitLib>()
                .eq(EliteHabitLib::getHabitCategory, habitCategory);
        return this.list(wrapper);
    }

    @Override
    public List<EliteHabitLib> generateHabits() {
        String prompt = """
            基于全球顶尖精英（世界500强CEO、奥运冠军、顶尖科学家、知名艺术家）的真实日常习惯，
            生成16条精英习惯，分4类各4条，要求：
            1. 每条必须具体可执行，不能是空泛的鸡汤（如"保持积极心态"这种不行）
            2. 每条必须注明来源人物或群体的真实习惯（如"Tim Cook凌晨4:30起床"）
            3. 强度等级1-5（1极低门槛/2低/3中/4较高/5高），照顾体能一般的中年人，多数2-3
            4. 用中文输出，习惯描述控制在30字以内

            四类：
            - 晨间(habit_category=1)：起床、晨间仪式、激活身体和大脑
            - 日间(habit_category=2)：工作专注、精力管理、人际边界
            - 下班后(habit_category=3)：自我提升、副业、学习
            - 睡前(habit_category=4)：放松、复盘、准备次日

            请严格返回JSON数组，格式：
            [{"habit_category":1,"habit_content":"xxx（来源：xxx）","intensity_level":2},...]
            不要包含markdown代码块标记，只返回纯JSON数组。""";

        String response = aiUtil.chat(prompt);
        if (response == null || response.isBlank()) {
            log.warn("AI habit generation returned empty, fallback to seed");
            return List.of();
        }

        // Strip markdown code fences if present
        String json = response.trim();
        if (json.startsWith("```")) {
            json = json.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();
        }

        try {
            JSONArray arr = JSONUtil.parseArray(json);
            List<EliteHabitLib> habits = new ArrayList<>();
            for (int i = 0; i < arr.size(); i++) {
                JSONObject obj = arr.getJSONObject(i);
                EliteHabitLib habit = new EliteHabitLib();
                habit.setHabitCategory(obj.getInt("habit_category"));
                habit.setHabitContent(obj.getStr("habit_content"));
                habit.setIntensityLevel(obj.getInt("intensity_level", 2));
                habit.setSuitBodyType(0);
                habits.add(habit);
                this.save(habit);
            }
            log.info("AI generated {} elite habits", habits.size());
            return habits;
        } catch (Exception e) {
            log.error("Failed to parse AI habit response: {}", response, e);
            return List.of();
        }
    }
}
