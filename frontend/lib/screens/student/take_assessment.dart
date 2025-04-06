import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assessment_provider.dart';
import '../../models/assessment.dart';
import '../../models/question.dart';
import 'assessment_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/state_fruits.dart';
import 'dart:math';
import '../../providers/language_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:translator/translator.dart' as google_translator;


class TakeAssessment extends StatefulWidget {
  final Assessment assessment;

  const TakeAssessment({
    super.key,
    required this.assessment,
  });

  @override
  State<TakeAssessment> createState() => _TakeAssessmentState();
}

class _TakeAssessmentState extends State<TakeAssessment> {
  int currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;
  late google_translator.GoogleTranslator translator;

  @override
  void initState() {
    super.initState();
    translator = google_translator.GoogleTranslator();
  }

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
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.assessment.questionPaper.questions;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.assessment.subject),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('No questions available for this assessment.'),
        ),
      );
    }

    if (currentQuestionIndex >= questions.length) {
      currentQuestionIndex = questions.length - 1;
    }

    final currentQuestion = questions[currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: FutureBuilder<String>(
              future: _translateText('Exit Assessment?'),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Exit Assessment?');
              },
            ),
            content: FutureBuilder<String>(
              future: _translateText('Your progress will be lost. Are you sure?'),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Your progress will be lost. Are you sure?');
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: FutureBuilder<String>(
                  future: _translateText('No'),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? 'No');
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: FutureBuilder<String>(
                  future: _translateText('Yes'),
                  builder: (context, snapshot) {
                    return Text(snapshot.data ?? 'Yes');
                  },
                ),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.assessment.subject),
              centerTitle: true,
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTimer(),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Question ${currentQuestionIndex + 1} of ${questions.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildQuestionCard(currentQuestion),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Wrap the buttons in a SafeArea to prevent overflow
                    SafeArea(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentQuestionIndex > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentQuestionIndex--;
                                    });
                                  },
                                  child: FutureBuilder<String>(
                                    future: _translateText('Previous'),
                                    builder: (context, snapshot) {
                                      return Text(snapshot.data ?? 'Previous');
                                    },
                                  ),
                                ),
                              ),
                            if (currentQuestionIndex < questions.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentQuestionIndex++;
                                    });
                                  },
                                  child: FutureBuilder<String>(
                                    future: _translateText('Next'),
                                    builder: (context, snapshot) {
                                      return Text(snapshot.data ?? 'Next');
                                    },
                                  ),
                                ),
                              ),
                            if (currentQuestionIndex == questions.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitAssessment,
                                  child: FutureBuilder<String>(
                                    future: _translateText('Submit'),
                                    builder: (context, snapshot) {
                                      return Text(snapshot.data ?? 'Submit');
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Loading overlay
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              final currentLanguage = languageProvider.currentLanguage;
                              String evaluatingText = 'Evaluating Answers...';
                              
                              // Add translations for different languages
                              switch (currentLanguage) {
                                case 'hi':
                                  evaluatingText = 'उत्तरों का मूल्यांकन किया जा रहा है...';
                                  break;
                                case 'te':
                                  evaluatingText = 'జవాబులను మూల్యాంకనం చేస్తోంది...';
                                  break;
                                case 'ta':
                                  evaluatingText = 'பதில்கள் மதிப்பீடு செய்யப்படுகின்றன...';
                                  break;
                                case 'kn':
                                  evaluatingText = 'ಉತ್ತರಗಳನ್ನು ಮೌಲ್ಯಮಾಪನ ಮಾಡಲಾಗುತ್ತಿದೆ...';
                                  break;
                                default:
                                  evaluatingText = 'Evaluating Answers...';
                              }
                              
                              return Text(
                                evaluatingText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final remaining = widget.assessment.endTime.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final color = minutes < 5 ? Colors.red : Colors.white;
    
    return Text(
      '${remaining.inHours}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.questionText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...question.options!.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    overflow: TextOverflow.visible,
                  ),
                  value: option,
                  groupValue: _answers[question.id],
                  onChanged: (value) {
                    if (value != null) {
                      _submitAnswer(question, value);
                    }
                  },
                );
              }),
              Text(
                'Marks: ${question.marks}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAnswer(Question question, String answer) {
    setState(() {
      _answers[question.id] = answer;
    });
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      
      // Retrieve the state from local storage
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? 'common'; // Default to 'common' if not found

      // Initialize tracking maps
      Map<String, int> subtopicTotalQuestions = {};
      Map<String, int> subtopicCorrectAnswers = {};
      Map<String, double> subtopicEval = {};

      // First pass: Count total questions per subtopic
      for (var question in widget.assessment.questionPaper.questions) {
        final subtopic = question.subtopic?.trim() ?? "Unknown";
        subtopicTotalQuestions[subtopic] = (subtopicTotalQuestions[subtopic] ?? 0) + 1;
      }

      // Second pass: Count correct answers per subtopic
      for (var question in widget.assessment.questionPaper.questions) {
        final subtopic = question.subtopic?.trim() ?? "Unknown";
        final userAnswer = _answers[question.id]?.trim();
        final correctAnswer = question.answer?.trim();
        
        if (userAnswer != null && correctAnswer != null && userAnswer == correctAnswer) {
          subtopicCorrectAnswers[subtopic] = (subtopicCorrectAnswers[subtopic] ?? 0) + 1;
        }
      }

      // Calculate final scores (0-10 scale)
      subtopicTotalQuestions.forEach((subtopic, total) {
        final correct = subtopicCorrectAnswers[subtopic] ?? 0;
        final percentage = (correct / total) * 100;
        subtopicEval[subtopic] = (percentage / 10).clamp(0, 10);
      });

      print('Subtopic Evaluation:');
      subtopicEval.forEach((subtopic, score) {
        print('$subtopic: ${score.toStringAsFixed(1)}/10');
      });

      // Retrieve roll number and name from local storage
      final rollNumString = prefs.getString('rollNumber') ?? '0'; // Retrieve as String
      final name = prefs.getString('studentName') ?? 'Student Name'; // Default name if not found

 // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      // Convert roll number to int
      final rollNum = int.tryParse(rollNumString) ?? 0; // Default to 0 if parsing fails

      // Get the current language from LanguageProvider
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final currentLanguage = languageProvider.currentLanguage;
      final languageName = LanguageProvider.languageNames[currentLanguage] ?? currentLanguage; // Get full language name

      print('Submitting assessment with data:');
      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/complet_assignment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the token to headers
        },
        body: jsonEncode({
          "roll_num": rollNum,
          "name": name,
          "state": state, // Use the retrieved state
          "id": widget.assessment.id,
          "subtopic_eval": subtopicEval,
          "lang": languageName, // Send the full language name
        })
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> apiResponse;
        try {
          apiResponse = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('Error decoding JSON: $e');
          apiResponse = {};
        }
        
        // Assuming 'score' is a double that you want to store
        final double rawScore = apiResponse['score']?.toDouble() ?? 0.0; // Ensure it's a double
        final int points = rawScore.toInt(); // Convert double to int
        
        // Update the student's points and score in SharedPreferences
        await _updateStudentData(points, rawScore); // Pass rawScore as double

        // Create a safe version of the results
        final completeResults = {
          'totalMarks': 0,
          'obtainedMarks': 0,
          'percentage': 0.0,
          'answers': Map<String, String>.from(_answers),
          'topicWise': Map<String, double>.from(subtopicEval),
          'apiAnalysis': {
            'currentAssessment': _sanitizeString(apiResponse['current_assessment_analysis']),
            'overallImprovement': _sanitizeString(apiResponse['overall_performance_improvement']),
            'keyAreas': _sanitizeString(apiResponse['key_areas_improvement']),
            'areasNeedingAttention': _sanitizeString(apiResponse['areas_requiring_more_attention']),
            'summary': _sanitizeString(apiResponse['summary']),
            'score': apiResponse['score'],
          }
        };

        if (mounted) {
          // Get the state from local storage and show fruit reward popup
          await _showFruitRewardPopup(rawScore, points); // Pass rawScore to popup
          
          // After popup is dismissed, navigate to results page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AssessmentResult(
                  assessment: widget.assessment,
                  answers: _answers,
                  results: completeResults,
                  summary: _sanitizeString(apiResponse['summary']),
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to submit assessment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assessment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStudentData(int points, double score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current points
      int currentPoints = prefs.getInt('student_points') ?? 0;
      print('Current points before update: $currentPoints'); // Debug print
      
      // Update points (ensure it's not negative)
      int newPoints = currentPoints + points;
      if (newPoints < 0) newPoints = 0;  // Ensure points don't go below zero
      
      // Save updated points
      await prefs.setInt('student_points', newPoints);
      
      // Save score as a string (convert to string to handle different types)
      await prefs.setString('student_score', score.toInt().toString()); // Convert double to int and then to string
      
      print('Updated student points: $currentPoints + $points = $newPoints');
      print('Updated student score: $score');
    } catch (e) {
      print('Error updating student data: $e');
    }
  }

  List<String> _generateFeedback(double percentage) {
    final List<String> feedback = [];
    
    if (widget.assessment.subject == 'Mathematics') {
      feedback.add(
        'Your algebra test shows good understanding of basic equation solving. '
        'You demonstrated ability to handle equations with addition, subtraction, '
        'and multiplication. To further improve, practice more complex equations '
        'and double-check your final answers. Keep working on translating word '
        'problems into algebraic expressions.'
      );
    } else {
      feedback.add(
        'You have completed the ${widget.assessment.subject} assessment. '
        'Your score is ${percentage.round()}%. Review the questions and answers '
        'above to understand areas for improvement.'
      );
    }

    return feedback;
  }

  String _sanitizeString(dynamic value) {
    if (value == null) return '';
    String str = value.toString();
    // Truncate if too long (optional)
    if (str.length > 1000) {
      str = '${str.substring(0, 997)}...';
    }
    return str;
  }

  Future<void> _showFruitRewardPopup(dynamic score, int points) async {
    // Get state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final state = prefs.getString('user_state') ?? 'common';
    
    // Get the fruit for this state
    final stateFruit = StateFruits.getStateFruit(state);
    
    // Ensure score is a number
    final int fruitScore;
    if (score is int) {
      fruitScore = score;
    } else if (score is double) {
      fruitScore = score.round();
    } else if (score is String) {
      fruitScore = int.tryParse(score) ?? 0;
    } else {
      fruitScore = 0;
    }
    
    if (mounted) {
      // Show the popup and wait for it to be dismissed
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation1, animation2) {
          return PopScope(
            canPop: false,
            child: _FruitRewardPopup(
              fruit: stateFruit,
              score: fruitScore,
              points: points,
              onDismiss: () {
                Navigator.pop(context);
                _navigateBackToDashboard();
              },
            ),
          );
        },
      );
    }
  }

  void _navigateBackToDashboard() {
    // Pop back to the dashboard
    Navigator.pop(context);
    
    // Force refresh of the dashboard
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        // This will trigger a rebuild of the dashboard
        setState(() {});
      }
    });
  }
}

