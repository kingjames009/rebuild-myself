class AiReport {
  final int? reportId;
  final int? userId;
  final int? cycleType;
  final String? cycleRange;
  final String? originalData;
  final String? reportContent;
  final String? createTime;

  AiReport({
    this.reportId,
    this.userId,
    this.cycleType,
    this.cycleRange,
    this.originalData,
    this.reportContent,
    this.createTime,
  });

  factory AiReport.fromJson(Map<String, dynamic> json) => AiReport(
        reportId: json['reportId'] ?? json['report_id'],
        userId: json['userId'] ?? json['user_id'],
        cycleType: json['cycleType'] ?? json['cycle_type'],
        cycleRange: json['cycleRange'] ?? json['cycle_range'],
        originalData: json['originalData'] ?? json['original_data'],
        reportContent: json['reportContent'] ?? json['report_content'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (cycleType != null) 'cycleType': cycleType,
        if (cycleRange != null) 'cycleRange': cycleRange,
        if (reportContent != null) 'reportContent': reportContent,
      };

  String get cycleLabel {
    const map = {1: '日复盘', 2: '周复盘', 3: '月复盘', 4: '年复盘'};
    return map[cycleType] ?? '复盘';
  }

  String get summary {
    if (reportContent == null || reportContent!.isEmpty) return '暂无内容';
    final lines = reportContent!.split('\n');
    for (final line in lines) {
      final trimmed = line.replaceAll(RegExp(r'^[#*\s\-]+'), '').trim();
      if (trimmed.isNotEmpty && trimmed.length > 3 && !trimmed.startsWith('好的') && !trimmed.startsWith('基于此')) {
        return '${trimmed.substring(0, trimmed.length.clamp(0, 60))}...';
      }
    }
    return '${reportContent!.substring(0, reportContent!.length.clamp(0, 60))}...';
  }
}
