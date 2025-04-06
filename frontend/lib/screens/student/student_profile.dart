import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/translated_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/state_fruits.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _isLoading = true;
  String _name = '';
  String _rollNumber = '';
  String _class = '';
  String _state = '';
  int _points = 0;
  int _testsCompleted = 0;
  double _accuracy = 0.0;
  List<Map<String, dynamic>> _badges = [];
  String _medalType = ''; // 'gold', 'silver', or 'bronze'

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      print('Starting to load profile data...'); // Debug start
      final prefs = await SharedPreferences.getInstance();

      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      // Fetch score from API
      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/student/my_score'),
        headers: {'Content-Type': 'application/json',
         'Authorization': 'Bearer $token', // Add the token to headers
         },
        body: jsonEncode({
          'class': prefs.getString('class') ?? '',
          'roll_num': int.tryParse(prefs.getString('rollNumber') ?? '0') ?? 0,
          'state': prefs.getString('state') ?? '',
        }),
      );

      int points = 0;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        points = data['score'] ?? 0;
        print('Score: $points');
      } else {
        print('Error fetching score: ${response.statusCode}');
        // Fallback to stored points if API fails
        points = prefs.getInt('user_points') ?? 0;
      }
      
      // Determine medal based on points
      final medalType = _determineMedalType(points);
      
      // Updated badges with translation keys
      final badges = [
        {
          'nameKey': 'quickLearner',
          'descKey': 'quickLearnerDesc',
          'icon': '🚀',
          'isUnlocked': points >= 100,
        },
        {
          'nameKey': 'mathWizard',
          'descKey': 'mathWizardDesc',
          'icon': '🧮',
          'isUnlocked': points >= 200,
        },
        {
          'nameKey': 'scienceExplorer',
          'descKey': 'scienceExplorerDesc',
          'icon': '🔬',
          'isUnlocked': points >= 300,
        },
        {
          'nameKey': 'languageMaster',
          'descKey': 'languageMasterDesc',
          'icon': '📚',
          'isUnlocked': points >= 400,
        },
      ];
      
      setState(() {
        _name = prefs.getString('student_name') ?? 'Student';
        _rollNumber = prefs.getString('rollNumber') ?? '';
        _class = prefs.getString('class') ?? '';
        _state = prefs.getString('state') ?? '';
        _points = points;
        _badges = badges;
        _medalType = medalType;
        _isLoading = false;
        
        // Print final state values
        print('Final state values:');
        print('Name: $_name');
        print('Roll Number: $_rollNumber');
        print('Class: $_class');
        print('State: $_state');
        print('Points: $_points');
      });
    } catch (e) {
      print('Error loading profile data: $e');
      print('Error stack trace: ${StackTrace.current}'); // Print stack trace
      setState(() => _isLoading = false);
    }
  }

  String _determineMedalType(int points) {
    if (points >= 300) return 'gold';
    if (points >= 200) return 'silver';
    if (points >= 100) return 'bronze';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomPaint(
                  painter: VerticalLinesPainter(),
                  size: Size.infinite,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TranslatedText(
                              'profilePage',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildStudentCard(),
                              _buildRankAndPoints(),
                              SizedBox(height: 20),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: _buildMedalStatus(),
                              ),
                              SizedBox(height: 20),
                              _buildAchievementShowcase(),
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: 55),
            padding: EdgeInsets.fromLTRB(25, 70, 25, 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E3A8A).withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.numbers_rounded, _rollNumber, 'rollNo'),
                    _buildInfoChip(Icons.school_rounded, _class, 'class'),
                    _buildStateChip(),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF60A5FA),
                      Color(0xFF3B82F6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF60A5FA).withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 2000.ms, delay: 200.ms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String translationKey) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF3B82F6).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFF3B82F6)),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 4),
          TranslatedText(
            translationKey,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF3B82F6).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF3B82F6)),
          SizedBox(width: 6),
          TranslatedText(
            'states.$_state',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRankAndPoints() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'totalPoints',
              _points.toString(),
              StateFruits.getStateFruit(_state).emoji,
              Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'rank',
              '#${(_points ~/ 100 + 1).toString()}',
              '👑',
              Color(0xFFFBBF24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String labelKey, String value, String emoji, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TranslatedText(
                  labelKey,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4),
              Text(
                emoji,
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, duration: 400.ms);
  }

  Widget _buildMedalStatus() {
    final medalColors = {
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'bronze': Color(0xFFCD7F32),
    };

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (medalColors[_medalType] ?? Colors.grey[400])!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.military_tech,
                  size: 32,
                  color: medalColors[_medalType] ?? Colors.grey[400],
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      _medalType.isEmpty ? 'noMedalYet' : '${_medalType}Medal',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(height: 4),
                    TranslatedText(
                      _medalType.isEmpty 
                          ? 'earnPointsForMedal'
                          : 'nextMilestone',
                      params: {
                        'points': _medalType.isEmpty 
                            ? '100'
                            : _getNextMedalPoints().toString(),
                      },
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_medalType.isNotEmpty) ...[
            SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _calculateMedalProgress(),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  medalColors[_medalType] ?? Colors.grey[400]!,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, duration: 400.ms);
  }

  double _calculateMedalProgress() {
    switch (_medalType) {
      case 'bronze':
        return (_points - 100) / 100; // Progress between 100-200
      case 'silver':
        return (_points - 200) / 100; // Progress between 200-300
      case 'gold':
        return 1.0; // Full progress
      default:
        return _points / 100; // Progress towards bronze
    }
  }

  Widget _buildNextAchievement() {
    Map<String, dynamic> defaultAchievement = {
      'name': 'All Achieved!',
      'icon': '🎉',
      'description': 'You\'ve unlocked all achievements',
    };

    // Find the next locked achievement
    Map<String, dynamic> nextAchievement;
    try {
      nextAchievement = _badges.firstWhere(
        (badge) => !badge['isUnlocked'],
        orElse: () => defaultAchievement,
      );
    } catch (e) {
      nextAchievement = defaultAchievement;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Achievement',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  nextAchievement['icon'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextAchievement['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      nextAchievement['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
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
      .fadeIn(delay: 300.ms)
      .slideY(begin: 0.2);
  }

  // Helper method to get next medal points requirement
  int _getNextMedalPoints() {
    if (_medalType.isEmpty) return 100;
    if (_medalType == 'bronze') return 200;
    if (_medalType == 'silver') return 300;
    return 0;
  }

  Widget _buildAchievementBadge(Map<String, dynamic> badge, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              badge['icon'],
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
        SizedBox(height: 8),
        TranslatedText(
          badge['nameKey'],
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index))
      .slideY(begin: 0.2, duration: Duration(milliseconds: 200));
  }

  Widget _buildLockedAchievementCard(Map<String, dynamic> badge) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      badge['icon'],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  badge['nameKey'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                TranslatedText(
                  badge['descKey'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms)
      .slideX(begin: 0.2);
  }

  Widget _buildAchievementShowcase() {
    final unlockedBadges = _badges.where((badge) => badge['isUnlocked']).toList();
    final lockedBadges = _badges.where((badge) => !badge['isUnlocked']).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlocked Achievements Section
          if (unlockedBadges.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                TranslatedText(
                  'achievements',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: unlockedBadges.asMap().entries.map((entry) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 100) / 3,
                  child: _buildAchievementBadge(entry.value, entry.key),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
          ],
          
          // Locked Achievements Section
          if (lockedBadges.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF1E3A8A), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: TranslatedText(
                    'achievementsToUnlock',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              children: lockedBadges.map((badge) => Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: _buildLockedAchievementCard(badge),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class VerticalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3A8A),
          Color(0xFF1E3A8A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Vertical lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 