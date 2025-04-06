import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/question_paper.dart';

class GeneratedPapersScreen extends StatelessWidget {
  const GeneratedPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Color(0xFFE8F3F9),
        elevation: 0,
        title: Text(
          'Generated Papers',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          final papers = provider.questionPapers;
          if (papers.isEmpty) {
            return Center(
              child: Text(
                'No papers generated yet',
                style: TextStyle(color: Color(0xFF2C3E50)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: papers.length,
            itemBuilder: (context, index) {
              final paper = papers[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
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
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    '${paper.subject} - ${paper.className}',
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Questions: ${paper.questions.length}',
                        style: TextStyle(color: Color(0xFF2C3E50)),
                      ),
                      Text(
                        'Total Marks: ${paper.totalMarks}',
                        style: TextStyle(color: Color(0xFF2C3E50)),
                      ),
                      Text(
                        'Duration: ${paper.duration} minutes',
                        style: TextStyle(color: Color(0xFF2C3E50)),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility, color: Color(0xFF4A90E2)),
                        onPressed: () => _viewPaper(context, paper),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Color(0xFF4A90E2)),
                        onPressed: () => _deletePaper(context, provider, paper),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deletePaper(BuildContext context, AssessmentProvider provider, QuestionPaper paper) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Paper'),
        content: Text('Are you sure you want to delete this paper?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteQuestionPaper(paper.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Paper deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPaper(BuildContext context, QuestionPaper paper) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionPaperView(paper: paper),
      ),
    );
  }
}