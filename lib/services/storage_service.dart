// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile/models/user_profile.dart';
import '../features/enrollment/models/enrollment.dart';

class StorageService {

  Future<void> init() async {}

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'name': profile.name,
      'email': profile.email,
      'highestQualification': profile.highestQualification,
      'interests': profile.interests,
      'createdAt': profile.createdAt.toIso8601String(),
    };
    await prefs.setString('user_profile', jsonEncode(data));
  }
// In storage_service.dart
  Future<void> cancelEnrollment(String courseId, double refundAmount) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Read enrollments as a SINGLE JSON STRING (not StringList!)
    final String? enrollmentsJson = prefs.getString('enrollments');
    List<dynamic> enrollments = [];

    if (enrollmentsJson != null) {
      try {
        final decoded = jsonDecode(enrollmentsJson);
        if (decoded is List) {
          enrollments = decoded;
        }
      } catch (e) {
        print('Failed to decode enrollments: $e');
      }
    }

    // 2. Remove enrollment with matching courseId
    final updatedEnrollments = enrollments.where((item) {
      if (item is Map<String, dynamic>) {
        return item['courseId'] != courseId;
      }
      return true; // keep non-map items (shouldn't exist)
    }).toList();

    // 3. Save back as SINGLE JSON STRING
    await prefs.setString('enrollments', jsonEncode(updatedEnrollments));

    // 4. Process refund
    final currentBalance = prefs.getDouble('wallet_balance') ?? 0.0;
    await prefs.setDouble('wallet_balance', currentBalance + refundAmount);
  }
  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_profile');
    if (jsonString == null) return null;

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserProfile(
      name: data['name'] as String,
      email: data['email'] as String,
      highestQualification: data['highestQualification'] as String,
      interests: List<String>.from(data['interests'] as List),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Future<bool> isProfileComplete() async {
    final profile = await getProfile();
    if (profile == null) return false;
    return profile.name.isNotEmpty &&
        profile.highestQualification.isNotEmpty &&
        profile.interests.isNotEmpty;
  }

  // ✅ CORRECTED: Proper async implementation without return issues
  Future<void> enrollInCourse(Enrollment enrollment) async {
    final prefs = await SharedPreferences.getInstance();
    final existingEnrollments = await getEnrollments();
    final updatedEnrollments = [...existingEnrollments, enrollment];

    final jsonList = updatedEnrollments.map((e) => {
      'id': e.id,
      'courseId': e.courseId,
      'courseTitle': e.courseTitle,
      'courseFee': e.courseFee,
      'enrolledAt': e.enrolledAt.toIso8601String(),
      'totalLectures': e.totalLectures,
      'completedLectures': e.completedLectures, // 👈 Include this field
      'lecturesProgress': e.lecturesProgress,
    }).toList();

    await prefs.setString('enrollments', jsonEncode(jsonList));
  }

  // ✅ CORRECTED: Proper async implementation
  Future<List<Enrollment>> getEnrollments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('enrollments');
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        return Enrollment(
          id: map['id'] as String,
          courseId: map['courseId'] as String,
          courseTitle: map['courseTitle'] as String,
          courseFee: (map['courseFee'] as num).toDouble(),
          enrolledAt: DateTime.parse(map['enrolledAt'] as String),
          totalLectures: map['totalLectures'] as int,
          completedLectures: map['completedLectures'] as int, // 👈 Load this field
          lecturesProgress: List<bool>.from(map['lecturesProgress'] as List),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLectureProgress(String courseId, int lectureNumber, bool completed) async {
    final enrollments = await getEnrollments();
    final index = enrollments.indexWhere((e) => e.courseId == courseId);

    if (index == -1) return;

    final updatedEnrollment = enrollments[index].copyWithProgress(lectureNumber, completed);
    final updatedList = [
      ...enrollments.take(index),
      updatedEnrollment,
      ...enrollments.skip(index + 1)
    ];

    // Save back
    final prefs = await SharedPreferences.getInstance();
    final jsonList = updatedList.map((e) => {
      'id': e.id,
      'courseId': e.courseId,
      'courseTitle': e.courseTitle,
      'courseFee': e.courseFee,
      'enrolledAt': e.enrolledAt.toIso8601String(),
      'totalLectures': e.totalLectures,
      'completedLectures': e.completedLectures,
      'lecturesProgress': e.lecturesProgress,
    }).toList();

    await prefs.setString('enrollments', jsonEncode(jsonList));
  }

  Future<double> getOverallProgress() async {
    final enrollments = await getEnrollments();
    if (enrollments.isEmpty) return 0.0;

    int totalLectures = 0;
    int completedLectures = 0;

    for (final e in enrollments) {
      totalLectures += e.totalLectures;
      completedLectures += e.completedLectures; // 👈 Now this works!
    }

    if (totalLectures == 0) return 0.0;
    return (completedLectures / totalLectures) * 100;
  }

  Future<double> getTotalSpent() async {
    final enrollments = await getEnrollments();
    double total = 0.0;
    for (final e in enrollments) {
      total += e.courseFee;
    }
    return total;
  }
}