import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/translated_text.dart';
import 'package:image_picker/image_picker.dart';
import 'question/explanation_player_screen.dart';
import 'question/question_box_painter.dart';
import 'question/camera_interface.dart';
import 'question/question_details_view.dart';
import 'question/history_tab.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../services/translation_loader_service.dart';
import '../../providers/language_provider.dart';
import 'dart:io'; // Add this for File and Platform
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this for secure storage
import 'package:shared_preferences/shared_preferences.dart';

class QuestionDoubtResolver extends StatefulWidget {
  const QuestionDoubtResolver({Key? key}) : super(key: key);

  @override
  State<QuestionDoubtResolver> createState() => _QuestionDoubtResolverState();
}

class _QuestionDoubtResolverState extends State<QuestionDoubtResolver> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // Scroll controller for the question tab
  final ScrollController _scrollController = ScrollController();
  
  // Subject and chapter selection
  String? selectedSubject;
  String? selectedChapter;
  
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
  
  // Replace hardcoded subjects and chapters with dynamic map
  Map<String, List<String>> _subjectsAndChapters = {};
  bool _isLoadingSubjects = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
    _loadGalleryAssets();
    // Add this line to fetch subjects when component initializes
    _fetchSubjectsAndChapters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _cameraController?.dispose();
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
        // For Android 12 and belowf
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
          });
        }
        
        // Analyze the captured image
        _analyzeImage();
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
      _detectedQuestions = []; // Clear previous questions
    });
    
    if (_showingImagePreview) {
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzingImage = true;
      _detectedQuestions = [];
    });

    try {
       // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');


      // Get the image file/data
      File? imageFile;
      if (_selectedImagePath != null) {
        imageFile = File(_selectedImagePath!);
      } else if (_selectedAsset != null) {
        final file = await _selectedAsset!.file;
        imageFile = file;
      }

      if (imageFile != null) {
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/extract_q'),
        );
        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Add the image file to the request
        var multipartFile = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        );
        request.files.add(multipartFile);

        // Send the request and print response details
        print('Sending request to: ${request.url}');
        var streamedResponse = await request.send();
        var responseData = await streamedResponse.stream.bytesToString();

        print('Response Status Code: ${streamedResponse.statusCode}');
        print('Response Headers: ${streamedResponse.headers}');
        print('Response Body: $responseData');

        var decodedResponse = json.decode(responseData);

        if (streamedResponse.statusCode == 200) {
          // Transform the API response to match our expected format
          List<Map<String, dynamic>> questions = [];
          List<String> questionsList = List<String>.from(decodedResponse['questions']);
          
          for (int i = 0; i < questionsList.length; i++) {
            questions.add({
              'id': 'q_${i + 1}', // Generate unique ID based on index
              'text': questionsList[i],
              'boundingBox': {
                'x': 0.0, // Default values since API doesn't provide bounding box
                'y': 0.0,
                'width': 100.0,
                'height': 50.0,
              },
            });
          }

          if (mounted) {
            setState(() {
              _isAnalyzingImage = false;
              _detectedQuestions = questions;
            });
          }
        } else {
          throw Exception('Failed to analyze image');
        }
      }
    } catch (e) {
      print('Error analyzing image: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('general.doubt.errors.analysis_failed'),
          ),
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
    
    // Load question details
    _loadQuestionDetails(question);
  }

  Future<void> _loadQuestionDetails(Map<String, dynamic> question) async {
    setState(() {
      _isLoadingQuestionDetails = true;
    });
    
    try {
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final prefs = await SharedPreferences.getInstance();
      final rollNumString = prefs.getString('rollNumber') ?? '0';
      final classNumString = prefs.getString('class') ?? '10';
      final stateString = prefs.getString('state') ?? 'Tamil Nadu';
      // Convert to int
      final rollNum = int.tryParse(rollNumString) ?? 0; // Default to 0 if parsing fails
      final classNum = int.tryParse(classNumString) ?? 10; // Default to 10 if parsing fails

    
      // Get the current language from LanguageProvider
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final currentLanguage = languageProvider.currentLanguage;
        final languageName = LanguageProvider.languageNames[currentLanguage] ?? currentLanguage;
      print("current language is $currentLanguage");
      // Debug the question ID
      
      // Log the request details
      final requestBody = {
        'question': question['text'],
        'subj': selectedSubject ,
        'chap': selectedChapter ,
        "class": classNum,
        "roll_num": rollNum,
        'lng': currentLanguage,
        "state": stateString
      };

      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/book_question'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );
      
      print('API Response status code: ${response.statusCode}');
      print('API Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        
        // Print the raw response for debugging
        print('Raw API response: $decodedResponse');
        
        // Store the access token if it exists in the response
        if (decodedResponse.containsKey('access')) {
          await storage.write(key: 'question_access', value: decodedResponse['access']);
          print('Stored access token: ${decodedResponse['access']}');
        }
        
        // Transform API response to match our expected format
        final Map<String, dynamic> questionDetails = {
          'question': {'text': question['text'] ?? 'No question text available'},
          'solution': decodedResponse['solution'] ?? '',
          'solution_explanation': decodedResponse['explanation'] ?? '',
          // Pass the entire subtopic object directly
          'subtopic': decodedResponse['subtopic'],
          'images': [],
          // Store access in the question details as well
          'access': decodedResponse['access'],
        };
        
        // Process subtopics for images
        if (decodedResponse['subtopic'] != null) {
          decodedResponse['subtopic'].forEach((String topicName, dynamic topicData) {
            // Add image if it exists and isn't already included
            if (topicData['img'] != null) {
              questionDetails['images'].add(topicData['img']);
            }
          });
        }

        print('Processed question details: $questionDetails');

        if (mounted) {
          setState(() {
            _selectedQuestionDetails = questionDetails;
            _isLoadingQuestionDetails = false;
          });
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading question details: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuestionDetails = false;
          // Set empty details instead of leaving previous data
          _selectedQuestionDetails = {'question': {'text': question['text'] ?? 'No question text available'}};
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

  void _onDragStart(double startY) {
    setState(() {
      _dragStartY = startY;
      _dragDistance = 0;
    });
  }

  void _onDragUpdate(double currentY) {
    setState(() {
      _dragDistance = _dragStartY - currentY;
    });
  }

  void _onDragEnd(double velocity) {
    if (_dragDistance.abs() > _dragThreshold || velocity.abs() > 300) {
      setState(() {
        if (_dragDistance > 0 || velocity < -300) {
          // Dragged up or flicked up
          _isGalleryExpanded = true;
        } else {
          // Dragged down or flicked down
          _isGalleryExpanded = false;
        }
        _dragDistance = 0;
      });
    } else {
      setState(() {
        _dragDistance = 0;
      });
    }
  }

  // Add this new method to fetch subjects and chapters
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

      // // Add detailed logging
      // print('API Response Status Code: ${response.statusCode}');
      // print('API Response Headers: ${response.headers}');
      // print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // print('Decoded Data: $data');
        
        if (mounted) {
          setState(() {
            // Clear existing selections
            selectedSubject = null;
            selectedChapter = null;
            
            // Update the subjects and chapters map
            _subjectsAndChapters = Map<String, List<String>>.from(
              data.map((key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              )),
            );
            
            // Set initial selections if data is available
            if (_subjectsAndChapters.isNotEmpty) {
              selectedSubject = _subjectsAndChapters.keys.first;
              if (_subjectsAndChapters[selectedSubject]?.isNotEmpty ?? false) {
                selectedChapter = _subjectsAndChapters[selectedSubject]!.first;
              }
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
              label: 'Retry',
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

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: TranslatedText(
          'general.doubt.title1',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF4A90E2),
          labelColor: Color(0xFF4A90E2),
          unselectedLabelColor: Color(0xFF2C3E50),
          tabs: [
            Tab(child: TranslatedText('general.doubt.questions.question')),
            Tab(child: TranslatedText('general.doubt.tabs.history')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionTab(),
          HistoryTab(),
        ],
      ),
    );
  }

  Widget _buildQuestionTab() {
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
    
    if (_showQuestionDetails) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionDetailsView(),
                  ],
                ),
              ),
            ),
          ),
          _buildCameraHeader(),
        ],
      );
    }
    
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -10) {
          setState(() {
            _showCameraInterface = true;
          });
          _initializeCamera();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSubject,
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                                  isExpanded: true,
                                  hint: Text('Select Subject'),
                                  style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedSubject = newValue;
                                        selectedChapter = null;
                                        if (_subjectsAndChapters[newValue]?.isNotEmpty ?? false) {
                                          selectedChapter = _subjectsAndChapters[newValue]!.first;
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
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedChapter,
                                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                                  isExpanded: true,
                                  hint: Text('Select Chapter'),
                                  style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedChapter = newValue;
                                      });
                                    }
                                  },
                                  items: (selectedSubject != null && _subjectsAndChapters.containsKey(selectedSubject))
                                      ? _subjectsAndChapters[selectedSubject]!.map<DropdownMenuItem<String>>((dynamic value) {
                                          return DropdownMenuItem<String>(
                                            value: value.toString(),
                                            child: Text(value.toString()),
                                          );
                                        }).toList()
                                      : <DropdownMenuItem<String>>[],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
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
                  ],
                ),
              ),
            ),
          ),
          _buildCameraHeader(),
        ],
      ),
    );
  }

  Widget _buildCameraHeader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showCameraInterface = true;
        });
        _initializeCamera();
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -10) {
          setState(() {
            _showCameraInterface = true;
          });
          _initializeCamera();
        }
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: TranslatedText(
                      'general.doubt.camera.swipe_up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

  Widget _buildQuestionDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject and Chapter selection at the top
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSubject,
                      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                      isExpanded: true,
                      hint: Text('Select Subject'),
                      style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedSubject = newValue;
                            selectedChapter = null;
                            if (_subjectsAndChapters[newValue]?.isNotEmpty ?? false) {
                              selectedChapter = _subjectsAndChapters[newValue]!.first;
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
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedChapter,
                      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4A90E2)),
                      isExpanded: true,
                      hint: Text('Select Chapter'),
                      style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedChapter = newValue;
                          });
                        }
                      },
                      items: (selectedSubject != null && _subjectsAndChapters.containsKey(selectedSubject))
                          ? _subjectsAndChapters[selectedSubject]!.map<DropdownMenuItem<String>>((dynamic value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList()
                          : <DropdownMenuItem<String>>[],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Question details view with modified topic explanation display
        QuestionDetailsView(
          selectedImagePath: _selectedImagePath,
          selectedAsset: _selectedAsset,
          selectedQuestionDetails: _selectedQuestionDetails,
          isLoadingQuestionDetails: _isLoadingQuestionDetails,
        ),
      ],
    );
  }
  String _getTranslatedText(String key) {
    return TranslationLoaderService().getTranslation(
      key,
      Provider.of<LanguageProvider>(context).currentLanguage
    );
  }
}


