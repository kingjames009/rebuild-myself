class EmptyMoodLog {
  final int? id;
  final int? userId;
  final int? emptyLevel;
  final double? emptyHours;
  final String? triggerCause;
  final double? wasteHours;
  final String? recordDate;
  final String? createTime;

  EmptyMoodLog({
    this.id,
    this.userId,
    this.emptyLevel,
    this.emptyHours,
    this.triggerCause,
    this.wasteHours,
    this.recordDate,
    this.createTime,
  });

  factory EmptyMoodLog.fromJson(Map<String, dynamic> json) => EmptyMoodLog(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        emptyLevel: json['emptyLevel'] ?? json['empty_level'],
        emptyHours: (json['emptyHours'] ?? json['empty_hours'] ?? 0).toDouble(),
        triggerCause: json['triggerCause'] ?? json['trigger_cause'],
        wasteHours: (json['wasteHours'] ?? json['waste_hours'] ?? 0).toDouble(),
        recordDate: json['recordDate'] ?? json['record_date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  EmptyMoodLog copyWith({int? id}) => EmptyMoodLog(
        id: id ?? this.id,
        userId: userId,
        emptyLevel: emptyLevel,
        emptyHours: emptyHours,
        triggerCause: triggerCause,
        wasteHours: wasteHours,
        recordDate: recordDate,
        createTime: createTime,
      );

  Map<String, dynamic> toJson() => {
        if (emptyLevel != null) 'emptyLevel': emptyLevel,
        if (emptyHours != null) 'emptyHours': emptyHours,
        if (triggerCause != null) 'triggerCause': triggerCause,
        if (wasteHours != null) 'wasteHours': wasteHours,
        if (recordDate != null) 'recordDate': recordDate,
      };
}
