import 'package:flutter/material.dart';
import '../../models/assessment.dart';
import 'package:translator/translator.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AssessmentResult extends StatefulWidget {
  final Assessment assessment;
  final Map<String, String> answers;
  final Map<String, dynamic> results;
  final String summary;

  const AssessmentResult({
    Key? key, 
    required this.assessment,
    required this.answers,
    required this.results,
    required this.summary,
  }) : super(key: key);

  @override
  _AssessmentResultState createState() => _AssessmentResultState();
}

class _AssessmentResultState extends State<AssessmentResult> {
  late final translator = GoogleTranslator();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
  }

  Future<String> _getTranslatedText(BuildContext context, String text) async {
    try {
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // If current language is English, return original text
      if (currentLang == 'en') return text;
      
      // Translate the text to the target language
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

  // Modify the text display widgets to use FutureBuilder for translation
  Widget _buildTranslatedText(String text, TextStyle style) {
    return FutureBuilder<String>(
      future: _getTranslatedText(context, text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 24, // Match the typical text height
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the total questions from the assessment instead of results
    final totalQuestions = widget.assessment.questionPaper.questions.length;
    
    // Count correct answers by comparing user answers with actual answers
    int correctAnswers = 0;
    widget.answers.forEach((questionId, userAnswer) {
      final question = widget.assessment.questionPaper.questions
          .firstWhere((q) => q.id == questionId);
      if (userAnswer == question.answer) {
        correctAnswers++;
      }
    });

    // Calculate percentage based on actual values
    final percentage = totalQuestions > 0 
        ? (correctAnswers / totalQuestions) * 100 
        : 0.0;
    
    // Update the results map
    widget.results['totalQuestions'] = totalQuestions;
    widget.results['correctAnswers'] = correctAnswers;
    widget.results['percentage'] = percentage;
    
    final subtopicEval = widget.results['topicWise'] as Map<String, dynamic>? ?? {};
    final answeredQuestions = widget.answers.length;
    final wrongAnswers = answeredQuestions - correctAnswers;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _getTranslatedText(context, 'Assessment Result'),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Assessment Result');
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Assessment Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTranslatedText(
                      widget.assessment.subject ?? 'Subject',
                      const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTranslatedText(
                      'Chapter: ${widget.assessment.chapter ?? 'Not specified'}',
                      const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    FutureBuilder<String>(
                      future: _getTranslatedText(context, 'Completed on: ${DateTime.now().toString().split(' ')[0]}'),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Completed on: ${DateTime.now().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Score Circle
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    // Score Circle with adjusted size
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: percentage == 0 
                            ? null
                            : SweepGradient(
                                center: Alignment.center,
                                startAngle: 0.0,
                                endAngle: (percentage / 100) * 6.28319,
                                colors: [
                                  _getScoreColor(percentage),
                                  _getScoreColor(percentage).withOpacity(0.1),
                                ],
                              ),
                        border: Border.all(
                          color: _getScoreColor(percentage),
                          width: 12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getScoreColor(percentage).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${percentage.round()}%',
                                style: TextStyle(
                                  fontSize: 36,  // Reduced size
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(percentage),
                                  height: 1.2,  // Added line height
                                ),
                              ),
                              const SizedBox(height: 4),  // Added small gap
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  _getScoreMessage(percentage),
                                  textAlign: TextAlign.center,  // Center align text
                                  style: TextStyle(
                                    fontSize: 12,  // Smaller font
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,  // Added line height
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),  // Reduced spacing
                    FutureBuilder<String>(
                      future: _getTranslatedText(context, _getScoreMessage(percentage)),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? _getScoreMessage(percentage),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(percentage),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTranslatedText(
                      _getMotivationalMessage(percentage),
                      TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildAPIFeedback(context),
            const SizedBox(height: 32),
            _buildSubtopicAnalysis(subtopicEval),
            const SizedBox(height: 32),
            
            // Back Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/student',
                  (route) => false,
                );
              },
              child: _buildTranslatedText(
                'Back to Dashboard',
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary({
    required int totalQuestions,
    required int answeredQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required double percentage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${percentage.round()}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(percentage),
              ),
            ),
            const SizedBox(height: 16),
            _buildTranslatedText(
              'Total Questions: $totalQuestions',
              const TextStyle(fontSize: 16),
            ),
            _buildTranslatedText(
              'Questions Attempted: $answeredQuestions',
              const TextStyle(fontSize: 16),
            ),
            _buildTranslatedText(
              'Correct Answers: $correctAnswers',
              const TextStyle(fontSize: 16),
            ),
            _buildTranslatedText(
              'Wrong Answers: $wrongAnswers',
              const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTranslatedText(
              'Question Analysis',
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.assessment.questionPaper.questions.map((question) {
              final userAnswer = widget.answers[question.id];
              final isCorrect = userAnswer == question.answer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTranslatedText(
                      question.questionText,
                      const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...question.options!.map((option) {
                      final isUserAnswer = option == userAnswer;
                      final isCorrectAnswer = option == question.answer;
                      
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isUserAnswer
                              ? (isCorrect ? Icons.check_circle : Icons.cancel)
                              : (isCorrectAnswer ? Icons.check_circle_outline : null),
                          color: isUserAnswer
                              ? (isCorrect ? Colors.green : Colors.red)
                              : (isCorrectAnswer ? Colors.green : null),
                        ),
                        title: _buildTranslatedText(
                          option,
                          const TextStyle(fontSize: 14),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAPIFeedback(BuildContext context) {
    final apiAnalysis = widget.results['apiAnalysis'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTranslatedText(
              'Assessment Analysis',
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTranslatedText(
              widget.summary,
              TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showMoreDetails(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 5,
              ),
              child: _buildTranslatedText(
                'Detailed Analysis',
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage(double score) {
    if (score == 0) return 'Start!';  // Shortened messages
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great!';
    if (score >= 70) return 'Good!';
    if (score >= 60) return 'Keep Going!';
    if (score >= 50) return 'Getting There!';
    if (score >= 30) return 'Keep Trying!';
    return 'You Can Do It!';
  }

  Color _getScoreColor(double score) {
    if (score == 0) return Colors.blue[300]!;
    if (score >= 90) return Colors.indigo;
    if (score >= 80) return Colors.green[600]!;
    if (score >= 70) return Colors.blue[600]!;
    if (score >= 60) return Colors.purple[500]!;
    if (score >= 50) return Colors.teal[500]!;
    return Colors.amber[600]!;
  }

  String _getMotivationalMessage(double score) {
    if (score < 50) {
      return "Every attempt helps you grow. You're on the right path!";  // Removed line break
    } else if (score < 70) {
      return "You're making progress! Keep up the good work!";  // Removed line break
    } else {
      return "Amazing progress! Keep shining!";  // Removed line break
    }
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreDetails(BuildContext context) {
    final apiAnalysis = widget.results['apiAnalysis'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: _buildTranslatedText(
            'Detailed Analysis',
            const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Current Assessment', apiAnalysis['currentAssessment']),
                _buildDetailSection('Overall Improvement', apiAnalysis['overallImprovement']),
                _buildDetailSection('Key Areas of Strength', apiAnalysis['keyAreas']),
                _buildDetailSection('Areas Needing Attention', apiAnalysis['areasNeedingAttention']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: _buildTranslatedText(
                'Close',
                const TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTranslatedText(
            title,
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildTranslatedText(
            content,
            const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicAnalysis(Map<String, dynamic> subtopicEval) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTranslatedText(
              'Subtopic Analysis',
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (var entry in subtopicEval.entries)
              _buildSubtopicDetail(entry.key, entry.value),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtopicDetail(String subtopic, dynamic details) {
    // Ensure details is a double
    final score = details is double ? details : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTranslatedText(
            '$subtopic - Score: ${score.toStringAsFixed(2)}',
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}