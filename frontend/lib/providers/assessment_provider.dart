import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/question_paper.dart';
import '../models/assessment.dart';
import 'package:intl/intl.dart';

class AssessmentProvider with ChangeNotifier {
  final List<QuestionPaper> _questionPapers = [];
  List<Assessment> _assessments = [];
  final Set<String> _completedAssessmentIds = {};
  late SharedPreferences _prefs;
  bool _initialized = false;
  String? _selectedSubject;
  String? _selectedClass;
  List<Question> _questions = [];

  AssessmentProvider() {
    _init();
  }

  Future<void> _init() async {
    await _initPrefs();
    if (!_initialized) {
      _addSampleData();
      _initialized = true;
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCompletedAssessments();
  }

  // Getters
  List<QuestionPaper> get questionPapers => [..._questionPapers];
  List<Assessment> get assessments => _assessments;
  
  // Updated getters for filtered assessments
  List<Assessment> get activeAssessments => _assessments
      .where((assessment) => 
          assessment.status == AssessmentStatus.active &&
          !_completedAssessmentIds.contains(assessment.id))
      .toList();

  List<Assessment> get upcomingAssessments => _assessments
      .where((assessment) => assessment.status == AssessmentStatus.upcoming)
      .toList();

  List<Assessment> get completedAssessments => _assessments
      .where((assessment) => 
          _completedAssessmentIds.contains(assessment.id) ||
          assessment.status == AssessmentStatus.completed)
      .toList();

  String? get selectedSubject => _selectedSubject;
  String? get selectedClass => _selectedClass;
  List<Question> get questions => _questions;

  // Admin Methods
  Future<void> addQuestionPaper(QuestionPaper paper) async {
    try {
      _questionPapers.add(paper);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuestionPaper(String id) async {
    _questionPapers.removeWhere((paper) => paper.id == id);
    notifyListeners();
  }

  // Teacher Methods
  Future<void> createAssessment({
    required String className,
    required String subject,
    required String topics,
    required String chapter,
    required DateTime startTime,
    required DateTime endTime,
    required QuestionPaper questionPaper,
    required List<String> selectedSubtopics,
  }) async {
    // Ensure dates are properly formatted
    final now = DateTime.now();
    
    final assessment = Assessment(
      id: now.millisecondsSinceEpoch.toString(),
      className: className,
      subject: subject,
      topics: topics,
      chapter: chapter,
      startTime: startTime,
      endTime: endTime,
      questionPaper: questionPaper,
      status: startTime.isAfter(now) 
          ? AssessmentStatus.upcoming 
          : AssessmentStatus.active,
      createdAt: now,
      questionCount: questionPaper.questions.length,
      isObjective: questionPaper.isObjective,
    );

    _assessments.add(assessment);
    notifyListeners();
  }

  // Performance Analysis Methods
  Map<String, double> getClassPerformance(String className) {
    // Implement class performance logic
    return {'average': 0.0}; // Placeholder
  }

  double getOverallProgress() {
    // Implement overall progress logic
    return 0.0; // Placeholder
  }

  Map<String, double> getSubjectWisePerformance() {
    // Implement subject-wise performance logic
    return {}; // Placeholder
  }

  List<Question> getQuestionsForTopic(String topic) {
    // Implement question filtering logic
    return []; // Placeholder
  }

  List<QuestionPaper> getMatchingPapers({
    required String className,
    required String subject,
    required String topics,
  }) {
    return _questionPapers.where((paper) {
      return paper.className == className &&
             paper.subject == subject &&
             paper.questions.any((q) => q.chapter == topics);
    }).toList();
  }

  // Add method to evaluate MCQ answers
  Map<String, dynamic> evaluateMCQAnswers(Assessment assessment, Map<String, String> answers) {
    try {
      print('Starting evaluation with answers: $answers');
      
      // Initialize with default values to ensure non-null
      Map<String, dynamic> results = {
        'totalMarks': 0,
        'obtainedMarks': 0,
        'correctAnswers': 0,
        'totalQuestions': 0,
        'percentage': 0.0,
        'subtopicEval': <String, double>{},
      };
      
      if (assessment.questionPaper.questions.isEmpty) {
        print('No questions found');
        return results;
      }

      int totalMarks = 0;
      int obtainedMarks = 0;
      int correctAnswers = 0;
      final questions = assessment.questionPaper.questions;
      
      // Initialize subtopic evaluation maps
      Map<String, int> subtopicTotalQuestions = {};
      Map<String, int> subtopicCorrectAnswers = {};
      Map<String, double> subtopicEvaluation = {};

      for (final question in questions) {
        try {
          final subtopic = question.subtopic.trim() ?? "General";
          subtopicTotalQuestions[subtopic] = (subtopicTotalQuestions[subtopic] ?? 0) + 1;
          
          final questionMarks = question.marks ?? 1;
          totalMarks += questionMarks;

          final userAnswer = answers[question.id];
          final correctAnswer = question.answer;

          if (userAnswer != null) {
            final isCorrect = userAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
            
            if (isCorrect) {
              obtainedMarks += questionMarks;
              correctAnswers++;
              subtopicCorrectAnswers[subtopic] = (subtopicCorrectAnswers[subtopic] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error processing question ${question.id}: $e');
          continue;
        }
      }

      // Calculate score out of 10 for each subtopic
      subtopicTotalQuestions.forEach((subtopic, total) {
        final correct = subtopicCorrectAnswers[subtopic] ?? 0;
        final score = total > 0 ? (correct * 10.0) / total : 0.0;
        subtopicEvaluation[subtopic] = double.parse(score.toStringAsFixed(1));
      });

      final double percentage = totalMarks > 0 ? (obtainedMarks * 100.0) / totalMarks : 0.0;

      results = {
        'totalMarks': totalMarks,
        'obtainedMarks': obtainedMarks,
        'correctAnswers': correctAnswers,
        'totalQuestions': questions.length,
        'percentage': percentage,
        'subtopicEval': subtopicEvaluation,
      };

      print('\nFinal Results:');
      print(results);
      
      return results;

    } catch (e, stackTrace) {
      print('Critical error in evaluateMCQAnswers: $e');
      print('Stack trace: $stackTrace');
      return _createDefaultResults();
    }
  }

  bool isAssessmentCompleted(String assessmentId) {
    return _completedAssessmentIds.contains(assessmentId);
  }

  Future<void> markAssessmentAsCompleted(String assessmentId, Map<String, dynamic> results) async {
    final assessmentIndex = _assessments.indexWhere((a) => a.id == assessmentId);
    if (assessmentIndex != -1) {
      _completedAssessmentIds.add(assessmentId);
      
      // Update the assessment with results
      final assessment = _assessments[assessmentIndex];
      _assessments[assessmentIndex] = assessment.copyWith(
        status: AssessmentStatus.completed,
        results: results,
        endTime: DateTime.now(),
      );

      // Save to persistent storage
      await _saveCompletedAssessments();
      notifyListeners();
    }
  }

  Future<void> _saveCompletedAssessments() async {
    if (!_initialized) await _init();
    try {
      await _prefs.setStringList('completed_assessments', _completedAssessmentIds.toList());
    } catch (e) {
      debugPrint('Error saving completed assessments: $e');
    }
  }

  Future<void> _loadCompletedAssessments() async {
    try {
      final completed = _prefs.getStringList('completed_assessments') ?? [];
      _completedAssessmentIds.addAll(completed);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading completed assessments: $e');
    }
  }

  void updateAssessmentStatus(Assessment assessment) {
    final now = DateTime.now();
    AssessmentStatus newStatus;

    try {
      if (now.isBefore(assessment.startTime)) {
        newStatus = AssessmentStatus.upcoming;
      } else if (now.isAfter(assessment.endTime)) {
        newStatus = AssessmentStatus.completed;
      } else {
        newStatus = AssessmentStatus.active;
      }

      if (assessment.status != newStatus) {
        final index = _assessments.indexOf(assessment);
        if (index != -1) {
          _assessments[index] = assessment.copyWith(status: newStatus);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating assessment status: $e');
    }
  }

  // Add this method to handle assessment submission
  Future<void> submitAssessment(String assessmentId, Map<String, dynamic> results) async {
    try {
      final assessmentIndex = _assessments.indexWhere((a) => a.id == assessmentId);
      if (assessmentIndex != -1) {
        _completedAssessmentIds.add(assessmentId);
        
        // Ensure results are not null
        final safeResults = Map<String, dynamic>.from(results);
        
        // Update the assessment with results
        final assessment = _assessments[assessmentIndex];
        _assessments[assessmentIndex] = assessment.copyWith(
          status: AssessmentStatus.completed,
          results: safeResults,
          endTime: DateTime.now(),
        );

        // Save to persistent storage
        await _saveCompletedAssessments();
        notifyListeners();
      }
    } catch (e) {
      print('Error submitting assessment: $e');
      rethrow;
    }
  }

  void _addSampleData() {
    // Create a sample question paper
    final sampleQuestionPaper = QuestionPaper(
      title: 'Sample Question Paper',
      subject: selectedSubject ?? '',
      className: selectedClass ?? '',
      questions: questions,
    );

    // Add the question paper
    _questionPapers.add(sampleQuestionPaper);

    // Create a sample active assessment
    final now = DateTime.now();
    final sampleAssessment = Assessment(
      id: 'sample_assessment_1',
      subject: 'Physics',
      className: 'Class 11',
      chapter: 'Mechanics',
      topics: 'Newton\'s Laws, Force',
      startTime: now.subtract(const Duration(minutes: 15)),
      endTime: now.add(const Duration(minutes: 45)),
      questionPaper: sampleQuestionPaper,
      status: AssessmentStatus.active,
      createdAt: now,
      questionCount: 2,
      isObjective: true,
    );

    // Add the active assessment
    _assessments.add(sampleAssessment);

    // Create a sample completed assessment
    final completedAssessment = Assessment(
      id: 'sample_completed_1',
      subject: 'Physics',
      className: 'Class 11',
      chapter: 'Mechanics',
      topics: 'Newton\'s Laws, Force',
      startTime: now.subtract(const Duration(days: 1)),
      endTime: now.subtract(const Duration(hours: 23)),
      questionPaper: sampleQuestionPaper,
      status: AssessmentStatus.completed,
      createdAt: now.subtract(const Duration(days: 1)),
      questionCount: 2,
      isObjective: true,
      results: {
        'totalMarks': 10,
        'obtainedMarks': 8,
        'correctAnswers': 1,
        'totalQuestions': 2,
        'percentage': 80.0,
        'topicWise': {
          'Newton\'s Laws': 100.0,
          'Force': 60.0,
        },
        'feedback': [
          'Excellent understanding of Newton\'s Laws',
          'Need to improve on Force concepts',
        ],
      },
    );

    // Add the completed assessment
    _assessments.add(completedAssessment);
    _completedAssessmentIds.add('sample_completed_1');
    
    notifyListeners();
  }

  void setSelectedSubject(String subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setSelectedClass(String className) {
    _selectedClass = className;
    notifyListeners();
  }

  void setQuestions(List<Question> questions) {
    _questions = questions;
    notifyListeners();
  }

  Question _createQuestion({
    required String id,
    required String questionText,
    required List<String> options,
    required String answer,
    required String subject,
    required String chapter,
    required String className,
  }) {
    return Question(
      id: id,
      questionText: questionText,
      options: options,
      answer: answer,
      why: 'No explanation provided',
      subtopic: 'General',
      qType: 'MCQ',
      subject: subject,
      chapter: chapter,
      className: className,
    );
  }

  // Update the sample question paper creation
  QuestionPaper createQuestionPaper({
    required String title,
    required List<Question> questions,
    int duration = 60,
  }) {
    return QuestionPaper(
      title: title,
      subject: _selectedSubject ?? '',
      className: _selectedClass ?? '',
      questions: questions,
      duration: duration,
    );
  }

  set assessments(List<Assessment> value) {
    _assessments = value;
    notifyListeners();
  }

  int getCurrentStreak() {
    // TODO: Implement actual streak calculation logic
    // For now, returning a default value
    return 0;
  }

  Map<String, dynamic> _createDefaultResults() {
    return {
      'totalMarks': 0,
      'obtainedMarks': 0,
      'correctAnswers': 0,
      'totalQuestions': 0,
      'percentage': 0.0,
      'subtopicEval': <String, double>{},
    };
  }

  void setAssessments(List<Assessment> assessments) {
    _assessments = assessments;
    notifyListeners();
  }

  // Add this helper method for date formatting
  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}