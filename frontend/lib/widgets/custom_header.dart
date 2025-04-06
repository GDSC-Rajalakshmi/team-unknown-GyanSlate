import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CustomHeader extends StatefulWidget implements PreferredSizeWidget {
  final String appName;
  final String? userName;
  final Color primaryColor;
  final LogoStyle logoStyle;
  final List<Widget>? actions;
  final bool isStudentDashboard;
  final int points;
  final String fruitEmoji;
  final bool showAnimations;
  final TextStyle? pointsStyle;
  final double emojiSize;
  final BoxDecoration? pointsContainerDecoration;
  final VoidCallback? onPointsContainerTap;

  const CustomHeader({
    super.key,
    this.appName = "EdGenius",
    this.userName,
    this.primaryColor = const Color(0xFF2196F3),
    this.logoStyle = LogoStyle.style1,
    this.actions,
    this.isStudentDashboard = false,
    this.points = 0,
    this.fruitEmoji = "",
    this.showAnimations = false,
    this.pointsStyle,
    this.emojiSize = 20.0,
    this.pointsContainerDecoration,
    this.onPointsContainerTap,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}

class _CustomHeaderState extends State<CustomHeader> with SingleTickerProviderStateMixin {
  final List<FruitParticle> _fruitParticles = [];
  bool _isRaining = false;
  late int _displayedPoints;
  
  @override
  void initState() {
    super.initState();
    _displayedPoints = widget.points;
  }
  
  @override
  void didUpdateWidget(CustomHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update displayed points when widget is updated with new points
    if (oldWidget.points != widget.points) {
      setState(() {
        _displayedPoints = widget.points;
      });
    }
  }

  void _startFruitRain() {
    if (_isRaining) return;
    
    setState(() {
      _isRaining = true;
      _fruitParticles.clear();
      
      // Create 20 fruit particles
      for (int i = 0; i < 20; i++) {
        _fruitParticles.add(FruitParticle(
          emoji: widget.fruitEmoji,
          position: Offset(
            Random().nextDouble() * MediaQuery.of(context).size.width,
            -50 - Random().nextDouble() * 100,
          ),
          size: 20 + Random().nextDouble() * 20,
          speed: 2 + Random().nextDouble() * 5,
          angle: -0.2 + Random().nextDouble() * 0.4,
        ));
      }
    });
    
    // Animate the particles
    _animateParticles();
  }
  
  void _animateParticles() async {
    if (!_isRaining) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    bool allParticlesOffScreen = true;
    
    for (var particle in _fruitParticles) {
      particle.position = Offset(
        particle.position.dx + particle.angle * particle.speed,
        particle.position.dy + particle.speed,
      );
      
      if (particle.position.dy < screenHeight + 100 && 
          particle.position.dx > -50 && 
          particle.position.dx < screenWidth + 50) {
        allParticlesOffScreen = false;
      }
    }
    
    if (allParticlesOffScreen) {
      setState(() {
        _isRaining = false;
      });
    } else {
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
      _animateParticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: statusBarHeight + 8,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.primaryColor.withBlue(min(widget.primaryColor.blue + 30, 255)),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  _buildAppName(),
                ],
              ),
              if (widget.isStudentDashboard) 
                GestureDetector(
                  onTap: widget.onPointsContainerTap ?? _startFruitRain,
                  child: _buildStudentPoints(),
                )
              else if (widget.userName != null)
                _buildProfileSection(),
            ],
          ),
        ),
        
        // Render fruit particles
        if (_isRaining)
          ...(_fruitParticles.map((particle) => Positioned(
            left: particle.position.dx,
            top: particle.position.dy,
            child: Text(
              particle.emoji,
              style: TextStyle(
                fontSize: particle.size,
              ),
            ),
          ))),
      ],
    );
  }

  Widget _buildStudentPoints() {
    // Format large numbers with K, M, B suffixes
    String formatPoints(int points) {
      if (points >= 1000000000) {
        return "${(points / 1000000000).toStringAsFixed(1)}B";
      } else if (points >= 1000000) {
        return "${(points / 1000000).toStringAsFixed(1)}M";
      } else if (points >= 1000) {
        return "${(points / 1000).toStringAsFixed(1)}K";
      } else {
        return points.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: widget.pointsContainerDecoration ?? BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Vibrant purple
            Color(0xFFEC4899), // Vibrant pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Points text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star icon instead of sparkle
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                // Points text with ConstrainedBox
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 70),
                  child: Text(
                    formatPoints(_displayedPoints),
                    overflow: TextOverflow.ellipsis,
                    style: widget.pointsStyle ?? GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(1.0, 1.0),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Fruit emoji
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.0,
              ),
            ),
            child: Text(
              widget.fruitEmoji,
              style: TextStyle(
                fontSize: widget.emojiSize - 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              _getLogoIcon(),
              color: widget.primaryColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppName() {
    return Row(
      children: [
        Text(
          'Ed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1,
          ),
        ),
        Text(
          'Genius',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            widget.userName!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(widget.userName ?? ""),
          style: TextStyle(
            color: widget.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getLogoIcon() {
    switch (widget.logoStyle) {
      case LogoStyle.style1:
        return Icons.school_outlined;
      case LogoStyle.style2:
        return Icons.psychology;
      case LogoStyle.style3:
        return Icons.auto_awesome;
      case LogoStyle.style4:
        return Icons.lightbulb_outline;
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}

class FruitParticle {
  String emoji;
  Offset position;
  double size;
  double speed;
  double angle; // For slight horizontal movement
  
  FruitParticle({
    required this.emoji,
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

enum LogoStyle {
  style1,
  style2,
  style3,
  style4,
}