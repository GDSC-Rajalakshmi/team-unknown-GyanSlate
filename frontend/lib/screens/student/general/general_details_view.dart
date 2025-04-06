import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'general_explanation_player_screen.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' show Random;
import 'package:http/http.dart' as http;
import '../../../providers/language_provider.dart';
import '../../../services/translation_loader_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:shared_preferences/shared_preferences.dart';


class QuestionDetailsView extends StatefulWidget {
  final String? selectedImagePath;
  final AssetEntity? selectedAsset;
  final Map<String, dynamic> selectedQuestionDetails;
  final bool isLoadingQuestionDetails;
  final File? attachedImage;
  final String? userInputText;
  final Function(int points)? onPointsEarned;

  const QuestionDetailsView({
    Key? key,
    this.selectedImagePath,
    this.selectedAsset,
    required this.selectedQuestionDetails,
    required this.isLoadingQuestionDetails,
    this.attachedImage,
    this.userInputText,
    this.onPointsEarned,
  }) : super(key: key);

  @override
  _QuestionDetailsViewState createState() => _QuestionDetailsViewState();
}

class _QuestionDetailsViewState extends State<QuestionDetailsView> {
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _allImages = [];
  
  // Track selected options for each MCQ
  Map<int, int?> _selectedOptions = {};
  PageController _pageController = PageController();
  bool _showPointsPopup = false;
  bool _isPopupFading = false;
  int _totalPoints = 0; // Total points earned
  
  FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  final translator = GoogleTranslator();
  
