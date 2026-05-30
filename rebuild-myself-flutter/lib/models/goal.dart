class Goal {
  final int? goalId;
  final int? userId;
  final int? goalLevel;
  final int? goalType;
  final String? title;
  final String? content;
  final String? startDate;
  final String? targetTime;
  final int? progress;
  final int? status;
  final String? preferredSegment;
  final String? createTime;
  final String? updateTime;

  Goal({
    this.goalId,
    this.userId,
    this.goalLevel,
    this.goalType,
    this.title,
    this.content,
    this.startDate,
    this.targetTime,
    this.progress,
    this.status,
    this.preferredSegment,
    this.createTime,
    this.updateTime,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    int? parseProgress(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return (v <= 1.0) ? (v * 100).round() : v.round();
      return int.tryParse(v.toString()) ?? 0;
    }

    return Goal(
      goalId: _parseInt(json['goalId'] ?? json['goal_id']),
      userId: _parseInt(json['userId'] ?? json['user_id']),
      goalLevel: _parseInt(json['goalLevel'] ?? json['goal_level']),
      goalType: _parseInt(json['goalType'] ?? json['goal_type']),
      title: json['goalTitle'] ?? json['goal_title'] ?? json['title'],
      content: json['goalContent'] ?? json['goal_content'] ?? json['content'],
      startDate: (json['startDate'] ?? json['start_date'])?.toString(),
      targetTime: (json['targetTime'] ?? json['target_time'] ?? json['targetDate'] ?? json['target_date'])?.toString(),
      progress: parseProgress(json['progress']),
      status: _parseInt(json['status']),
      preferredSegment: json['preferredSegment'] ?? json['preferred_segment'],
      createTime: (json['createTime'] ?? json['create_time'])?.toString(),
      updateTime: (json['updateTime'] ?? json['update_time'])?.toString(),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
        if (goalId != null) 'goalId': goalId,
        if (title != null) 'goalTitle': title,
        if (content != null) 'goalContent': content,
        if (goalLevel != null) 'goalLevel': goalLevel,
        if (goalType != null) 'goalType': goalType,
        if (startDate != null) 'startDate': startDate,
        if (targetTime != null) 'targetTime': targetTime,
        if (progress != null) 'progress': progress,
        if (status != null) 'status': status,
        if (preferredSegment != null) 'preferredSegment': preferredSegment,
      };

  int get progressPercent => (progress ?? 0).clamp(0, 100);

  String get typeLabel {
    const map = {1: '学习', 2: '财务', 3: '健康', 4: '习惯'};
    return map[goalType] ?? '通用';
  }

  String get statusLabel {
    const map = {0: '未开始', 1: '进行中', 2: '已完成'};
    return map[status] ?? '进行中';
  }

  String get segmentLabel {
    const map = {'上班前': '🌅 上班前', '午休': '☀️ 午休', '下班后': '🌆 下班后'};
    return map[preferredSegment] ?? '不指定';
  }

  static const segments = ['上班前', '午休', '下班后'];
}
