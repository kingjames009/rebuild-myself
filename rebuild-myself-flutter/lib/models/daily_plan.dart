class DailyModelPlan {
  final int? planId;
  final int? userId;
  final String? planDate;
  final String? timePeriod;
  final String? planContent;
  final int? planType;
  final int? difficulty;
  final String? createTime;
  final int? isCompleted;
  final String? actualNote;
  final String? completedAt;

  DailyModelPlan({
    this.planId,
    this.userId,
    this.planDate,
    this.timePeriod,
    this.planContent,
    this.planType,
    this.difficulty,
    this.createTime,
    this.isCompleted,
    this.actualNote,
    this.completedAt,
  });

  factory DailyModelPlan.fromJson(Map<String, dynamic> json) => DailyModelPlan(
        planId: json['planId'] ?? json['plan_id'],
        userId: json['userId'] ?? json['user_id'],
        planDate: json['planDate'] ?? json['plan_date'],
        timePeriod: json['timePeriod'] ?? json['time_period'],
        planContent: json['planContent'] ?? json['plan_content'],
        planType: json['planType'] ?? json['plan_type'],
        difficulty: json['difficulty'],
        createTime: json['createTime'] ?? json['create_time'],
        isCompleted: json['isCompleted'] ?? json['is_completed'],
        actualNote: json['actualNote'] ?? json['actual_note'],
        completedAt: json['completedAt'] ?? json['completed_at'],
      );

  Map<String, dynamic> toJson() => {
        if (planId != null) 'planId': planId,
        if (planDate != null) 'planDate': planDate,
        if (timePeriod != null) 'timePeriod': timePeriod,
        if (planContent != null) 'planContent': planContent,
        if (planType != null) 'planType': planType,
        if (difficulty != null) 'difficulty': difficulty,
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (actualNote != null) 'actualNote': actualNote,
        if (completedAt != null) 'completedAt': completedAt,
      };

  String get typeLabel {
    const map = {1: '学习', 2: '副业', 3: '阅读', 4: '休闲', 5: '心理', 0: '综合'};
    return map[planType] ?? '综合';
  }

  DailyModelPlan copyWith({
    int? planId,
    int? userId,
    String? planDate,
    String? timePeriod,
    String? planContent,
    int? planType,
    int? difficulty,
    String? createTime,
    int? isCompleted,
    String? actualNote,
    String? completedAt,
  }) =>
      DailyModelPlan(
        planId: planId ?? this.planId,
        userId: userId ?? this.userId,
        planDate: planDate ?? this.planDate,
        timePeriod: timePeriod ?? this.timePeriod,
        planContent: planContent ?? this.planContent,
        planType: planType ?? this.planType,
        difficulty: difficulty ?? this.difficulty,
        createTime: createTime ?? this.createTime,
        isCompleted: isCompleted ?? this.isCompleted,
        actualNote: actualNote ?? this.actualNote,
        completedAt: completedAt ?? this.completedAt,
      );
}
