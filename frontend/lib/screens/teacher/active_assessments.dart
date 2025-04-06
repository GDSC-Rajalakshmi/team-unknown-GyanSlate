import 'package:flutter/material.dart';

class ActiveAssessments extends StatelessWidget {
  const ActiveAssessments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Assessments'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 5, // Sample active assessments
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment ${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Class: ${10 + (index % 3)}th Standard'),
                    Text('Subject: ${['Mathematics', 'Physics', 'Chemistry'][index % 3]}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (index + 1) * 0.2,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Students Completed: ${(index + 1) * 10}/40'),
                        Text('Time Left: ${60 - (index * 10)} mins'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // View detailed results
                          },
                          child: const Text('View Results'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // End assessment
                          },
                          child: const Text('End Assessment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 