import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/groq_service.dart';
import 'services/course_service.dart';
import 'features/profile/models/user_profile.dart';
import 'features/enrollment/models/enrollment.dart';
import 'features/courses/models/course_suggestion.dart';

// Application services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final groqServiceProvider = Provider<GroqService>((ref) {
  // Replace with your actual Groq API key
  final apiKey = 'YOUR_GROQ_API_KEY_HERE';
  return GroqService(apiKey);
});

final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService(ref.read(groqServiceProvider));
});

// User Profile Notifier
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final StorageService _storageService;

  UserProfileNotifier(this._storageService) : super(const AsyncLoading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _storageService.getProfile();
      state = AsyncData(profile);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncLoading();
    try {
      await _storageService.saveProfile(profile);
      state = AsyncData(profile);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// Example: If you have user info in shared prefs or auth state
final userNameProvider = Provider<String>((ref) {
  // e.g., return ref.watch(authStateProvider).user?.name ?? 'User';
  return 'Learner'; // fallback
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return UserProfileNotifier(ref.read(storageServiceProvider));
});

// ✅ CORRECTED COURSE SUGGESTIONS NOTIFIER
class CourseSuggestionsNotifier extends StateNotifier<AsyncValue<List<CourseSuggestion>>> {
  final GroqService _groqService;
  final Ref _ref;

  CourseSuggestionsNotifier(this._groqService, this._ref)
      : super(const AsyncData([]));

  Future<void> generateSuggestions() async {
    final profileState = _ref.read(userProfileProvider);

    if (profileState.valueOrNull == null) {
      state = AsyncError(
          Exception('Complete your profile first'), StackTrace.current);
      return;
    }

    final profile = profileState.valueOrNull!;
    state = const AsyncLoading();

    try {
      final suggestions = await _groqService.getSuggestions(
        qualification: profile.highestQualification,
        interests: profile.interests,
      );

      // 🔧 SAFELY EXTRACT AND PARSE 'top_courses'
      final topCoursesData = suggestions['top_courses'];

      List<dynamic> courseList;
      if (topCoursesData is String) {
        // If it's a JSON string, decode it
        courseList = json.decode(topCoursesData) as List<dynamic>;
      } else if (topCoursesData is List) {
        // Already a list — good!
        courseList = topCoursesData;
      } else {
        throw Exception('Unexpected format for "top_courses": $topCoursesData');
      }

      final courses = courseList
          .map((c) => CourseSuggestion.fromJson(c as Map<String, dynamic>))
          .toList();

      state = AsyncData(courses);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// ✅ CORRECTED PROVIDER REGISTRATION
final courseSuggestionsProvider = StateNotifierProvider<CourseSuggestionsNotifier, AsyncValue<List<CourseSuggestion>>>((ref) {
  return CourseSuggestionsNotifier(
      ref.read(groqServiceProvider),
      ref
  );
});

// Enrollment Notifier
class EnrollmentNotifier extends StateNotifier<AsyncValue<List<Enrollment>>> {
  final StorageService _storageService;

  EnrollmentNotifier(this._storageService) : super(const AsyncLoading()) {
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    try {
      final enrollments = await _storageService.getEnrollments();
      state = AsyncData(enrollments);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> enrollInCourse(Enrollment enrollment) async {
    state = const AsyncLoading();
    try {
      await _storageService.enrollInCourse(enrollment);
      await _loadEnrollments();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateLectureProgress(String courseId, int lectureNumber, bool completed) async {
    try {
      await _storageService.updateLectureProgress(courseId, lectureNumber, completed);
      await _loadEnrollments();
    } catch (e) {
      print('Progress update error: $e');
    }
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, AsyncValue<List<Enrollment>>>((ref) {
  return EnrollmentNotifier(ref.read(storageServiceProvider));
});