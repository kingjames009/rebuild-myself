class DailyRecord {
  final int? recordId;
  final int? userId;
  final int? recordType;
  final String? content;
  final int? costTime;
  final String? triggerReason;
  final int? emotionScore;
  final String? recordDate;
  final String? createTime;

  DailyRecord({
    this.recordId,
    this.userId,
    this.recordType,
    this.content,
    this.costTime,
    this.triggerReason,
    this.emotionScore,
    this.recordDate,
    this.createTime,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        recordId: json['recordId'] ?? json['record_id'],
        userId: json['userId'] ?? json['user_id'],
        recordType: json['recordType'] ?? json['record_type'],
        content: json['content'],
        costTime: json['costTime'] ?? json['cost_time'],
        triggerReason: json['triggerReason'] ?? json['trigger_reason'],
        emotionScore: json['emotionScore'] ?? json['emotion_score'],
        recordDate: json['recordDate'] ?? json['record_date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (recordType != null) 'recordType': recordType,
        if (content != null) 'content': content,
        if (costTime != null) 'costTime': costTime,
        if (triggerReason != null) 'triggerReason': triggerReason,
        if (emotionScore != null) 'emotionScore': emotionScore,
        if (recordDate != null) 'recordDate': recordDate,
      };

  String get typeLabel {
    const map = {1: '学习', 2: '作息', 3: '情绪', 4: '拖延', 5: '短视频', 6: '私密杂念'};
    return map[recordType] ?? '其他';
  }
}
