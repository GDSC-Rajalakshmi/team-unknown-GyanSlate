import 'package:flutter/material.dart' hide LinearGradient;
import 'package:flutter/material.dart' as material show LinearGradient;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'teacher/assessment_management.dart';
import '../widgets/custom_header.dart';
import '../widgets/translated_text.dart';
import '../providers/language_provider.dart';
import '../services/translation_loader_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'teacher/upload_notes.dart';
import 'dart:async';
import 'package:rive/rive.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  // Rive controller variables
  StateMachineController? controller;
  SMIBool? isIdle;

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      isIdle = controller.findInput<bool>('isIdle') as SMIBool;
      isIdle?.value = true;  // Explicitly set to true
      
      // Ensure other states are false if they exist
      final lookUp = controller.findInput<bool>('isLookUp') as SMIBool?;
      final dance = controller.findInput<bool>('isDance') as SMIBool?;
      
      if (lookUp != null) lookUp.value = false;
      if (dance != null) dance.value = false;
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Updated color palette to match
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightText = Color(0xFF2C3E50);
  static const Color cardBg = Color(0xFFFFFFFF);

  Future<bool> _checkTeacherAccess(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    try {
      final decodedToken = JwtDecoder.decode(token);
      print(decodedToken); // For debugging
      if (decodedToken['role'] == 'teacher' || decodedToken['role'] == 'all') {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have teacher access'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid session. Please log in again'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkTeacherAccess(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return _UnauthorizedAccessScreen(
            message: 'Please log in with teacher credentials.',
            onTimerComplete: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        }

        return Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildFeatureGrid(context),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFFE3ECFF),
      elevation: 0,
      centerTitle: true,
      title: TranslatedText(
        'teacherDashboard.appName',
        style: GoogleFonts.poppins(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: RiveAnimation.asset(
              "assets/animations/birb.riv",
              onInit: _onRiveInit,
              fit: BoxFit.contain,
              stateMachines: const ['birb'],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TranslatedText(
              'teacherDashboard.welcome.title',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: TranslatedText(
              'teacherDashboard.welcome.subtitle',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                TranslatedText(
                  'teacherDashboard.quickActions.title',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          ..._buildFeatureCards(context),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCards(BuildContext context) {
    final features = [
      {
        'titleKey': 'assessment.title',
        'subtitleKey': 'assessment.subtitle',
        'icon': Icons.assessment,
        'route': const AssessmentManagement(),
      },
      {
        'titleKey': 'uploadNotes.title',
        'subtitleKey': 'uploadNotes.subtitle',
        'icon': Icons.upload_file,
        'route': const UploadNotes(),
      },
    ];

    return features.map((feature) => Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF4A90E2).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => feature['route'] as Widget),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF4A90E2).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        'teacherDashboard.quickActions.${feature["titleKey"]}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      TranslatedText(
                        'teacherDashboard.quickActions.${feature["subtitleKey"]}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF4A90E2),
                ),
              ],
            ),
          ),
        ),
      ),
    )).toList();
  }
}

class _UnauthorizedAccessScreen extends StatefulWidget {
  final String message;
  final VoidCallback onTimerComplete;

  const _UnauthorizedAccessScreen({
    required this.message,
    required this.onTimerComplete,
  });

  @override
  State<_UnauthorizedAccessScreen> createState() => _UnauthorizedAccessScreenState();
}

class _UnauthorizedAccessScreenState extends State<_UnauthorizedAccessScreen> {
  int _secondsRemaining = 4;
  late Timer _timer;
  final _translationService = TranslationLoaderService();
  late LanguageProvider _languageProvider;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            TranslatedText(
              'teacherDashboard.unauthorizedAccess.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TranslatedText('teacherDashboard.unauthorizedAccess.message'),
            const SizedBox(height: 24),
            Text(
              _translationService.getTranslation(
                'teacherDashboard.unauthorizedAccess.redirecting',
                _languageProvider.currentLanguage ?? 'en'
              ).replaceAll('{seconds}', _secondsRemaining.toString())
               .replaceAll(
                 '{unit}', 
                 _translationService.getTranslation(
                   _secondsRemaining == 1 
                     ? 'teacherDashboard.unauthorizedAccess.second'
                     : 'teacherDashboard.unauthorizedAccess.seconds',
                   _languageProvider.currentLanguage ?? 'en'
                 )
               ),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
} 