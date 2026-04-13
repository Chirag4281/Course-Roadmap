// lib/features/enrollment/models/enrollment.dart
class Enrollment {
  final String id;
  final String courseId;
  final String courseTitle;
  final double courseFee;
  final DateTime enrolledAt;
  final int totalLectures;
  final int completedLectures; // 👈 This field MUST exist
  final List<bool> lecturesProgress;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseFee,
    required this.enrolledAt,
    required this.totalLectures,
    required this.completedLectures, // 👈 Include in constructor
    required this.lecturesProgress,
  });

  factory Enrollment.empty(String courseId, int totalLectures) {
    return Enrollment(
      id: 'temp',
      courseId: courseId,
      courseTitle: courseId,
      courseFee: 0.0,
      enrolledAt: DateTime.now(),
      totalLectures: totalLectures,
      completedLectures: 0, // 👈 Initialize to 0
      lecturesProgress: List.filled(totalLectures, false),
    );
  }

  Enrollment copyWithProgress(int lectureNumber, bool completed) {
    final newProgress = List<bool>.from(lecturesProgress);
    if (lectureNumber > 0 && lectureNumber <= newProgress.length) {
      if (newProgress[lectureNumber - 1] != completed) {
        newProgress[lectureNumber - 1] = completed;
      }
    }

    // Calculate completed lectures from progress array
    int newCompleted = newProgress.where((p) => p).length;

    return Enrollment(
      id: id,
      courseId: courseId,
      courseTitle: courseTitle,
      courseFee: courseFee,
      enrolledAt: enrolledAt,
      totalLectures: totalLectures,
      completedLectures: newCompleted, // 👈 Use calculated value
      lecturesProgress: newProgress,
    );
  }
}