  // Generate static content based on user input
  Map<String, dynamic> generateStaticContent(String userInput) {
    // Default content if no specific topic is detected
    Map<String, dynamic> content = {
      'question': {
        'id': '126',
        'text': userInput.isEmpty ? 'General question about the attached image' : userInput
      },
      'solution': 'Based on your question, here is a concise answer that addresses the key points.',
      'solution_explanation': 'Your question touches on an important concept in this field. To fully understand this topic, we need to examine several key principles and how they interact.\n\nThe fundamental idea here is that complex systems often follow predictable patterns when we understand the underlying mechanisms. By breaking down the problem into smaller components, we can analyze each part and then synthesize a comprehensive understanding.\n\nThis approach allows us to not only answer the specific question but also develop a framework for addressing similar questions in the future. The methodology involves careful observation, application of established principles, and logical reasoning to reach a valid conclusion.',
      'steps': [
        'Identify the core concepts relevant to the question',
        'Apply fundamental principles to analyze the problem',
        'Break down complex elements into manageable components',
        'Synthesize information to form a comprehensive understanding',
        'Verify the solution by testing it against known examples or cases'
      ],
      'mcqs': [
        {
          'question': 'What is the capital of France?',
          'options': ['Paris', 'London', 'Berlin', 'Madrid']
        },
        {
          'question': 'What is 2 + 2?',
          'options': ['3', '4', '5', '6']
        },
        // Add more MCQs as needed
      ]
    };
    
    // Check for specific topics and provide relevant content
    if (userInput.toLowerCase().contains("photosynthesis")) {
      content = {
        'question': {
          'id': '123',
          'text': 'Explain the process of photosynthesis and its importance in ecosystems.'
        },
        'solution': 'Photosynthesis is the process by which green plants, algae, and some bacteria convert light energy into chemical energy. The process uses carbon dioxide and water to produce glucose and oxygen.',
        'solution_explanation': 'Photosynthesis is one of the most important biological processes on Earth. It occurs in the chloroplasts of plant cells, specifically in the grana and stroma. The process can be divided into two main stages: the light-dependent reactions and the Calvin cycle (light-independent reactions).\n\nIn the light-dependent reactions, chlorophyll and other pigments in the thylakoid membranes capture light energy, which is used to split water molecules, releasing oxygen as a byproduct. This process also produces ATP and NADPH, which are energy carriers.\n\nIn the Calvin cycle, the ATP and NADPH from the light-dependent reactions are used to convert carbon dioxide into glucose. This occurs in the stroma of the chloroplast and doesn\'t directly require light, though it depends on the products of the light-dependent reactions.',
        'steps': [
          'Light energy is absorbed by chlorophyll in the thylakoid membranes',
          'Water molecules are split, releasing oxygen (photolysis)',
          'ATP and NADPH are produced as energy carriers',
          'Carbon dioxide is fixed in the Calvin cycle using the energy from ATP and NADPH',
          'Glucose is synthesized as the end product',
          'Oxygen is released as a byproduct, which is essential for aerobic organisms'
        ]
      };
    } 
    else if (userInput.toLowerCase().contains("quadratic")) {
      content = {
        'question': {
          'id': '124',
          'text': 'How do you solve a quadratic equation using the quadratic formula?'
        },
        'solution': 'For a quadratic equation in the form ax² + bx + c = 0, the solutions are given by the quadratic formula: x = (-b ± √(b² - 4ac)) / 2a',
        'solution_explanation': 'The quadratic formula is a reliable method for solving any quadratic equation. For an equation in the standard form ax² + bx + c = 0, where a, b, and c are coefficients and a ≠ 0, the formula gives us the two possible values of x.\n\nThe discriminant (b² - 4ac) tells us about the nature of the roots:\n• If b² - 4ac > 0, there are two distinct real roots\n• If b² - 4ac = 0, there is exactly one real root (a repeated root)\n• If b² - 4ac < 0, there are two complex conjugate roots\n\nThe quadratic formula is derived by completing the square for the general form of a quadratic equation.',
        'steps': [
          'Identify the coefficients a, b, and c from the standard form ax² + bx + c = 0',
          'Calculate the discriminant: b² - 4ac',
          'Substitute the values into the quadratic formula: x = (-b ± √(b² - 4ac)) / 2a',
          'Simplify the expression to find the two values of x',
          'Check your answers by substituting them back into the original equation'
        ]
      };
    }
    else if (userInput.toLowerCase().contains("newton") || userInput.toLowerCase().contains("law") || userInput.toLowerCase().contains("motion")) {
      content = {
        'question': {
          'id': '125',
          'text': 'What are Newton\'s three laws of motion and how do they apply to everyday situations?'
        },
        'solution': 'Newton\'s three laws of motion are: 1) An object at rest stays at rest, and an object in motion stays in motion unless acted upon by an external force. 2) Force equals mass times acceleration (F = ma). 3) For every action, there is an equal and opposite reaction.',
        'solution_explanation': 'Sir Isaac Newton\'s three laws of motion, published in 1687, form the foundation of classical mechanics and explain how objects move in response to forces.\n\nThe first law, also known as the law of inertia, states that an object will maintain its state of rest or uniform motion in a straight line unless acted upon by an external force. This explains why we need seatbelts in cars - when a car stops suddenly, our bodies tend to continue moving forward due to inertia.\n\nThe second law quantifies the relationship between force, mass, and acceleration. It states that the acceleration of an object is directly proportional to the net force applied and inversely proportional to its mass. This is expressed mathematically as F = ma. This explains why it\'s harder to push a heavy shopping cart than a lighter one.\n\nThe third law states that for every action, there is an equal and opposite reaction. When you push against a wall, the wall pushes back with equal force. This principle is what allows rockets to propel forward - they expel gas backward, and the equal and opposite reaction propels the rocket forward.',
        'steps': [
          'First Law (Inertia): Objects resist changes in their state of motion',
          'Second Law (F = ma): The acceleration of an object depends on the force applied and its mass',
          'Third Law (Action-Reaction): Forces always occur in pairs of equal magnitude and opposite direction',
          'These laws apply to all macroscopic objects under normal conditions',
          'They form the foundation of classical mechanics and engineering principles'
        ]
      };
    }
    
    return content;
  }

