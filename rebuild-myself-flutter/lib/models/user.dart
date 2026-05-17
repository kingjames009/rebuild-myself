class User {
  final int? userId;
  final String? phone;
  final String? nickname;
  final String? avatar;
  final String? longTermGoal;
  final String? createTime;
  final String? updateTime;
  final double? height;
  final double? weight;
  final String? healthNote;

  User({
    this.userId,
    this.phone,
    this.nickname,
    this.avatar,
    this.longTermGoal,
    this.createTime,
    this.updateTime,
    this.height,
    this.weight,
    this.healthNote,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'],
        phone: json['phone'],
        nickname: json['nickname'] ?? '自律用户',
        avatar: json['avatar'],
        longTermGoal: json['longTermGoal'] ?? json['long_term_goal'],
        createTime: json['createTime'] ?? json['create_time'],
        updateTime: json['updateTime'] ?? json['update_time'],
        height: _parseDouble(json['height']),
        weight: _parseDouble(json['weight']),
        healthNote: json['healthNote'] ?? json['health_note'],
      );

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        if (nickname != null) 'nickname': nickname,
        if (avatar != null) 'avatar': avatar,
        if (longTermGoal != null) 'longTermGoal': longTermGoal,
        if (longTermGoal != null) 'long_term_goal': longTermGoal,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (healthNote != null) 'healthNote': healthNote,
      };
}
