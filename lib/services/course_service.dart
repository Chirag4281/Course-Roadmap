import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groq_service.dart';
import '../features/courses/models/course_suggestion.dart';

class CourseService {
  final GroqService _groqService;

  CourseService(this._groqService);

  Future<List<dynamic>> getCourseLectures(String courseTitle, List<String> interests) async {
    return await _groqService.getCourseLectures(courseTitle);
  }

  // In production, this would fetch from a backend API
  Future<List<CourseSuggestion>> getFeaturedCourses() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      CourseSuggestion(
        title: 'Data Science & Machine Learning',
        description: 'Master Python, statistics, and ML algorithms to solve real-world problems',
        durationWeeks: 12,
        difficulty: 'Intermediate',
        estimatedSalary: '\$90,000 - \$160,000',
        pros: [
          'Extremely high demand',
          'Works across all industries',
          'Strong remote opportunities',
          'Clear career progression'
        ],
        cons: [
          'Math-intensive',
          'Requires continuous learning',
          'Competitive entry-level market'
        ],
      ),
      CourseSuggestion(
        title: 'Full-Stack Web Development',
        description: 'Build modern web applications with React, Node.js, and cloud deployment',
        durationWeeks: 10,
        difficulty: 'Intermediate',
        estimatedSalary: '\$75,000 - \$140,000',
        pros: [
          'Immediate job opportunities',
          'Portfolio showcases skills effectively',
          'Freelance potential',
          'Creative problem solving'
        ],
        cons: [
          'Rapidly changing technologies',
          'Frontend/backend context switching',
          'Debugging complexity'
        ],
      ),
      CourseSuggestion(
        title: 'Cloud Architecture (AWS/Azure)',
        description: 'Design, deploy and manage scalable cloud infrastructure for enterprises',
        durationWeeks: 8,
        difficulty: 'Advanced',
        estimatedSalary: '\$110,000 - \$180,000',
        pros: [
          'Critical business skill',
          'High compensation',
          'Vendor certifications add value',
          'Strategic career path'
        ],
        cons: [
          'Steep learning curve',
          'Requires systems thinking',
          'Cost management complexity'
        ],
      ),
    ];
  }
}