import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study.dart';
import '../services/database_helper.dart';
import '../services/api_client.dart';

class FocusTimerProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool _isPaused = false;
  int _targetSeconds = 25 * 60; // default 25 min
  String? _planDate;
  String? _timePeriod;
  String? _planContent;
  String _trackType = 'ai';
  Timer? _ticker;

  // Wall-clock based timing — survives background/screen-off
  DateTime? _startedAt;
  int _accumulatedSeconds = 0; // elapsed before last pause

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get targetSeconds => _targetSeconds;
  String? get planDate => _planDate;
  String? get timePeriod => _timePeriod;
  String? get planContent => _planContent;
  String get trackType => _trackType;

  /// True elapsed seconds from wall clock
  int get elapsedSeconds {
    if (!_isRunning) return 0;
    if (_isPaused) return _accumulatedSeconds;
    final since = _startedAt != null
        ? DateTime.now().difference(_startedAt!).inSeconds
        : 0;
    return (_accumulatedSeconds + since).clamp(0, _targetSeconds);
  }

  /// Remaining seconds from wall clock
  int get remainingSeconds {
    if (!_isRunning) return 0;
    return (_targetSeconds - elapsedSeconds).clamp(0, _targetSeconds);
  }

  /// Remaining time formatted as MM:SS or HH:MM:SS
  String get formattedTime {
    final total = remainingSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Elapsed time formatted as MM:SS
  String get formattedElapsed {
    final e = elapsedSeconds;
    final h = e ~/ 3600;
    final m = (e % 3600) ~/ 60;
    final s = e % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedTarget {
    final m = _targetSeconds ~/ 60;
    if (m >= 60) return '${m ~/ 60}小时${m % 60}分钟';
    return '$m分钟';
  }

  /// Progress: 0 = not started, 1 = fully used
  double get progress {
    if (_targetSeconds <= 0) return 0;
    return (elapsedSeconds / _targetSeconds).clamp(0.0, 1.0);
  }

  bool get isCompleted => _isRunning && remainingSeconds <= 0 && _targetSeconds > 0;

  bool matchesPlan(String date, String period) {
    return _isRunning && _planDate == date && _timePeriod == period;
  }

  void setTrackType(String type) {
    _trackType = type;
    notifyListeners();
  }

  void setTarget(int minutes) {
    _targetSeconds = minutes * 60;
    notifyListeners();
  }

  void startTimer({
    required int minutes,
    required String planDate,
    required String timePeriod,
    required String planContent,
  }) {
    _targetSeconds = minutes * 60;
    _accumulatedSeconds = 0;
    _startedAt = DateTime.now();
    _planDate = planDate;
    _timePeriod = timePeriod;
    _planContent = planContent;
    _isRunning = true;
    _isPaused = false;
    _startTicking();
    notifyListeners();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds <= 0 && _targetSeconds > 0) {
        // Auto-pause when countdown reaches 0
        _accumulatedSeconds = _targetSeconds;
        _isPaused = true;
        _ticker?.cancel();
      }
      notifyListeners();
    });
  }

  void pauseTimer() {
    if (!_isRunning || _isPaused) return;
    // Accumulate elapsed since last start
    if (_startedAt != null) {
      _accumulatedSeconds += DateTime.now().difference(_startedAt!).inSeconds;
      if (_accumulatedSeconds > _targetSeconds) _accumulatedSeconds = _targetSeconds;
    }
    _isPaused = true;
    _ticker?.cancel();
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isRunning || !_isPaused) return;
    _startedAt = DateTime.now();
    _isPaused = false;
    _startTicking();
    notifyListeners();
  }

  /// Stop and save elapsed time as study record. Returns the minutes saved.
  Future<int> stopTimer() async {
    if (!_isRunning) return 0;
    // Finalize elapsed from wall clock
    if (!_isPaused && _startedAt != null) {
      _accumulatedSeconds += DateTime.now().difference(_startedAt!).inSeconds;
    }
    if (_accumulatedSeconds > _targetSeconds) _accumulatedSeconds = _targetSeconds;
    _ticker?.cancel();
    _isRunning = false;
    _isPaused = false;
    final mins = _accumulatedSeconds ~/ 60;
    final date = _planDate;
    final content = _planContent;
    final track = _trackType;
    _planDate = null;
    _timePeriod = null;
    _planContent = null;
    _startedAt = null;
    _accumulatedSeconds = 0;
    _targetSeconds = 25 * 60;
    notifyListeners();

    if (mins > 0 && date != null) {
      final record = StudyTrackRecord(
        trackType: track,
        studyContent: content ?? '专注计时学习',
        studyMinutes: mins,
        difficultyLevel: 3,
        escapeStatus: 0,
        recordDate: date,
      );

      final db = await DatabaseHelper().db;
      await db.insert('study_track_record', record.toJson());

      // Mark the corresponding daily plan as completed
      final period = _timePeriod;
      if (period != null) {
        await db.update('daily_model_plan', {
          'isCompleted': 1,
          'is_completed': 1,
          'completedAt': DateTime.now().toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
        }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [date, period]);
        await db.update('daily_model_plan', {
          'isCompleted': 1,
          'is_completed': 1,
          'completedAt': DateTime.now().toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
        }, where: 'plan_date = ? AND time_period = ?', whereArgs: [date, period]);
      }

      final api = ApiClient();
      if (api.hasToken) {
        try {
          await api.post('/study/add', data: {
            'trackType': track,
            'content': content ?? '专注计时学习',
            'minutes': mins,
            'difficulty': 3,
            'escapeStatus': false,
            'date': date,
          });
        } catch (_) {}
      }

      return mins;
    }
    return 0;
  }

  /// Cancel timer without saving
  void cancelTimer() {
    _ticker?.cancel();
    _isRunning = false;
    _isPaused = false;
    _planDate = null;
    _timePeriod = null;
    _planContent = null;
    _startedAt = null;
    _accumulatedSeconds = 0;
    _targetSeconds = 25 * 60;
    notifyListeners();
  }

  /// Total elapsed minutes today (live, for home page stat)
  int get todayElapsedMinutes => _isRunning ? elapsedSeconds ~/ 60 : 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
