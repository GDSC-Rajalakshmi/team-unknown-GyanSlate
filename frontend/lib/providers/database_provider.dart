import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/syllabus.dart';
import '../models/question.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Syllabus> _syllabi = [];
  List<Question> _questions = [];

  List<Syllabus> get syllabi => _syllabi;
  List<Question> get questions => _questions;

  Future<void> initDatabase() async {
    await _db.init();
    await refreshData();
  }

  Future<void> refreshData() async {
    await Future.wait([
      refreshSyllabi(),
      refreshQuestions(),
    ]);
  }

  Future<void> refreshSyllabi() async {
    try {
      _syllabi = await _db.getSyllabi();
      notifyListeners();
    } catch (e) {
      print('Error refreshing syllabi: $e');
      _syllabi = [];
    }
  }

  Future<void> refreshQuestions() async {
    try {
      _questions = await _db.getQuestions();
      notifyListeners();
    } catch (e) {
      print('Error refreshing questions: $e');
      _questions = [];
    }
  }

  Future<void> addSyllabus(Syllabus syllabus) async {
    try {
      await _db.saveSyllabus(syllabus);
      await refreshSyllabi();
    } catch (e) {
      print('Error adding syllabus: $e');
      rethrow;
    }
  }

  Future<void> updateSyllabus(Syllabus syllabus) async {
    try {
      await _db.saveSyllabus(syllabus);
      await refreshSyllabi();
    } catch (e) {
      print('Error updating syllabus: $e');
      rethrow;
    }
  }

  Future<void> deleteSyllabus(String className, String section, String subject) async {
    try {
      await _db.removeSyllabus(className, section, subject);
      await refreshSyllabi();
    } catch (e) {
      print('Error deleting syllabus: $e');
      rethrow;
    }
  }

  Future<void> addQuestion(Question question) async {
    try {
      await _db.addQuestion(question);
      await refreshQuestions();
    } catch (e) {
      print('Error adding question: $e');
      rethrow;
    }
  }

  List<Question> getQuestionsForSyllabus(Syllabus syllabus) {
    return _questions.where((q) =>
        q.className == syllabus.className &&
        q.subject == syllabus.subject).toList();
  }

  // Additional helper methods
  List<String> getUniqueClasses() {
    return _syllabi.map((s) => s.className).toSet().toList()..sort();
  }

  List<String> getSubjectsForClass(String className) {
    return _syllabi
        .where((s) => s.className == className)
        .map((s) => s.subject)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> getSectionsForClass(String className) {
    return _syllabi
        .where((s) => s.className == className)
        .map((s) => s.section)
        .toSet()
        .toList()
      ..sort();
  }
} 