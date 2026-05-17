class SidelinePlan {
  final int? id;
  final int? userId;
  final String? sideType;
  final String? dailyAction;
  final int? progress;
  final String? blockReason;
  final int? energyCost;
  final String? recordDate;
  final String? createTime;

  SidelinePlan({
    this.id,
    this.userId,
    this.sideType,
    this.dailyAction,
    this.progress,
    this.blockReason,
    this.energyCost,
    this.recordDate,
    this.createTime,
  });

  factory SidelinePlan.fromJson(Map<String, dynamic> json) => SidelinePlan(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        sideType: json['sideType'] ?? json['side_type']?.toString(),
        dailyAction: json['dailyAction'] ?? json['daily_action'] ?? json['dailyAction'],
        progress: json['progress'],
        blockReason: json['blockReason'] ?? json['block_reason'],
        energyCost: json['energyCost'] ?? json['energy_cost'],
        recordDate: json['recordDate'] ?? json['record_date'] ?? json['date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (sideType != null) 'sideType': sideType,
        if (dailyAction != null) 'dailyAction': dailyAction,
        if (energyCost != null) 'energyCost': energyCost,
        if (blockReason != null) 'blockReason': blockReason,
        if (recordDate != null) 'date': recordDate,
      };

  String get typeLabel {
    const map = {'english': '英语方向', 'ai': 'AI方向', 'dev': '开发综合'};
    return map[sideType] ?? sideType ?? '未知';
  }
}
