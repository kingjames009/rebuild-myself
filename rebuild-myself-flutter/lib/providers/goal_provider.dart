import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../services/api_client.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  List<TaskTodo> _tasks = [];
  bool _loading = false;

  List<Goal> get goals => _goals;
  List<TaskTodo> get tasks => _tasks;
  bool get loading => _loading;

  List<Goal> goalsByLevel(int level) => _goals.where((g) => g.goalLevel == level).toList();
  List<TaskTodo> tasksByQuadrant(int q) => _tasks.where((t) => t.taskLevel == q).toList();

  final _api = ApiClient();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      final goals = <Goal>[];
      for (final level in [1, 2, 3, 4]) {
        final resp = await _api.get('/goal/list', params: {'level': level});
        if (resp.ok && resp.data is List) {
          for (final g in resp.data) {
            goals.add(Goal.fromJson(g));
          }
        }
      }
      _goals = goals;

      final today = _today();
      final taskResp = await _api.get('/task/list', params: {'date': today});
      if (taskResp.ok && taskResp.data is List) {
        _tasks = (taskResp.data as List).map((t) => TaskTodo.fromJson(t)).toList();
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    final resp = await _api.post('/goal', data: goal.toJson());
    if (resp.ok) await loadAll();
  }

  Future<void> updateGoal(Goal goal) async {
    final resp = await _api.put('/goal', data: goal.toJson());
    if (resp.ok) await loadAll();
  }

  Future<void> deleteGoal(int goalId) async {
    final resp = await _api.delete('/goal/$goalId');
    if (resp.ok) await loadAll();
  }

  Future<void> addTask(TaskTodo task) async {
    final resp = await _api.post('/task', data: task.toJson());
    if (resp.ok) await loadAll();
  }

  Future<void> toggleTask(int taskId, bool completed) async {
    final resp = await _api.put('/task/toggle/$taskId');
    if (resp.ok) await loadAll();
  }

  Future<void> deleteTask(int taskId) async {
    final resp = await _api.delete('/task/$taskId');
    if (resp.ok) await loadAll();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
