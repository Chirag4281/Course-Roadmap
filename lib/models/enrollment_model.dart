class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final DateTime enrolledAt;
  final double totalFeesPaid;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    required this.totalFeesPaid,
  });
  factory Enrollment.empty() {
    return Enrollment(
      id: '',
      userId: '',
      courseId: '',
      enrolledAt: DateTime.now(),
      totalFeesPaid: 0.0,
    );
  }
  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      courseId: map['course_id'] as String,
      enrolledAt: DateTime.fromMillisecondsSinceEpoch(map['enrolled_at'] as int),
      totalFeesPaid: (map['total_fees_paid'] as num).toDouble(),
    );
  }
}