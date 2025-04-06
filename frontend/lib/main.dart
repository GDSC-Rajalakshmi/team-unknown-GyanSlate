import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'screens/admin_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/student/student_login.dart';
import 'providers/assessment_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/lecture_video_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/header_themes.dart';
import 'providers/user_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'providers/language_provider.dart';
import 'widgets/translated_text.dart';
import 'widgets/language_selector.dart';
import 'services/translation_loader_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/authorization_page.dart';
import 'widgets/nebula_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting app initialization...');
  
  try {
    // Initialize translation service first and await its completion
    final translationService = TranslationLoaderService();
    print('Loading translations...');
    await translationService.loadTranslations();
    print('Translations loaded successfully');
    
    // Initialize shared preferences
    final prefs = await SharedPreferences.getInstance();
    print('Shared preferences initialized');
    
    // Initialize database service
    final dbService = DatabaseService();
    print('Database service initialized');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AssessmentProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider(prefs)),
          ChangeNotifierProvider(create: (_) => LectureVideoProvider(dbService)),
          Provider.value(value: dbService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    // You might want to show an error screen here
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GyanSlate',
      theme: ThemeData(
        primaryColor: HeaderThemes.themes['blue'],
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthorizationPage(),
        '/home': (context) => const MyHomePage(),
        '/admin': (context) => const AdminDashboard(),
        '/teacher': (context) => const TeacherDashboard(),
        '/student': (context) => const StudentDashboard(),
        '/student-login': (context) => const StudentLogin(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWeb = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Color(0xFF4A90E2)),
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
            tooltip: 'Back to Authorization',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? screenSize.width * 0.1 : 24,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  SizedBox(height: isWeb ? 25 : 30),
                  _buildWelcomeText(isWeb),
                  SizedBox(height: isWeb ? 30 : 40),
                  Container(
                    width: isWeb ? 600 : double.infinity,
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildRoleButtons(context, isWeb),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildLogo() {
  return Container(
    height: 130,
    width: 130,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      // No background color
      boxShadow: [
        BoxShadow(
          color: Color(0xFF4A90E2).withOpacity(0.6), // soft glow
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ],
    ),
    child: ClipOval(
      child: Transform.scale(
        scale: 1.9, // Increase this to make the image larger
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}



  Widget _buildWelcomeText(bool isWeb) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TranslatedText(
          'welcome',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 36 : 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
            letterSpacing: 1.2,
          ),
        ),
        
        SizedBox(height: 14),
        
        TranslatedText(
          'selectRole',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            color: Color(0xFF2C3E50).withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButtons(BuildContext context, bool isWeb) {
    final roles = [
      {'title': 'admin', 'icon': Icons.admin_panel_settings, 'route': '/admin'},
      {'title': 'teacher', 'icon': Icons.school, 'route': '/teacher'},
      {'title': 'student', 'icon': Icons.person, 'route': '/student-login'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('selectRole'),
        SizedBox(height: 20),
        ...roles.asMap().entries.map((entry) {
          final index = entry.key;
          final role = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(bottom: index < roles.length - 1 ? 14 : 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, role['route'] as String),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: isWeb ? 54 : 64,
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 18),
                        Icon(
                          role['icon'] as IconData,
                          size: isWeb ? 20 : 22,
                          color: Color(0xFF4A90E2),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: TranslatedText(
                            role['title'] as String,
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: isWeb ? 18 : 20,
                          color: Color(0xFF4A90E2),
                        ),
                        SizedBox(width: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)))
            .slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad);
        }).toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String translationKey) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
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
        Expanded(
          child: TranslatedText(
            translationKey,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}