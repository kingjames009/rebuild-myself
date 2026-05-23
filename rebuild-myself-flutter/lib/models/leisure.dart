class LifeLeisureRecord {
  final int? id;
  final int? userId;
  final String? leisureType;
  final int? leisureMinutes;
  final int? happyScore;
  final int? arrangeState;
  final String? recordDate;
  final String? createTime;

  LifeLeisureRecord({
    this.id,
    this.userId,
    this.leisureType,
    this.leisureMinutes,
    this.happyScore,
    this.arrangeState,
    this.recordDate,
    this.createTime,
  });

  factory LifeLeisureRecord.fromJson(Map<String, dynamic> json) =>
      LifeLeisureRecord(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        leisureType: json['leisureType'] ?? json['leisure_type']?.toString() ?? json['type']?.toString(),
        leisureMinutes: json['leisureMinutes'] ?? json['leisure_minutes'] ?? json['minutes'],
        happyScore: json['happyScore'] ?? json['happy_score'] ?? json['happyScore'],
        arrangeState: json['arrangeState'] ?? json['arrange_state'],
        recordDate: json['recordDate'] ?? json['record_date'] ?? json['date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (leisureType != null) 'type': leisureType,
        if (leisureMinutes != null) 'minutes': leisureMinutes,
        if (happyScore != null) 'happyScore': happyScore,
        if (recordDate != null) 'date': recordDate,
      };

  LifeLeisureRecord copyWith({int? id}) => LifeLeisureRecord(
        id: id ?? this.id,
        userId: userId,
        leisureType: leisureType,
        leisureMinutes: leisureMinutes,
        happyScore: happyScore,
        arrangeState: arrangeState,
        recordDate: recordDate,
        createTime: createTime,
      );

  String get typeLabel {
    const map = {
      'relax': '放松', 'meditate': '冥想', 'quotes': '治愈短句',
      'stretch': '拉伸', 'organize': '环境整理', 'knowledge': '碎片新知',
    };
    return map[leisureType] ?? leisureType ?? '未知';
  }
}
