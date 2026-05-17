class TaskTodo {
  final int? taskId;
  final int? userId;
  final String? taskTitle;
  final int? taskLevel;
  int? isComplete;
  final String? taskDate;
  final int? goalId;
  final String? goalTitle;
  final String? createTime;

  TaskTodo({
    this.taskId,
    this.userId,
    this.taskTitle,
    this.taskLevel,
    this.isComplete,
    this.taskDate,
    this.goalId,
    this.goalTitle,
    this.createTime,
  });

  factory TaskTodo.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return TaskTodo(
      taskId: parseInt(json['taskId'] ?? json['task_id']),
      userId: parseInt(json['userId'] ?? json['user_id']),
      taskTitle: (json['taskTitle'] ?? json['task_title'])?.toString(),
      taskLevel: parseInt(json['taskLevel'] ?? json['task_level']),
      isComplete: parseInt(json['isComplete'] ?? json['is_complete']),
      taskDate: (json['taskDate'] ?? json['task_date'])?.toString(),
      goalId: parseInt(json['goalId'] ?? json['goal_id']),
      goalTitle: (json['goalTitle'] ?? json['goal_title'])?.toString(),
      createTime: (json['createTime'] ?? json['create_time'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (taskId != null) 'taskId': taskId,
        if (taskTitle != null) 'taskTitle': taskTitle,
        if (taskLevel != null) 'taskLevel': taskLevel,
        if (isComplete != null) 'isComplete': isComplete,
        if (taskDate != null) 'taskDate': taskDate,
        if (goalId != null) 'goalId': goalId,
      };

  String get levelLabel {
    const map = {1: '重要紧急', 2: '重要不紧急', 3: '紧急不重要', 4: '不重要不紧急'};
    return map[taskLevel] ?? '-';
  }

  bool get completed => isComplete == 1;
}
