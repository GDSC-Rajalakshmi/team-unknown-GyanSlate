import './question_paper.dart';

enum AssessmentStatus { pending, inProgress, completed, upcoming, active }

class Assessment {
  final String id;
  final String subject;
  final String chapter;
  final String className;
  final String topics;
  final DateTime startTime;
  final DateTime endTime;
  final QuestionPaper questionPaper;
  final AssessmentStatus status;
  final DateTime createdAt;
  final int questionCount;
  final bool isObjective;
  Map<String, dynamic>? results;

  Assessment({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.className,
    required this.topics,
    required this.startTime,
    required this.endTime,
    required this.questionPaper,
    required this.status,
    required this.createdAt,
    required this.questionCount,
    required this.isObjective,
    this.results,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'],
      subject: json['subject'],
      chapter: json['chapter'],
      className: json['className'],
      topics: json['topics'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      questionPaper: QuestionPaper.fromJson(json['questionPaper']),
      status: AssessmentStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
      questionCount: json['questionCount'],
      isObjective: json['isObjective'],
      results: json['results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'chapter': chapter,
      'className': className,
      'topics': topics,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'questionPaper': questionPaper.toJson(),
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'questionCount': questionCount,
      'isObjective': isObjective,
      'results': results,
    };
  }

  Assessment copyWith({
    String? id,
    String? subject,
    String? chapter,
    String? className,
    String? topics,
    DateTime? startTime,
    DateTime? endTime,
    QuestionPaper? questionPaper,
    AssessmentStatus? status,
    DateTime? createdAt,
    int? questionCount,
    bool? isObjective,
    Map<String, dynamic>? results,
  }) {
    return Assessment(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      className: className ?? this.className,
      topics: topics ?? this.topics,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionPaper: questionPaper ?? this.questionPaper,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      questionCount: questionCount ?? this.questionCount,
      isObjective: isObjective ?? this.isObjective,
      results: results ?? this.results,
    );
  }
} 