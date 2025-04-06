import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart' as flutter;
import '../../../widgets/translated_text.dart';
import '../../../providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../../../services/translation_loader_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ExplanationPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> question;
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
  int _pointsEarned = 10;
  bool _isPopupFading = false;
  bool _showFailurePopup = false;
  bool _isFailurePopupFading = false;
  String _animationMessage = "";
  bool _showAnimationMessage = false;
  int _speakingPoints = 0; // Start with 0%
  int _displayedPoints = 0; // For animation
  Timer? _progressAnimationTimer;
  late Timer _pageTimer;
  int _remainingSeconds = 300; // 5 minutes = 300 seconds
  bool _isTimeUp = false;
  DateTime? _micStartTime;
  int _totalMicDurationSeconds = 0;
  Timer? _micDurationTimer;
  String _fetchedContent = ''; // Variable to hold the fetched content
  
  @override
  void initState() {
    super.initState();
    
    _initializeSpeech();
    _initializePageTimer();
    
    _confettiController = ConfettiController(duration: Duration(seconds: 4));
    
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fetchContent(); // Fetch content on initialization
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

  Future<void> _startListening() async {
    final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final Map<String, String> languageToLocale = {
      'en': 'en-US',
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
            print('Speech result: ${result.recognizedWords}'); // Debug log
            setState(() {
              if (result.finalResult) {
                if (result.recognizedWords.isNotEmpty) {
                  if (_transcription.isEmpty) {
                    _transcription = result.recognizedWords;
                  } else {
                    _transcription = '$_transcription ${result.recognizedWords}';
                  }
                  print('Updated transcription: $_transcription'); // Debug log
                }
              }
            });
          },
          listenFor: Duration(seconds: 30),
          localeId: localeId,
          partialResults: true,
          cancelOnError: false, // Changed to false to prevent early cancellation
          listenMode: stt.ListenMode.dictation, // Changed to dictation mode
        );
      } catch (e) {
        print('Error in speech recognition: $e');
      }
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
      if (_speakingPoints > 0) {
        _animationMessage = "I understand some parts. Can you explain more clearly?";
      } else {
        _animationMessage = "I don't understand. Can you explain differently?";
      }
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

  Future<void> _listen() async {
    try {
      if (!_isListening) {
        // Start mic duration tracking
        setState(() {
          _micStartTime = DateTime.now();
          _totalMicDurationSeconds = 0;
        });
        
        // Start a timer to update duration every second
        _micDurationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (_micStartTime != null) {
            setState(() {
              _totalMicDurationSeconds = DateTime.now().difference(_micStartTime!).inSeconds;
            });
          }
        });

        final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        
        bool available = await _speech.initialize(
          onError: (error) => print('Speech recognition error: $error'),
          onStatus: (status) => print('Speech status: $status'),
        );

        if (available) {
          var locales = await _speech.locales();
          print('Available locales: ${locales.map((e) => '${e.localeId}: ${e.name}')}');

          setState(() {
            _isListening = true;
            _transcription = ''; // Clear transcription when starting new recording
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
              print('Restarting speech recognition...');
              await _startListening();
            }
          });
        } else {
          print('Speech recognition not available');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getTranslatedText('general.doubt.explanation_player.errors.speech_not_available')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Stop mic duration tracking
        _micDurationTimer?.cancel();
        final endTime = DateTime.now();
        if (_micStartTime != null) {
          _totalMicDurationSeconds = endTime.difference(_micStartTime!).inSeconds;
        }

        // Stopping recording
        setState(() {
          _isListening = false;
        });
        _restartTimer?.cancel();
        await _speech.stop();

        if (_isControllerInitialized && _transcription.isNotEmpty) {
          print('Processing transcription: $_transcription');
          print('Total mic duration: $_totalMicDurationSeconds seconds');
          _lookInput?.value = 0;
          _handsUpInput?.value = false;
          
          // Submit to backend for processing
          await _submitExplanation();
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
  
  Future<void> _submitExplanation() async {
    if (_transcription.isEmpty) {
      print('No transcription to submit');
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('Submitting explanation: $_transcription');
      print('Mic duration: $_totalMicDurationSeconds ');
      
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      print('currentLang: $currentLang');
      // Get values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? '';
      final className = prefs.getString('class') ?? '';
      final rollNum = prefs.getString('rollNumber') ?? '';

      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      // Get the access token directly from secure storage
      String? accessToken = await storage.read(key: 'question_access');
      print('Retrieved access token: $accessToken');
      // Make sure we have an access token
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/expl'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the token to headers
        },
        body: jsonEncode({
          'access': accessToken, // Use the stored access token
          'expl': _transcription,
          // 'questionId': widget.question['id'],
          'lng': currentLang,
          'question': widget.question['text'],
          'state': state,
          'class': className,
          'roll_num': rollNum,
          'timeout': false,
          'duration': _totalMicDurationSeconds,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int score = data['score'] ?? 0;
        final bool isWin = data['is_win'] ?? false;
        final int newPoints = data['new_points'] ?? 0;
        
        print('Received score: $score, isWin: $isWin, newPoints: $newPoints');
        
        setState(() {
          _speakingPoints = score;
          _animationMessage = isWin 
              ? "Great explanation!" 
              : (_speakingPoints > 0 
                  ? "I understand some parts. Can you explain more clearly?" 
                  : "I don't understand. Can you explain differently?");
          _pointsEarned = newPoints;
        });
        
        await _animateProgressBar();
        
        if (isWin) {
          _successInput?.fire();
          _showSuccessAnimation();
        } else {
          _failInput?.fire();
          _showFailAnimation();
        }
        
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _checkInput?.value = true;
              _isLoading = false;
            });
          }
        });
      } else if (response.statusCode == 402) {
        // New handling for 402 status code
        setState(() {
          _animationMessage = "Your attempt is over"; // Set the message for the popup
        });
        // Show the popup (you can customize this part as needed)
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Notice"),
              content: Text(_animationMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        print('Error response: ${response.statusCode} - ${response.body}'); // Debug log
        setState(() {
          _isLoading = false;
          _animationMessage = "Error processing explanation. Please try again.";
        });
        _showFailAnimation();
      }
    } catch (e) {
      print('Exception in _submitExplanation: $e'); // Debug log
      setState(() {
        _isLoading = false;
        _animationMessage = "Connection error. Please try again.";
      });
      _showFailAnimation();
    }
  }

  Future<void> _animateProgressBar() async {
    // Create a completer to make this function awaitable
    Completer<void> completer = Completer<void>();
    
    // Cancel any existing animation
    _progressAnimationTimer?.cancel();
    
    // Start from current displayed value
    int startValue = _displayedPoints;
    int endValue = _speakingPoints;
    int difference = (endValue - startValue).abs();
    
    // If no change, complete immediately
    if (difference == 0) {
      completer.complete();
      return completer.future;
    }
    
    // Calculate animation duration based on difference
    // Larger differences take longer to animate
    int durationMs = 1000 + (difference * 20); // Base 1s + 20ms per point
    durationMs = durationMs.clamp(1000, 3000); // Between 1-3 seconds
    
    // Calculate step size and interval
    int steps = 20; // Number of animation steps
    int stepValue = (endValue - startValue) ~/ steps;
    int intervalMs = durationMs ~/ steps;
    
    // Handle case where difference is too small for integer division
    if (stepValue == 0 && startValue != endValue) {
      stepValue = endValue > startValue ? 1 : -1;
    }
    
    _progressAnimationTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if ((stepValue > 0 && _displayedPoints >= endValue) || 
          (stepValue < 0 && _displayedPoints <= endValue) ||
          startValue == endValue) {
        // Animation complete
        setState(() {
          _displayedPoints = endValue;
        });
        timer.cancel();
        completer.complete(); // Complete the future when animation is done
      } else {
        // Update displayed value
        setState(() {
          _displayedPoints += stepValue;
          // Ensure we don't overshoot
          if ((stepValue > 0 && _displayedPoints > endValue) || 
              (stepValue < 0 && _displayedPoints < endValue)) {
            _displayedPoints = endValue;
          }
        });
      }
    });
    
    return completer.future; // Return the future so we can await it
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

  String _getTranslatedText(String key) {
    try {
      final translationService = Provider.of<TranslationLoaderService>(context, listen: false);
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      return translationService.getTranslation(key, currentLang) ?? key;
    } catch (e) {
      print('Translation error for key $key: $e');
      return key;
    }
  }

  void _initializePageTimer() {
    _pageTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isTimeUp = true;
          _pageTimer.cancel();
          // Make API call before navigating back
          _handleTimeout();
        }
      });
    });
  }

  Future<void> _handleTimeout() async {
    await _handleExit(isTimeout: true);
    
    // Navigate back after timeout
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleExit({required bool isTimeout}) async {
    try {
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // Get values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? '';
      final className = prefs.getString('class') ?? '';
      final rollNum = prefs.getString('rollNumber') ?? '';

      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      final accessToken = await storage.read(key: 'question_access');
      
      print('Calling API on ${isTimeout ? "timeout" : "back navigation"}');

      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/expl'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'access': accessToken,
          'timeout': true,
        }),
      );

      print('Exit submission response: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error in exit submission: $e');
    }
  }

  String _formatTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchContent() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      // Get the access token directly from secure storage
      String? accessToken = await storage.read(key: 'question_access');
      
      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/what_to_expl'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the access token
        },
        body: jsonEncode({
          'access': accessToken, // Send the access token in the body
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fetchedContent = data['what_to_exp'] ?? 'No content available'; // Update fetched content
        });
      } else if (response.statusCode == 402) {
        setState(() {
          _animationMessage = "Your attempt is over"; // Set the message for the popup
        });
        // Show the popup (you can customize this part as needed)
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Notice"),
              content: Text(_animationMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        print('Error fetching content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in _fetchContent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Call the API before allowing navigation back
        await _handleExit(isTimeout: false);
        return true; // Allow the navigation
      },
      child: Scaffold(
        backgroundColor: Color(0xFFD5E2EA),
        appBar: AppBar(
          title: TranslatedText(
            'general.doubt.explanation_player.title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60 ? Colors.red.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 20,
                    color: _remainingSeconds < 60 ? Colors.red : Colors.deepPurple,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(),
                    style: TextStyle(
                      color: _remainingSeconds < 60 ? Colors.red : Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                      TranslatedText(
                        'general.doubt.explanation_player.title',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 24),
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
                                        text: '$_displayedPoints% ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getColorForPercentage(_displayedPoints.toDouble()),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: TranslatedText(
                                          'general.doubt.explanation_player.messages.have_understood',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.psychology,
                                  color: _getColorForPercentage(_displayedPoints.toDouble()),
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
                                      (_displayedPoints / 100) * 0.9, // Use _displayedPoints here
                                  decoration: BoxDecoration(
                                    gradient: flutter.LinearGradient(
                                      colors: [
                                        _getColorForPercentage((_displayedPoints / 2).toDouble()),
                                        _getColorForPercentage(_displayedPoints.toDouble()),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getColorForPercentage(_displayedPoints.toDouble()).withOpacity(0.3),
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
                      TranslatedText(
                        'general.doubt.question_details.explain_play.button',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _fetchedContent, // Display fetched content instead of question text
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
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
                  duration: Duration(seconds: 1),
                  curve: Curves.easeOut,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            Text('🎉 ', style: TextStyle(fontSize: 32)),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                child: TranslatedText(
                                  'general.doubt.explanation_player.points.great_job',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                            Text(' 🎉', style: TextStyle(fontSize: 32)),
                          ],
                        ),
                        SizedBox(height: 16),
                        TranslatedText(
                          'general.doubt.explanation_player.points.earned',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '✨ ',
                              style: TextStyle(
                                fontSize: 30,
                              ),
                            ),
                            Text(
                              '+$_pointsEarned',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700, // Changed text color for white background
                              ),
                            ),
                            Text(
                              ' ✨',
                              style: TextStyle(
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TranslatedText(
                          'general.doubt.explanation_player.points.points',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        TranslatedText(
                          'general.doubt.explanation_player.points.keep_up',
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
      ),
    );
  }

  @override
  void dispose() {
    _progressAnimationTimer?.cancel();
    _confettiController.dispose();
    _colorAnimationController.dispose();
    _restartTimer?.cancel();
    _stateMachineController?.dispose();
    _speech.stop();
    _pageTimer.cancel();
    _micDurationTimer?.cancel();
    super.dispose();
  }
} 