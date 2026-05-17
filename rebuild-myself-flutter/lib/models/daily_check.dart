class DailyCompareCheck {
  final int? checkId;
  final int? userId;
  final String? planDate;
  final String? deviationContent;
  final String? escapeReason;
  final int? progressScore;
  final String? createTime;

  DailyCompareCheck({
    this.checkId,
    this.userId,
    this.planDate,
    this.deviationContent,
    this.escapeReason,
    this.progressScore,
    this.createTime,
  });

  factory DailyCompareCheck.fromJson(Map<String, dynamic> json) =>
      DailyCompareCheck(
        checkId: json['checkId'] ?? json['check_id'],
        userId: json['userId'] ?? json['user_id'],
        planDate: json['planDate'] ?? json['plan_date'],
        deviationContent: json['deviationContent'] ?? json['deviation_content'],
        escapeReason: json['escapeReason'] ?? json['escape_reason'],
        progressScore: json['progressScore'] ?? json['progress_score'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (planDate != null) 'planDate': planDate,
        if (deviationContent != null) 'deviationContent': deviationContent,
        if (escapeReason != null) 'escapeReason': escapeReason,
        if (progressScore != null) 'progressScore': progressScore,
      };
}
