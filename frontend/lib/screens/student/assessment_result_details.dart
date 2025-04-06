import 'package:flutter/material.dart';
import '../../models/assessment.dart';
import 'package:fl_chart/fl_chart.dart';

class AssessmentResultDetails extends StatelessWidget {
  final Assessment assessment;

  const AssessmentResultDetails({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final results = assessment.results;
    if (results == null) {
      return const Scaffold(
        body: Center(
          child: Text('No results available'),
        ),
      );
    }

    final percentage = (results['percentage'] as num?)?.toDouble() ?? 0.0;
    final totalQuestions = results['totalQuestions'] as int? ?? 0;
    final correctAnswers = results['correctAnswers'] as int? ?? 0;
    final wrongAnswers = totalQuestions - correctAnswers;
    final topicWise = Map<String, double>.from(
      (results['topicWise'] as Map<String, dynamic>?) ?? {}
    );
    final feedback = (results['feedback'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Resultsdfgdfg'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Assessment Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      assessment.subject,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chapter: ${assessment.chapter}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Completed on: ${_formatDate(assessment.endTime)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Score Circle Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
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
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(percentage),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  _getScoreMessage(percentage),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Overall Analysis Card
            if (feedback.isNotEmpty) ...[
              _buildFeedbackSection(feedback),
              const SizedBox(height: 24),
            ],

            // 4. Topic-wise Performance
            if (topicWise.isNotEmpty) ...[
              _buildTopicWisePerformance(topicWise),
              const SizedBox(height: 24),
            ],

            // 5. Mark Percentage
            _buildMarkPercentage(percentage, totalQuestions, correctAnswers),
            const SizedBox(height: 24),

            // 6. Statistics Section
            _buildStatisticsSection(totalQuestions, correctAnswers, wrongAnswers),
            const SizedBox(height: 24),

            // 7. Question Analysis
            _buildQuestionAnalysis(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Add all the helper methods from AssessmentResult
  String _getScoreMessage(double score) {
    if (score == 0) return 'Start!';
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
      return "Every attempt helps you grow. You're on the right path!";
    } else if (score < 70) {
      return "You're making progress! Keep up the good work!";
    } else {
      return "Amazing progress! Keep shining!";
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTopicWiseChart(Map<String, double> topicWise) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= topicWise.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    topicWise.keys.elementAt(value.toInt()),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%',
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
        ),
        borderData: FlBorderData(show: false),
        barGroups: topicWise.entries
            .map((entry) => BarChartGroupData(
                  x: topicWise.keys.toList().indexOf(entry.key),
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: _getBarColor(entry.value),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Color _getBarColor(double value) {
    if (value >= 80) return Colors.green[400]!;
    if (value >= 60) return Colors.blue[400]!;
    if (value >= 40) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Widget _buildFeedbackSection(List<String> feedback) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Overall Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Feedback content
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analysis content
                  ...feedback.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Improvement Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "We'll use visual aids, experiments, and real-life examples to improve your grasp of these challenging topics.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Additional Resources Section
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: Colors.green.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Check out our recommended practice exercises and study materials in the Resources section.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildQuestionAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...assessment.questionPaper.questions.map((question) {
              final userAnswer = assessment.results?['answers']?[question.id] as String?;
              final isCorrect = userAnswer == question.answer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                        title: Text(option),
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

  // Add this new method to build statistics grid
  Widget _buildStatisticsGrid(int totalQuestions, int correctAnswers, int wrongAnswers) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Questions',
                totalQuestions,
                Icons.assignment_rounded,
                Colors.blue[600]!,
                Colors.blue[100]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Attempted',
                totalQuestions,
                Icons.edit_note_rounded,
                Colors.purple[600]!,
                Colors.purple[100]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Correct',
                correctAnswers,
                Icons.check_circle_rounded,
                Colors.green[600]!,
                Colors.green[100]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Wrong',
                wrongAnswers,
                Icons.cancel_rounded,
                Colors.red[600]!,
                Colors.red[100]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicWisePerformance(Map<String, double> topicWise) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Topic-wise Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              height: 300,
              child: _buildTopicWiseChart(topicWise),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkPercentage(double percentage, int totalQuestions, int correctAnswers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.score_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Mark Percentage',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(
                Icons.percent_rounded,
                color: _getScoreColor(percentage),
                size: 28,
              ),
              title: const Text(
                'Overall Percentage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(percentage),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'Marks Obtained',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Text(
                '$correctAnswers/$totalQuestions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(int totalQuestions, int correctAnswers, int wrongAnswers) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatisticsGrid(totalQuestions, correctAnswers, wrongAnswers),
          ],
        ),
      ),
    );
  }
} 