  @override
  void initState() {
    super.initState();
    // Initialize _allImages with empty list if null
    _allImages = [];
    _processImages();
    _initTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuestionDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedQuestionDetails != oldWidget.selectedQuestionDetails) {
      setState(() {
        _selectedOptions.clear();
        _totalPoints = 0;
      });
    }
  }

  void _processImages() {
    _allImages = [];
    
    try {
      // Add null checks for selectedQuestionDetails
      if (widget.selectedQuestionDetails != null && 
          widget.selectedQuestionDetails.containsKey('images') && 
          widget.selectedQuestionDetails['images'] != null) {
        
        final imagesData = widget.selectedQuestionDetails['images'] as List<dynamic>;
        
        for (var imageItem in imagesData) {
          if (imageItem is Map<String, dynamic>) {
            imageItem.forEach((subtopic, imageData) {
              if (imageData != null) {
                _allImages.add({
                  'subtopic': subtopic,
                  'image': imageData,
                });
              }
            });
          } else if (imageItem is String) {
            // Handle case where image is directly a string URL
            _allImages.add({
              'subtopic': 'General',
              'image': imageItem,
            });
          }
        }
      }
    } catch (e) {
      print('Error processing images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show loading state
    if (widget.isLoadingQuestionDetails) {
      return _buildLoadingState();
    }
    
    // Check if we have any question details to display
    if (widget.selectedQuestionDetails.isNotEmpty) {
      print("Displaying question details from API");
      return _buildQuestionDetails(widget.selectedQuestionDetails);
    }
    
    // If we have an image but no other content, show image-only view
    if (widget.selectedImagePath != null || 
        widget.selectedAsset != null || 
        widget.attachedImage != null) {
      return _buildImageOnlyView();
    }
    
    // Fallback to empty state
    return _buildEmptyState();
  }

  Widget _buildQuestionDetails(Map<String, dynamic> details) {
    // Add null checks for accessing details
    final questionText = details['question']?['text'] ?? 
                        _getTranslatedText('general.doubt.details.fallback.no_question');
    final solutionText = details['response'] ?? 
                        details['solution_explanation'] ?? 
                        details['solution'] ?? 
                        _getTranslatedText('general.doubt.details.fallback.no_explanation');

    return Container(
      color: Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question section without listen button
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90E2),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.question_mark_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getTranslatedText('general.doubt.details.sections.question'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      questionText,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Visual section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image,
                        color: Color(0xFF4A90E2),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTranslatedText('general.doubt.details.sections.visual'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(details),
                ),
                SizedBox(height: 24),
              ],
            ),

            // Solution section with improved listen button
            Container(
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90E2),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getTranslatedText('general.doubt.details.sections.solution'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Improved Listen button
                        ElevatedButton.icon(
                          onPressed: () {
                            print("Listen button pressed");
                            _speakSolution(solutionText);
                          },
                          icon: Icon(
                            isSpeaking ? Icons.stop_circle : Icons.play_circle_fill,
                            size: 24,
                          ),
                          label: Text(
                            isSpeaking ? 'Stop' : 'Listen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF4A90E2),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: _buildFormattedText(solutionText),
                  ),
                ],
              ),
            ),

            // MCQs section
            if (details.containsKey('mcqs') && details['mcqs'] != null && details['mcqs'] is List && (details['mcqs'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: Color(0xFF4A90E2),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getTranslatedText('general.doubt.details.sections.mcq.title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: (details['mcqs'] as List).length,
                      itemBuilder: (context, index) {
                        var mcq = details['mcqs'][index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mcq['question'] ?? 
                              _getTranslatedText('general.doubt.details.fallback.no_mcq'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: (mcq['options'] as List).length,
                                itemBuilder: (context, optionIndex) {
                                  String option = mcq['options'][optionIndex];
                                  bool isCorrect = mcq['correct_option'] == option;
                                  bool isSelected = _selectedOptions[index] == optionIndex;
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                                          : Color(0xFFF8FAFB),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
                                            : Color(0xFFE0E0E0),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: RadioListTile<int>(
                                      title: Text(
                                        option,
                                        style: TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 15,
                                        ),
                                      ),
                                      value: optionIndex,
                                      groupValue: _selectedOptions[index],
                                      onChanged: _selectedOptions[index] != null ? null : (value) async {
                                        setState(() {
                                          _selectedOptions[index] = value;
                                        });
                                        
                                        Future.delayed(Duration(milliseconds: 500), () async {
                                          if (index < (details['mcqs'] as List).length - 1) {
                                            _pageController.nextPage(
                                              duration: Duration(milliseconds: 300),
                                              curve: Curves.easeIn,
                                            );
                                          } else {
                                            // Calculate points based on correct answers
                                            int earnedPoints = 0;
                                            for (int i = 0; i < (details['mcqs'] as List).length; i++) {
                                              var mcq = details['mcqs'][i];
                                              if (_selectedOptions[i] != null && 
                                                  mcq['options'][_selectedOptions[i]] == mcq['correct_option']) {
                                                // Generate random points between 10 and 30 for each correct answer
                                                earnedPoints += 10 + Random().nextInt(21);
                                              }
                                            }
                                            
                                            // Show popup immediately
                                            setState(() {
                                              _showPointsPopup = true;
                                              _totalPoints = earnedPoints;
                                            });
                                            
                                            // Call onPointsEarned callback
                                            widget.onPointsEarned?.call(earnedPoints);

                                            // Get the stored token
                                            final storage = const FlutterSecureStorage();
                                            final token = await storage.read(key: 'token');
                                            
                                            // Send score to backend
                                            try {
                                              final prefs = await SharedPreferences.getInstance();
                                              final rollNumString = prefs.getString('rollNumber') ?? '0';
                                              final classNumString = prefs.getString('class') ?? '10';
                                              final stateString = prefs.getString('state') ?? 'TN';
                                              
                                              // Convert strings to integers
                                              final rollNum = int.parse(rollNumString);
                                              final classNum = int.parse(classNumString);
                                            
                                              
                                              final response = await http.post(
                                                Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/update_score'),
                                                headers: {
                                                  'Content-Type': 'application/json',
                                                  'Authorization': 'Bearer $token',
                                                },
                                                body: json.encode({
                                                  'score': earnedPoints,
                                                  'roll_num': rollNum,
                                                  'class': classNum,
                                                  'state': stateString,
                                                  'timestamp': DateTime.now().toIso8601String(),
                                                }),
                                              );

                                              print('Score update response status: ${response.statusCode}');
                                              print('Score update response body: ${response.body}');

                                              if (response.statusCode != 200) {
                                                print('Error updating score on server: ${response.statusCode}');
                                                print('Response body: ${response.body}');
                                              }
                                            } catch (e) {
                                              print('Error sending score to server: $e');
                                            }
                                            
                                            // Hide popup after a few seconds
                                            Future.delayed(Duration(seconds: 3), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isPopupFading = true;
                                                });
                                                Future.delayed(Duration(milliseconds: 300), () {
                                                  if (mounted) {
                                                    setState(() {
                                                      _showPointsPopup = false;
                                                      _isPopupFading = false;
                                                    });
                                                  }
                                                });
                                              }
                                            });
                                          }
                                        });
                                      },
                                      activeColor: Color(0xFF4A90E2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),

            // Interactive explanation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExplanationPlayerScreen(
                        question: details['question'] != null && details['question'] is Map 
                            ? details['question']['text'] ?? 'No question available'
                            : 'No question available',
                        details: details,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.play_circle_outline, size: 20),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _getTranslatedText('general.doubt.details.buttons.talk_and_play'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
          ),
          SizedBox(height: 16),
          Text(
            _getTranslatedText('general.doubt.details.analyzing'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            _getTranslatedText('general.doubt.details.type_question'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _getTranslatedText('general.doubt.details.analyzing_image'),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _getTranslatedText('general.doubt.details.visual_content'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOnlyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _getTranslatedText('general.doubt.details.sections.visual'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildImageWidget(widget.selectedQuestionDetails),
                ),
              ],
            ),
          ),
          
          // Placeholder for content that will be generated
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Analyzing Image',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A11CB),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslatedText('general.doubt.details.analyzing_image'),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> details) {
    // Add null checks for all image sources
    if (details.containsKey('image') && details['image'] != null) {
      final imageUrl = details['image'] as String;
      return _buildNetworkImage(imageUrl);
    }
    
    if (details.containsKey('images') && 
        details['images'] != null && 
        details['images'] is List && 
        details['images'].isNotEmpty) {
      final firstImage = details['images'][0];
      if (firstImage is String) {
        return _buildNetworkImage(firstImage);
      }
    }
    
    if (widget.selectedImagePath != null) {
      return Image.file(
        File(widget.selectedImagePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    } else if (widget.selectedAsset != null) {
      return FutureBuilder<File?>(
        future: widget.selectedAsset!.file,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorWidget();
              },
            );
          }
          return _buildImageErrorWidget();
        },
      );
    } else if (widget.attachedImage != null) {
      return Image.file(
        widget.attachedImage!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
    
    // Default placeholder
    String userInput = '';
    if (details.containsKey('userInput') && details['userInput'] != null) {
      userInput = details['userInput'] as String;
    } else if (widget.userInputText != null && widget.userInputText!.isNotEmpty) {
      userInput = widget.userInputText!;
    }
    
    // Choose an appropriate placeholder based on the topic
    IconData topicIcon = Icons.school;
    Color iconColor = Colors.blue;
    
    if (userInput.toLowerCase().contains("math") || 
        userInput.toLowerCase().contains("algebra") ||
        userInput.toLowerCase().contains("calculus") ||
        userInput.toLowerCase().contains("equation")) {
      topicIcon = Icons.functions;
      iconColor = Colors.indigo;
    } else if (userInput.toLowerCase().contains("physics") ||
               userInput.toLowerCase().contains("force") ||
               userInput.toLowerCase().contains("motion")) {
      topicIcon = Icons.speed;
      iconColor = Colors.orange;
    } else if (userInput.toLowerCase().contains("chemistry") ||
               userInput.toLowerCase().contains("molecule") ||
               userInput.toLowerCase().contains("atom")) {
      topicIcon = Icons.science;
      iconColor = Colors.green;
    } else if (userInput.toLowerCase().contains("biology") ||
               userInput.toLowerCase().contains("cell") ||
               userInput.contains("organism")) {
      topicIcon = Icons.biotech;
      iconColor = Colors.teal;
    }
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              topicIcon,
              size: 80,
              color: iconColor.withOpacity(0.7),
            ),
            SizedBox(height: 16),
            Text(
              _getTranslatedText('general.doubt.details.visual_content'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build network image with error handling
  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
        ),
      ),
      errorWidget: (context, url, error) => _buildImageErrorWidget(),
      fit: BoxFit.contain,
      height: 250,
      width: double.infinity,
    );
  }

  // Helper method for image error widget
  Widget _buildImageErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: Colors.red, size: 40),
          SizedBox(height: 8),
          Text('Failed to load image'),
        ],
      ),
    );
  }

  String _getTranslatedText(String key) {
    return TranslationLoaderService().getTranslation(
      key,
      Provider.of<LanguageProvider>(context).currentLanguage
    );
  }

  Future<void> _initTts() async {
    try {
      // Get current locale/language
      final currentLocale = Localizations.localeOf(context).languageCode;
      
      // Map language codes to TTS language codes
      final languageMap = {
        'en': 'en-US',
        'ta': 'ta-IN',
        'hi': 'hi-IN',
        'te': 'te-IN'
      };

      // Set language based on current locale
      final ttsLanguage = languageMap[currentLocale] ?? 'en-US';
      await flutterTts.setLanguage(ttsLanguage);
      
      // Configure TTS settings
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      // Check if language is supported
      final available = await flutterTts.isLanguageAvailable(ttsLanguage);
      if (!available) {
        print("Language $ttsLanguage not available, falling back to en-US");
        await flutterTts.setLanguage("en-US");
      }

      // Get available engines (Android only)
      if (Platform.isAndroid) {
        final engines = await flutterTts.getEngines;
        print("Available TTS engines: $engines");
        
        // Prefer Google engine if available
        if (engines.contains('com.google.android.tts')) {
          await flutterTts.setEngine('com.google.android.tts');
        }
      }
    } catch (e) {
      print("TTS initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize text to speech: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _speakSolution(String text) async {
    try {
      if (isSpeaking) {
        print("Stopping current speech");
        await flutterTts.stop();
        setState(() {
          isSpeaking = false;
        });
        return;
      }

      print("Starting to speak: $text");
      setState(() {
        isSpeaking = true;
      });

      var result = await flutterTts.speak(text);
      print("Speak result: $result");

      // Add completion handler
      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            isSpeaking = false;
          });
        }
      });

    } catch (e) {
      print("Error in _speakSolution: $e");
      setState(() {
        isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFormattedText(String text) {
    List<Widget> widgets = [];
    List<String> paragraphs = text.split('\n\n');
    
    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      List<String> lines = paragraph.split('\n');
      for (String line in lines) {
        if (line.trim().isEmpty) continue;

        // Headers (like "Using interpolation:")
        if (line.trim().endsWith(':')) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                line.trim(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          );
        }
        // Mathematical formulas
        else if (_isMathExpression(line.trim())) {
          final parts = _splitMathExpression(line.trim());
          widgets.add(
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE9ECEF)),
              ),
              child: Wrap(
                children: parts.map((part) {
                  return Container(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      part,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }
        // Variable definitions
        else if (_isVariableDefinition(line.trim())) {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                line.trim(),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          );
        }
        // Regular text with possible bold sections
        else {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: _buildRichText(line.trim()),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<String> _splitMathExpression(String expression) {
    // Split the expression into parts that can be wrapped
    List<String> parts = [];
    
    // Handle Q1 and Q3 formulas
    if (expression.contains('Q1') || expression.contains('Q3')) {
      // Split by operators while keeping them
      var matches = RegExp(r'(Q[13])|([=+\-×÷\[\]()])|([0-9.]+)|([a-zA-Z]+)')
          .allMatches(expression);
      
      for (var match in matches) {
        String part = match.group(0)!;
        // Add appropriate spacing around operators
        if (RegExp(r'[=+\-×÷\[\]()]').hasMatch(part)) {
          parts.add(' $part ');
        } else {
          parts.add(part);
        }
      }
    } else {
      // Handle other mathematical expressions
      var matches = RegExp(r'([=+\-×÷\[\]()])|([0-9.]+)|([a-zA-Z]+)')
          .allMatches(expression);
      
      for (var match in matches) {
        String part = match.group(0)!;
        if (RegExp(r'[=+\-×÷\[\]()]').hasMatch(part)) {
          parts.add(' $part ');
        } else {
          parts.add(part);
        }
      }
    }
    
    return parts.map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  }

  bool _isMathExpression(String text) {
    String normalized = text.toLowerCase().trim();
    return normalized.startsWith('q1 =') ||
           normalized.startsWith('q3 =') ||
           (normalized.contains('=') && 
            (normalized.contains('[') || 
             normalized.contains('(') ||
             normalized.contains('/') ||
             normalized.contains('×') ||
             normalized.contains('÷')));
  }

  bool _isVariableDefinition(String text) {
    String normalized = text.toLowerCase().trim();
    return normalized.startsWith('l =') ||
           normalized.startsWith('cf =') ||
           normalized.startsWith('f =') ||
           normalized.startsWith('h =');
  }

  Widget _buildRichText(String text) {
    List<TextSpan> spans = [];
    List<String> parts = text.split('*');
    bool isBold = false;

    for (String part in parts) {
      if (part.isNotEmpty) {
        spans.add(TextSpan(
          text: part,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF2C3E50),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ));
      }
      isBold = !isBold;
    }

    return RichText(text: TextSpan(children: spans));
  }
}