import 'package:flutter/material.dart' hide LinearGradient;
import 'package:flutter/material.dart' as material show LinearGradient;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/state_fruits.dart';
import '../widgets/custom_header.dart';
import '../widgets/translated_text.dart';
import '../providers/language_provider.dart';
import 'student/available_assessments.dart';
import 'dart:math';
import '../services/translation_loader_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'student/question_doubt_resolver.dart';
import 'student/general_doubt_resolver.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'student/student_profile.dart';
import 'student/student_leaderboard.dart';
import 'student/student_login.dart';
import 'package:rive/rive.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _studentName = '';
  int _userPoints = 0;
  String _userState = '';
  String _fruitEmoji = '';
  final List<FruitParticle> _fruitParticles = [];
  bool _isRaining = false;
  final _translationService = TranslationLoaderService();
  late LanguageProvider _languageProvider;
  final ValueNotifier<bool> _menuNotifier = ValueNotifier<bool>(false);

  // Updated gradient patterns for left-to-center flow
  static const List<List<Color>> featureGradients = [
    [Color(0xFFF0F4FF), Color(0xFFE6EEFF), Colors.white], // Soft blue gradient
    [Color(0xFFFFF4F0), Color(0xFFFFEEE8), Colors.white], // Soft peach gradient
    [Color(0xFFF0FFF4), Color(0xFFE8FAF0), Colors.white], // Soft mint gradient
  ];

  // Update Rive controller variables
  StateMachineController? controller;
  SMITrigger? bumpTrigger;
  SMIBool? isSlowDancing;
  SMIBool? isIdle;
  bool isDancing = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  }

  @override
  void activate() {
    super.activate();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // First load local data
      await _loadStudentData();
      
      // Then fetch points and fruit data
      await _loadPointsAndFruit();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('student_name') ?? '';
    final state = prefs.getString('state') ?? 'Tamil Nadu';
    
    if (mounted) {
      setState(() {
        _studentName = name;
        _userState = state;
        print('Loaded student name: $_studentName');
        print('Loaded state: $_userState');
      });
    }
  }

  Future<void> _loadPointsAndFruit() async {
    final prefs = await SharedPreferences.getInstance();
    final studentClass = prefs.getString('class') ?? '';
    final rollNum = prefs.getString('rollNumber') ?? '';
    
    // Get the token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
   
    try {
      final response = await http.post(
        Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/student/my_score'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'class': studentClass,
          'roll_num': rollNum,
          'state': _userState,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('score data: $data');
        if (mounted) {
          setState(() {
            _userPoints = data['score'] ?? 0;
            final fruit = StateFruits.getStateFruit(_userState);
            _fruitEmoji = fruit.emoji;
          });
        }
      } else {
        print('Failed to load points: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _userPoints = 0; // Reset to 0 if API fails
            _fruitEmoji = StateFruits.getStateFruit(_userState).emoji;
          });
        }
      }
    } catch (e) {
      print('Error fetching points: $e');
      if (mounted) {
        setState(() {
          _userPoints = 0; // Reset to 0 if API fails
          _fruitEmoji = StateFruits.getStateFruit(_userState).emoji;
        });
      }
    }
  }

  void startFruitRain() {
    if (_isRaining) return;
    
    setState(() {
      _isRaining = true;
      _fruitParticles.clear();
      
      // Create particles with an explosive pattern
      final centerX = MediaQuery.of(context).size.width / 2;
      final centerY = MediaQuery.of(context).size.height / 2;
      
      for (int i = 0; i < 30; i++) {
        // Calculate angle for circular explosion
        double angle = Random().nextDouble() * 2 * pi;
        double distance = 10 + Random().nextDouble() * 20; // Start closer to center
        
        _fruitParticles.add(FruitParticle(
          emoji: StateFruits.getStateFruit(_userState).emoji,
          position: Offset(
            centerX + cos(angle) * distance,
            centerY + sin(angle) * distance,
          ),
          size: 24 + Random().nextDouble() * 16,
          speed: 6 + Random().nextDouble() * 5, // Slightly reduced speed
          angle: cos(angle) * 2.5, // Slightly reduced angle force
          rotation: Random().nextDouble() * 0.3,
          opacity: 1.0,
        ));
      }
    });
    
    // Animate the particles
    _animateParticles();
  }
  
  void _animateParticles() async {
    if (!_isRaining || !mounted) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    bool allParticlesOffScreen = true;
    
    for (var particle in _fruitParticles) {
      // Calculate direction vector from center
      final centerX = MediaQuery.of(context).size.width / 2;
      final centerY = MediaQuery.of(context).size.height / 2;
      
      double dx = particle.position.dx - centerX;
      double dy = particle.position.dy - centerY;
      double distance = sqrt(dx * dx + dy * dy);
      
      // Normalize and apply speed (smoother acceleration curve)
      double speedMultiplier = max(0.8, min(4.0, 120 / max(10, distance)));
      
      if (distance > 0) {
        // Add slight easing for smoother movement
        dx = dx / distance * particle.speed * speedMultiplier;
        dy = dy / distance * particle.speed * speedMultiplier;
        
        // Add subtle wobble for organic movement
        dx += sin(distance * 0.02) * 0.3;
        dy += cos(distance * 0.02) * 0.3;
      }
      
      particle.position = Offset(
        particle.position.dx + dx,
        particle.position.dy + dy,
      );
      
      // Smoother rotation based on distance
      particle.rotation += 0.06 * (1 - min(1.0, distance / 500));
      
      // Fade out based on distance from center
      double fadeDistance = min(screenWidth, screenHeight) / 2.5;
      if (distance > fadeDistance) {
        // Calculate opacity based on distance with easing
        double fadeProgress = (distance - fadeDistance) / fadeDistance;
        particle.opacity = max(0, 1.0 - fadeProgress * fadeProgress); // Quadratic easing
      }
      
      // Check if particle is still on screen and visible
      if (particle.position.dx > -30 && 
          particle.position.dx < screenWidth + 30 &&
          particle.position.dy > -30 && 
          particle.position.dy < screenHeight + 30 &&
          particle.opacity > 0.05) {
        allParticlesOffScreen = false;
      }
    }
    
    if (allParticlesOffScreen) {
      if (mounted) {
        setState(() {
          _isRaining = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {});
      }
      await Future.delayed(const Duration(milliseconds: 8)); // Higher frame rate for smoother animation
      _animateParticles();
    }
  }

  // Enhanced color palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryPurple = Color(0xFF7C3AED);
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color darkText = Color(0xFF1F2937);
  static const Color lightText = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Update features list to include only the desired features
  static final List<Map<String, dynamic>> _features = [
    {
      'section': 'availableAssessments',
      'icon': Icons.assignment,
      'color': accentOrange,
      'builder': (BuildContext context) => const AvailableAssessments(),
    },
    {
      'section': 'questionResolver',
      'icon': Icons.quiz,
      'color': primaryBlue,
      'builder': (BuildContext context) => const QuestionDoubtResolver(),
    },
    {
      'section': 'doubtResolver',
      'icon': Icons.help_outline,
      'color': accentGreen,
      'builder': (BuildContext context) => const GeneralDoubtResolver(),
    },
  ];

  // Add this method to handle logout
  Future<void> _handleLogout(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLanguage;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _translationService.getTranslation(
            'student.dashboard.logout.title',
            currentLanguage,
          ),
        ),
        content: Text(
          _translationService.getTranslation(
            'student.dashboard.logout.message',
            currentLanguage,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _translationService.getTranslation(
                'student.dashboard.logout.cancel',
                currentLanguage,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              
              // Clear only student-specific data
              final prefs = await SharedPreferences.getInstance();
              
              // Clear specific student data from SharedPreferences
              await Future.wait([
                prefs.remove('student_name'),
                prefs.remove('rollNumber'),
                prefs.remove('class'),
                prefs.remove('state'),
                prefs.remove('user_state'),
                prefs.remove('user_points'),
                prefs.remove('hasSignedUp'),
                // prefs.remove('student_token'),
                // // Only remove the student-specific token
                // storage.delete(key: 'token'),
              ]);

              if (context.mounted) {
                // Navigate to home page and remove all previous routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home', // Changed from '/student-login' to '/home'
                  (route) => false,
                );
              }
            },
            child: Text(
              _translationService.getTranslation(
                'student.dashboard.logout.confirm',
                currentLanguage,
              ),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        // Navigate to home page instead of login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    }
  }

  Future<bool> _checkStudentAccess() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translationService.getTranslation(
              'student.dashboard.loginFirst',
              _languageProvider.currentLanguage ?? 'en',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    try {
      final decodedToken = JwtDecoder.decode(token);
      print(decodedToken); // For debugging
      if (decodedToken['role'] == 'student' || decodedToken['role'] == 'all') {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _translationService.getTranslation(
                'student.dashboard.noStudentAccess',
                _languageProvider.currentLanguage ?? 'en',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _translationService.getTranslation(
              'student.dashboard.invalidSession',
              _languageProvider.currentLanguage ?? 'en',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Update the Rive initialization method
  void _onRiveInit(Artboard artboard) {
    print('Rive initialization started');
    
    try {
      final controller = StateMachineController.fromArtboard(artboard, 'birb');
      
      if (controller != null) {
        artboard.addController(controller);
        this.controller = controller;
        
        // Get the correct input names from your Rive file
        bumpTrigger = controller.findSMI('look up') as SMITrigger;
        isSlowDancing = controller.findSMI('dance') as SMIBool;
        
        print('\nInputs found:');
        print('Look up trigger: ${bumpTrigger?.name}');
        print('Dance: ${isSlowDancing?.name}');

        // Set initial dance state to false
        if (isSlowDancing != null) {
          isSlowDancing!.value = false;
        }
      }
    } catch (e) {
      print('Error during Rive initialization: $e');
    }
  }

  Widget _buildBirbAnimation() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Look Up Button
                ElevatedButton.icon(
                  onPressed: () {
                    if (bumpTrigger != null) {
                      print('Looking up');
                      bumpTrigger!.fire();
                    }
                  },
                  icon: Icon(Icons.visibility),
                  label: TranslatedText(
                    'student.dashboard.birbControls.lookUp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade900,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Dance Button
                Container(
                  constraints: BoxConstraints(maxWidth: 150), // Limit maximum width
                  child: ElevatedButton(
                    onPressed: () {
                      if (isSlowDancing != null) {
                        bool newDanceState = !isDancing;
                        print(newDanceState ? 'Starting dance' : 'Stopping dance');
                        isSlowDancing!.value = newDanceState;
                        setLocalState(() => isDancing = newDanceState);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDancing ? Colors.pink.shade100 : Colors.grey.shade100,
                      foregroundColor: isDancing ? Colors.pink.shade900 : Colors.grey.shade900,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isDancing ? Icons.music_note : Icons.music_off, size: 18),
                        SizedBox(width: 6),
                        Flexible(
                          child: TranslatedText(
                            isDancing 
                              ? 'student.dashboard.birbControls.stopDancing'
                              : 'student.dashboard.birbControls.dance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: RiveAnimation.asset(
                'assets/animations/birb.riv',
                onInit: _onRiveInit,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _menuNotifier.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkStudentAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return Scaffold(
            backgroundColor: Color(0xFFF8FAFF),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 16),
                  TranslatedText(
                    'student.dashboard.loading',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data != true) {
          return _buildUnauthorizedAccessScreen(
            _translationService.getTranslation(
              'student.dashboard.unauthorizedAccess.message',
              _languageProvider.currentLanguage ?? 'en',
            ),
          );
        }

        return Scaffold(
          backgroundColor: Color(0xFFF8FAFF),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _initializeData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        _buildFeatureGrid(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: material.LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E3A8A).withOpacity(0.3),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  tooltip: 'Back to Home',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StudentProfile(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StudentProfile(),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _studentName.isNotEmpty ? _studentName.capitalize() : 'Student',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _translationService.getTranslation(
                                        'student.dashboard.studentDashboard',
                                        _languageProvider.currentLanguage ?? 'en',
                                      ),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 120),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '$_userPoints',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _fruitEmoji,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: material.LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: material.LinearGradient(
          begin: Alignment(-1.0, -1.0),
          end: Alignment(1.0, 1.0),
          colors: [
            Color(0xFFE3ECFF),
            Color(0xFFF0F4FF),
            Color(0xFFE8F0FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B8DD6).withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBirbAnimation(),
          const SizedBox(height: 20),
          Text(
            _studentName.isNotEmpty 
              ? _translationService.getTranslation(
                  'student.dashboard.welcomeBack.withName',
                  _languageProvider.currentLanguage ?? 'en',
                ).replaceAll('{name}', _studentName.capitalize())
              : _translationService.getTranslation(
                  'student.dashboard.welcomeBack.withoutName',
                  _languageProvider.currentLanguage ?? 'en',
                ),
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'student.dashboard.accessResources',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: material.LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            '$_userPoints',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Text(
            _fruitEmoji,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 4, bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                TranslatedText(
                  'student.dashboard.quickActions',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _features.length,
                  itemBuilder: (context, index) => _buildFeatureCard(
                    context: context,
                    feature: _features[index],
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required Map<String, dynamic> feature,
    required int index,
  }) {
    final gradientColors = [
      [Color(0xFFF0F7FF), Color(0xFFE6F0FF), Colors.white], // Blue
      [Color(0xFFFDF2F8), Color(0xFFFCE7F3), Colors.white], // Pink
      [Color(0xFFF0FDF4), Color(0xFFDCFCE7), Colors.white], // Green
    ][index % 3];
    
    final borderColors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFFEC4899), // Pink
      Color(0xFF22C55E), // Green
    ];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: material.LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColors[index % 3].withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B8DD6).withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: feature['builder']),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: borderColors[index % 3].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColors[index % 3].withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    feature['icon'],
                    size: 26,
                    color: borderColors[index % 3],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translationService.getTranslation(
                          'student.dashboard.features.${feature['section']}.title',
                          _languageProvider.currentLanguage ?? 'en',
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _translationService.getTranslation(
                          'student.dashboard.features.${feature['section']}.subtitle',
                          _languageProvider.currentLanguage ?? 'en',
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _menuNotifier,
      builder: (context, isMenuOpen, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (isMenuOpen)
              Positioned(
                bottom: 80,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildFeatureButton(
                              title: TranslatedText(
                                'student.dashboard.menu.profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              icon: Icons.person,
                              color: Color(0xFF60A5FA),
                              onTap: () {
                                _menuNotifier.value = false;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StudentProfile(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            _buildFeatureButton(
                              title: TranslatedText(
                                'student.dashboard.menu.leaderboard',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              icon: Icons.leaderboard,
                              color: Color(0xFF60A5FA),
                              onTap: () {
                                _menuNotifier.value = false;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StudentLeaderboard(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 12),
                            _buildFeatureButton(
                              title: TranslatedText(
                                'student.dashboard.menu.logout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              icon: Icons.logout,
                              color: Colors.red,
                              onTap: () {
                                _menuNotifier.value = false;
                                _handleLogout(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Main Menu Button
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF60A5FA),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF60A5FA).withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _menuNotifier.value = !_menuNotifier.value,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AnimatedRotation(
                        duration: Duration(milliseconds: 300),
                        turns: isMenuOpen ? 0.5 : 0,
                        child: Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureButton({
    required Widget title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              title,
              SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthorizedAccessScreen(String message) {
    return _UnauthorizedAccessScreen(
      message: message,
      onTimerComplete: () {
        Navigator.of(context).pushReplacementNamed('/home');
      },
      translationService: _translationService,
    );
  }
}

// Add this class for the fruit particles
class FruitParticle {
  String emoji;
  Offset position;
  double size;
  double speed;
  double angle;
  double rotation;
  double opacity;
  
  FruitParticle({
    required this.emoji,
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotation,
    required this.opacity,
  });
}

// Add this class at the bottom of your file
class FruitRainPainter extends CustomPainter {
  final List<FruitParticle> particles;
  
  FruitRainPainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (var particle in particles) {
      // Skip rendering particles that are too far off screen
      if (particle.position.dx < -50 || 
          particle.position.dx > size.width + 50 ||
          particle.position.dy < -50 || 
          particle.position.dy > size.height + 50) {
        continue;
      }
      
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      // Draw the main emoji (skip shadow for performance)
      textPainter.text = TextSpan(
        text: particle.emoji,
        style: TextStyle(
          fontSize: particle.size,
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

class _UnauthorizedAccessScreen extends StatefulWidget {
  final String message;
  final VoidCallback onTimerComplete;
  final TranslationLoaderService translationService;

  const _UnauthorizedAccessScreen({
    required this.message,
    required this.onTimerComplete,
    required this.translationService,
  });

  @override
  State<_UnauthorizedAccessScreen> createState() => _UnauthorizedAccessScreenState();
}

class _UnauthorizedAccessScreenState extends State<_UnauthorizedAccessScreen> {
  int _secondsRemaining = 4;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          widget.onTimerComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguage ?? 'en';
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              widget.translationService.getTranslation(
                'student.dashboard.unauthorizedAccess.title',
                currentLanguage,
              ),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(widget.message),
            const SizedBox(height: 24),
            Text(
              widget.translationService.getTranslation(
                'student.dashboard.unauthorizedAccess.redirecting',
                currentLanguage,
              ).replaceAll(
                '{seconds}',
                _secondsRemaining.toString(),
              ).replaceAll(
                '{unit}',
                widget.translationService.getTranslation(
                  _secondsRemaining == 1
                      ? 'student.dashboard.unauthorizedAccess.second'
                      : 'student.dashboard.unauthorizedAccess.seconds',
                  currentLanguage,
                ),
              ),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
