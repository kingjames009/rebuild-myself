import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/database_helper.dart';

class ReadingProvider extends ChangeNotifier {
  List<BookReadRecord> _records = [];
  bool _loading = false;

  List<BookReadRecord> get records => _records;
  bool get loading => _loading;

  List<BookReadRecord> get wealthBooks => _records.where((r) => r.bookType == '1' || r.bookType == 'wealth').toList();
  List<BookReadRecord> get psychologyBooks => _records.where((r) => r.bookType == '2' || r.bookType == 'psychology').toList();
  List<BookReadRecord> get humanityBooks => _records.where((r) => r.bookType == '3' || r.bookType == 'humanity').toList();

  int get totalMinutes => _records.fold(0, (sum, r) => sum + (r.readMinutes ?? 0));

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('book_read_record', orderBy: 'create_time DESC');
    _records = rows.map((r) => BookReadRecord.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(BookReadRecord record) async {
    final db = await DatabaseHelper().db;
    final newId = await db.insert('book_read_record', record.toJson());
    _records.insert(0, record.copyWith(id: newId));
    notifyListeners();
  }

  Future<void> update(BookReadRecord record) async {
    final db = await DatabaseHelper().db;
    await db.update('book_read_record', record.toJson(), where: 'id = ?', whereArgs: [record.id]);
    for (int i = 0; i < _records.length; i++) {
      if (_records[i].id == record.id) { _records[i] = record; break; }
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('book_read_record', where: 'id = ?', whereArgs: [id]);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
