class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final String answer;
  final String why;
  final String subtopic;
  final String qType;
  final String subject;
  final String chapter;
  final String className;
  final DateTime createdAt;
  final int marks;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.answer,
    required this.why,
    required this.subtopic,
    required this.qType,
    required this.subject,
    required this.chapter,
    required this.className,
    DateTime? createdAt,
    this.marks = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  // For API responses
  factory Question.fromApiResponse(Map<String, dynamic> json, {
    required String subject,
    required String chapter,
    required String className,
  }) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['correct_option'] ?? '',
      why: json['why'] ?? '',
      subtopic: json['subtopic'] ?? '',
      qType: json['q_type'] ?? 'MCQ',
      subject: subject,
      chapter: chapter,
      className: className,
    );
  }

  // For database operations
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: json['questionText'] ?? json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? json['correct_option'] ?? '',
      why: json['why'] ?? '',
      subtopic: json['subtopic'] ?? '',
      qType: json['qType'] ?? json['q_type'] ?? 'MCQ',
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      className: json['className'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      marks: json['marks'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'answer': answer,
      'why': why,
      'subtopic': subtopic,
      'qType': qType,
      'subject': subject,
      'chapter': chapter,
      'className': className,
      'createdAt': createdAt.toIso8601String(),
      'marks': marks,
    };
  }

  // Add copyWith method for convenience
  Question copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    String? answer,
    int? marks,
    String? subject,
    String? chapter,
    String? className,
    DateTime? createdAt,
    String? why,
    String? subtopic,
    String? qType,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      why: why ?? this.why,
      subtopic: subtopic ?? this.subtopic,
      qType: qType ?? this.qType,
      marks: marks ?? this.marks,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      className: className ?? this.className,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Add a toString method for debugging
  @override
  String toString() {
    return 'Question{questionText: $questionText, options: $options, answer: $answer, why: $why, subtopic: $subtopic, qType: $qType}';
  }
}

enum QuestionDifficulty {
  easy,
  medium,
  hard
} 