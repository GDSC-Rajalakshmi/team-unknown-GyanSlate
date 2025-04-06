import 'package:flutter/material.dart';
import './question_paper_generator.dart';
import './generated_papers_screen.dart';

class QuestionGenerator extends StatelessWidget {
  const QuestionGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Color(0xFFE8F3F9),
        elevation: 0,
        title: Text(
          'Question Generator',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose an Option',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildOptionCard(
                context,
                'Generate New Paper',
                Icons.assignment,
                'Create a new question paper using AI',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuestionPaperGenerator(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                'View Generated Papers',
                Icons.list_alt,
                'View and manage your generated question papers',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeneratedPapersScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(icon, size: 48, color: Color(0xFF4A90E2)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2C3E50).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}