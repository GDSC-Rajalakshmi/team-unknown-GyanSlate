import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/translated_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'general/general_explanation_player_screen.dart';
import 'general/general_history_tab.dart' as general;
import 'general/general_camera_interface.dart';
import 'general/general_details_view.dart';
import 'general/general_box_painter.dart';
// import 'question/history_tab.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import 'package:http_parser/http_parser.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_loader_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeneralDoubtResolver extends StatefulWidget {
  const GeneralDoubtResolver({super.key});

  @override
  State<GeneralDoubtResolver> createState() => _GeneralDoubtResolverState();
}

class _GeneralDoubtResolverState extends State<GeneralDoubtResolver> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // Scroll controller for the question tab
  final ScrollController _scrollController = ScrollController();
  
  // Subject and chapter selection
  Map<String, List<String>> _subjectsAndChapters = {};
  String? _selectedSubject;
  String? _selectedChapter;
  
  // Camera and gallery variables
  bool _showCameraInterface = false;
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  
  // Gallery variables
  bool _isGalleryExpanded = false;
  List<String> _capturedImages = [];
  List<AssetEntity> _galleryAssets = [];
  
  // Image selection variables
  bool _showingImagePreview = false;
  String? _selectedImagePath;
  AssetEntity? _selectedAsset;
  
  // Question detection variables
  bool _isAnalyzingImage = false;
  List<Map<String, dynamic>> _detectedQuestions = [];
  
  // Question details variables
  bool _showQuestionDetails = false;
  bool _isLoadingQuestionDetails = false;
  Map<String, dynamic> _selectedQuestionDetails = {};
  
  // Drag gesture variables
  double _dragStartY = 0;
  double _dragDistance = 0;
  final double _dragThreshold = 50;
  
  // Sample data - Replace with your actual data
  // final List<String> subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology'];
  // final Map<String?, List<String>> chaptersBySubject = {
  //   'Mathematics': ['Algebra', 'Geometry', 'Calculus', 'Statistics'],
  //   'Physics': ['Mechanics', 'Thermodynamics', 'Electromagnetism', 'Optics'],
  //   'Chemistry': ['Organic Chemistry', 'Inorganic Chemistry', 'Physical Chemistry'],
  //   'Biology': ['Botany', 'Zoology', 'Human Physiology', 'Genetics'],
  // };

  // Add these controllers as class members
  final TextEditingController _doubtController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  bool _hasText = false;
  bool _hasFollowUpText = false;
  
  // Add speech to text variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcription = '';

  // Add variables to track attached images
  File? _attachedImage;
  AssetEntity? _attachedAsset;
  bool _hasAttachedImage = false;

  // Add new variables for points popup
  bool _showPointsPopup = false;
  bool _isPopupFading = false;
  int _totalPoints = 0;
  late ConfettiController _confettiController;
  Color _currentOverlayColor = Colors.transparent;

  // Add this variable to track loading state
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
    _loadGalleryAssets();
    
    // Add listeners to the text controllers
    _doubtController.addListener(_updateTextState);
    _followUpController.addListener(_updateFollowUpTextState);
    
    // Initialize speech to text
    _initializeSpeechAsync();
    _confettiController = ConfettiController(duration: Duration(seconds: 4));

    // Fetch subjects and chapters when component initializes
    _fetchSubjectsAndChapters();
  }

  Future<void> _initializeSpeechAsync() async {
    bool available = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    if (mounted) {
      setState(() {
        if (!available) {
          print('Speech recognition not available');
        }
      });
    }
  }
  
  Future<void> _listen(bool isFollowUp) async {
    try {
      if (!_isListening) {
        await _speech.stop();
        
        // Get the current language from provider
        final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        
        // Map language codes to speech recognition locale IDs
        final Map<String, String> languageToLocale = {
          'en': 'en_US',
          'ta': 'ta_IN',
          'hi': 'hi_IN',
          'te': 'te_IN'
        };
        
        // Get the appropriate locale ID
        final localeId = languageToLocale[currentLang] ?? 'en_US';
        
        setState(() {
          _isListening = true;
          _transcription = '';
        });

        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                if (result.recognizedWords.isNotEmpty) {
                  _transcription = result.recognizedWords;
                  
                  if (isFollowUp) {
                    _followUpController.text = _transcription;
                    _hasFollowUpText = true;
                  } else {
                    _doubtController.text = _transcription;
                    _hasText = true;
                  }
                }
              });
            }
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          partialResults: true,
          localeId: localeId,  // Use the selected language's locale
          cancelOnError: true,
          onSoundLevelChange: (level) {
            // Optional: could be used to show visual feedback of sound level
          },
        );
      } else {
        setState(() {
          _isListening = false;
        });
        await _speech.stop();
      }
    } catch (e) {
      print('Error with speech recognition: $e');
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('general.doubt.errors.speech_recognition')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateTextState() {
    setState(() {
      _hasText = _doubtController.text.isNotEmpty;
    });
  }
  
  void _updateFollowUpTextState() {
    setState(() {
      _hasFollowUpText = _followUpController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _cameraController?.dispose();
    _doubtController.dispose();
    _followUpController.dispose();
    _speech.stop();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Check camera permission
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    // Check storage permission based on platform
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt <= 32) {
        // For Android 12 and below
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
      } else {
        // For Android 13+
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
      }
    } else if (Platform.isIOS) {
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        photosStatus = await Permission.photos.request();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    
    if (_cameras.isNotEmpty && _cameraController == null) {
      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> _loadGalleryAssets() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      
      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final assets = await recentAlbum.getAssetListRange(
          start: 0,
          end: 20, // Load first 20 images
        );
        
        if (mounted) {
          setState(() {
            _galleryAssets = assets;
          });
        }
      }
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        
        if (mounted) {
          setState(() {
            _showingImagePreview = true;
            _selectedImagePath = file.path;
            _selectedAsset = null;
            _capturedImages.insert(0, file.path);
            if (_capturedImages.length > 10) {
              _capturedImages.removeLast();
            }
            
            // Attach the image to the input field
            _attachedImage = File(file.path);
            _attachedAsset = null;
            _hasAttachedImage = true;
            _showCameraInterface = false; // Close camera after capturing
            
            // Make sure we don't automatically trigger question details
            _showQuestionDetails = false;
          });
        }
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
  }

  void _selectGalleryImage(String? imagePath, AssetEntity? asset) {
    setState(() {
      _showingImagePreview = imagePath != null || asset != null;
      _selectedImagePath = imagePath;
      _selectedAsset = asset;
      
      // Attach the image to the input field
      if (imagePath != null) {
        _attachedImage = File(imagePath);
        _attachedAsset = null;
        _hasAttachedImage = true;
      } else if (asset != null) {
        _attachedImage = null;
        _attachedAsset = asset;
        _hasAttachedImage = true;
      }
      
      // Don't automatically show question details
      _showCameraInterface = false; // Close camera interface
      
      // Make sure we don't automatically trigger question details
      _showQuestionDetails = false;
    });
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzingImage = true;
      _detectedQuestions = [];
    });

    try {
      // Get the image file/data
      File? imageFile;
      if (_selectedImagePath != null) {
        imageFile = File(_selectedImagePath!);
      } else if (_selectedAsset != null) {
        final file = await _selectedAsset!.file;
        imageFile = file;
      }

      if (imageFile != null) {
        // Simulate detection with mock data instead of API call
        await Future.delayed(Duration(seconds: 1)); // Simulate network delay
        
        List<Map<String, dynamic>> mockQuestions = [
          {
            'id': '1',
            'text': 'Sample detected question 1',
            'boundingBox': {'x': 0.1, 'y': 0.2, 'width': 0.8, 'height': 0.1},
          },
          {
            'id': '2',
            'text': 'Sample detected question 2',
            'boundingBox': {'x': 0.1, 'y': 0.4, 'width': 0.8, 'height': 0.1},
          }
        ];

        if (mounted) {
          setState(() {
            _isAnalyzingImage = false;
            _detectedQuestions = mockQuestions;
          });
        }
      }
    } catch (e) {
      print('Error analyzing image: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze image: $e')),
        );
      }
    }
  }

  void _selectQuestion(Map<String, dynamic> question) {
    // Close the camera interface but don't dispose the controller yet
    setState(() {
      _showCameraInterface = false;
      _isGalleryExpanded = false;
      _isLoadingQuestionDetails = true;
      _showQuestionDetails = true;
      _selectedQuestionDetails = {}; // Clear previous details
    });
    
    // Load question details with mock data instead of API call
    _loadQuestionDetailsMock(question);
  }

  Future<void> _loadQuestionDetailsMock(Map<String, dynamic> question) async {
    setState(() {
      _isLoadingQuestionDetails = true;
    });
    
    try {
      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));
      
      // Create mock data
      final Map<String, dynamic> mockQuestionDetails = {
        'question': question,
        'subtopic_explanation': [
          'This is a sample subtopic explanation.',
          'It covers the key concepts needed to understand this question.'
        ],
        'images': [],
        'solution': 'This is a sample solution to the question.',
        'solution_explanation': 'This explains how to arrive at the solution step by step.',
      };
      
      if (mounted) {
        setState(() {
          _selectedQuestionDetails = mockQuestionDetails;
          _isLoadingQuestionDetails = false;
        });
      }
    } catch (e) {
      print('Error loading question details: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuestionDetails = false;
          // Set empty details instead of leaving previous data
          _selectedQuestionDetails = {'question': question};
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load question details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper method to get actual subject name for API
  String _getActualSubjectName(String translationKey) {
    switch (translationKey) {
      case 'general.doubt.subjects.mathematics':
        return 'Mathematics';
      case 'general.doubt.subjects.physics':
        return 'Physics';
      case 'general.doubt.subjects.chemistry':
        return 'Chemistry';
      case 'general.doubt.subjects.biology':
        return 'Biology';
      case 'general.doubt.subjects.computerScience':
        return 'Computer Science';
      default:
        return 'General';
    }
  }

  // Helper method to get actual chapter name for API
  String _getActualChapterName(String translationKey) {
    switch (translationKey) {
      case 'general.doubt.chapters.mathematics.algebra':
        return 'Algebra';
      case 'general.doubt.chapters.mathematics.geometry':
        return 'Geometry';
      case 'general.doubt.chapters.mathematics.calculus':
        return 'Calculus';
      case 'general.doubt.chapters.physics.mechanics':
        return 'Mechanics';
      case 'general.doubt.chapters.physics.thermodynamics':
        return 'Thermodynamics';
      case 'general.doubt.chapters.physics.optics':
        return 'Optics';
      case 'general.doubt.chapters.computerScience.programming':
        return 'Programming';
      case 'general.doubt.chapters.computerScience.databases':
        return 'Databases';
      case 'general.doubt.chapters.computerScience.networking':
        return 'Networking';
      // Add other chapters as needed
      default:
        return 'General';
    }
  }

  // Modify the _sendQuestionToAPI method
  Future<void> _sendQuestionToAPI(String questionText) async {
    try {
      // Get values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? '';
      final className = prefs.getString('class') ?? '';
      

      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Retrieved token: $token');

      // Get the current language from LanguageProvider
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final currentLanguage = languageProvider.currentLanguage;
        final languageName = LanguageProvider.languageNames[currentLanguage] ?? currentLanguage;


      // Get actual subject and chapter names
      final String actualSubject = _getActualSubjectName(_selectedSubject!);
      final String actualChapter = _getActualChapterName(_selectedChapter!);

      if (_hasAttachedImage && (_attachedImage != null || _attachedAsset != null)) {
        // For image upload case
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/doubt'),
        );
        
        // Get both tokens
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'token');
        final accessToken = await storage.read(key: 'access_token');
        
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Create the data object and encode it as JSON
        request.fields['data'] = jsonEncode({
          'question': questionText,
          'subj': _selectedSubject ,
          'chap': _selectedChapter ,
          'state': state,
          'lng': currentLanguage,
          'clss': int.tryParse(className) ?? 0,  // Convert to int, default to 0 if parsing fails
          'is_img': 1  // Use integer instead of string,
        });

        // Add image file if present
        if (_attachedImage != null) {
          var file = await http.MultipartFile.fromPath(
            'image',
            _attachedImage!.path,
          );
          request.files.add(file);
        } else if (_attachedAsset != null) {
          final file = await _attachedAsset!.file;
          if (file != null) {
            var bytes = await file.readAsBytes();
            var multipartFile = http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }

        // Send the request
        print('Sending request with image to API...');
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        print('API Response: $responseData');

        // Handle response
        if (response.statusCode == 200) {
          // Parse the response and extract the access token
          final decodedResponse = json.decode(responseData);
          if (decodedResponse['access'] != null) {
            // Store the new access token
            await storage.write(key: 'access_token', value: decodedResponse['access']);
          }
          
          _handleSuccessResponse(responseData, questionText);
        } else {
          throw Exception('Server returned status code ${response.statusCode}');
        }
      } else {
         // Get values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('state') ?? '';
      final className = prefs.getString('class') ?? '';
      

      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Retrieved token: $token');

        // Get the current language from LanguageProvider
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final currentLanguage = languageProvider.currentLanguage;
        final languageName = LanguageProvider.languageNames[currentLanguage] ?? currentLanguage;

        // For text-only case
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/doubt'),
        );
        
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Add the data as a form field
        request.fields['data'] = jsonEncode({
          'question': questionText,
          // 'subj': actualSubject,
          // 'chap': actualChapter,
          'subj': _selectedSubject,
          'chap': _selectedChapter,
          'state': state,
          'clss': int.tryParse(className) ?? 0,  // Convert to int, default to 0 if parsing fails
          'is_img': 0,
          'lng': currentLanguage,
        });

        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('Response body: ${response.body}');
          
          // Parse the response and extract the access token
          final responseData = json.decode(response.body);
          if (responseData['access'] != null) {
            // Store the new access token
            await storage.write(key: 'access_token', value: responseData['access']);
            print(responseData["access"]);
          }
          
          _handleSuccessResponse(response.body, questionText);
        } else {
          print('Response body error: ${response.body}');
          throw Exception('Server returned status code ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error sending question to API: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuestionDetails = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send question: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Helper method to handle successful API response
  void _handleSuccessResponse(String responseData, String questionText) {
    var decodedResponse = json.decode(responseData);
    
    if (mounted) {
      setState(() {
        _isLoadingQuestionDetails = false;
        _selectedQuestionDetails = {
          'question': {
            'id': '1',
            'text': questionText,
          },
          'userInput': questionText,
          'image': decodedResponse['img'],
          'response': decodedResponse['doubt_resolution'],
          'mcqs': decodedResponse['mcqs'],
          ...decodedResponse,  // Spread any other API response data
        };
        _showQuestionDetails = true;
      });
      
      // Handle points if included in response
      if (decodedResponse.containsKey('points')) {
        int points = decodedResponse['points'] ?? 0;
        if (points > 0) {
          _handlePointsEarned(points);
        }
      }
    }
  }

  // Add this method to handle points earned
  void _handlePointsEarned(int points) {
    // Start confetti first
    _confettiController.play();

    // Show popup with a slight delay to sync with confetti
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _totalPoints = points;
          _showPointsPopup = true;
          _currentOverlayColor = Color(0xFF4CAF50).withOpacity(0.3); // Green overlay
        });
      }
    });

    // Start fading out popup after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPopupFading = true;
          _currentOverlayColor = Colors.transparent;
        });
      }
    });

    // Hide popup after 4 seconds (matching confetti duration)
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showPointsPopup = false;
          _isPopupFading = false;
        });
      }
    });

    // Stop confetti after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      _confettiController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen if subjects are being fetched
    if (_isLoadingSubjects) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
              ),
              SizedBox(height: 16),
              Text(
                _getTranslatedText('general.doubt.loading'),
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),  // Updated background color
      appBar: AppBar(
        backgroundColor: Colors.white,  // Updated header background color
        elevation: 2,
        title: Text(
          _getTranslatedText('general.doubt.title'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),  // Updated header text color
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF4A90E2),  // Updated indicator color
          labelColor: Color(0xFF4A90E2),  // Updated selected tab color
          unselectedLabelColor: Color(0xFF2C3E50),  // Updated unselected tab color
          tabs: [
            Tab(
              text: _getTranslatedText('general.doubt.tabs.doubts'),
            ),
            Tab(
              text: _getTranslatedText('general.doubt.tabs.history'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildQuestionTab(),
              general.HistoryTab(),
            ],
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),

          // Color overlay
          if (_currentOverlayColor != Colors.transparent)
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              color: _currentOverlayColor,
            ),

          // Points popup
          if (_showPointsPopup)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isPopupFading ? 0.0 : 1.0,
                    duration: Duration(seconds: 1),
                    curve: Curves.easeOut,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 32),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade100,
                                      Colors.green.shade50,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              Text(
                                '$_totalPoints',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        Colors.green.shade700,
                                        Colors.green.shade500,
                                      ],
                                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TranslatedText(
                            'general.doubt.points.earned',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12),
                          TranslatedText(
                            'general.doubt.points.keep_going',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
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

  Widget _buildQuestionTab() {
    print("Building question tab. showCameraInterface=$_showCameraInterface, showQuestionDetails=$_showQuestionDetails");
    
    if (_showCameraInterface) {
      return CameraInterface(
        isCameraInitialized: _isCameraInitialized,
        cameraController: _cameraController,
        isGalleryExpanded: _isGalleryExpanded,
        showingImagePreview: _showingImagePreview,
        selectedImagePath: _selectedImagePath,
        selectedAsset: _selectedAsset,
        capturedImages: _capturedImages,
        galleryAssets: _galleryAssets,
        isAnalyzingImage: _isAnalyzingImage,
        detectedQuestions: _detectedQuestions,
        dragStartY: _dragStartY,
        dragDistance: _dragDistance,
        dragThreshold: _dragThreshold,
        onClose: () {
          setState(() {
            _showCameraInterface = false;
          });
        },
        captureImage: _captureImage,
        onSelectGalleryImage: _selectGalleryImage,
        onSelectQuestion: _selectQuestion,
        onDragStart: _onDragStart,
        onDragUpdate: _onDragUpdate,
        onDragEnd: _onDragEnd,
      );
    }
    
    // If showing question details, return the details view
    if (_showQuestionDetails) {
      print("Showing question details view with details: $_selectedQuestionDetails");
      return Column(
        children: [
          // Main content area with question details
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question details view - this is the key part that displays all content
                    QuestionDetailsView(
                      selectedImagePath: _selectedImagePath,
                      selectedAsset: _selectedAsset,
                      selectedQuestionDetails: _selectedQuestionDetails,
                      isLoadingQuestionDetails: _isLoadingQuestionDetails,
                      attachedImage: _attachedImage,
                      userInputText: _followUpController.text,
                      onPointsEarned: _handlePointsEarned,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom input section with camera header
          _buildInputSection(),
        ],
      );
    }
    
    // Default view with input field
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.question_answer_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                TranslatedText(
                  'general.doubt.empty_state.title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                TranslatedText(
                  'general.doubt.empty_state.description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Use the input section here instead of just the camera header
        _buildInputSection(),
      ],
    );
  }

  Widget _buildInputSection() {
    // Determine if the send button should be enabled
    bool shouldShowSend = _hasText;  // Only show send when there's text
    bool shouldShowMic = !_hasText && !_isListening;  // Show mic when no text and not listening

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubject,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                        isExpanded: true,
                        hint: Text('Select Subject'),
                        style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSubject = newValue;
                              // Reset chapter selection when subject changes
                              _selectedChapter = null;
                              if (_subjectsAndChapters[newValue]?.isNotEmpty ?? false) {
                                _selectedChapter = _subjectsAndChapters[newValue]!.first;
                              }
                            });
                          }
                        },
                        items: _subjectsAndChapters.keys.map<DropdownMenuItem<String>>((dynamic value) {
                          return DropdownMenuItem<String>(
                            value: value.toString(),
                            child: Text(value.toString()),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedChapter,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                        isExpanded: true,
                        hint: Text('Select Chapter'),
                        style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedChapter = newValue;
                            });
                          }
                        },
                        items: (_selectedSubject != null && _subjectsAndChapters.containsKey(_selectedSubject))
                            ? _subjectsAndChapters[_selectedSubject]!.map<DropdownMenuItem<String>>((dynamic value) {
                                return DropdownMenuItem<String>(
                                  value: value.toString(),
                                  child: Text(value.toString()),
                                );
                              }).toList()
                            : <DropdownMenuItem<String>>[],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Attached image preview
          if (_hasAttachedImage)
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 16, bottom: 8),
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _attachedImage != null
                            ? Image.file(
                                _attachedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : _attachedAsset != null
                                ? FutureBuilder<Uint8List?>(
                                    future: _attachedAsset!.thumbnailData,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                                          strokeWidth: 2,
                                        ));
                                      }
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        );
                                      }
                                      return Center(child: Icon(Icons.image_not_supported, size: 16));
                                    },
                                  )
                                : Container(),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _clearAttachedImage,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
          
          // Modified input row
          Row(
            children: [
              SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF4A90E2),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _showCameraInterface = true;
                    });
                    _initializeCamera();
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              Expanded(
                child: TextField(
                  controller: _doubtController,
                  decoration: InputDecoration(
                    hintText: _hasAttachedImage 
                        ? _getTranslatedText('general.doubt.input.addImageDescription')
                        : _getTranslatedText('general.doubt.input.askQuestion'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF8FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 1,
                  onChanged: (text) {
                    setState(() {
                      _hasText = text.isNotEmpty;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              // Modified button logic
              CircleAvatar(
                radius: 20,
                backgroundColor: shouldShowSend 
                    ? Color(0xFF4A90E2) 
                    : _isListening 
                        ? Colors.red 
                        : shouldShowMic 
                            ? Color(0xFF4A90E2)
                            : Colors.transparent, // Hide when only image is attached
                child: shouldShowSend || shouldShowMic || _isListening
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          shouldShowSend ? Icons.send : (_isListening ? Icons.stop : Icons.mic),
                          color: Colors.white,
                        ),
                        onPressed: shouldShowSend ? _sendMessage : () => _listen(false),
                      )
                    : null, // No button when only image is attached
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show attached image if available - with much smaller size
          if (_hasAttachedImage)
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8, right: 8),
                  width: 60, // Small width
                  height: 60, // Small height
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _attachedImage != null
                            ? Image.file(
                                _attachedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : _attachedAsset != null
                                ? FutureBuilder<Uint8List?>(
                                    future: _attachedAsset!.thumbnailData,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator(strokeWidth: 2));
                                      }
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        );
                                      }
                                      return Center(child: Icon(Icons.image_not_supported, size: 16));
                                    },
                                  )
                                : Container(),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _clearAttachedImage,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12, // Very small icon
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SizedBox()), // Push the image to the left
              ],
            ),
          
          // Input row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _showCameraInterface = true;
                    });
                    _initializeCamera();
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              Expanded(
                child: TextField(
                  controller: _doubtController,
                  decoration: InputDecoration(
                    hintText: _hasAttachedImage 
                        ? TranslationLoaderService().getTranslation(
                            'general.doubt.input.addImageDescription',
                            Provider.of<LanguageProvider>(context).currentLanguage
                          )
                        : TranslationLoaderService().getTranslation(
                            'general.doubt.input.askQuestion',
                            Provider.of<LanguageProvider>(context).currentLanguage
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 1,
                  onChanged: (text) {
                    setState(() {
                      _hasText = text.isNotEmpty;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              
              CircleAvatar(
                radius: 20,
                backgroundColor: (_hasText || _hasAttachedImage) ? Colors.blue : _isListening ? Colors.red : Colors.blue.shade100,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    (_hasText || _hasAttachedImage) ? Icons.send : (_isListening ? Icons.stop : Icons.mic),
                    color: (_hasText || _hasAttachedImage) ? Colors.white : (_isListening ? Colors.white : Colors.blue),
                  ),
                  onPressed: _sendMessage,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can replace this with your actual image asset
            Image.asset(
              'assets/images/empty_solution.png', 
              height: 150,
              width: 150,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.question_answer_outlined,
                  size: 120,
                  color: Colors.blue.withOpacity(0.7),
                );
              },
            ),
            const SizedBox(height: 24),
            TranslatedText(
              'general.doubt.empty_state.title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TranslatedText(
              'general.doubt.empty_state.description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Method to send a message
  void _sendMessage() {
    print("_sendMessage called with text: ${_doubtController.text}");
    
    // If we're listening for voice input, stop it
    if (_isListening) {
      _listen(false);
      return;
    }
    
    // Check if we have text (now required even with image)
    if (!_hasText) {
      // Show error message if image is attached but no text
      if (_hasAttachedImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslatedText('general.doubt.errors.text_required_with_image')),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Start voice input if no content
      _listen(false);
      return;
    }
    
    // Get the user input text
    final String userInputText = _doubtController.text;
    
    // Call the API to send the question
    _sendQuestionToAPI(userInputText);
    
    // Set state to show question details directly in the main page
    setState(() {
      _isLoadingQuestionDetails = true;
      _showQuestionDetails = true;
      
      // Pass the attached image to the details view
      _selectedImagePath = _attachedImage?.path;
      _selectedAsset = _attachedAsset;
      
      // Create a consistent structure for the question details
      _selectedQuestionDetails = {
        'userInput': userInputText,
        'hasImage': _hasAttachedImage || _selectedImagePath != null || _selectedAsset != null,
        'subject': _selectedSubject,
        'chapter': _selectedChapter
      };
      
      print("STATE UPDATED: _showQuestionDetails=$_showQuestionDetails");
      
      // Clear input fields
      _doubtController.clear();
      _hasText = false;
      _isListening = false;
      _transcription = '';
    });
    
    // Stop speech recognition if active
    if (_speech.isListening) {
      _speech.stop();
    }
    
    // After a short delay, clear the input attachments
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _attachedImage = null;
        _attachedAsset = null;
        _hasAttachedImage = false;
      });
    });
  }

  // Method to clear attached image
  void _clearAttachedImage() {
    setState(() {
      _attachedImage = null;
      _attachedAsset = null;
      _hasAttachedImage = false;
    });
  }

  // Update the drag gesture handlers to match the expected signatures
  void _onDragStart(double position) {
    // Store the starting position
    setState(() {
      _dragStartY = position;
      _dragDistance = 0;
    });
    print("Drag started at: $position");
  }

  void _onDragUpdate(double position) {
    // Calculate the drag distance
    setState(() {
      _dragDistance = position - _dragStartY;
    });
    print("Drag updated: $position, distance: $_dragDistance");
  }

  void _onDragEnd(double velocity) {
    // Handle the end of the drag based on distance and velocity
    print("Drag ended with velocity: $velocity");
    
    // Reset drag values
    setState(() {
      _dragStartY = 0;
      _dragDistance = 0;
    });
  }

  String _getTranslatedText(String key) {
    return TranslationLoaderService().getTranslation(
      key,
      Provider.of<LanguageProvider>(context).currentLanguage
    );
  }

  // Update the fetch method to handle loading state
  Future<void> _fetchSubjectsAndChapters() async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      final prefs = await SharedPreferences.getInstance();
      final classNumString = prefs.getString('class') ?? '10';
      
      final classNum = int.tryParse(classNumString) ?? 10; // Default to 10 if parsing fails

      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/availabilty'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'class': classNum,
        }),
      );

      // Add detailed logging
      print('API Response Status Code: ${response.statusCode}');
      // print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // print('Decoded Data: $data');
        
        if (mounted) {
          setState(() {
            _subjectsAndChapters = Map<String, List<String>>.from(
              data.map((key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              )),
            );
            
            // Set initial selections
            if (_subjectsAndChapters.isNotEmpty) {
              _selectedSubject = _subjectsAndChapters.keys.first;
              _selectedChapter = _subjectsAndChapters[_selectedSubject]?.first;
            }
            
            _isLoadingSubjects = false;
          });
        }
      } else {
        throw Exception('Failed to load subjects and chapters');
      }
    } catch (e) {
      print('Error fetching subjects and chapters: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubjects = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subjects and chapters: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: _getTranslatedText('general.doubt.retry'),
              textColor: Colors.white,
              onPressed: () {
                _fetchSubjectsAndChapters(); // Retry loading
              },
            ),
          ),
        );
      }
    }
  }
}