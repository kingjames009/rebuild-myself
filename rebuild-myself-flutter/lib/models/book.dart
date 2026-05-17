class BookReadRecord {
  final int? id;
  final int? userId;
  final String? bookType;
  final String? bookName;
  final int? readMinutes;
  final int? readProgress;
  final String? bookNotes;
  final int? escapeStatus;
  final String? recordDate;
  final String? createTime;

  BookReadRecord({
    this.id,
    this.userId,
    this.bookType,
    this.bookName,
    this.readMinutes,
    this.readProgress,
    this.bookNotes,
    this.escapeStatus,
    this.recordDate,
    this.createTime,
  });

  factory BookReadRecord.fromJson(Map<String, dynamic> json) => BookReadRecord(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        bookType: json['bookType'] ?? json['book_type']?.toString(),
        bookName: json['bookName'] ?? json['book_name'],
        readMinutes: json['readMinutes'] ?? json['read_minutes'],
        readProgress: json['readProgress'] ?? json['read_progress'] ?? json['progress'],
        bookNotes: json['bookNotes'] ?? json['book_notes'] ?? json['notes'],
        escapeStatus: json['escapeStatus'] ?? json['escape_status'] ?? (json['escapeStatus'] == true ? 1 : 0),
        recordDate: json['recordDate'] ?? json['record_date'] ?? json['date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (bookType != null) 'bookType': bookType,
        if (bookName != null) 'bookName': bookName,
        if (readMinutes != null) 'readMinutes': readMinutes,
        if (readProgress != null) 'progress': readProgress,
        if (bookNotes != null) 'notes': bookNotes,
        if (escapeStatus != null) 'escapeStatus': escapeStatus == 1,
        if (recordDate != null) 'date': recordDate,
      };

  String get typeLabel {
    const map = {'wealth': '财商赚钱', 'psychology': '心理成长', 'humanity': '人文休闲'};
    return map[bookType] ?? bookType ?? '未知';
  }

  bool get isEscaped => escapeStatus == 1;
}
