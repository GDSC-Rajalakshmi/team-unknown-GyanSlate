import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/custom_header.dart';  // Correct import path
import '../providers/user_provider.dart';  // Correct import path
import 'admin/question_paper_generator.dart';
import '../widgets/translated_text.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:math';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<bool> _checkAdminAccess(BuildContext context) async {
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
      print(decodedToken);
      if (decodedToken['role'] == 'admin' || decodedToken['role'] == 'all') {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have admin privileges'),
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

  // Enhanced color palette
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color secondaryPurple = Color(0xFF7C3AED);
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightText = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFFFFFFF);

  static final List<Map<String, dynamic>> _features = [
    {
      'title': 'MCQ Generator',
      'subtitle': 'Create AI questions',
      'icon': Icons.question_answer,
      'color': secondaryPurple,
      'builder': (BuildContext context) => const QuestionPaperGenerator(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminAccess(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return _UnauthorizedAccessScreen(
            message: 'Please log in with admin credentials.',
            onTimerComplete: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        }

        return Scaffold(
          backgroundColor: Color(0xFFF8FAFB),
          appBar: AppBar(
            backgroundColor: Color(0xFF4A90E2),
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
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
            title: Text(
              'GyanSlate',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                  icon: Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
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

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF357ABD),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Admin Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your educational content and settings',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4A90E2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ..._features.map((feature) => Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: feature['builder']),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          feature['icon'],
                          color: Color(0xFF4A90E2),
                          size: 26,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              feature['subtitle'],
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 24,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 400.ms)
      .slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad);
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unauthorized Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(widget.message),
            const SizedBox(height: 24),
            Text(
              'Redirecting to home page in $_secondsRemaining ${_secondsRemaining == 1 ? 'second' : 'seconds'}...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}