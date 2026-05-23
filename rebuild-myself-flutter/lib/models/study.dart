class StudyTrackRecord {
  final int? id;
  final int? userId;
  final String? trackType;
  final String? studyContent;
  final int? studyMinutes;
  final int? difficultyLevel;
  final int? escapeStatus;
  final String? recordDate;
  final String? createTime;

  StudyTrackRecord({
    this.id,
    this.userId,
    this.trackType,
    this.studyContent,
    this.studyMinutes,
    this.difficultyLevel,
    this.escapeStatus,
    this.recordDate,
    this.createTime,
  });

  factory StudyTrackRecord.fromJson(Map<String, dynamic> json) =>
      StudyTrackRecord(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        trackType: json['trackType'] ?? json['track_type']?.toString(),
        studyContent: json['studyContent'] ?? json['study_content'] ?? json['content'],
        studyMinutes: json['studyMinutes'] ?? json['study_minutes'] ?? json['minutes'],
        difficultyLevel: json['difficultyLevel'] ?? json['difficulty_level'] ?? json['difficulty'],
        escapeStatus: json['escapeStatus'] ?? json['escape_status'] ?? (json['escapeStatus'] == true ? 1 : 0),
        recordDate: json['recordDate'] ?? json['record_date'] ?? json['date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  StudyTrackRecord copyWith({int? id}) => StudyTrackRecord(
        id: id ?? this.id,
        userId: userId,
        trackType: trackType,
        studyContent: studyContent,
        studyMinutes: studyMinutes,
        difficultyLevel: difficultyLevel,
        escapeStatus: escapeStatus,
        recordDate: recordDate,
        createTime: createTime,
      );

  Map<String, dynamic> toJson() => {
        if (trackType != null) 'trackType': trackType,
        if (studyContent != null) 'content': studyContent,
        if (studyMinutes != null) 'minutes': studyMinutes,
        if (difficultyLevel != null) 'difficulty': difficultyLevel,
        if (escapeStatus != null) 'escapeStatus': escapeStatus == 1,
        if (recordDate != null) 'date': recordDate,
      };

  String get trackLabel {
    const map = {'speech': '英语演讲', 'ai': 'AI学习', 'app': '应用开发'};
    return map[trackType] ?? trackType ?? '未知';
  }

  bool get isEscaped => escapeStatus == 1;
}
