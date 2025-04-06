import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/common_header.dart';

class TeacherDashboardLayout extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const TeacherDashboardLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  State<TeacherDashboardLayout> createState() => _TeacherDashboardLayoutState();
}

class _TeacherDashboardLayoutState extends State<TeacherDashboardLayout> {
  int _selectedIndex = 0;

  void _handleNavigation(int index) {
    // Close the drawer first
    Navigator.of(context).pop();

    // Use a Future to navigate after the drawer closes
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _selectedIndex = index;
      });

      // Navigate to the appropriate route
      switch (index) {
        case 0:
          Navigator.of(context).pushReplacementNamed(AppRoutes.teacherDashboard);
          break;
        case 1:
          Navigator.of(context).pushReplacementNamed(AppRoutes.createAssessment);
          break;
        case 2:
          Navigator.of(context).pushReplacementNamed(AppRoutes.studentAnalysis);
          break;
        case 3:
          Navigator.of(context).pushReplacementNamed(AppRoutes.settings);
          break;
        case 4:
          // Handle Logout
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(title: widget.title),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Teacher Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'teacher@educationguide.com',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () => _handleNavigation(0),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Create Assessment'),
              selected: _selectedIndex == 1,
              onTap: () => _handleNavigation(1),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Student Analysis'),
              selected: _selectedIndex == 2,
              onTap: () => _handleNavigation(2),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              selected: _selectedIndex == 3,
              onTap: () => _handleNavigation(3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              selected: _selectedIndex == 4,
              onTap: () => _handleNavigation(4),
            ),
          ],
        ),
      ),
      body: widget.body,
    );
  }
}