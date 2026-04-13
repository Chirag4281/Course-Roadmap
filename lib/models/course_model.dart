import 'lecture_model.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final double fees; // Existing field from database
  final String stream;
  final String level;
  final String duration;
  final String instructor;
  final String imageUrl;
  final String roadmapPros;
  final String roadmapCons;
  final String roadmapSalaryRange;
  final String roadmapCareerPaths;
  final List<String> nextCourseSuggestions;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.fees,
    required this.stream,
    required this.level,
    required this.duration,
    required this.instructor,
    required this.imageUrl,
    required this.roadmapPros,
    required this.roadmapCons,
    required this.roadmapSalaryRange,
    required this.roadmapCareerPaths,
    required this.nextCourseSuggestions,
    required this.createdAt,
  });

  // ✅ ADD THIS GETTER - allows UI to use course.price while keeping database field as 'fees'
  double get price => fees;

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      fees: (map['fees'] as num).toDouble(),
      stream: map['stream'] as String,
      level: map['level'] as String,
      duration: map['duration'] as String,
      instructor: map['instructor'] as String,
      imageUrl: map['image_url'] as String? ?? '',
      roadmapPros: map['roadmap_pros'] as String? ?? '',
      roadmapCons: map['roadmap_cons'] as String? ?? '',
      roadmapSalaryRange: map['roadmap_salary_range'] as String? ?? '',
      roadmapCareerPaths: map['roadmap_career_paths'] as String? ?? '',
      nextCourseSuggestions: map['next_course_suggestions'] != null
          ? (map['next_course_suggestions'] as String).split(',').map((s) => s.trim()).toList()
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
  // ✅ ADD THIS GETTER - generates AI lectures on-demand without storing them
  List<Lecture>? get generatedLectures {
    // Only generate for AI suggestion courses (real courses should fetch from DB)
    if (!id.startsWith('ai_suggestion_')) return null;

    // Generate fallback lectures for AI suggestions
    return List.generate(6, (index) {
      final titles = [
        'Introduction to $stream',
        'Core Principles & Frameworks',
        'Hands-on Practical Exercises',
        'Real-world Case Studies',
        'Advanced Techniques & Strategies',
        'Capstone Project & Assessment'
      ];
      final descriptions = [
        'Overview of fundamental concepts and industry context',
        'Deep dive into essential theories and methodologies',
        'Apply learned concepts through guided practice sessions',
        'Analyze real implementations and success stories',
        'Master next-level skills and optimization techniques',
        'Demonstrate your skills through a comprehensive project'
      ];
      return Lecture(
        id: '${id}_lecture_${index + 1}',
        courseId: id,
        title: titles[index],
        description: descriptions[index],
        durationMinutes: 15 + (index * 5),
        orderIndex: index + 1,
        isCompleted: false,
        completedAt: null,
      );
    });
  }
// ADD THIS CONSTRUCTOR TO YOUR Course CLASS
  Course.aiSuggestion({
    required String title,
    required String stream,
    required List<String> nextSteps,
    String? description,
    double fees = 4999.0,
  }) : id = 'ai_suggestion_${title.hashCode}',
        title = title,
        description = description ?? 'AI-recommended course based on your career profile and interests. This personalized recommendation helps you build in-demand skills for your professional growth.',
        fees = fees,
        stream = stream,
        level = 'Intermediate',
        duration = '8 weeks',
        instructor = 'AI Career Advisor',
        imageUrl = '',
        roadmapPros = '• Personalized for your career path\n• Builds in-demand skills\n• Aligns with market trends',
        roadmapCons = '• Not yet available in catalog\n• Coming soon based on demand',
        roadmapSalaryRange = '₹6-15 LPA (estimated)',
        roadmapCareerPaths = 'Custom career progression based on your profile and industry trends',
        nextCourseSuggestions = nextSteps,
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fees': fees, // Database still uses 'fees' column
      'stream': stream,
      'level': level,
      'duration': duration,
      'instructor': instructor,
      'image_url': imageUrl,
      'roadmap_pros': roadmapPros,
      'roadmap_cons': roadmapCons,
      'roadmap_salary_range': roadmapSalaryRange,
      'roadmap_career_paths': roadmapCareerPaths,
      'next_course_suggestions': nextCourseSuggestions.join(', '),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}