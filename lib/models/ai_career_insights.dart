// models/ai_career_insights.dart
class AiCareerInsights {
  final String relevanceReason;
  final int relevanceScore;
  final String careerFit;
  final List<String> nextSteps;
  final String pros;
  final String cons;
  final String salaryRange;
  final List<String> careerPaths;

  AiCareerInsights({
    required this.relevanceReason,
    required this.relevanceScore,
    required this.careerFit,
    required this.nextSteps,
    required this.pros,
    required this.cons,
    required this.salaryRange,
    required this.careerPaths,
  });

  factory AiCareerInsights.fromJson(Map<String, dynamic> json) {
    return AiCareerInsights(
      relevanceReason: json['relevance_reason'] ?? 'This course aligns with your career goals.',
      relevanceScore: (json['relevance_score'] as num?)?.toInt() ?? 75,
      careerFit: json['career_fit'] ?? 'Good Fit',
      nextSteps: List<String>.from(json['next_steps'] ?? []),
      pros: json['pros'] ?? 'Builds in-demand skills.',
      cons: json['cons'] ?? 'Requires foundational knowledge.',
      salaryRange: json['salary_range'] ?? '₹4–12 LPA',
      careerPaths: List<String>.from(json['career_paths'] ?? []),
    );
  }
}