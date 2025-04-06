import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/translated_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StudentLeaderboard extends StatefulWidget {
  const StudentLeaderboard({super.key});

  @override
  State<StudentLeaderboard> createState() => _StudentLeaderboardState();
}

class _StudentLeaderboardState extends State<StudentLeaderboard> {
  bool _isLoading = true;
  String _currentUserName = '';
  int _currentUserPoints = 0;
  int _currentUserRank = 0;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserName = prefs.getString('student_name') ?? 'Student';
      
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      

      // Fetch current user's points from API
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

      int currentUserPoints = 0;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserPoints = data['score'] ?? 0;
      } else {
        print('Error fetching score: ${response.statusCode}');
        // Fallback to stored points if API fails
        currentUserPoints = prefs.getInt('user_points') ?? 0;
      }

      // Updated leaderboard data with Indian names and states
      final leaderboardData = [
        {'name': 'Priya Ramachandran', 'points': 850, 'state': 'Tamil Nadu'},
        {'name': 'Arjun Krishnan', 'points': 720, 'state': 'Kerala'},
        {'name': 'Deepika Patel', 'points': 695, 'state': 'Gujarat'},
        {'name': currentUserName, 'points': currentUserPoints, 'state': prefs.getString('state') ?? ''},
        {'name': 'Rajesh Kumar', 'points': 580, 'state': 'Tamil Nadu'},
        {'name': 'Ananya Sharma', 'points': 545, 'state': 'Karnataka'},
        {'name': 'Karthik Sundaram', 'points': 510, 'state': 'Tamil Nadu'},
        {'name': 'Meena Lakshmi', 'points': 485, 'state': 'Andhra Pradesh'},
        {'name': 'Vijay Subramaniam', 'points': 460, 'state': 'Tamil Nadu'},
        {'name': 'Kavitha Rajan', 'points': 435, 'state': 'Tamil Nadu'},
      ];

      // Sort by points
      leaderboardData.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
      
      // Find current user rank
      final userRank = leaderboardData.indexWhere((user) => user['name'] == currentUserName) + 1;

      setState(() {
        _currentUserName = currentUserName;
        _currentUserPoints = currentUserPoints;
        _currentUserRank = userRank;
        _leaderboardData = leaderboardData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: LeaderboardBackgroundPainter(),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildTopThree(),
                      SizedBox(height: 20),
                      _buildUserRankCard(),
                      SizedBox(height: 20),
                      Expanded(
                        child: _buildLeaderboardList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          TranslatedText(
            'leaderboard',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    if (_leaderboardData.length < 3) return SizedBox.shrink();

    return Container(
      height: 260,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Podium platforms
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Second Place Platform
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFC0C0C0).withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Color(0xFFC0C0C0), width: 2),
                  ),
                ),
                // First Place Platform
                Container(
                  width: 120,
                  height: 100,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700).withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Color(0xFFFFD700), width: 2),
                  ),
                ),
                // Third Place Platform
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFCD7F32).withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Color(0xFFCD7F32), width: 2),
                  ),
                ),
              ],
            ),
          ),
          // Winners
          Positioned(
            bottom: 90,
            left: 16,
            child: SizedBox(
              width: 100,
              child: _buildWinnerItem(_leaderboardData[1], 2, Color(0xFFC0C0C0)),
            ),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: _buildWinnerItem(_leaderboardData[0], 1, Color(0xFFFFD700)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            right: 16,
            child: SizedBox(
              width: 100,
              child: _buildWinnerItem(_leaderboardData[2], 3, Color(0xFFCD7F32)),
            ),
          ),
          // Position numbers
          Positioned(
            bottom: 20,
            left: 16,
            child: SizedBox(
              width: 100,
              child: Center(
                child: Text(
                  '2',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC0C0C0),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '1',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: SizedBox(
              width: 100,
              child: Center(
                child: Text(
                  '3',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCD7F32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerItem(Map<String, dynamic> user, int position, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (position == 1) ...[
          Icon(
            Icons.workspace_premium,
            color: color,
            size: 32,
          ).animate()
            .scale(delay: 400.ms, duration: 600.ms)
            .shake(delay: 1000.ms),
          SizedBox(height: 4),
        ],
        Container(
          width: position == 1 ? 70 : 60,
          height: position == 1 ? 70 : 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user['name'][0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: position == 1 ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                user['name'],
                style: GoogleFonts.poppins(
                  fontSize: position == 1 ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${user['points']} pts',
                style: GoogleFonts.poppins(
                  fontSize: position == 1 ? 12 : 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 200 * position))
      .slideY(begin: 0.2);
  }

  Widget _buildUserRankCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'yourRanking',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '#$_currentUserRank',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _currentUserPoints.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(width: 4),
                TranslatedText(
                  'points',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn()
      .slideY(begin: 0.2);
  }

  Widget _buildLeaderboardList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: _leaderboardData.length,
        itemBuilder: (context, index) {
          final user = _leaderboardData[index];
          final isCurrentUser = user['name'] == _currentUserName;
          
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser ? Color(0xFF3B82F6).withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrentUser ? Color(0xFF3B82F6) : Colors.grey[200],
                  ),
                  child: Center(
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      TranslatedText(
                        'states.${user['state'].replaceAll(' ', '')}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? Color(0xFF3B82F6).withOpacity(0.2)
                        : Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        user['points'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? Color(0xFF3B82F6) : Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 4),
                      TranslatedText(
                        'points',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? Color(0xFF3B82F6) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.2);
        },
      ),
    );
  }
}

class LeaderboardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient for the entire page
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3A8A),
          Color(0xFF1E3A8A),
          Color(0xFF1E3A8A).withOpacity(0.9),
          Color(0xFF1E3A8A).withOpacity(0.0),
        ],
        stops: [0.0, 0.3, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw the background for full height
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw vertical lines for the entire height
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

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 