class LifeEssentialConfig {
  final int? id;
  final int? userId;
  final int category; // 1锻炼2阅读3冥想4技能5休闲
  final String name;
  final int defaultDuration;
  final String? variants; // JSON array string
  final int energyLevel; // 1-3
  final int minWeeklyFreq;
  final int maxWeeklyFreq;
  final String preferredPeriod; // morning/afternoon/evening/night/any
  final int enabled; // 0/1
  final String? createTime;

  LifeEssentialConfig({
    this.id,
    this.userId,
    required this.category,
    required this.name,
    this.defaultDuration = 30,
    this.variants,
    this.energyLevel = 1,
    this.minWeeklyFreq = 1,
    this.maxWeeklyFreq = 7,
    this.preferredPeriod = 'any',
    this.enabled = 1,
    this.createTime,
  });

  factory LifeEssentialConfig.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v, [int d = 0]) {
      if (v == null) return d;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? d;
      return d;
    }

    return LifeEssentialConfig(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      category: parse(json['category']),
      name: json['name'] ?? '',
      defaultDuration: parse(json['defaultDuration'] ?? json['default_duration'], 30),
      variants: json['variants'],
      energyLevel: parse(json['energyLevel'] ?? json['energy_level'], 1),
      minWeeklyFreq: parse(json['minWeeklyFreq'] ?? json['min_weekly_freq'], 1),
      maxWeeklyFreq: parse(json['maxWeeklyFreq'] ?? json['max_weekly_freq'], 7),
      preferredPeriod: json['preferredPeriod'] ?? json['preferred_period'] ?? 'any',
      enabled: parse(json['enabled'], 1),
      createTime: json['createTime'] ?? json['create_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'category': category,
        'name': name,
        'defaultDuration': defaultDuration,
        if (variants != null) 'variants': variants,
        'energyLevel': energyLevel,
        'minWeeklyFreq': minWeeklyFreq,
        'maxWeeklyFreq': maxWeeklyFreq,
        'preferredPeriod': preferredPeriod,
        'enabled': enabled,
      };

  static const categoryLabels = ['', '锻炼', '阅读', '冥想', '技能', '休闲'];
  static const periodLabels = {
    'morning': '上午',
    'afternoon': '下午',
    'evening': '晚间',
    'night': '睡前',
    'any': '任意',
  };

  String get categoryLabel =>
      category < categoryLabels.length ? categoryLabels[category] : '其他';
  String get periodLabel => periodLabels[preferredPeriod] ?? preferredPeriod;
}
