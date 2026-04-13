import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/groq_service.dart';

class AISuggestionParams {
  final String qualification;
  final List<String> interests;
  final String currentCourse;

  AISuggestionParams({
    required this.qualification,
    required this.interests,
    required this.currentCourse,
  });
}

