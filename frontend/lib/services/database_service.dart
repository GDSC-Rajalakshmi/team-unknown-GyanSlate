import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/syllabus.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  late Map<String, dynamic> _data;
  static const String _dbFileName = 'edugenius_db.json';

  // Initialize database
  Future<void> init() async {
    try {
      if (kIsWeb) {
        // Web implementation using SharedPreferences
        final preferences = await SharedPreferences.getInstance();
        final String? storedData = preferences.getString(_dbFileName);
        if (storedData != null) {
          _data = json.decode(storedData);
        } else {
          _data = {
            'questions': [],
            'syllabi': [],
          };
          await _saveData();
        }
      } else {
        // Mobile implementation using path_provider
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_dbFileName');
        
        if (await file.exists()) {
          final String contents = await file.readAsString();
          _data = json.decode(contents);
        } else {
          _data = {
            'questions': [],
            'syllabi': [],
          };
          await _saveData();
        }
      }
    } catch (e) {
      // Initialize with empty data if there's an error
      _data = {
        'questions': [],
        'syllabi': [],
      };
      print('Error initializing database: $e');
    }
  }

  // Save data
  Future<void> _saveData() async {
    if (kIsWeb) {
      // Web implementation using SharedPreferences
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_dbFileName, json.encode(_data));
    } else {
      // Mobile implementation using path_provider
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dbFileName');
      await file.writeAsString(json.encode(_data));
    }
  }

  // Add a question
  Future<void> addQuestion(Question question) async {
    _data['questions'].add(question.toJson());
    await _saveData();
  }

  // Method to get questions from your API
  Future<List<Question>> getQuestions() async {
    try {
      // Since we're not using Firebase, return empty list for now
      return [];
    } catch (e) {
      print('Error getting questions: $e');
      return [];
    }
  }

  // Method to get questions by subject from your API
  Future<List<Question>> getQuestionsBySubject(String subject) async {
    try {
      // Since we're not using Firebase, return empty list for now
      return [];
    } catch (e) {
      print('Error getting questions by subject: $e');
      return [];
    }
  }

  // Delete a question
  Future<void> deleteQuestion(String id) async {
    _data['questions'].removeWhere((json) => json['id'] == id);
    await _saveData();
  }

  // Update a question
  Future<void> updateQuestion(Question question) async {
    final index = (_data['questions'] as List)
        .indexWhere((json) => json['id'] == question.id);
    if (index != -1) {
      _data['questions'][index] = question.toJson();
      await _saveData();
    }
  }

  // Get questions by class and subject
  Future<List<Question>> getQuestionsByClassAndSubject(
    String className,
    String subject,
  ) async {
    return (_data['questions'] as List)
        .where((json) => 
            json['className'] == className && 
            json['subject'] == subject)
        .map((json) => Question.fromJson(json))
        .toList();
  }

  // Get questions by topic
  Future<List<Question>> getQuestionsByTopic(String topic) async {
    return (_data['questions'] as List)
        .where((json) => json['chapter'] == topic)
        .map((json) => Question.fromJson(json))
        .toList();
  }

  // Syllabus Methods
  Future<List<Syllabus>> getSyllabi() async {
    return (_data['syllabi'] as List)
        .map((json) => Syllabus.fromJson(json))
        .toList();
  }

  Future<void> saveSyllabus(Syllabus syllabus) async {
    final index = (_data['syllabi'] as List).indexWhere((json) =>
        json['className'] == syllabus.className &&
        json['section'] == syllabus.section &&
        json['subject'] == syllabus.subject);

    if (index != -1) {
      _data['syllabi'][index] = syllabus.toJson();
    } else {
      _data['syllabi'].add(syllabus.toJson());
    }
    await _saveData();
  }

  Future<void> removeSyllabus(String className, String section, String subject) async {
    _data['syllabi'].removeWhere((json) =>
        json['className'] == className &&
        json['section'] == section &&
        json['subject'] == subject);
    await _saveData();
  }

  // Clear all data (for testing)
  Future<void> clearData() async {
    _data = {
      'questions': [],
      'syllabi': [],
    };
    await _saveData();
  }

  Future<List<Map<String, dynamic>>> getLectureVideos() async {
    if (!_data.containsKey('lecture_videos')) {
      _data['lecture_videos'] = [];
      await _saveData();
    }
    return List<Map<String, dynamic>>.from(_data['lecture_videos']);
  }

  Future<void> addLectureVideo(Map<String, dynamic> video) async {
    if (!_data.containsKey('lecture_videos')) {
      _data['lecture_videos'] = [];
    }
    _data['lecture_videos'].add(video);
    await _saveData();
  }

  Future<void> updateLectureVideo(String id, Map<String, dynamic> video) async {
    if (!_data.containsKey('lecture_videos')) {
      _data['lecture_videos'] = [];
    }
    final index = (_data['lecture_videos'] as List)
        .indexWhere((v) => v['id'] == id);
    if (index != -1) {
      _data['lecture_videos'][index] = video;
      await _saveData();
    }
  }

  Future<void> deleteLectureVideo(String id) async {
    if (!_data.containsKey('lecture_videos')) {
      _data['lecture_videos'] = [];
    }
    _data['lecture_videos'].removeWhere((v) => v['id'] == id);
    await _saveData();
  }

  // Add this method to initialize the database
  Future<void> initialize() async {
    // Initialize your database here
    // This is a placeholder - implement based on your actual database
  }
} 