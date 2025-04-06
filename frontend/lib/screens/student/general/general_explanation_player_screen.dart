import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import 'package:flutter/material.dart' as flutter;
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/translation_loader_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExplanationPlayerScreen extends StatefulWidget {
  final String question;
  final Map<String, dynamic> details;

  const ExplanationPlayerScreen({
    Key? key,
    required this.question,
    required this.details,
  }) : super(key: key);

  @override
  State<ExplanationPlayerScreen> createState() => _ExplanationPlayerScreenState();
}

class _ExplanationPlayerScreenState extends State<ExplanationPlayerScreen> with SingleTickerProviderStateMixin {
  StateMachineController? _stateMachineController;
  SMIBool? _checkInput;
  SMINumber? _lookInput;
  SMIBool? _handsUpInput;
  SMITrigger? _successInput;
  SMITrigger? _failInput;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  bool _isControllerInitialized = false;
  bool _isLoading = true;
  Timer? _restartTimer;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  Color _currentOverlayColor = Colors.transparent;
  late ConfettiController _confettiController;
  bool _showPointsPopup = false;
  int _pointsEarned = 0;
  bool _isPopupFading = false;
  bool _showFailurePopup = false;
  bool _isFailurePopupFading = false;
  String _animationMessage = "";
  bool _showAnimationMessage = false;
  int _speakingPoints = 0; // Changed from 100 to 0
  DateTime? _startListeningTime;
  late Timer _pageTimer;
  int _remainingSeconds = 300; // 5 minutes in seconds
  bool _isTimerExpired = false;
  Timer? _progressTimer;
  int _currentProgress = 0;
  
  final Map<String, List<String>> expectedResponsesByLanguage = {
    'en': ['welcome', 'hello', 'hi', 'greetings'],
    'ta': ['வணக்கம்', 'நல்வரவு', 'வாருங்கள்'],
    'hi': ['स्वागत', 'नमस्ते', 'हैलो', 'प्रणाम'],
    'te': ['స్వాగతం', 'నమస్కారం', 'హలో', 'సుస్వాగతం']
  };
  
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializePageTimer();
    
    // Initialize confetti controller with 4 second duration
    _confettiController = ConfettiController(duration: Duration(seconds: 4));
    
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeSpeech() {
    _speech = stt.SpeechToText();
    _initializeSpeechAsync();
  }

  Future<void> _initializeSpeechAsync() async {
    bool available = await _speech.initialize();
    if (mounted) {
      setState(() {
        if (!available) {
          _transcription = 'Speech recognition not available';
        }
      });
    }
  }

