class UserAspiration {
  final int? id;
  final int? userId;
  final String content;
  final int category; // 0通用1学习2副业3阅读4休闲5健康6技能
  final int priority; // 1-5
  final int status; // 0待安排1进行中2已完成
  final int scheduleCount;
  final String? startDate;
  final String? endDate;
  final String? createTime;

  UserAspiration({
    this.id,
    this.userId,
    required this.content,
    this.category = 0,
    this.priority = 3,
    this.status = 0,
    this.scheduleCount = 0,
    this.startDate,
    this.endDate,
    this.createTime,
  });

  factory UserAspiration.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v, [int d = 0]) {
      if (v == null) return d;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? d;
      return d;
    }

    String? str(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    return UserAspiration(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      content: json['content'] ?? '',
      category: parse(json['category']),
      priority: parse(json['priority'], 3),
      status: parse(json['status']),
      scheduleCount: parse(json['scheduleCount'] ?? json['schedule_count']),
      startDate: str(json['startDate'] ?? json['start_date']),
      endDate: str(json['endDate'] ?? json['end_date']),
      createTime: json['createTime'] ?? json['create_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'content': content,
        'category': category,
        'priority': priority,
        'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

  static const categoryLabels = ['通用', '学习', '副业', '阅读', '休闲', '健康', '技能'];
  static const statusLabels = ['待安排', '进行中', '已完成'];

  String get categoryLabel =>
      category < categoryLabels.length ? categoryLabels[category] : '通用';
  String get statusLabel =>
      status < statusLabels.length ? statusLabels[status] : '未知';

  String get dateRangeLabel {
    if (startDate == null && endDate == null) return '无限期';
    if (startDate != null && endDate != null) return '$startDate ~ $endDate';
    if (startDate != null) return '${startDate}起';
    return '至$endDate';
  }

  bool get isExpired {
    final ed = endDate;
    if (ed == null) return false;
    final end = DateTime.tryParse(ed);
    if (end == null) return false;
    return DateTime.now().isAfter(end.add(const Duration(days: 1)));
  }
}
