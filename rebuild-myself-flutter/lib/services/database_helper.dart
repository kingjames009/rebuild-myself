import 'local_storage.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  LocalStorage? __db;

  Future<LocalStorage> get db async {
    if (__db != null) return __db!;
    __db = LocalStorage();
    await _seedIfNeeded(__db!);
    return __db!;
  }

  Future<void> _seedIfNeeded(LocalStorage db) async {
    final habits = await db.query('elite_habit_lib');
    if (habits.isEmpty) {
      final seed = [
        {'habit_category': 1, 'habit_content': '6:30 起床，喝一杯温水', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 1, 'habit_content': '5分钟晨间拉伸', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 1, 'habit_content': '写下今日最重要的3件事', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '每45分钟休息3分钟', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '午休不超过30分钟', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '用绿茶替代下午茶', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '正念工作：专注于当前任务，暂停脑中杂音', 'intensity_level': 3, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '工作人际调节：遇到分歧或不愉快，先觉察自己的情绪反应，深呼吸3次，不急于回击也不压抑，冷静后选择最有利于局面的回应方式', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '边界守护：专注自己的工作，不卷入他人情绪', 'intensity_level': 3, 'suit_body_type': 0},
        {'habit_category': 2, 'habit_content': '注意力锚点：每45分钟起身伸展，重置注意力', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 3, 'habit_content': '下班后过渡放松10分钟', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 3, 'habit_content': '30分钟微学习', 'intensity_level': 3, 'suit_body_type': 0},
        {'habit_category': 3, 'habit_content': '20分钟副业推进', 'intensity_level': 3, 'suit_body_type': 0},
        {'habit_category': 3, 'habit_content': '20分钟阅读', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 4, 'habit_content': '22:30 远离屏幕', 'intensity_level': 2, 'suit_body_type': 0},
        {'habit_category': 4, 'habit_content': '5分钟冥想放松', 'intensity_level': 1, 'suit_body_type': 0},
        {'habit_category': 4, 'habit_content': '5分钟复盘今日', 'intensity_level': 1, 'suit_body_type': 0},
      ];
      for (final h in seed) {
        await db.insert('elite_habit_lib', Map<String, dynamic>.from(h));
      }
    }
  }
}
