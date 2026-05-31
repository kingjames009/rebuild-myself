class VentingEntry {
  final int? id;
  final int? userId;
  final String? recordDate;
  final String? content;
  final String? createTime;

  VentingEntry({
    this.id,
    this.userId,
    this.recordDate,
    this.content,
    this.createTime,
  });

  factory VentingEntry.fromJson(Map<String, dynamic> json) => VentingEntry(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        recordDate: json['recordDate'] ?? json['record_date'],
        content: json['content'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  VentingEntry copyWith({int? id, String? content}) => VentingEntry(
        id: id ?? this.id,
        userId: userId,
        recordDate: recordDate,
        content: content ?? this.content,
        createTime: createTime,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (recordDate != null) 'recordDate': recordDate,
        if (content != null) 'content': content,
        if (createTime != null) 'createTime': createTime,
      };
}
