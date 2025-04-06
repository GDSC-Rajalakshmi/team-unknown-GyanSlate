import './question.dart';

class QuestionPaper {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final DateTime createdAt;
  final String subject;
  final String className;
  final int totalMarks;
  final int duration;
  final bool isObjective;

  QuestionPaper({
    String? id,
    required this.title,
    this.description = '',
    required this.questions,
    DateTime? createdAt,
    required this.subject,
    required this.className,
    int? totalMarks,
    this.duration = 60,
    this.isObjective = true,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt = createdAt ?? DateTime.now(),
    totalMarks = totalMarks ?? questions.fold(0, (sum, q) => sum + q.marks);

  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    return QuestionPaper(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      subject: json['subject'] ?? '',
      className: json['className'] ?? '',
      duration: json['duration'] ?? 60,
      isObjective: json['isObjective'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
      'className': className,
      'totalMarks': totalMarks,
      'duration': duration,
      'isObjective': isObjective,
    };
  }
} 