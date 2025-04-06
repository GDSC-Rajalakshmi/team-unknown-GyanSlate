import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/assessment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../widgets/translated_text.dart';


class PerformanceAnalysis extends StatefulWidget {
  final Assessment assessment;

  const PerformanceAnalysis({
    super.key,
    required this.assessment,
  });

  @override
  State<PerformanceAnalysis> createState() => _PerformanceAnalysisState();
}

class _PerformanceAnalysisState extends State<PerformanceAnalysis> {
  double selectedMark = 5.0;
  bool _isLoading = true;
  List<StudentPerformance> _performanceData = [];

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() => _isLoading = true);
    try {
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // Get the language provider
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
           final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      //print('currentLang: $currentLang');

      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/teacher/learning_gap_analysis'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'id': widget.assessment.id,
        'lng': currentLang}),
      );

      if (response.statusCode == 200) {
        print("response.body: ${response.body}");
        final List<dynamic> data = json.decode(response.body);
        _performanceData = data.map((item) => StudentPerformance.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load performance data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading performance data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFB),
        appBar: AppBar(
          backgroundColor: Color(0xFFE8F3F9),
          elevation: 0,
          title: TranslatedText(
            'performanceAnalysis.title',
            params: {'id': widget.assessment.id},
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
              Tab(child: TranslatedText('performanceAnalysis.tabs.studentAnalysis')),
              Tab(child: TranslatedText('performanceAnalysis.tabs.topicAnalysis')),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _performanceData.isEmpty
                ? Center(
                    child: TranslatedText(
                      'performanceAnalysis.messages.noData',
                      style: TextStyle(color: Color(0xFF2C3E50)),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return TabBarView(
                        children: [
                          _buildStudentAnalysisTab(constraints),
                          _buildTopicAnalysisTab(constraints),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildTopicAnalysisTab(BoxConstraints constraints) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_performanceData.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }

    // Calculate average scores for each topic
    Map<String, double> topicAverages = {};
    
    // First, collect all scores for each topic
    for (var student in _performanceData) {
      student.subtopicScore.forEach((topic, score) {
        if (!topicAverages.containsKey(topic)) {
          topicAverages[topic] = 0.0;
        }
        topicAverages[topic] = topicAverages[topic]! + score;
      });
    }
    
    // Calculate the average by dividing by number of students
    topicAverages.forEach((topic, totalScore) {
      topicAverages[topic] = totalScore / _performanceData.length;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: topicAverages.entries.map((entry) {
          final topic = entry.key;
          final averageScore = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: averageScore / 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                  ),
                  const SizedBox(height: 8),
                  TranslatedText(
                    'performanceAnalysis.topicAnalysis.averageScore',
                    style: TextStyle(color: Color(0xFF2C3E50)),
                    params: {'score': averageScore.toStringAsFixed(1)},
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentAnalysisTab(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'performanceAnalysis.studentAnalysis.markThreshold',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: selectedMark,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label: selectedMark.toStringAsFixed(1),
                        activeColor: Color(0xFF4A90E2),
                        onChanged: (value) {
                          setState(() {
                            selectedMark = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TranslatedText(
                        'performanceAnalysis.studentAnalysis.markOutOf',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        params: {'mark': selectedMark.toStringAsFixed(1)},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...getUniqueSubtopics().map((subtopic) {
            final studentsWithLowScore = getStudentsWithLowScore(subtopic);
            
            if (studentsWithLowScore.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(subtopic),
                  subtitle: TranslatedText(
                    'performanceAnalysis.studentAnalysis.belowThreshold',
                    style: TextStyle(color: Colors.red[700]),
                    params: {'count': studentsWithLowScore.length.toString()},
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: studentsWithLowScore.length,
                      itemBuilder: (context, index) {
                        final student = studentsWithLowScore[index];
                        final score = student.subtopicScore[subtopic] ?? 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getScoreColor(score),
                                child: Text(
                                  score.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name),
                                    TranslatedText(
                                      'performanceAnalysis.studentAnalysis.rollNo',
                                      style: TextStyle(
                                        color: Color(0xFF2C3E50).withOpacity(0.7),
                                      ),
                                      params: {'rollNo': student.rollNum},
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: score / 10,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getScoreColor(score),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Add these helper methods to your class
  Set<String> getUniqueSubtopics() {
    Set<String> subtopics = {};
    for (var student in _performanceData) {
      subtopics.addAll(student.subtopicScore.keys);
    }
    return subtopics;
  }

  List<StudentPerformance> getStudentsWithLowScore(String subtopic) {
    return _performanceData.where((student) {
      final score = student.subtopicScore[subtopic] ?? 0.0;
      return score < selectedMark;
    }).toList();
  }

  Color _getScoreColor(double score) {
    if (score <= 4) return Colors.red;
    if (score <= 7) return Colors.orange;
    return Colors.green;
  }
}

// Add this class to handle the API response data
class StudentPerformance {
  final String name;
  final String rollNum;
  final Map<String, double> subtopicScore;

  StudentPerformance({
    required this.name,
    required this.rollNum,
    required this.subtopicScore,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    Map<String, double> scores = {};
    Map<String, dynamic> rawScores = json['subtopic_score'] ?? {};
    
    rawScores.forEach((key, value) {
      scores[key] = (value is num) ? value.toDouble() : 0.0;
    });

    return StudentPerformance(
      name: json['name'] ?? 'Unknown',
      rollNum: json['roll_num'] ?? '',
      subtopicScore: scores,
    );
  }
} 