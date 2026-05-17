package com.rebuildmyself.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.rebuildmyself.entity.EliteHabitLib;

import java.util.List;

public interface EliteHabitLibService extends IService<EliteHabitLib> {

    List<EliteHabitLib> listByCategory(Integer habitCategory);

    List<EliteHabitLib> generateHabits();
}