class _FruitRewardPopup extends StatefulWidget {
  final StateFruit fruit;
  final int score;
  final int points;
  final VoidCallback? onDismiss;

  const _FruitRewardPopup({
    required this.fruit,
    required this.score,
    required this.points,
    this.onDismiss,
  });

  @override
  State<_FruitRewardPopup> createState() => _FruitRewardPopupState();
}

class _FruitRewardPopupState extends State<_FruitRewardPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FruitParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize particles immediately
    _initializeParticles();
    
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        if (widget.onDismiss != null) {
          widget.onDismiss!();
        }
      }
    });
  }

  void _initializeParticles() {
    // Create particles for the blast effect
    for (int i = 0; i < 40; i++) {
      // Calculate angle for circular explosion
      double angle = _random.nextDouble() * 2 * pi;
      
      _particles.add(_FruitParticle(
        emoji: widget.fruit.emoji,
        position: const Offset(0, 0), // Will be set in build
        velocity: Offset(
          cos(angle) * (5 + _random.nextDouble() * 5),
          sin(angle) * (5 + _random.nextDouble() * 5),
        ),
        size: 20 + _random.nextDouble() * 10, // Smaller size to avoid overflow
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        opacity: 1.0,
      ));
    }
    
    // Start animation
    _animateParticles();
  }

  void _animateParticles() {
    if (!mounted) return;
    
    setState(() {
      for (var particle in _particles) {
        // Add gravity effect
        particle.velocity += const Offset(0, 0.1);
        
        // Update position
        particle.position += particle.velocity;
        
        // Update rotation
        particle.rotation += particle.rotationSpeed;
        
        // Slow down particles with air resistance
        particle.velocity = particle.velocity * 0.98;
        
        // Fade out particles
        particle.opacity = (particle.opacity - 0.008).clamp(0.0, 1.0);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 16), _animateParticles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    // Set initial position for particles if not set
    for (var particle in _particles) {
      if (particle.position == const Offset(0, 0)) {
        particle.position = Offset(centerX, centerY);
      }
    }
    
    return Stack(
      children: [
        // Use CustomPaint for particles to avoid overflow issues
        SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: CustomPaint(
            painter: _FruitParticlePainter(_particles),
          ),
        ),

        // Popup content
        Center(
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.purple.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated fruit emoji
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + 0.1 * sin(_controller.value * 2 * pi),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.fruit.emoji,
                          style: const TextStyle(
                            fontSize: 50,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Congratulations text
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      final currentLanguage = languageProvider.currentLanguage;
                      String congratsText = 'Congratulations!';
                      String pointsText = 'points';
                      String addedText = 'added to your account!';
                      
                      switch (currentLanguage) {
                        case 'hi':
                          congratsText = 'बधाई हो!';
                          pointsText = 'अंक';
                          addedText = 'आपके खाते में जोड़े गए!';
                          break;
                        case 'te':
                          congratsText = 'అభినందనలు!';
                          pointsText = 'పాయింట్లు';
                          addedText = 'మీ ఖాతాకు జోడించబడింది!';
                          break;
                        case 'ta':
                          congratsText = 'வாழ்த்துக்கள்!';
                          pointsText = 'புள்ளிகள்';
                          addedText = 'உங்கள் கணக்கில் சேர்க்கப்பட்டது!';
                          break;
                        case 'kn':
                          congratsText = 'ಅಭಿನಂದನೆಗಳು!';
                          pointsText = 'ಅಂಕಗಳು';
                          addedText = 'ನಿಮ್ಮ ಖಾತೆಗೆ ಸೇರಿಸಲಾಗಿದೆ!';
                          break;
                      }
                      
                      return Column(
                        children: [
                          Text(
                            congratsText,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    Colors.purple.shade700,
                                    Colors.blue.shade500,
                                  ],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${widget.points} $pointsText',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            addedText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for fruit particles to avoid overflow issues
class _FruitParticlePainter extends CustomPainter {
  final List<_FruitParticle> particles;
  
  _FruitParticlePainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (var particle in particles) {
      // Skip particles with very low opacity
      if (particle.opacity < 0.05) continue;
      
      // Skip particles that are too far off screen
      if (particle.position.dx < -50 || 
          particle.position.dx > size.width + 50 ||
          particle.position.dy < -50 || 
          particle.position.dy > size.height + 50) {
        continue;
      }
      
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      // Apply opacity
      final paint = Paint()..color = Colors.white.withOpacity(particle.opacity);
      
      // Draw the emoji
      textPainter.text = TextSpan(
        text: particle.emoji,
        style: TextStyle(
          fontSize: particle.size,
          height: 1.0,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper class for fruit particles
class _FruitParticle {
  String emoji;
  Offset position;
  Offset velocity;
  double size;
  double rotation;
  double rotationSpeed;
  double opacity;

  _FruitParticle({
    required this.emoji,
    required this.position,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
  });}
