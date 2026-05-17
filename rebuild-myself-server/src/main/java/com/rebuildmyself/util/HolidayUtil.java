package com.rebuildmyself.util;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.MonthDay;
import java.util.Set;

/**
 * Chinese public holiday utility.
 * Updated annually based on State Council notices.
 * All dates are non-work days unless listed in MAKEUP_WORKDAYS.
 */
public class HolidayUtil {

    /** Public holidays 2026 (non-work days) */
    private static final Set<MonthDay> HOLIDAYS_2026 = Set.of(
        MonthDay.of(1, 1), MonthDay.of(1, 2), MonthDay.of(1, 3),                         // 元旦
        MonthDay.of(2, 17), MonthDay.of(2, 18), MonthDay.of(2, 19),                       // 春节2/17-2/23
        MonthDay.of(2, 20), MonthDay.of(2, 21), MonthDay.of(2, 22), MonthDay.of(2, 23),
        MonthDay.of(4, 5), MonthDay.of(4, 6), MonthDay.of(4, 7),                          // 清明
        MonthDay.of(5, 1), MonthDay.of(5, 2), MonthDay.of(5, 3),                          // 劳动节5/1-5/5
        MonthDay.of(5, 4), MonthDay.of(5, 5),
        MonthDay.of(6, 19), MonthDay.of(6, 20), MonthDay.of(6, 21),                        // 端午
        MonthDay.of(9, 25), MonthDay.of(9, 26), MonthDay.of(9, 27),                        // 中秋
        MonthDay.of(10, 1), MonthDay.of(10, 2), MonthDay.of(10, 3),                        // 国庆10/1-10/7
        MonthDay.of(10, 4), MonthDay.of(10, 5), MonthDay.of(10, 6), MonthDay.of(10, 7)
    );

    /** Makeup workdays (weekend days that become workdays due to holiday adjustment) */
    private static final Set<MonthDay> MAKEUP_WORKDAYS_2026 = Set.of(
        MonthDay.of(1, 4),    // 元旦后补班(周日)
        MonthDay.of(2, 15),   // 春节前补班(周日)
        MonthDay.of(2, 28),   // 春节后补班(周六)
        MonthDay.of(4, 11),   // 清明后补班(周六)
        MonthDay.of(5, 10),   // 劳动节后补班(周日)
        MonthDay.of(6, 14),   // 端午前补班(周日)
        MonthDay.of(9, 19),   // 国庆前补班(周六)
        MonthDay.of(9, 20),   // 中秋前补班(周日)
        MonthDay.of(10, 10),  // 国庆后补班(周六)
        MonthDay.of(10, 11)   // 国庆后补班(周日)
    );

    public static boolean isWorkday(LocalDate date) {
        MonthDay md = MonthDay.from(date);
        if (MAKEUP_WORKDAYS_2026.contains(md)) return true;
        if (HOLIDAYS_2026.contains(md)) return false;
        DayOfWeek dow = date.getDayOfWeek();
        return dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY;
    }

    public static boolean isRestDay(LocalDate date) {
        return !isWorkday(date);
    }
}
