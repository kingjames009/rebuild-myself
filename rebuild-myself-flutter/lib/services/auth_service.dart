class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<String> today() async {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  Map<String, String> weekRange() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return {
      'start': '${monday.year}-${_pad(monday.month)}-${_pad(monday.day)}',
      'end': '${sunday.year}-${_pad(sunday.month)}-${_pad(sunday.day)}',
    };
  }

  Map<String, String> monthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return {
      'start': '${start.year}-${_pad(start.month)}-${_pad(start.day)}',
      'end': '${end.year}-${_pad(end.month)}-${_pad(end.day)}',
    };
  }

  String formatDate(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

  String _pad(int n) => n.toString().padLeft(2, '0');
}
