class CourseSuggestion {
  final String title;
  final String description;
  final int durationWeeks;
  final String difficulty;
  final String estimatedSalary;
  final List<String> pros;
  final List<String> cons;

  CourseSuggestion({
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.difficulty,
    required this.estimatedSalary,
    required this.pros,
    required this.cons,
  });

  factory CourseSuggestion.fromJson(Map<String, dynamic> json) {
    return CourseSuggestion(
      title: json['title'] ?? 'Untitled Course',
      description: json['description'] ?? 'No description available',
      durationWeeks: json['duration_weeks'] ?? 6,
      difficulty: json['difficulty'] ?? 'Intermediate',
      estimatedSalary: json['estimated_salary_range'] ?? '\$50,000 - \$100,000',
      pros: List<String>.from(json['pros'] ?? ['Strong job market', 'Good earning potential']),
      cons: List<String>.from(json['cons'] ?? ['Requires dedication', 'Continuous learning needed']),
    );
  }
}