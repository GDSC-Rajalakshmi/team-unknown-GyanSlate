import 'package:flutter/material.dart';
import 'take_assessment.dart';
import '../../models/assessment.dart';
import '../../models/question_paper.dart';
import '../../models/question.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/translated_text.dart';  // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import 'package:translator/translator.dart' as google_translator;

class AvailableAssessments extends StatefulWidget {
  const AvailableAssessments({super.key});

  @override
  State<AvailableAssessments> createState() => _AvailableAssessmentsState();
}

class _AvailableAssessmentsState extends State<AvailableAssessments> {
  bool _isLoading = true;
  Map<String, List<dynamic>> _assessments = {
    'active': [],
    'upcoming': [],
    'past': [],
  };
  
  // Add translator instance
  late google_translator.GoogleTranslator translator;

  @override
  void initState() {
    super.initState();
    translator = google_translator.GoogleTranslator();
    _fetchAssessments();
  }

  // Add translation helper method
  Future<String> _translateText(String text) async {
    try {
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // If current language is English, return original text
      if (currentLang == 'en') return text;
      
      final translation = await translator.translate(
        text,
        to: currentLang,
      );
      
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  Future<void> _fetchAssessments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rollNumString = prefs.getString('rollNumber') ?? '0';
      final classNumString = prefs.getString('class') ?? '10';
      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Retrieved token: $token');

     // Get the language provider
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
           final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
        
      // Convert to int
      final rollNum = int.tryParse(rollNumString) ?? 0; // Default to 0 if parsing fails
      final classNum = int.tryParse(classNumString) ?? 10; // Default to 10 if parsing fails

      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/student/list_assignment'),
        body: jsonEncode({
          "class": classNum,
          "roll_num": rollNum,
          "lng": currentLang
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the token to headers
        },
      );

      // Check if widget is still mounted before calling setState
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("List of assessments: $data");
        setState(() {
          _assessments = {
            'active': List.from(data['active'] ?? []),
            'upcoming': List.from(data['upcomming'] ?? []),
            'past': List.from(data['past'] ?? []),
          };
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load assessments');
      }
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading assessments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('availableAssessments'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(child: TranslatedText('tabs.active')),
                      Tab(child: TranslatedText('tabs.upcoming')),
                      Tab(child: TranslatedText('tabs.past')),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAssessmentList(_assessments['active']!),
                        _buildAssessmentList(_assessments['upcoming']!),
                        _buildAssessmentList(_assessments['past']!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAssessmentList(List<dynamic> assessments) {
    return Container(
      color: Colors.grey[50],
      child: assessments.isEmpty
          ? const Center(child: TranslatedText('assessmentInfo.noAssessments'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assessments.length,
              itemBuilder: (context, index) {
                final assessment = assessments[index];
                final startTime = _parseDateTime(assessment['start']);
                final endTime = _parseDateTime(assessment['end']);
                final assessmentType = _getAssessmentType(assessment);
                
                // Color schemes
                Color accentColor;
                Color statusColor;
                String statusText;
                
                switch(assessmentType) {
                  case 'active':
                    accentColor = const Color(0xFF2196F3);
                    statusColor = const Color(0xFF4CAF50);
                    statusText = 'ACTIVE';
                    break;
                  case 'upcoming':
                    accentColor = const Color(0xFFFF9800);
                    statusColor = const Color(0xFFFF9800);
                    statusText = 'UPCOMING';
                    break;
                  case 'past':
                    accentColor = Colors.grey;
                    statusColor = Colors.grey;
                    statusText = 'COMPLETED';
                    break;
                  default:
                    accentColor = const Color(0xFF2196F3);
                    statusColor = const Color(0xFF4CAF50);
                    statusText = 'ACTIVE';
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Subject Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getSubjectIcon(assessment['subject']),
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<String>(
                                    future: _translateText(assessment['subject']),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? assessment['subject'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<String>(
                                    future: Future.wait([
                                      _translateText('Chapter : '),
                                      _translateText(assessment['chapter'].toString())
                                    ]).then((translations) => '${translations[0]} ${translations[1]}'),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? 'Chapter : ${assessment['chapter']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            FutureBuilder<String>(
                              future: _translateText(statusText),
                              builder: (context, snapshot) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    snapshot.data ?? statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Time and Progress Section with translations
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                FutureBuilder<String>(
                                  future: _translateText(_formatDate(startTime)),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? _formatDate(startTime),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (assessmentType == 'active')
                                        FutureBuilder<String>(
                                          future: _translateText('Time Remaining: ${_getRemainingTime(endTime)}'),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? 'Time Remaining: ${_getRemainingTime(endTime)}',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        )
                                      else if (assessmentType == 'upcoming')
                                        FutureBuilder<String>(
                                          future: _translateText('Starts in: ${_getTimeUntilStart(startTime)}'),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? 'Starts in: ${_getTimeUntilStart(startTime)}',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: assessmentType == 'past'
                                              ? 1.0
                                              : (assessmentType == 'upcoming'
                                                  ? 0.0
                                                  : _getTimeProgress(startTime, endTime)),
                                          backgroundColor: statusColor.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (assessmentType == 'active') ...[
                                  const SizedBox(width: 16),
                                  _buildStartButton(context, assessment, accentColor),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String text,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Map<String, dynamic> assessment, Color accentColor) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          // Get the language provider
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          final languageName = LanguageProvider.languageNames[languageProvider.currentLanguage];

          // Retrieve the state from local storage
          final prefs = await SharedPreferences.getInstance();
          final state = prefs.getString('state') ?? 'common';

          // Get the stored token
          final storage = const FlutterSecureStorage();
          final token = await storage.read(key: 'token');

          // Make API call to get questions
          final response = await http.post(
            Uri.parse('http://192.168.255.209:5000/student/attend_assignment'),
            body: jsonEncode({
              "state": state,
              "id": assessment['id'].toString(),
              "lang": languageName
            }),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // Add the token to headers
            },
          );

          if (!context.mounted) return;
          Navigator.pop(context); // Remove loading indicator

          if (response.statusCode == 200) {
            final questionsData = jsonDecode(response.body) as List;
            print("questionsData: ${questionsData}");
            // Convert API response to Question objects
            final questions = questionsData.map((q) => Question(
              id: q['id'].toString(),
              questionText: q['question'] ?? '',
              options: List<String>.from(q['options'] ?? []),
              answer: q['correct_option'] ?? '',
              why: q['why'] ?? 'No explanation provided',
              subtopic: q['subtopic'] ?? 'General',
              qType: 'MCQ',
              subject: assessment['subject'] ?? '',
              chapter: assessment['chapter'] ?? '',
              className: assessment['className'] ?? '',
            )).toList();

            // Update assessment with fetched questions
            assessment['questions'] = questions;
            
            final assessmentObj = _createAssessment(assessment);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TakeAssessment(
                  assessment: assessmentObj,
                ),
              ),
            );
          } else {
            throw Exception('Failed to load questions');
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading questions: $e')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.play_arrow),
      label: const TranslatedText('assessmentInfo.start'),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.science_outlined;
      default:
        return Icons.book;
    }
  }

  String _getRemainingTime(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }

  double _getTimeProgress(DateTime startTime, DateTime endTime) {
    final total = endTime.difference(startTime).inMinutes;
    final elapsed = DateTime.now().difference(startTime).inMinutes;
    return 1 - (elapsed / total).clamp(0.0, 1.0);
  }

  DateTime _parseDateTime(String dateStr) {
    // Split the date string into components
    List<String> parts = dateStr.split(' ');
    
    // Convert month abbreviation to number
    Map<String, String> months = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
      'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
      'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
    };
    
    // Reconstruct date in ISO format
    String day = parts[1].padLeft(2, '0');
    String month = months[parts[2]]!;
    String year = parts[3];
    String time = parts[4];
    
    // Create ISO formatted string
    return DateTime.parse('$year-$month-$day $time');
  }

  Assessment _createAssessment(Map<String, dynamic> data) {
    final questionsList = data['questions'] as List<Question>;
    final questions = questionsList.map((q) => q).toList();

    QuestionPaper questionPaper = QuestionPaper(
      title: 'Assessment ${DateTime.now()}',
      subject: data['subject'] ?? '',
      className: data['className'] ?? '',
      questions: questions,
    );

    return Assessment(
      id: data['id'].toString(),
      subject: data['subject'],
      chapter: data['chapter'],
      className: 'Class 11',
      topics: data['chapter'],
      startTime: _parseDateTime(data['start']),
      endTime: _parseDateTime(data['end']),
      status: AssessmentStatus.active,
      createdAt: DateTime.now(),
      questionCount: questions.length,
      isObjective: true,
      questionPaper: questionPaper,
    );
  }

  // Helper method to determine assessment type
  String _getAssessmentType(Map<String, dynamic> assessment) {
    if (_assessments['active']!.contains(assessment)) {
      return 'active';
    } else if (_assessments['upcoming']!.contains(assessment)) {
      return 'upcoming';
    } else {
      return 'past';
    }
  }

  // Helper method to get time until assessment starts
  String _getTimeUntilStart(DateTime startTime) {
    final remaining = startTime.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }
  }
}