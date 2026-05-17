class CustomPriorityItem {
  final int? id;
  final String content;
  final String preferredSegment; // '上班前' / '午休' / '下班后'
  final String? createTime;

  CustomPriorityItem({
    this.id,
    required this.content,
    this.preferredSegment = '下班后',
    this.createTime,
  });

  static const segments = ['上班前', '午休', '下班后'];

  factory CustomPriorityItem.fromJson(Map<String, dynamic> json) =>
      CustomPriorityItem(
        id: json['id'],
        content: json['content'] ?? '',
        preferredSegment: json['preferredSegment'] ?? json['preferred_segment'] ?? '下班后',
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'content': content,
        'preferredSegment': preferredSegment,
        if (createTime != null) 'createTime': createTime,
      };

  CustomPriorityItem copy() => CustomPriorityItem(
        id: id,
        content: content,
        preferredSegment: preferredSegment,
        createTime: createTime,
      );
}
