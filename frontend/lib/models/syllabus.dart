class Syllabus {
  final String className;
  final String section;
  final String subject;
  final List<String> chapters;
  final Map<String, List<String>> topics;
  final DateTime createdAt;
  final DateTime updatedAt;

  Syllabus({
    required this.className,
    required this.section,
    required this.subject,
    required this.chapters,
    required this.topics,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from JSON
  factory Syllabus.fromJson(Map<String, dynamic> json) {
    return Syllabus(
      className: json['className'] as String,
      section: json['section'] as String,
      subject: json['subject'] as String,
      chapters: List<String>.from(json['chapters'] as List),
      topics: Map<String, List<String>>.from(
        (json['topics'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            List<String>.from(value as List),
          ),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'section': section,
      'subject': subject,
      'chapters': chapters,
      'topics': topics,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with some fields updated
  Syllabus copyWith({
    String? className,
    String? section,
    String? subject,
    List<String>? chapters,
    Map<String, List<String>>? topics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Syllabus(
      className: className ?? this.className,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      chapters: chapters ?? this.chapters,
      topics: topics ?? this.topics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to add a chapter
  Syllabus addChapter(String chapter, List<String> chapterTopics) {
    final newChapters = List<String>.from(chapters)..add(chapter);
    final newTopics = Map<String, List<String>>.from(topics)
      ..[chapter] = chapterTopics;
    
    return copyWith(
      chapters: newChapters,
      topics: newTopics,
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to remove a chapter
  Syllabus removeChapter(String chapter) {
    final newChapters = List<String>.from(chapters)..remove(chapter);
    final newTopics = Map<String, List<String>>.from(topics)..remove(chapter);
    
    return copyWith(
      chapters: newChapters,
      topics: newTopics,
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to update topics for a chapter
  Syllabus updateTopics(String chapter, List<String> newTopics) {
    final updatedTopics = Map<String, List<String>>.from(topics)
      ..[chapter] = newTopics;
    
    return copyWith(
      topics: updatedTopics,
      updatedAt: DateTime.now(),
    );
  }
}

class Chapter {
  final String name;
  final List<Topic> topics;
  final int weightage; // Percentage weightage in exams

  Chapter({
    required this.name,
    required this.topics,
    this.weightage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'topics': topics.map((topic) => topic.toMap()).toList(),
      'weightage': weightage,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      name: map['name'],
      topics: (map['topics'] as List)
          .map((topic) => Topic.fromMap(topic))
          .toList(),
      weightage: map['weightage'] ?? 0,
    );
  }
}

class Topic {
  final String name;
  final String description;
  final int weightage; // Percentage weightage within chapter

  Topic({
    required this.name,
    this.description = '',
    this.weightage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'weightage': weightage,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      name: map['name'],
      description: map['description'] ?? '',
      weightage: map['weightage'] ?? 0,
    );
  }
} 