  void _onRiveInit(Artboard artboard) {
    print('Rive Init Called');
    try {
      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller == null) {
        print('Failed to create controller');
        setState(() => _isLoading = false);
        return;
      }

      artboard.addController(controller);
      _stateMachineController = controller;

      // Find inputs with correct names from Rive file
      _checkInput = controller.findInput<bool>('Check') as SMIBool?;
      _lookInput = controller.findInput<double>('Look') as SMINumber?;
      _handsUpInput = controller.findInput<bool>('hands_up') as SMIBool?;
      _successInput = controller.findInput<bool>('success') as SMITrigger?;
      _failInput = controller.findInput<bool>('fail') as SMITrigger?;

      // Set initial idle state
      _checkInput?.value = true;  // Start with Check true for idle
      _lookInput?.value = 0;      // Center look
      _handsUpInput?.value = false;

      setState(() {
        _isControllerInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Rive animation: $e');
      setState(() => _isLoading = false);
    }
  }

  void _initializePageTimer() {
    _pageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _isTimerExpired = true;
            _pageTimer.cancel();
            _handleTimerExpired();
          }
        });
      }
    });
  }

  void _handleTimerExpired() async {
    // Stop listening if active
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    // Send final data to API with timeout flag
    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // Get the stored token
      final token = await storage.read(key: 'token');

      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? '';
      final classNum = int.tryParse(prefs.getString('class') ?? '') ?? 0;
      final rollNum = int.tryParse(prefs.getString('rollNumber') ?? '') ?? 0;


      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/student/expl'),
        headers: {'Content-Type': 'application/json',
         'Authorization': 'Bearer $token',},
        body: jsonEncode({
          'access': accessToken,
          'timeout': true,
        }),
      );

      // // Log the response details
      // print('API Response Status Code: ${response.statusCode}');
      // print('API Response Headers: ${response.headers}');
      // print('API Response Body timeout: ${response.body}');

      // Try to parse and log JSON response if available
      try {
        final decodedResponse = json.decode(response.body);
        print('Decoded Response: $decodedResponse');
      } catch (e) {
        print('Error decoding response: $e');
      }

      // Navigate back regardless of API response
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error sending timeout data: $e');
      // Navigate back even if API call fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startListening() async {
    final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final Map<String, String> languageToLocale = {
      'en': 'en-US',  // Changed format to match speech_to_text requirements
      'ta': 'ta-IN',
      'hi': 'hi-IN',
      'te': 'te-IN'
    };
    final localeId = languageToLocale[currentLang] ?? 'en-US';

    if (!_speech.isListening) {
      try {
        print('Starting speech recognition in locale: $localeId');
        await _speech.listen(
          onResult: (result) {
            setState(() {
              if (result.finalResult) {
                if (result.recognizedWords.isNotEmpty) {
                  if (_transcription.isEmpty) {
                    _transcription = result.recognizedWords;
                  } else {
                    _transcription = _transcription + ' ' + result.recognizedWords;
                  }
                }
                print('Recognized in ${currentLang}: $_transcription');
              }
            });
          },
          listenFor: Duration(seconds: 30),
          localeId: localeId,
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        print('Error in speech recognition: $e');
      }
    }
  }

  Future<void> _listen() async {
    try {
      if (!_isListening) {
        _startListeningTime = DateTime.now();
        
        final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        
        bool available = await _speech.initialize(
          onError: (error) => print('Speech recognition error: $error'),
          onStatus: (status) => print('Speech status: $status'),
        );

        if (available) {
          setState(() {
            _isListening = true;
            if (_isControllerInitialized) {
              _checkInput?.value = false;
              _lookInput?.value = -100;
              _handsUpInput?.value = false;
              _successInput?.value = false;
              _failInput?.value = false;
            }
          });

          await _startListening();

          _restartTimer?.cancel();
          _restartTimer = Timer.periodic(Duration(milliseconds: 50), (timer) async {
            if (_isListening && !_speech.isListening) {
              await _startListening();
            }
          });
        }
      } else {
        // Stopping recording
        setState(() {
          _isListening = false;
        });
        _restartTimer?.cancel();
        await _speech.stop();

        // Calculate duration in seconds
        final duration = _startListeningTime != null 
            ? DateTime.now().difference(_startListeningTime!).inSeconds 
            : 0;

        // Send data to API
        try {
          // Get required data
        final storage = const FlutterSecureStorage();
        final accessToken = await storage.read(key: 'access_token');
        
      // Get the stored token
      final token = await storage.read(key: 'token');

        final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        
        // Get stored values from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final state = prefs.getString('state') ?? '';
        // Convert class and roll number to integers
        final classNum = int.tryParse(prefs.getString('class') ?? '') ?? 0;
        final rollNum = int.tryParse(prefs.getString('rollNumber') ?? '') ?? 0;

          final response = await http.post(
            Uri.parse('http://192.168.255.209:5000/student/expl'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'access': accessToken,
              'expl': _transcription,
              'lng': currentLang,
              'question': widget.question,
              'state': state,
              'class': classNum,
              'roll_num': rollNum,
              'timeout': false,
              'duration': duration,
            }),
          );

          // Check for status code 402
          if (response.statusCode == 402) {
            // Display a popup indicating the attempt is over
            _showAttemptOverPopup();
          } else if (response.statusCode == 200) {
            try {
              final decodedResponse = json.decode(response.body);
              print('Decoded Response: $decodedResponse');
              
              final int newScore = decodedResponse['score'] ?? _speakingPoints;
              final bool isWin = decodedResponse['is_win'] ?? false;
              final int newPoints = decodedResponse['new_points'] ?? 10;
              
              // Start progress bar animation
              _animateProgressBar(newScore);
              
              // Wait for progress bar animation to complete before showing popup
              Future.delayed(Duration(milliseconds: (newScore - _speakingPoints).abs() * 50), () {
                if (mounted) {
                  setState(() {
                    _pointsEarned = newPoints;  // Set the points earned from API
                  });
                  
                  if (isWin) {
                    _showSuccessAnimation();
                  } else {
                    _showFailAnimation();
                  }
                }
              });
              
            } catch (e) {
              print('Error decoding response: $e');
              _showFailAnimation();
            }
          } else {
            print('Failed to send explanation: ${response.statusCode}');
            print('Error Response Body: ${response.body}');
            _showFailAnimation();
          }
        } catch (e) {
          print('Error sending explanation to API: $e');
          _showFailAnimation();
        }

        // Existing animation logic
        if (_isControllerInitialized) {
          _lookInput?.value = 0;
          _handsUpInput?.value = false;
          
          // Animation based on API response can be handled in the try-catch block above
          
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _checkInput?.value = true;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error in _listen: $e');
      setState(() => _isListening = false);
      _restartTimer?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('general.doubt.explanation_player.errors.speech_recognition')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorOverlay(bool isSuccess) {
    setState(() {
      _currentOverlayColor = isSuccess 
          ? Color(0xFF4CAF50)  // Solid green
          : Color(0xFFFF5252); // Solid red
    });

    // Auto-hide the overlay after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentOverlayColor = Colors.transparent;
        });
      }
    });
  }

  void _showSuccessAnimation() {
    _showColorOverlay(true);
    _confettiController.play();
    
    // Show success message with the animation
    setState(() {
      _animationMessage = "Great explanation!";
      _showAnimationMessage = true;
      _showPointsPopup = true;
      _isPopupFading = false;
    });
    
    // Start fading out popup after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPopupFading = true;
        });
      }
    });
    
    // Hide popup and message after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showPointsPopup = false;
          _isPopupFading = false;
          _showAnimationMessage = false;
        });
      }
    });
  }

  void _showFailAnimation() {
    _showColorOverlay(false);
    
    // Show message with the animation
    setState(() {
      _animationMessage = "I don't understand. Can you explain differently?";
      _showAnimationMessage = true;
    });
    
    // Hide message after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showAnimationMessage = false;
        });
      }
    });
  }

  Color _getColorForPercentage(double percentage) {
    // Red for low percentages, yellow for middle, green for high
    if (percentage < 30) {
      return Colors.red.shade600;
    } else if (percentage < 70) {
      // Smoothly transition from red to yellow to green
      if (percentage < 50) {
        // Red to yellow (30-50%)
        double t = (percentage - 30) / 20;
        return Color.lerp(Colors.red.shade600, Colors.amber.shade600, t)!;
      } else {
        // Yellow to green (50-70%)
        double t = (percentage - 50) / 20;
        return Color.lerp(Colors.amber.shade600, Colors.green.shade600, t)!;
      }
    } else {
      return Colors.green.shade600;
    }
  }

  // Add translation helper method
  String _getTranslatedText(String key) {
    return TranslationLoaderService().getTranslation(
      key,
      Provider.of<LanguageProvider>(context).currentLanguage
    );
  }

  PreferredSize _buildTimerBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(2.0),
      child: LinearProgressIndicator(
        value: _remainingSeconds / 300, // Progress from 1.0 to 0.0
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          _remainingSeconds < 60 
              ? Colors.red 
              : _remainingSeconds < 120 
                  ? Colors.orange 
                  : Colors.green
        ),
      ),
    );
  }

  void _animateProgressBar(int targetScore) {
    // Cancel any existing timer
    _progressTimer?.cancel();
    
    // Start from current progress
    _currentProgress = _speakingPoints;
    
    _progressTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_currentProgress < targetScore) {
        setState(() {
          _currentProgress += 1;
          _speakingPoints = _currentProgress;
        });
      } else if (_currentProgress > targetScore) {
        setState(() {
          _currentProgress -= 1;
          _speakingPoints = _currentProgress;
        });
      } else {
        timer.cancel();
      }
    });
  }

    void _showAttemptOverPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getTranslatedText('general.doubt.attempt_over.title')),
          content: Text(_getTranslatedText('general.doubt.attempt_over.message')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(_getTranslatedText('general.doubt.attempt_over.ok')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD5E2EA),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_getTranslatedText('general.doubt.explanation_player.title')),
            Text(
              '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _remainingSeconds < 60 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: _buildTimerBar(),
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Points bar
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$_speakingPoints% ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getColorForPercentage(_speakingPoints.toDouble()),
                                      ),
                                    ),
                                    TextSpan(
                                      text: _getTranslatedText('general.doubt.explanation_player.messages.have_understood'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.psychology,
                                color: _getColorForPercentage(_speakingPoints.toDouble()),
                                size: 24,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Stack(
                            children: [
                              // Background bar
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // Progress bar
                              Container(
                                height: 12,
                                width: MediaQuery.of(context).size.width * 
                                    (_speakingPoints / 100) * 0.9, // Adjust for padding
                                decoration: BoxDecoration(
                                  gradient: flutter.LinearGradient(
                                    colors: [
                                      _getColorForPercentage((_speakingPoints / 2).toDouble()),
                                      _getColorForPercentage(_speakingPoints.toDouble()),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getColorForPercentage(_speakingPoints.toDouble()).withOpacity(0.3),
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Animation with speech bubble
                    Container(
                      height: 300,
                      width: 300,
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Rive animation
                          RiveAnimation.asset(
                            'assets/animations/login_screen_character.riv',
                            onInit: _onRiveInit,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                          
                          // Speech bubble
                          if (_showAnimationMessage)
                            Positioned(
                              top: 40,
                              right: 20,
                              child: AnimatedOpacity(
                                opacity: _showAnimationMessage ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: 200,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _animationMessage,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _animationMessage.contains("Great") 
                                              ? Colors.green.shade700 
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // Triangle pointer for speech bubble
                                      Container(
                                        margin: EdgeInsets.only(top: 8),
                                        width: 0,
                                        height: 0,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(width: 10, color: Colors.transparent),
                                            bottom: BorderSide(width: 10, color: Colors.white),
                                            left: BorderSide(width: 10, color: Colors.transparent),
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
                    
                    // Rest of the content
                    SizedBox(height: 30),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _getTranslatedText('general.doubt.explanation_player.under'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _getTranslatedText('general.doubt.explanation_player.explanation_prompt'),
                        style: TextStyle(
                          fontSize: 16,  // Reduced from 18
                          fontWeight: FontWeight.w400,  // Lighter weight
                          color: Colors.deepPurple.shade600,
                          height: 1.4,  // Better line height for readability
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: _listen,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.red : Colors.deepPurple,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    if (_transcription.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _transcription,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Top left
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0.7,
              maxBlastForce: 40,
              minBlastForce: 20,
              emissionFrequency: 0.03, // Lower frequency for 4-second duration
              numberOfParticles: 4, // Fewer particles
              gravity: 0.7,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.greenAccent,
                Colors.lightGreen,
                Colors.lightGreenAccent,
                Colors.white,
              ],
              minimumSize: const Size(5, 5),
              maximumSize: const Size(10, 10),
            ),
          ),
          
          // Top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 40,
              minBlastForce: 20,
              emissionFrequency: 0.03, // Lower frequency for 4-second duration
              numberOfParticles: 4, // Fewer particles
              gravity: 0.7,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.greenAccent,
                Colors.lightGreen,
                Colors.lightGreenAccent,
                Colors.white,
              ],
              minimumSize: const Size(5, 5),
              maximumSize: const Size(10, 10),
            ),
          ),
          
          // Top right
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 2.4,
              maxBlastForce: 40,
              minBlastForce: 20,
              emissionFrequency: 0.03, // Lower frequency for 4-second duration
              numberOfParticles: 4, // Fewer particles
              gravity: 0.7,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.greenAccent,
                Colors.lightGreen,
                Colors.lightGreenAccent,
                Colors.white,
              ],
              minimumSize: const Size(5, 5),
              maximumSize: const Size(10, 10),
            ),
          ),
          
          // Points popup with fade-out effect
          if (_showPointsPopup)
            Center(
              child: AnimatedOpacity(
                opacity: _isPopupFading ? 0.0 : 1.0,
                duration: Duration(seconds: 1), // 1-second fade-out
                curve: Curves.easeOut,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white, // Changed to white background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎉 '),
                          Text(
                            _getTranslatedText('general.doubt.explanation_player.points.great_job'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(' 🎉'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        _getTranslatedText('general.doubt.explanation_player.points.earned'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨ '),
                          Text(
                            '+$_pointsEarned',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(' ✨'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getTranslatedText('general.doubt.explanation_player.points.points'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _getTranslatedText('general.doubt.explanation_player.points.keep_up'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Left overlay - ONLY when showing success/fail
          if (_currentOverlayColor != Colors.transparent)
            AnimatedContainer(
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              width: 2,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: _currentOverlayColor,
                boxShadow: [
                  BoxShadow(
                    color: _currentOverlayColor.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 20,
                    offset: Offset(5, 0),
                  ),
                ],
              ),
            ),
          
          // Right overlay - ONLY when showing success/fail
          if (_currentOverlayColor != Colors.transparent)
            Positioned(
              right: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: 2,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: _currentOverlayColor,
                  boxShadow: [
                    BoxShadow(
                      color: _currentOverlayColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 20,
                      offset: Offset(-5, 0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Make API call when leaving the page
    _sendTimeoutData();
    
    _confettiController.dispose();
    _colorAnimationController.dispose();
    _restartTimer?.cancel();
    _stateMachineController?.dispose();
    _speech.stop();
    _pageTimer.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendTimeoutData() async {
    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      
      // Get the stored token
      final token = await storage.read(key: 'token');
      
      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/student/expl'),
        headers: {'Content-Type': 'application/json',
         'Authorization': 'Bearer $token',
         },
        body: jsonEncode({
          'access': accessToken,
          'timeout': true,
        }),
      );

      // // Log the response details
      // print('API Response Status Code: ${response.statusCode}');
      // print('API Response Headers: ${response.headers}');
      // print('API Response Body timeout: ${response.body}');

      // Try to parse and log JSON response if available
      try {
        final decodedResponse = json.decode(response.body);
        print('Decoded Response: $decodedResponse');
      } catch (e) {
        print('Error decoding response: $e');
      }
    } catch (e) {
      print('Error sending timeout data: $e');
    }
  }
}
