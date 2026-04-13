// services/ai_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_career_insights.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';

class AiService {
  final String groqApiKey = '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';

  Future<AiCareerInsights> generateCareerInsights(User user, Course course) async {
    final prompt = '''
You are an expert career counselor. Given:
- User interests: ${user.interests.join(', ')}
- Course: "${course.title}" in stream "${course.stream}"
- User goal: Career growth

Respond ONLY with valid JSON containing:
{
  "relevance_reason": "1-2 sentence explanation",
  "relevance_score": 85,
  "career_fit": "Strong Fit",
  "next_steps": ["Step 1", "Step 2", "Step 3"],
  "pros": "Concise pros",
  "cons": "Concise cons",
  "salary_range": "₹X–Y LPA",
  "career_paths": ["Path 1", "Path 2", "Path 3"]
}
''';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama3-70b-8192', // or mixtral
        'messages': [{'role': 'user', 'content': prompt}],
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) throw Exception('AI failed');

    final content = jsonDecode(response.body)['choices'][0]['message']['content'];
    final json = jsonDecode(content) as Map<String, dynamic>;
    return AiCareerInsights.fromJson(json);
  }
}