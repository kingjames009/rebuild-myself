class TimeBlockConfig {
  final int? id;
  String start;
  String end;
  String label;
  int type; // 0=fixed anchor, 1=task slot, 2=free/recommendation

  TimeBlockConfig({
    this.id,
    this.start = '18:00',
    this.end = '18:30',
    this.label = '',
    this.type = 1,
  });

  String get periodLabel => '$start-$end';

  static const typeLabels = {0: '固定', 1: '待办', 2: '推荐'};
  String get typeLabel => typeLabels[type] ?? '待办';

  factory TimeBlockConfig.fromJson(Map<String, dynamic> json) => TimeBlockConfig(
        id: json['id'] ?? json['blockId'],
        start: json['start'] ?? '18:00',
        end: json['end'] ?? '18:30',
        label: json['label'] ?? '',
        type: json['type'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'start': start,
        'end': end,
        'label': label,
        'type': type,
      };

  TimeBlockConfig copy() => TimeBlockConfig(
        id: id, start: start, end: end, label: label, type: type,
      );

  /// Workday blocks are now dynamically generated from WorkSchedule.
  /// Returns empty list — use WorkSchedule to generate segments instead.
  static List<TimeBlockConfig> defaultWorkday() => [];

  /// Weekend full-day template (8 blocks, 1 hour each, 8:00-22:00)
  static List<TimeBlockConfig> defaultWeekend() => [
        TimeBlockConfig(start: '08:00', end: '09:00', label: '晨间仪式 — 起床、运动、早餐', type: 0),
        TimeBlockConfig(start: '09:00', end: '10:00', type: 1),
        TimeBlockConfig(start: '10:00', end: '11:00', type: 1),
        TimeBlockConfig(start: '11:00', end: '12:00', type: 1),
        TimeBlockConfig(start: '12:00', end: '13:00', label: '午餐 + 午休', type: 0),
        TimeBlockConfig(start: '13:00', end: '14:00', type: 1),
        TimeBlockConfig(start: '14:00', end: '15:00', type: 1),
        TimeBlockConfig(start: '15:00', end: '16:00', type: 1),
        TimeBlockConfig(start: '16:00', end: '17:00', type: 1),
        TimeBlockConfig(start: '17:00', end: '18:00', label: '运动/户外活动', type: 2),
        TimeBlockConfig(start: '18:00', end: '19:00', label: '晚餐', type: 0),
        TimeBlockConfig(start: '19:00', end: '20:00', type: 1),
        TimeBlockConfig(start: '20:00', end: '21:00', type: 1),
        TimeBlockConfig(start: '21:00', end: '22:00', label: '晚间复盘 + 睡前准备', type: 0),
      ];
}

/// User's work schedule for weekday plan generation, plus weekend study schedule.
class WorkSchedule {
  // Weekday work times
  String workStart;
  String workEnd;
  String lunchStart;
  String lunchEnd;

  // Weekend/holiday study times
  String studyStart;
  String studyEnd;

  WorkSchedule({
    this.workStart = '09:00',
    this.workEnd = '18:00',
    this.lunchStart = '12:00',
    this.lunchEnd = '13:00',
    this.studyStart = '08:00',
    this.studyEnd = '22:00',
  });

  static const morningStart = '06:00';
  static const nightEnd = '22:30';

  static const segments = ['上班前', '上班时·上午', '午休', '上班时·下午', '下班后'];
  static const workSegments = ['上班时·上午', '上班时·下午'];

  bool get isConfigured => workStart != '09:00' || workEnd != '18:00' || lunchStart != '12:00' || lunchEnd != '13:00';

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
        workStart: json['workStart'] ?? json['work_start'] ?? '09:00',
        workEnd: json['workEnd'] ?? json['work_end'] ?? '18:00',
        lunchStart: json['lunchStart'] ?? json['lunch_start'] ?? '12:00',
        lunchEnd: json['lunchEnd'] ?? json['lunch_end'] ?? '13:00',
        studyStart: json['studyStart'] ?? json['study_start'] ?? '08:00',
        studyEnd: json['studyEnd'] ?? json['study_end'] ?? '22:00',
      );

  Map<String, dynamic> toJson() => {
        'workStart': workStart,
        'workEnd': workEnd,
        'lunchStart': lunchStart,
        'lunchEnd': lunchEnd,
        'studyStart': studyStart,
        'studyEnd': studyEnd,
      };

  WorkSchedule copy() => WorkSchedule(
        workStart: workStart,
        workEnd: workEnd,
        lunchStart: lunchStart,
        lunchEnd: lunchEnd,
        studyStart: studyStart,
        studyEnd: studyEnd,
      );

  static WorkSchedule defaultSchedule() => WorkSchedule();

  /// Parse "HH:MM" to minutes since midnight.
  static int parseMinutes(String time) {
    final parts = time.split(':');
    return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
  }

  /// Format minutes since midnight to "HH:MM".
  static String formatMinutes(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Split a time range into 1-hour blocks. Returns list of [start, end] pairs.
  static List<List<String>> hourlySlots(String segStart, String segEnd) {
    return slotsOf(segStart, segEnd, 60);
  }

  /// Split a time range into blocks of [durationMinutes]. Returns list of [start, end] pairs.
  static List<List<String>> slotsOf(String segStart, String segEnd, int durationMinutes) {
    final slots = <List<String>>[];
    final startMin = parseMinutes(segStart);
    final endMin = parseMinutes(segEnd);
    int current = startMin;
    while (current < endMin) {
      int next = current + durationMinutes;
      if (next > endMin) next = endMin;
      slots.add([formatMinutes(current), formatMinutes(next)]);
      current = next;
    }
    return slots;
  }

  /// Returns which of the 5 segments a given time slot belongs to.
  String segmentFor(String slotStart) {
    final m = parseMinutes(slotStart);
    final ws = parseMinutes(workStart);
    final ls = parseMinutes(lunchStart);
    final le = parseMinutes(lunchEnd);
    final we = parseMinutes(workEnd);
    if (m < ws) return '上班前';
    if (m < ls) return '上班时·上午';
    if (m < le) return '午休';
    if (m < we) return '上班时·下午';
    return '下班后';
  }

  /// Build time blocks covering the full workday.
  /// Morning/evening use 1-hour blocks; work segments use [workBlockMinutes].
  /// Higher protection levels use shorter blocks for more frequent check-ins:
  /// Green 30min, Yellow 20min, Red 15min.
  List<TimeBlockConfig> buildDayBlocks({int workBlockMinutes = 30}) {
    final blocks = <TimeBlockConfig>[];
    final segs = [
      [morningStart, workStart],
      [workStart, lunchStart],
      [lunchStart, lunchEnd],
      [lunchEnd, workEnd],
      [workEnd, nightEnd],
    ];
    final labels = ['晨间仪式 + 学习锻炼', '正念专注', '午休恢复', '正念专注', '自我精进'];
    final types = [1, 0, 2, 0, 1];

    for (int i = 0; i < segs.length; i++) {
      // Work segments (index 1, 3): 30-minute blocks for frequent mindfulness check-ins
      final isWorkSegment = i == 1 || i == 3;
      final duration = isWorkSegment ? workBlockMinutes : 60;
      final slots = slotsOf(segs[i][0], segs[i][1], duration);
      for (final slot in slots) {
        blocks.add(TimeBlockConfig(
          start: slot[0],
          end: slot[1],
          label: labels[i],
          type: types[i],
        ));
      }
    }
    return blocks;
  }
}
