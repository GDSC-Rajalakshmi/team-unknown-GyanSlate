import '../models/question.dart';

class QuestionAPI {
  static Future<List<Question>> generateQuestions({
    required String subject,
    required String chapter,
    required Map<String, double> subtopicWeightage,
  }) async {
    // TODO: Implement API call to AI service
    // This is a placeholder implementation
    // In the actual implementation, you would:
    // 1. Make an HTTP request to your AI service
    // 2. Process the response
    // 3. Convert the response data to Question objects
    // 4. Return the list of questions
    
    return [];
  }
} 