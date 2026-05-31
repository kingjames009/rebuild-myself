class DailySummaryEntry {
  final int? id;
  final int? userId;
  final String? recordDate;
  final String? content;
  final String? createTime;

  DailySummaryEntry({this.id, this.userId, this.recordDate, this.content, this.createTime});

  factory DailySummaryEntry.fromJson(Map<String, dynamic> json) => DailySummaryEntry(
        id: json['id'] ?? json['record_id'],
        userId: json['userId'] ?? json['user_id'],
        recordDate: json['recordDate'] ?? json['record_date'],
        content: json['content'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'userId': userId,
        if (recordDate != null) 'recordDate': recordDate,
        if (content != null) 'content': content,
        if (createTime != null) 'createTime': createTime,
      };

  DailySummaryEntry copyWith({int? id, String? content}) => DailySummaryEntry(
        id: id ?? this.id,
        userId: userId,
        recordDate: recordDate,
        content: content ?? this.content,
        createTime: createTime,
      );
}
