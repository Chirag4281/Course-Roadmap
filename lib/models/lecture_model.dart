class Lecture {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int durationMinutes;
  final int orderIndex;
  final bool isCompleted;
  final DateTime? completedAt;

  Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.orderIndex,
    required this.isCompleted,
    this.completedAt,
  });

  // 👇 ADD THIS copyWith METHOD
  Lecture copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    int? durationMinutes,
    int? orderIndex,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Lecture(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      orderIndex: orderIndex ?? this.orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Lecture.fromMap(Map<String, dynamic> map) {
    return Lecture(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      durationMinutes: map['duration_minutes'] as int,
      orderIndex: map['order_index'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'order_index': orderIndex,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }
}