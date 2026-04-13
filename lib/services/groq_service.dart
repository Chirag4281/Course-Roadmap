import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  final String apiKey = "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";

  GroqService(String apiKey);


  Future<Map<String, dynamic>> getSuggestions({
    required String qualification,
    required List<String> interests,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Groq API key not configured. Please add your key in settings.');
    }

    final prompt = '''
You are an expert career counselor. Based on the following profile:
- Highest Qualification: $qualification
- Interests: ${interests.join(', ')}

Provide JSON response with:
1. top_courses: Array of 5 recommended courses with {title, description, duration_weeks, difficulty, estimated_salary_range, pros, cons}
2. career_paths: Array of viable career paths
3. learning_roadmap: Structured learning path with phases

RESPONSE MUST BE VALID JSON ONLY. No markdown, no explanations.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } catch (e) {
      // Proper error handling without fallback UI issues
      throw Exception('Failed to get suggestions: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getCourseLectures(String courseTitle) async {
    final prompt = '''
Generate a realistic lecture structure for "$courseTitle" course.
Return VALID JSON array with objects containing:
- lecture_number (int)
- title (string)
- duration_minutes (int)
- description (string)
- video_preview_url (string - use placeholder URLs)
- is_preview (bool)

Example format:
[
  {
    "lecture_number": 1,
    "title": "Introduction to Excel",
    "duration_minutes": 15,
    "description": "Learn Excel basics...",
    "video_preview_url": "https://example.com/preview1.mp4",
    "is_preview": true
  }
]

RESPONSE MUST BE VALID JSON ONLY.
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 1500,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } catch (e) {
      // Generate realistic fallback lectures WITHOUT UI fallback issues
      return _generateDefaultLectures(courseTitle);
    }
  }

  List<dynamic> _generateDefaultLectures(String courseTitle) {
    return [
      {
        "lecture_number": 1,
        "title": "Introduction to $courseTitle",
        "duration_minutes": 18,
        "description": "Get started with the fundamentals of $courseTitle",
        "video_preview_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "is_preview": true
      },
      {
        "lecture_number": 2,
        "title": "Core Concepts",
        "duration_minutes": 22,
        "description": "Deep dive into essential concepts",
        "video_preview_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "is_preview": false
      },
      {
        "lecture_number": 3,
        "title": "Practical Applications",
        "duration_minutes": 25,
        "description": "Real-world use cases and examples",
        "video_preview_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
        "is_preview": false
      },
      {
        "lecture_number": 4,
        "title": "Advanced Techniques",
        "duration_minutes": 30,
        "description": "Master advanced features and workflows",
        "video_preview_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        "is_preview": false
      },
      {
        "lecture_number": 5,
        "title": "Project & Certification",
        "duration_minutes": 20,
        "description": "Capstone project and certification path",
        "video_preview_url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
        "is_preview": false
      }
    ];
  }
}