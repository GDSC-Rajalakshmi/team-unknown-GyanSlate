import 'package:flutter/material.dart';
import 'teacher_dashboard_layout.dart';
import '../../../core/routes/app_routes.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TeacherDashboardLayout(
      title: 'Teacher Dashboard',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Teacher Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildFeatureCard(
                context,
                'Create Assessment',
                'Create and manage assessments for your students. Select classes, sections, subjects, and chapters to create comprehensive assessments.',
                Icons.assignment,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.createAssessment);
                },
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                'Student Analysis',
                'Track and analyze student performance across different assessments. Get detailed insights into student progress.',
                Icons.analytics,
                onTap: () {
                  // TODO: Navigate to Student Analysis
                },
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                'Dashboard Overview',
                'Quick access to important information and statistics about your classes and students.',
                Icons.dashboard,
                onTap: () {
                  // TODO: Navigate to Dashboard Overview
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 