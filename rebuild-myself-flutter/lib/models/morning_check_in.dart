class MorningCheckIn {
  final int? id;
  final String date;
  final double sleepHours;
  final int anxietyLevel;
  final int protectionLevel;
  final String? createTime;

  MorningCheckIn({
    this.id,
    required this.date,
    required this.sleepHours,
    required this.anxietyLevel,
    required this.protectionLevel,
    this.createTime,
  });

  /// Compute protection level from sleep and anxiety.
  /// Green (1): sleep >= 6 AND anxiety <= 2 — standard
  /// Yellow (2): one factor is poor — body anchoring
  /// Red (3): both factors are poor — physical interruption
  static int computeProtection(double sleep, int anxiety) {
    if (sleep >= 6 && anxiety <= 2) return 1;
    if (sleep < 6 && anxiety >= 4) return 3;
    return 2;
  }

  factory MorningCheckIn.fromJson(Map<String, dynamic> json) => MorningCheckIn(
        id: json['id'],
        date: (json['date'] ?? '').toString(),
        sleepHours: (json['sleepHours'] ?? json['sleep_hours'] ?? 7).toDouble(),
        anxietyLevel: json['anxietyLevel'] ?? json['anxiety_level'] ?? 1,
        protectionLevel: json['protectionLevel'] ?? json['protection_level'] ?? 1,
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'sleep_hours': sleepHours,
        'anxiety_level': anxietyLevel,
        'protection_level': protectionLevel,
        if (createTime != null) 'create_time': createTime,
      };

  String get protectionLabel {
    switch (protectionLevel) {
      case 1: return '绿';
      case 2: return '黄';
      case 3: return '红';
      default: return '未自检';
    }
  }
}
