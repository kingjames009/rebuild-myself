import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study.dart';
import '../services/database_helper.dart';
import '../services/api_client.dart';

class FocusTimerProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool _isPaused = false;
  bool _autoSaved = false; // true after _autoSaveCompleted prevents duplicate saves
  int _targetSeconds = 25 * 60;
  String? _planDate;
  String? _timePeriod;
  String? _planContent;
  String _trackType = 'ai';
  Timer? _ticker;

  DateTime? _startedAt;
  int _accumulatedSeconds = 0;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get targetSeconds => _targetSeconds;
  String? get planDate => _planDate;
  String? get timePeriod => _timePeriod;
  String? get planContent => _planContent;
  String get trackType => _trackType;

  int get elapsedSeconds {
    if (!_isRunning) return 0;
    if (_isPaused) return _accumulatedSeconds;
    final since = _startedAt != null
        ? DateTime.now().difference(_startedAt!).inSeconds
        : 0;
    return (_accumulatedSeconds + since).clamp(0, _targetSeconds);
  }

  int get remainingSeconds {
    if (!_isRunning) return 0;
    return (_targetSeconds - elapsedSeconds).clamp(0, _targetSeconds);
  }

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

  double get progress {
    if (_targetSeconds <= 0) return 0;
    return (elapsedSeconds / _targetSeconds).clamp(0.0, 1.0);
  }

  bool get isCompleted =>
      _isRunning && remainingSeconds <= 0 && _targetSeconds > 0;

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

  // ── Session persistence ──────────────────────────────────────────
  // Timer state is saved to the timer_session table on every state
  // change so that app restarts / crashes never lose progress.
  // The table has at most 1 row (id = 1).

  Future<void> _saveSession() async {
    final db = await DatabaseHelper().db;
    await db.delete('timer_session');
    if (_isRunning) {
      await db.insert('timer_session', {
        'id': 1,
        'planDate': _planDate,
        'plan_date': _planDate,
        'timePeriod': _timePeriod,
        'time_period': _timePeriod,
        'planContent': _planContent,
        'plan_content': _planContent,
        'trackType': _trackType,
        'track_type': _trackType,
        'accumulatedSeconds': _accumulatedSeconds,
        'accumulated_seconds': _accumulatedSeconds,
        'startedAt': _startedAt?.toIso8601String(),
        'started_at': _startedAt?.toIso8601String(),
        'isPaused': _isPaused ? 1 : 0,
        'is_paused': _isPaused ? 1 : 0,
        'targetSeconds': _targetSeconds,
        'target_seconds': _targetSeconds,
      });
    }
  }

  Future<void> _clearSession() async {
    final db = await DatabaseHelper().db;
    await db.delete('timer_session');
  }

  /// Public — called by the home page on app lifecycle pause to
  /// persist the current timer state before the app goes to background.
  Future<void> persistSession() => _saveSession();

  /// Called once after the provider is created to restore any
  /// timer session that was interrupted by app close / crash.
  Future<void> restoreSession() async {
    final db = await DatabaseHelper().db;
    final rows = await db.query('timer_session');
    if (rows.isEmpty) {
      // No persisted session. If in-memory state is still running
      // (e.g. from auto-save that cleared the session but didn't
      // reset state), clean it up so the MiniStat doesn't double-count.
      if (_isRunning) {
        _isRunning = false;
        _isPaused = false;
        _accumulatedSeconds = 0;
      }
      return;
    }
    final r = rows.first;

    final sessionDate =
        (r['planDate'] ?? r['plan_date'] ?? '').toString();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Only restore today's session — stale cross-day sessions are discarded.
    if (sessionDate != today) {
      await _clearSession();
      return;
    }

    _planDate = sessionDate;
    _timePeriod =
        (r['timePeriod'] ?? r['time_period'] ?? '').toString();
    _planContent =
        (r['planContent'] ?? r['plan_content'] ?? '').toString();
    _trackType =
        (r['trackType'] ?? r['track_type'] ?? 'ai').toString();
    _accumulatedSeconds =
        (r['accumulatedSeconds'] ?? r['accumulated_seconds'] ?? 0) as int;
    _targetSeconds =
        (r['targetSeconds'] ?? r['target_seconds'] ?? 25 * 60) as int;

    final isPausedVal = r['isPaused'] ?? r['is_paused'] ?? 0;
    _isPaused = isPausedVal == 1 || isPausedVal == true;

    final startedAtStr =
        (r['startedAt'] ?? r['started_at'] ?? '').toString();
    if (startedAtStr.isNotEmpty) {
      _startedAt = DateTime.tryParse(startedAtStr);
    }

    _isRunning = true;

    // If the session was actively running (not paused), advance
    // elapsed by the wall-clock gap and reset the anchor.
    if (!_isPaused && _startedAt != null) {
      final wallDiff =
          DateTime.now().difference(_startedAt!).inSeconds;
      _accumulatedSeconds =
          (_accumulatedSeconds + wallDiff).clamp(0, _targetSeconds);
      _startedAt = DateTime.now();
      _startTicking();
    }

    if (mounted) notifyListeners();
  }

  /// Whether this ChangeNotifier is still attached to listeners.
  /// (ChangeNotifier doesn't expose this, so we use a simple flag.)
  bool _mounted = true;
  bool get mounted => _mounted;

  // ── Timer logic ──────────────────────────────────────────────────

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
    _autoSaved = false;
    _startTicking();
    notifyListeners();
    _saveSession();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds <= 0 && _targetSeconds > 0) {
        _accumulatedSeconds = _targetSeconds;
        _isPaused = true;
        _ticker?.cancel();
        _autoSaveCompleted();
      }
      notifyListeners();
    });
  }

  void pauseTimer() {
    if (!_isRunning || _isPaused) return;
    if (_startedAt != null) {
      _accumulatedSeconds +=
          DateTime.now().difference(_startedAt!).inSeconds;
      if (_accumulatedSeconds > _targetSeconds) {
        _accumulatedSeconds = _targetSeconds;
      }
    }
    _isPaused = true;
    _ticker?.cancel();
    notifyListeners();
    _saveSession();
  }

  void resumeTimer() {
    if (!_isRunning || !_isPaused) return;
    _startedAt = DateTime.now();
    _isPaused = false;
    _startTicking();
    notifyListeners();
    _saveSession();
  }

  /// Stop and save elapsed time as a study record.
  /// Returns the minutes saved.
  /// Does NOT call notifyListeners — the caller must sequence:
  /// 1. stopTimer() — save to DB, clear session, reset state
  /// 2. StudyProvider.loadAll() — load new record into memory
  /// 3. notifyStop() — now the MiniStat sees correct data
  Future<int> stopTimer() async {
    if (!_isRunning) return 0;

    if (!_isPaused && _startedAt != null) {
      _accumulatedSeconds +=
          DateTime.now().difference(_startedAt!).inSeconds;
    }
    if (_accumulatedSeconds > _targetSeconds) {
      _accumulatedSeconds = _targetSeconds;
    }
    _ticker?.cancel();

    final mins = _accumulatedSeconds ~/ 60;
    final date = _planDate;
    final content = _planContent;
    final track = _trackType;
    final period = _timePeriod;

    // Save to study_track_record BEFORE clearing in-memory state,
    // unless _autoSaveCompleted already did it (prevents duplicates).
    if (!_autoSaved && mins > 0 && date != null) {
      await _saveStudyRecord(
        trackType: track,
        content: content ?? '专注计时学习',
        minutes: mins,
        date: date,
        period: period,
      );
    }

    // Clear in-memory state and persisted session.
    await _clearSession();
    _isRunning = false;
    _isPaused = false;
    _autoSaved = false;
    _planDate = null;
    _timePeriod = null;
    _planContent = null;
    _startedAt = null;
    _accumulatedSeconds = 0;
    _targetSeconds = 25 * 60;
    // notifyListeners() deliberately NOT called here —
    // the caller must load StudyProvider first, then call notifyStop().

    return mins;
  }

  /// Public wrapper for notifyListeners. Called after stopTimer() +
  /// StudyProvider.loadAll() so the MiniStat rebuilds with correct totals.
  void notifyStop() => notifyListeners();

  /// Cancel timer without saving. Only used for explicit user
  /// cancellation (the "放弃计时" button).
  void cancelTimer() {
    _ticker?.cancel();
    _isRunning = false;
    _isPaused = false;
    _autoSaved = false;
    _planDate = null;
    _timePeriod = null;
    _planContent = null;
    _startedAt = null;
    _accumulatedSeconds = 0;
    _targetSeconds = 25 * 60;
    _clearSession();
    // notifyListeners() deliberately NOT called here —
    // the caller should call notifyStop() after any needed cleanup.
  }

  /// Auto-save when countdown reaches 0 — no user action needed.
  /// The time is already earned; don't make the user confirm it.
  Future<void> _autoSaveCompleted() async {
    _autoSaved = true;
    final mins = _accumulatedSeconds ~/ 60;
    if (mins > 0 && _planDate != null) {
      await _saveStudyRecord(
        trackType: _trackType,
        content: _planContent ?? '专注计时学习',
        minutes: mins,
        date: _planDate!,
        period: _timePeriod,
      );
    }
    await _clearSession();
    notifyListeners();
  }

  /// Shared helper: insert a study record, mark plan completed, sync.
  Future<void> _saveStudyRecord({
    required String trackType,
    required String content,
    required int minutes,
    required String date,
    String? period,
  }) async {
    final record = StudyTrackRecord(
      trackType: trackType,
      studyContent: content,
      studyMinutes: minutes,
      difficultyLevel: 3,
      escapeStatus: 0,
      recordDate: date,
    );

    final db = await DatabaseHelper().db;
    await db.insert('study_track_record', record.toJson());

    // Mark the corresponding daily plan as completed.
    if (period != null) {
      final done = {
        'isCompleted': 1,
        'is_completed': 1,
        'completedAt': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      };
      await db.update('daily_model_plan', done,
          where: 'planDate = ? AND timePeriod = ?',
          whereArgs: [date, period]);
      await db.update('daily_model_plan', done,
          where: 'plan_date = ? AND time_period = ?',
          whereArgs: [date, period]);
    }

    // Background sync to server.
    final api = ApiClient();
    if (api.hasToken) {
      try {
        await api.post('/study/add', data: {
          'trackType': trackType,
          'content': content,
          'minutes': minutes,
          'difficulty': 3,
          'escapeStatus': false,
          'date': date,
        });
      } catch (_) {}
    }
  }

  int get todayElapsedMinutes => _isRunning ? elapsedSeconds ~/ 60 : 0;

  @override
  void dispose() {
    _mounted = false;
    _ticker?.cancel();
    super.dispose();
  }
}
