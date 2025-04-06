import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/assessment_provider.dart';
import '../../models/assessment.dart';
import '../../models/question_paper.dart';
import './assessment_creator.dart';
import 'performance_analysis.dart';
import '../../widgets/translated_text.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';  // For HttpDate
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';


class AssessmentManagement extends StatefulWidget {
  const AssessmentManagement({super.key});

  @override
  State<AssessmentManagement> createState() => _AssessmentManagementState();
}

class _AssessmentManagementState extends State<AssessmentManagement> {
  bool _isLoading = true;

  // Add this dummy question paper
  final QuestionPaper dummyQuestionPaper = QuestionPaper(
    title: 'Default Question Paper',
    subject: '',
    className: '',
    questions: [],
    duration: 60,
  );

  @override
  void initState() {
    super.initState();
    // Fetch assessments only when page loads
    _fetchAssessments();
  }

  Future<void> _fetchAssessments() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Get the language provider
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
         // final languageName = LanguageProvider.languageNames[languageProvider.currentLanguage];
           final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
          // print('Language Name: $currentLang');

      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/teacher/list_assignment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',  // Specify content type
        },
        body: json.encode({'lng': currentLang}),  // Send language parameter
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Assessment> allAssessments = [];
        final processedIds = <String>{};

        // Process active assessments
        if (data['active'] != null) {
          for (var item in data['active'] as List) {
            final id = item['id'].toString();
            if (!processedIds.contains(id)) {
              processedIds.add(id);
              allAssessments.add(Assessment(
                id: id,
                subject: item['subject'] ?? '',
                chapter: item['chapter'] ?? '',
                className: item['class']?.toString() ?? '',
                startTime: _parseDateTime(item['start']),
                endTime: _parseDateTime(item['end']),
                status: AssessmentStatus.active,
                topics: item['chapter'] ?? '',
                questionPaper: dummyQuestionPaper,
                createdAt: DateTime.now(),
                questionCount: 0,
                isObjective: true,
              ));
            }
          }
        }

        // Process upcoming assessments
        if (data['upcomming'] != null) {
          for (var item in data['upcomming'] as List) {
            final id = item['id'].toString();
            if (!processedIds.contains(id)) {
              processedIds.add(id);
              allAssessments.add(Assessment(
                id: id,
                subject: item['subject'] ?? '',
                chapter: item['chapter'] ?? '',
                className: item['class']?.toString() ?? '',
                startTime: _parseDateTime(item['start']),
                endTime: _parseDateTime(item['end']),
                status: AssessmentStatus.upcoming,
                topics: item['chapter'] ?? '',
                questionPaper: dummyQuestionPaper,
                createdAt: DateTime.now(),
                questionCount: 0,
                isObjective: true,
              ));
            }
          }
        }

        // Process past assessments
        if (data['past'] != null) {
          for (var item in data['past'] as List) {
            final id = item['id'].toString();
            if (!processedIds.contains(id)) {
              processedIds.add(id);
              allAssessments.add(Assessment(
                id: id,
                subject: item['subject'] ?? '',
                chapter: item['chapter'] ?? '',
                className: item['class']?.toString() ?? '',
                startTime: _parseDateTime(item['start']),
                endTime: _parseDateTime(item['end']),
                status: AssessmentStatus.completed,
                topics: item['chapter'] ?? '',
                questionPaper: dummyQuestionPaper,
                createdAt: DateTime.now(),
                questionCount: 0,
                isObjective: true,
              ));
            }
          }
        }

        if (mounted) {
          final provider = Provider.of<AssessmentProvider>(context, listen: false);
          provider.setAssessments(allAssessments);
        }
      }
    } catch (e) {
      print('Error in _fetchAssessments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assessments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Remove the timer since we're not using it anymore
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFB),  // Updated background color
        appBar: AppBar(
          backgroundColor: Color(0xFFE8F3F9),  // Updated header color
          elevation: 0,
          title: TranslatedText(
            'assessmentManagement.title',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
          bottom: TabBar(
            labelColor: Color(0xFF2C3E50),
            unselectedLabelColor: Color(0xFF2C3E50).withOpacity(0.7),
            indicatorColor: Color(0xFF4A90E2),
            tabs: [
              Tab(child: TranslatedText('assessmentManagement.tabs.active')),
              Tab(child: TranslatedText('assessmentManagement.tabs.upcoming')),
              Tab(child: TranslatedText('assessmentManagement.tabs.completed')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAssessmentList('active'),
            _buildAssessmentList('upcoming'),
            _buildAssessmentList('completed'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AssessmentCreator(),
              ),
            );
          },
          backgroundColor: Color(0xFF4A90E2),
          label: TranslatedText(
            'assessmentManagement.actions.createAssessment',
            style: TextStyle(
              color: Colors.white,  // Set text color to white
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(
            Icons.add,
            color: Colors.white,  // Set icon color to white
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentList(String type) {
    return Consumer<AssessmentProvider>(
      builder: (context, provider, child) {
        // Add debug prints to check filtering
        print('Total assessments in provider: ${provider.assessments.length}');
        print('Active count: ${provider.assessments.where((a) => a.status == AssessmentStatus.active).length}');
        print('Upcoming count: ${provider.assessments.where((a) => a.status == AssessmentStatus.upcoming).length}');
        print('Completed count: ${provider.assessments.where((a) => a.status == AssessmentStatus.completed).length}');
        
        // Filter assessments based on type
        final assessments = provider.assessments.where((a) {
          switch (type) {
            case 'active':
              return a.status == AssessmentStatus.active;
            case 'upcoming':
              return a.status == AssessmentStatus.upcoming;
            case 'completed':
              return a.status == AssessmentStatus.completed;
            default:
              return false;
          }
        }).toList();

        print('Filtered assessments for $type: ${assessments.length}');
        
        // Rest of the widget remains the same
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _isLoading = true);
            await _fetchAssessments();
            setState(() => _isLoading = false);
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : assessments.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: TranslatedText(
                          'assessmentManagement.messages.noAssessments',
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: assessments.length,
                      itemBuilder: (context, index) {
                        final assessment = assessments[index];
                        print('Building card for assessment ${assessment.id} with status ${assessment.status}');
                        return _buildAssessmentCard(assessment);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TranslatedText(
                    'assessmentManagement.card.assessmentId',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                    params: {'id': assessment.id},
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(assessment.status.toString().split('.').last),
              ],
            ),
            const SizedBox(height: 8),
            TranslatedText(
              'assessmentManagement.card.class',
              style: TextStyle(color: Color(0xFF2C3E50)),
              overflow: TextOverflow.ellipsis,
              params: {'className': assessment.className ?? "N/A"},
            ),
            TranslatedText(
              'assessmentManagement.card.subject',
              style: TextStyle(color: Color(0xFF2C3E50)),
              overflow: TextOverflow.ellipsis,
              params: {'subject': assessment.subject},
            ),
            TranslatedText(
              'assessmentManagement.card.chapter',
              style: TextStyle(color: Color(0xFF2C3E50)),
              overflow: TextOverflow.ellipsis,
              params: {'chapter': assessment.chapter},
            ),
            const SizedBox(height: 8),
            if (assessment.status == AssessmentStatus.active) ...[
              LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Color(0xFF2C3E50).withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: TranslatedText(
                    _getTimeTranslationKey(assessment),
                    style: TextStyle(color: Color(0xFF2C3E50).withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                    params: _getTimeParams(assessment),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (assessment.status == AssessmentStatus.completed || 
                      assessment.status == AssessmentStatus.active)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PerformanceAnalysis(
                              assessment: assessment,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.analytics, color: Color(0xFF4A90E2)),
                      label: TranslatedText(
                        'assessmentManagement.actions.viewResults',
                        style: TextStyle(color: Color(0xFF4A90E2)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeTranslationKey(Assessment assessment) {
    switch (assessment.status) {
      case AssessmentStatus.completed:
        return 'assessmentManagement.time.completed';
      case AssessmentStatus.upcoming:
        return 'assessmentManagement.time.scheduled';
      case AssessmentStatus.active:
        return 'assessmentManagement.time.remaining';
      default:
        return '';
    }
  }

  Map<String, String> _getTimeParams(Assessment assessment) {
    switch (assessment.status) {
      case AssessmentStatus.completed:
        return {'date': assessment.endTime.toString().split(' ')[0]};
      case AssessmentStatus.upcoming:
        return {'date': assessment.startTime.toString().split(' ')[0]};
      case AssessmentStatus.active:
        final remaining = assessment.endTime.difference(DateTime.now());
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes.remainder(60);
        return {
          'hours': hours.toString(),
          'minutes': minutes.toString(),
        };
      default:
        return {};
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String translationKey = 'assessmentManagement.status.$status';
    
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    
    return Chip(
      label: TranslatedText(translationKey),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  // Update the date parsing method
  DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    
    try {
      // Parse RFC format date (e.g., "Mon, 24 Mar 2025 16:15:00 GMT")
      return HttpDate.parse(dateStr);
    } catch (e) {
      try {
        // Fallback to manual parsing if HttpDate fails
        final DateFormat format = DateFormat("E, dd MMM yyyy HH:mm:ss 'GMT'");
        return format.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $dateStr');
        // Return current time if parsing fails
        return DateTime.now();
      }
    }
  }
  String _getTranslatedText(String key) {
    // This is a synchronous version for static text
    // For dynamic text, use _translateText instead
    return key;  // Return the key as-is for now, you can integrate with your translation system later
  }
} 