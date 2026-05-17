class BehaviorIntervene {
  final int? interveneId;
  final int? userId;
  final int? interveneType;
  final String? interveneTime;
  final int? isSuccess;
  final String? moodBefore;
  final String? createTime;

  BehaviorIntervene({
    this.interveneId,
    this.userId,
    this.interveneType,
    this.interveneTime,
    this.isSuccess,
    this.moodBefore,
    this.createTime,
  });

  factory BehaviorIntervene.fromJson(Map<String, dynamic> json) =>
      BehaviorIntervene(
        interveneId: json['interveneId'] ?? json['intervene_id'],
        userId: json['userId'] ?? json['user_id'],
        interveneType: json['interveneType'] ?? json['intervene_type'],
        interveneTime: json['interveneTime'] ?? json['intervene_time'],
        isSuccess: json['isSuccess'] ?? json['is_success'],
        moodBefore: json['moodBefore'] ?? json['mood_before'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (interveneType != null) 'interveneType': interveneType,
        if (moodBefore != null) 'moodBefore': moodBefore,
        if (isSuccess != null) 'isSuccess': isSuccess,
        if (interveneTime != null) 'interveneTime': interveneTime,
      };

  String get typeLabel {
    const map = {1: '拖延矫正', 2: '杂念疏导', 3: '短视频戒断', 4: '懒惰管理'};
    return map[interveneType] ?? '综合';
  }
}
