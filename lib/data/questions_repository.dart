import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/question.dart';

class QuestionsRepository {
  Future<List<Question>> loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/data/questions.json');
      final data = await json.decode(response);
      List<dynamic> questionsJson;
      if (data is List) {
        questionsJson = data;
      } else if (data is Map && data.containsKey('questions')) {
        questionsJson = data['questions'];
      } else {
        throw Exception('Invalid JSON structure for questions');
      }
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading questions: $e');
      return [];
    }
  }
}
