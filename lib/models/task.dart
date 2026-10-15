enum Priority {
  high('Yüksek'),
  medium('Orta'),
  low('Düşük');

  const Priority(this.label);

  final String label;
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final Priority priority;
  final DateTime? dueDate;

  /// When the task was ticked off; null while it is open.
  final DateTime? completedAt;
  final DateTime createdAt;

  bool get done => completedAt != null;

  Task copyWith({
    String? title,
    String? note,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'priority': priority.name,
    'dueDate': dueDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final completedAt = json['completedAt'] as String?;
    final legacyDone = json['done'] as bool? ?? false;
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      priority:
          Priority.values.asNameMap()[json['priority']] ?? Priority.medium,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      // Data saved before completion times existed only had a flag; the
      // creation time is the best guess for when it was done.
      completedAt: completedAt != null
          ? DateTime.parse(completedAt)
          : (legacyDone ? createdAt : null),
      createdAt: createdAt,
    );
  }

  /// Whether the task belongs on the list of the calendar day [day]: it
  /// existed by the end of that day and wasn't already done before it began.
  bool isOnListOf(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    if (!createdAt.isBefore(end)) return false;
    return completedAt == null || !completedAt!.isBefore(start);
  }

  /// Whether the task was ticked off during the calendar day [day].
  bool wasCompletedOn(DateTime day) {
    final c = completedAt;
    return c != null &&
        c.year == day.year &&
        c.month == day.month &&
        c.day == day.day;
  }

  /// Orders by priority, then earliest due date (tasks without a date go
  /// last), then oldest first. With [doneLast], done tasks sink to the end;
  /// without it they keep their place so a ticked-off task doesn't jump.
  static int compare(Task a, Task b, {bool doneLast = true}) {
    if (doneLast && a.done != b.done) return a.done ? 1 : -1;
    final byPriority = a.priority.index.compareTo(b.priority.index);
    if (byPriority != 0) return byPriority;
    if (a.dueDate != b.dueDate) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    }
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }
}
