import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Make layout responsive
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B4EFF),
              Color(0xFF9747FF),
              Color(0xFF8A2BE2),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 40 : 24,
                    vertical: isWeb ? 40 : 20,
                  ),
                  child: Column(
                    children: [
                      // Animated logo
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms)
                        .scale(delay: 200.ms),

                      SizedBox(height: 40),

                      // Animated welcome text
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Welcome to\nAI Assessment System',
                            textAlign: TextAlign.center,
                            textStyle: TextStyle(
                              fontSize: isWeb ? 40 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            speed: Duration(milliseconds: 100),
                          ),
                        ],
                        totalRepeatCount: 1,
                      ),

                      SizedBox(height: 16),

                      Text(
                        'Select your role to hello',
                        style: TextStyle(
                          fontSize: isWeb ? 20 : 18,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ).animate()
                        .fadeIn(delay: 1000.ms)
                        .slideY(begin: 0.3),

                      Spacer(),

                      // Role buttons with staggered animation
                      ..._buildAnimatedRoleButtons(context),

                      Spacer(),

                      // Footer text
                      Text(
                        '© 2024 AI Assessment System',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
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
    );
  }

  List<Widget> _buildAnimatedRoleButtons(BuildContext context) {
    final roles = [
      {'title': 'Admin', 'icon': Icons.admin_panel_settings, 'color': Color(0xFFFF6B6B)},
      {'title': 'Teacher', 'icon': Icons.school, 'color': Color(0xFF4ECDC4)},
      {'title': 'Student', 'icon': Icons.person, 'color': Color(0xFFFFBE0B)},
    ];

    return roles.asMap().entries.map((entry) {
      final index = entry.key;
      final role = entry.value;
      
      return Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _buildRoleButton(
          role['title'] as String,
          context,
          role['icon'] as IconData,
          role['color'] as Color,
        ).animate()
          .fadeIn(delay: Duration(milliseconds: 1200 + (index * 200)))
          .slideX(begin: 0.2),
      );
    }).toList();
  }

  Widget _buildRoleButton(String role, BuildContext context, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          // Add button press animation here
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: color, backgroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          padding: EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            SizedBox(width: 16),
            Text(
              role,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 18, color: color),
          ],
        ),
      ),
    );
  }
} 