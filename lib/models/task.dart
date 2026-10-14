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
    this.done = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final Priority priority;
  final DateTime? dueDate;
  final bool done;
  final DateTime createdAt;

  bool isOverdue(DateTime now) =>
      !done && dueDate != null && dueDate!.isBefore(now);

  Task copyWith({
    String? title,
    String? note,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? done,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      done: done ?? this.done,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'priority': priority.name,
    'dueDate': dueDate?.toIso8601String(),
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String? ?? '',
    priority: Priority.values.asNameMap()[json['priority']] ?? Priority.medium,
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    done: json['done'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// Open tasks first; then by priority, then earliest due date
  /// (tasks without a date go last), then oldest first.
  static int compare(Task a, Task b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    final byPriority = a.priority.index.compareTo(b.priority.index);
    if (byPriority != 0) return byPriority;
    if (a.dueDate != b.dueDate) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    }
    return a.createdAt.compareTo(b.createdAt);
  }
}
