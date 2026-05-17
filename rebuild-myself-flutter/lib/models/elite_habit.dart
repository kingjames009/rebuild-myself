class EliteHabit {
  final int? id;
  final int? habitCategory;
  final String? habitContent;
  final int? intensityLevel;
  final int? suitBodyType;
  final String? createTime;

  EliteHabit({
    this.id,
    this.habitCategory,
    this.habitContent,
    this.intensityLevel,
    this.suitBodyType,
    this.createTime,
  });

  factory EliteHabit.fromJson(Map<String, dynamic> json) => EliteHabit(
        id: json['id'],
        habitCategory: json['habitCategory'] ?? json['habit_category'],
        habitContent: json['habitContent'] ?? json['habit_content'],
        intensityLevel: json['intensityLevel'] ?? json['intensity_level'],
        suitBodyType: json['suitBodyType'] ?? json['suit_body_type'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (habitCategory != null) 'habitCategory': habitCategory,
        if (habitContent != null) 'habitContent': habitContent,
        if (intensityLevel != null) 'intensityLevel': intensityLevel,
      };

  String get categoryLabel {
    const map = {1: '晨间', 2: '日间', 3: '下班后', 4: '睡前'};
    return map[habitCategory] ?? '综合';
  }
}
